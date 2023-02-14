;;; rhq.el --- Client for rhq                        -*- lexical-binding: t; -*-

;; Copyright (C) 2022  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: tools, extensions

;; Version: 0.7.1
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/ROCKTAKEY/rhq
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Client for rhq.

;; The command rhq is available on https://github.com/ubnt-intrepid/rhq.
;; This command manage all your repository.

;;; Code:

(require 'shell)
(require 'cl-lib)

(defgroup rhq nil
  "Client for rhq command."
  :prefix "rhq-"
  :group 'tools)

;; Copied from shell.el in emacs-28.0.91
(defun rhq--split-string-shell-command (string)
  "Split STRING (a shell command) into a list of strings.
General shell syntax, like single and double quoting, as well as
backslash quoting, is respected."
  (with-temp-buffer
    (insert string)
    (let ((comint-file-name-quote-list shell-file-name-quote-list))
      (car (shell--parse-pcomplete-arguments)))))

(defcustom rhq-executable "rhq"
  "Location of rhq executable."
  :group 'rhq
  :type '(choice
          (const "rhq")
          (file :must-match t)))

(defcustom rhq-async-buffer "*rhq*"
  "Output buffer name for `rhq-call-command'."
  :group 'rhq
  :type 'string)

(defcustom rhq-root-directory "~/rhq"
  "Default root directory."
  :group 'rhq
  :type 'directory)

(defconst rhq--subcommands
  '("add"
    "clone"
    "completion"
    "help"
    "import"
    "list"
    "new"
    "refresh")
  "Subcommands available on rhq.")

(defun rhq--make-shell-command-string (&rest args)
  "Join ARGS and make shell command string."
  (mapconcat
   #'shell-quote-argument
   args
   " "))

(defun rhq--read-project (root &optional no-require-match)
  "Read project from user input.
This function listens relative path from ROOT if it is rooted from ROOT.
Otherwise, listens absolute path.

If NO-REQUIRE-MATCH is non-nil,  this function can return non-project.
It should be string which describe what string is needed as
unmatched returned string."
  (completing-read
   (if no-require-match
       (format "Project or %s: " no-require-match)
     "Project: ")
   (rhq-get-project-list root) nil (not no-require-match)))

(defun rhq--check-executable-availability ()
  "Confirm `rhq-executable' exist as executable."
  (unless (executable-find rhq-executable)
    (error "\"rhq\" is not available. Please run `rhq-install-executable' and install it")))

(defun rhq--process-exit-normally-p (process)
  "Return non-nil if PROCESS exited normally."
  (and (memq (process-status process) '(exit closed failed signal))
       (= (process-exit-status process) 0)))

(defun rhq--dirname-or-url-exist (dirname-or-url)
  "Return absolute dir name predicted from DIRNAME-OR-URL, or nil."
  (let* ((dirname
          (save-match-data
            (and (string-match "\\(?:https?://\\)?\\(.*\\)" dirname-or-url)
                 (match-string 1 dirname-or-url))))
         (absolute-dirname (and
                            dirname
                            (cl-some
                             (lambda (project)
                               (when (file-equal-p (expand-file-name dirname rhq-root-directory)
                                                   project)
                                 project))
                             (rhq-get-project-list)))))
    absolute-dirname))

;;;###autoload
(defun rhq-install-executable (&optional noconfirm)
  "Install rhq.
If NOCONFIRM is non-nil, you are not asked confirmation."
  (interactive "P")
  (when (or noconfirm
            (y-or-n-p "\"Cargo\" is prerequisited. Install rhq? "))
    (async-shell-command "cargo install rhq")))

;;;###autoload
(defun rhq-call-command (subcommand &rest args)
  "Call `rhq-executable' with SUBCOMMAND and ARGS, asynchronously."
  (interactive
   (cons
    (completing-read
     "Subcommand: "
     rhq--subcommands)
    (rhq--split-string-shell-command
     (read-from-minibuffer "Arguments: "))))
  (rhq--check-executable-availability)
  (let ((async-shell-command-display-buffer nil))
    (async-shell-command
     (apply #'rhq--make-shell-command-string
            rhq-executable
            subcommand
            args)
     rhq-async-buffer)
    (get-buffer-process (get-buffer rhq-async-buffer))))

;;;###autoload
(defun rhq-call-command-to-string (subcommand &rest args)
  "Call `rhq-executable' with SUBCOMMAND and ARGS, and get output as string."
  (rhq--check-executable-availability)
  (shell-command-to-string
   (apply #'rhq--make-shell-command-string
          rhq-executable
          subcommand
          args)))

;;;###autoload
(defun rhq-get-project-list (&optional root)
  "Get list of projects managed by rhq, relatively from ROOT.
If ROOT is nil, return absolute paths."
  (mapcar (lambda (dir)
            (let ((relative-dir (file-relative-name dir root)))
              (if (or (not root)
                      (string-match-p "\\.\\." relative-dir))
                  dir
                relative-dir)))
          (split-string (rhq-call-command-to-string "list") "\n" t)))

;;;###autoload
(defun rhq-open-project (dirname)
  "Find project directory named DIRNAME from project list by \"rhq list\"."
  (interactive
   (list (rhq--read-project rhq-root-directory)))
  (let ((default-directory rhq-root-directory))
   (find-file dirname)))

;;;###autoload
(defun rhq-open-project-or-clone (dirname-or-url)
  "Find project directory named DIRNAME-OR-URL from list by \"rhq list\".
When DIRNAME-OR-URL is not found, it is passed to `rhq-clone' to clone project."
  (interactive
   (list (rhq--read-project rhq-root-directory "project URL (\"username/repo\" is also allowed)")))
  (let ((absolute-path (rhq--dirname-or-url-exist dirname-or-url)))
    (if absolute-path
        (find-file absolute-path)
      (set-process-sentinel
       (rhq-clone dirname-or-url)
       (lambda (process _)
         (when (rhq--process-exit-normally-p process)
           (let* ((dirname (rhq--dirname-or-url-exist dirname-or-url)))
             (find-file (expand-file-name  dirname)))))))))

;;;###autoload
(defun rhq-find-file (filename)
  "Read project and find file named FILENAME in it."
  (interactive
   (let ((project (rhq--read-project rhq-root-directory)))
     (list (let ((default-directory rhq-root-directory))
             (read-file-name "Find file: "
                             project project)))))
  (find-file filename))

;;;###autoload
(defun rhq-refresh ()
  "Rhq executable refreshes project list."
  (interactive)
  (rhq-call-command "refresh"))

;;;###autoload
(defun rhq-import (dirname &optional depth)
  "Import DIRNAME as root of rhq-managed projects.
Directories in DIRNAME are regarded as one of project.

DEPTH means maximal depth of entries for each base directory, which is passed
as \"--depth\" argument."
  (interactive
   `(,(read-directory-name "Import root of projects: ")
     ,(when prefix-arg
        (read-number "Maximal depth of entries: "))))
  (apply #'rhq-call-command "import" dirname
         (when depth (list "--depth" (number-to-string depth)))))

;;;###autoload
(defun rhq-add (dirname)
  "Add DIRNAME as rhq-managed project."
  (interactive "DImport project: ")
  (rhq-call-command "add" dirname))

(defconst rhq--vcs-list
  '("git"
    "hg"
    "darcs"
    "pijul")
  "Possible values as --vcs argument on \"rhq new\".")

;;;###autoload
(defun rhq-clone (url &optional root vcs)
  "Clone repository from URL by rhq.

If ROOT is non-nil, it should be path to destination of new repository.
If VCS is non-nil, it should be version control system name defined in
`rhq--vcs-list'.

With prefix argument, you can explicitly pass ROOT and VCS from minibuffer."
  (interactive
   `(,(read-string "Project URL (\"username/repo\" is also allowed): ")
     ,@(when prefix-arg
         (list
          (read-directory-name "Root directory name (where the repository is placed): " default-directory)
          (completing-read "Version control system: "
                           rhq--vcs-list)))))
  (apply
   #'rhq-call-command
   "clone"
   url
   `(,@(when root (list "--root" root))
     ,@(when vcs (list "--vcs" vcs)))))

;;;###autoload
(defun rhq-new (name &optional root vcs)
  "Create new repository named NAME.
NAME can be \"github.com/username/repo\", \"username/repo\" and so on.
If ROOT is non-nil, it should be path to destination of new repository.
If VCS is non-nil, it should be version control system name defined in
`rhq--vcs-list'.

With prefix argument, you can explicitly pass ROOT and VCS from minibuffer."
  (interactive
   `(,(read-string "New repository name (like \"username/repo\"): ")
     ,@(when prefix-arg
         (list
          (read-directory-name "Root directory name (where the repository is placed): " default-directory)
          (completing-read "Version control system: "
                           rhq--vcs-list)))))
  (apply
   #'rhq-call-command
   "new"
   name
   `(,@(when root (list "--root" root))
     ,@(when vcs (list "--vcs" vcs)))))


;;;; `projectile' integration

(defvar projectile-known-projects)
(declare-function projectile-relevant-known-projects "ext:projectile")

;;;###autoload
(defun rhq-projectile-reload-projects ()
  "Reload project list from rhq and put it into `projectile-known-projects'."
  (interactive)
  (setq projectile-known-projects
        (delete-dups
         (nconc projectile-known-projects
                (rhq-get-project-list rhq-root-directory)))))

(defun rhq-projectile--advice-reload-projects (&rest _)
  "Reload project list from rhq and put it into `projectile-known-projects'.
Same as `rhq-projectile-reload-projects' except it can receive any number of
arguments."
  (rhq-projectile-reload-projects))

;;;###autoload
(define-minor-mode rhq-projectile-mode
  "Global minor mode to integrate `rhq' and `projectile'.

It automatically reload projects from rhq and put it into
`projectile-known-projects'."
  :global t
  :group 'rhq
  (if rhq-projectile-mode
      (advice-add #'projectile-relevant-known-projects :before #'rhq-projectile--advice-reload-projects)
    (advice-remove #'projectile-relevant-known-projects #'rhq-projectile--advice-reload-projects)))


;;;; `consult' integration

(defvar rhq-consult-source-project-directory
  '( :name "Project Directory"
     :narrow (?P . "Projects")
     :hidden nil
     :category file
     :face consult-file
     :history file-name-history
     :state consult--file-state
     :items rhq-get-project-list)
  "Project file candidate source for `consult-buffer'.")

(provide 'rhq)
;;; rhq.el ends here
  "Project file candidate source for `consult-buffer'.")

(provide 'rhq)
;;; rhq.el ends here
