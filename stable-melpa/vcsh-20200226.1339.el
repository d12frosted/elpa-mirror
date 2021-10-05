;;; vcsh.el --- vcsh integration -*- lexical-binding: t -*-

;; Author: Štěpán Němec <stepnem@gmail.com>
;; Created: 2019-07-15 00:46:28 Monday +0200
;; URL: https://gitlab.com/stepnem/vcsh-el
;; Package-Version: 20200226.1339
;; Package-Commit: 7e376436b8f450a5571e19246136ccf77bbdd4f1
;; Keywords: vc, files
;; License: public domain
;; Version: 0.4.4
;; Tested-with: GNU Emacs 27, 28
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; Original idea by Jonas Bernoulli (see the first two links below).

;; This library only provides basic "enter" functionality
;; (`vcsh-link', `vcsh-unlink') and a few convenience commands
;; (`vcsh-new' to init a repo and add files to it,
;; `vcsh-write-gitignore').

;; For Magit integration there's magit-vcsh.el as a separate add-on
;; library.

;; Please note that this library works by creating a regular file
;; named ".git" inside $VCSH_BASE directory (typically $HOME) and does
;; not remove this file automatically, so don't be surprised if your
;; shell suddenly behaves as after "vcsh enter" when inside that
;; directory.  You can use `vcsh-unlink' or simply remove the file to
;; get rid of it.

;; Cf. also:

;; https://github.com/magit/magit/issues/2939
;; https://github.com/magit/magit/issues/460
;; https://github.com/vanicat/magit/blob/t/vcsh/magit-vcsh.el

;; Corrections and constructive feedback appreciated.

;;; Code:

(eval-when-compile (require 'subr-x))   ; string-join, when-let

(defgroup vcsh () "Vcsh integration."
  :group 'vc)

(defun vcsh-absolute-p ()
  "Return non-nil if absolute file paths should be set.
Otherwise use relative paths."
  (not (string= (getenv "VCSH_WORKTREE") "relative")))

(defun vcsh-base ()
  "Return name of vcsh work tree directory."
  (or (getenv "VCSH_BASE") (getenv "HOME")))

(defun vcsh-repo-d ()
  "Return name of directory where vcsh repos are located."
  (or (getenv "VCSH_REPO_D")
      (and (getenv "XDG_CONFIG_HOME")
           (substitute-env-in-file-name "$XDG_CONFIG_HOME/vcsh/repo.d"))
      (substitute-env-in-file-name "$HOME/.config/vcsh/repo.d")))

(defun vcsh-repo-p (dir)
  "Return non-nil if DIR is a vcsh repository."
  (when (string-match-p "[^/]\\.git/?$" dir)
    (let ((default-directory (file-name-as-directory (vcsh-repo-d))))
      (setq dir (file-truename dir))
      (and (file-accessible-directory-p dir)
           (file-equal-p (file-name-directory (directory-file-name dir))
                         default-directory)))))

(defun vcsh-repo-path (repo)
  "Return absolute path of vcsh repository REPO."
  (expand-file-name (concat repo ".git") (vcsh-repo-d)))

(defun vcsh-repos ()
  "Return list of vcsh repo names."
  (mapcar #'file-name-base (directory-files (vcsh-repo-d) nil "^[^.]")))

(defun vcsh-read-repo ()
  "Read vcsh repo directory name interactively."
  (completing-read "vcsh repository: " (vcsh-repos) nil t))

;;;###autoload
(defun vcsh-link (repo)
  "Make REPO become the .git directory for vcsh base directory.
This is similar to vcsh \"enter\" command."
  (interactive (list (vcsh-read-repo)))
  (let ((worktree (vcsh-base))
        (repo-path (vcsh-repo-path repo)))
    (with-temp-file (expand-file-name ".git" worktree)
      (insert "gitdir: " (if (vcsh-absolute-p) repo-path
                           (file-relative-name repo-path worktree)) "\n"))))

;;;###autoload
(defun vcsh-unlink ()
  "Undo the effect of `vcsh-link' (vcsh \"enter\" command)."
  (interactive)
  (delete-file (expand-file-name ".git" (vcsh-base))))

(defun vcsh-command (cmd &rest args)
  "Run vcsh command CMD with ARGS and display the output, if any."
  (when-let ((output (apply #'process-lines "vcsh" cmd args)))
    (display-message-or-buffer
     (concat "\"vcsh " cmd " " (string-join args " ") "\": "
             (string-join output "\n")))))

;;;###autoload
(defun vcsh-new (name files)
  "Init a new vcsh repo and add files to it.
NAME is the repository name, FILES is a list of file names.
After creation, this command also calls `vcsh-write-gitignore'
for the new repo, and runs `vcsh-after-new-functions'."
  (interactive (list (read-string "Repo name: ")
                     (let (fls done)
                       (while (not done)
                         (push (read-file-name "File: " (vcsh-base)) fls)
                         (unless (y-or-n-p (format "%s\n\n%s? "
                                                   (string-join fls "\n")
                                                   "Add more files"))
                           (setq done t)))
                       fls)))
  (vcsh-command "init" name)
  (apply #'vcsh-command "run" name "git" "add" files)
  (vcsh-write-gitignore name)
  (run-hook-with-args 'vcsh-after-new-functions name))

(defcustom vcsh-after-new-functions nil
  "Special (\"abnormal\") hook run after `vcsh-new'.
The functions are called with the name (a string) of the newly
created repo as their sole argument."
  :type 'hook)

;;;###autoload
(defun vcsh-write-gitignore (&optional repo)
  "Run \"vcsh write-gitignore\" for REPO.
With a prefix argument or if REPO is nil, run the command for all vcsh
repositories."
  (interactive (unless current-prefix-arg (list (vcsh-read-repo))))
  (let ((write (apply-partially #'vcsh-command "write-gitignore")))
    (if repo (funcall write repo) (mapc write (vcsh-repos)))))

(defun vcsh-reload ()
  "Reload the vcsh library."
  (interactive)
  (unload-feature 'vcsh t)
  (require 'vcsh))

(provide 'vcsh)
;;; vcsh.el ends here
