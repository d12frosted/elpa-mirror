;;; repo.el --- Running repo from Emacs

;; Author: Damien Merenne
;; URL: https://github.com/canatella/repo-el
;; Package-Version: 20220819.707
;; Package-Commit: b874903f43fc0a33a687789d674cacc2accf2403
;; Created: 2016-01-11
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This package integrate the google repo development cycle into Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:


;;; User customizable variable

(defgroup repo nil
  "Run repo commands from emacs"
  :group 'processes)

(defcustom repo-executable "repo"
  "The repo executable path."
  :type '(file)
  :group 'repo)

(defcustom repo-vc-function nil
  "The function to execute to show git status.

If not set, repo uses `magit-status' if available, `vc-dir' otherwise."
  :type '(function)
  :group 'repo)

;;; Our variables

(defvar repo-workspace nil "The repo workspace associated to the current buffer.")
(make-variable-buffer-local 'repo-workspace)

(defvar repo-project-regexp "^\\(?1:project\\) \\(?2:[^ ]+\\)/\\W+")

;;; Our functions

(defun repo-status-buffer-name (directory)
  "Return the repo status buffer name for DIRECTORY."
  (format "*repo: %s" (file-name-nondirectory (directory-file-name directory))))

(defun repo-status-buffer (directory)
  "Return the repo status buffer for DIRECTORY."
  (get-buffer-create (repo-status-buffer-name directory)))

(defun repo-process-buffer-name (directory)
  "Return the repo process buffer name for DIRECTORY."
  (format "*repo-process: %s" (file-name-nondirectory (directory-file-name directory))))

(defun repo-process-buffer (directory)
  "Return the repo status buffer for DIRECTORY."
  (get-buffer-create (repo-process-buffer-name directory)))

(defun repo-toplevel (&optional directory)
  "Walk up DIRECTORY hierarchy to find one holding a .repo directory.

Use `default-directory' if DIRECTORY is nil."
  (let ((workspace (locate-dominating-file (or directory default-directory) ".repo")))
    (when workspace
      (file-name-as-directory (file-truename workspace)))))

(defun repo-read-workspace ()
  "Read a repo workspace in the minibuffer, with completion."
  (file-name-as-directory
   (read-directory-name "Repo workspace: " (or (repo-toplevel) default-directory))))

(defun repo-workspace-p (directory)
  "True if DIRECTORY look like a repo workspace."
  (file-accessible-directory-p (concat (file-name-as-directory directory) ".repo")))

(defun repo-revert-buffer (ignore-auto no-confirm)
  "Reload a Repo status buffer.

IGNORE-AUTO and NO-CONFIRM has no effect here."
  (let ((inhibit-read-only t))
    (repo-status repo-workspace)))

(defun repo-internal-vc-function ()
    "Return the function to call for opening git status buffer."
    (if repo-vc-function
        repo-vc-function
      (if (fboundp 'magit-status-setup-buffer)
          (function magit-status-setup-buffer)
        (function vc-dir))))

(defun repo-call-vc-function (dirname)
    "Call `repo-vc-function' with DIRNAME as argument."
  (funcall (repo-internal-vc-function) dirname))

(defun repo-find ()
  "Find item at point.
If point is on
... a file line, find that file.
... a project line, run `repo-vc-function' for that project.
... the manifest line, run `repo-vc-function' for the manifests directory.
... the workspace line, dun `dired' on that directory"
  (interactive)
  (save-excursion
    (goto-char (line-beginning-position))
    (cond ((looking-at "^ [-AMDRCTU][-md]\t\\(.*\\)")
                   (let ((file (match-string 1))
                                 (project (progn (re-search-backward "project +\\([^ ]+\\)" nil t)
                                                                 (match-string 1))))
                         (find-file (concat repo-workspace project file))))
                  ((looking-at "project +\\([^ ]+\\)")
           (let ((project (match-string 1)))
             (repo-call-vc-function (concat repo-workspace project))))
          ((looking-at-p "Manifest groups:") nil)
          ((looking-at "Manifest \\(merge \\)?branch: +\\(.*\\)$")
           (repo-call-vc-function (concat repo-workspace ".repo/manifests/")))
          ((looking-at "Workspace: +\\([^ ]+\\)$")
           (dired (match-string 1))))))

(defun repo-exec (directory sentinel &rest args)
  "Run repo in DIRECTORY, outputing to BUFFER with ARGS.

Run SENTINEL after the process exits."
  (let* ((default-directory (file-name-as-directory directory))
         (buffer (repo-process-buffer directory))
         (repo-args (append (list "repo" buffer repo-executable
                                  "--color=never" "--no-pager") args))
         proc)
    (with-current-buffer buffer
      (insert (format "Running repo %s\n" (mapconcat 'identity args " "))))
    (setq proc (apply 'start-process repo-args))
    (set-process-sentinel proc sentinel)
    proc))

(defun repo-default-sentinel (proc event)
  "Cleanup after running repo status.

PROC is the repo status process, EVENT is the sentinel event."
  (with-current-buffer (process-buffer proc)
    ;; Make sure we are at the end of the buffer
    (goto-char (point-max))
    (insert (format "Repo process %s\n" event))
    (unless (string-match event "finished\n")
      (error "Repo process failed, see %s for errors." (buffer-name)))))


(defun repo-init-default-directory (url &optional revision name)
  "Initialize repo WORKSPACE with manifest URL, manifest REVISION and manifest NAME."
  (interactive
   (list (read-string "Manifest URL: ")
         (read-string "Manifest revision: " "refs/heads/master")
         (read-string "Manifest name: " "default.xml")))
  (repo-exec default-directory (function repo-default-sentinel)
             "-u" url "-b" revision "-m" name))

(defun repo-call-init-default-directory (workspace)
  "Interactively call `repo-init-default-directory' with WORKSPACE."
  (when (y-or-n-p (format "%s does not look like a repo workspace, initialize it? "
                          workspace))
    (let ((default-directory workspace))
      (call-interactively (function repo-init-default-directory)))
    't))

(defun repo-next-project ()
  "Move to next project in Repo status buffer."
  (interactive)
  (let ((pos (point)))
    (save-excursion
      (forward-line)
      (when (re-search-forward repo-project-regexp nil t)
        (setq pos (point))))
    (when (> pos (point))
      (goto-char pos)
      (beginning-of-line))))

(defun repo-previous-project ()
  "Move to previous project in Repo status buffer."
  (interactive)
  (re-search-backward repo-project-regexp nil t))



;;;###autoload
(defun repo-status (workspace)
  "Show the status of the Repo WORKSPACE in a buffer.

With a prefix argument prompt for a directory to be used as workspace."
  (interactive
   (list (or (and (not current-prefix-arg) (repo-toplevel))
             (repo-read-workspace))))
  (unless (repo-workspace-p workspace)
    (unless (repo-call-init-default-directory workspace)
      (user-error "Repo needs an initialized workspace")))
  (let ((status-buffer (get-buffer (repo-status-buffer-name workspace))))
    (when status-buffer
      (switch-to-buffer status-buffer)))
  (repo-status-exec-info workspace))


(defun repo-status-exec-info (workspace)
  "Run repo info for WORKSPACE."
  (repo-exec workspace (function repo-status-exec-status) "info" "-lo"))

(defun repo-status-exec-status (proc event)
  "Cleanup after running repo info and start repo status.

PROC is the repo info process, EVENT is the sentinel event."
  (repo-default-sentinel proc event)
  (with-current-buffer (process-buffer proc)
    (let ((workspace default-directory))
      (repo-exec default-directory (function repo-status-parse-buffer) "status" "-j" "1"))))

(defun repo-status-insert (buffer msg &rest args)
  "Insert into BUFFER the value of `format' called with MSG and ARGS."
  (with-current-buffer buffer
    (insert (apply (function format) msg args))))

(defun repo-status-parse-buffer (proc event)
  "Cleanup after running repo status and parse process buffer.

PROC is the repo info process, EVENT is the sentinel event."
  (repo-default-sentinel proc event)
  (with-current-buffer (process-buffer proc)
    (let* ((workspace default-directory)
           (status-name (repo-status-buffer-name workspace))
           (status (get-buffer-create (format "%s-temp*" status-name)))
           (parse-error (lambda ()
                          (kill-buffer status)
                          (error "Unable to parse repo output from %s"
                                 (repo-process-buffer-name workspace)))))
      (save-excursion
        (goto-char (point-max))
        (repo-status-insert status "% -23s%s\n" "Workspace:" workspace)
        (unless (re-search-backward "Running repo info -lo" nil t)
          (funcall parse-error))
        (forward-line)
        (unless (looking-at "^Manifest branch: \\(.*\\)$")
          (funcall parse-error))
        (repo-status-insert status "% -23s%s\n" "Manifest branch:" (match-string 1))
        (forward-line)
        (unless (looking-at "^Manifest merge branch: \\(.*\\)$")
          (funcall parse-error))
        (repo-status-insert status "% -23s%s\n" "Manifest merge branch:" (match-string 1))
        (forward-line)
        (unless (looking-at "^Manifest groups: \\(.*\\)$")
          (funcall parse-error))
        (repo-status-insert status "% -23s%s\n\n" "Manifest groups:" (match-string 1))
        (unless (re-search-forward "Running repo status" nil t)
          (funcall parse-error))
        (forward-line)
        (while (not (looking-at "Repo process finished"))
          (repo-status-insert status "%s" (thing-at-point 'line))
          (forward-line))
        (repo-status-setup-buffer status workspace)
        ))))

(defun repo-status-setup-buffer (buffer workspace)
  "Setup the repo status BUFFER for WORKSPACE."
  (with-current-buffer buffer
    (setq-local default-directory workspace)
    (repo-mode)
    (let ((name (repo-status-buffer-name workspace)))
      (if (get-buffer name)
          (progn
            (with-current-buffer name
              (let ((inhibit-read-only 't))
                (erase-buffer)
                (insert-buffer-substring buffer)))
            (kill-buffer)
            (switch-to-buffer name))
        (progn
          (rename-buffer name)
          (switch-to-buffer buffer))))))

(defun repo-status-bury-buffer (&optional kill-buffer)
  "Bury the current buffer.

With a prefix argument, sets KILL-BUFFER and  kill the buffer instead."
  (interactive "P")
  (quit-window kill-buffer))

(defvar repo-font-lock-defaults
  `((
     ("^project \\([^ ]+\\)/\\W+\\(\\(*** NO BRANCH ***\\)\\|\\(branch \\(\\w+\\)\\)\\)$" . ((1 font-lock-type-face) (5 font-lock-function-name-face)))
     ("^Workspace: +\\(.*\\)$" . (1 font-lock-function-name-face))
     ("^Manifest.* branch: +\\(.*\\)$" . (1 font-lock-keyword-face))
     ("^ \\([-AMDRCTU][-md]\\)" . (1 font-lock-warning-face))
     ))
  "Keywords for repo status buffer syntax highlighting.")

(defvar repo-mode-map nil "Keymap for repo-mode.")
(when (not repo-mode-map)
  (setq repo-mode-map (make-sparse-keymap))
  (define-key repo-mode-map (kbd "g")       #'revert-buffer)
  (define-key repo-mode-map (kbd "RET")     #'repo-find)
  (define-key repo-mode-map (kbd "q")       #'repo-status-bury-buffer)
  (define-key repo-mode-map (kbd "p")       #'previous-line)
  (define-key repo-mode-map (kbd "n")       #'next-line)
  (define-key repo-mode-map (kbd "f")       #'forward-char)
  (define-key repo-mode-map (kbd "b")       #'backward-char)
  (define-key repo-mode-map (kbd "C-c C-p") #'repo-previous-project)
  (define-key repo-mode-map (kbd "C-c C-n") #'repo-next-project))

(define-derived-mode repo-mode fundamental-mode "Repo"
  "A mode for repo status buffer."
  (setq-local font-lock-defaults repo-font-lock-defaults)
  (setq-local revert-buffer-function #'repo-revert-buffer)
  (setq-local repo-workspace default-directory)
  (read-only-mode))


(provide 'repo)

;;; repo.el ends here
