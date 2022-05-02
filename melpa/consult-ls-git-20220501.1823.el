;;; consult-ls-git.el --- Consult integration for git  -*- lexical-binding: t; -*-

;; Copyright (C) 2022

;; Author:  Robin Joy
;; Keywords: convenience
;; Package-Version: 20220501.1823
;; Package-Commit: f2398b354994e583ad22af324a129cf94d06009e
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (consult "0.16"))
;; URL: https://github.com/rcj/consult-ls-git

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

;; `consult-ls-git' allows to quickly select a file from a git repository
;; or act on a stash.  It provides a consult multi view of files
;; considered by 'git status', stashes as well as all tracked files.
;; Alternatively you can narrow to a specific section via the shortcut key:
;;   s: Status
;;   z: Stash
;;   f: Tracked Files

;; If `default-directory' is inside a git repository, it will use this
;; repository.  Otherwise `consult-ls-git-project-prompt-function' is
;; used to select the project directory.

;; Each view also has a standalone command in case that is preferable:
;;   consult-ls-git-status
;;   consult-ls-git-stash
;;   consult-ls-git-tracked-files

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'project)
(require 'vc)

(defgroup consult-ls-git nil
  "Consult for git."
  :group 'consult-ls-git)

(defcustom consult-ls-git-sources
  '(consult-ls-git--source-status-files
    consult-ls-git--source-stash
    consult-ls-git--source-tracked-files)
  "Sources used by `consult-ls-git'."
  :group 'consult-ls-git
  :type '(repeat symbol))

(defcustom consult-ls-git-status-types
  '(("^\\( M \\)\\(.*\\)" . modified-not-staged)
    ("^\\(M+ *\\)\\(.*\\)" . modified-and-staged)
    ("^\\([?]\\{2\\} \\)\\(.*\\)" . untracked)
    ("^\\([AC] +\\)\\(.*\\)" . added-copied)
    ("^\\( [D] \\)\\(.*\\)" . deleted-not-staged)
    ("^\\(RM?\\).* -> \\(.*\\)" . renamed-modified)
    ("^\\([D] +\\)\\(.*\\)" . deleted-and-staged)
    ("^\\(UU \\)\\(.*\\)" . conflict)
    ("^\\(AM \\)\\(.*\\)" . added-modified)
    ("^.*" . unknown))
  "Match a git status abbreviation to a readable string."
  :group 'consult-ls-git
  :type '(repeat (string . function)))

(defcustom consult-ls-git-stash-actions
  '(("apply" . vc-git-stash-apply)
    ("pop" . vc-git-stash-pop)
    ("drop" . vc-git-stash-delete)
    ("show" . vc-git-stash-show))
  "List of possible actions to invoke on a stash."
  :group 'consult-ls-git
  :type '(repeat (string . function)))

(defcustom consult-ls-git-status-command-options nil
  "List of command line options passed to git status to determine candidates."
  :group 'consult-ls-git
  :type '(repeat string))

(defcustom consult-ls-git-show-untracked-files t
  "If t show untracked files in the status view."
  :group 'consult-ls-git
  :type 'boolean)

(defcustom consult-ls-git-stash-command-options nil
  "List of command line options passed git stash to determine candidates."
  :group 'consult-ls-git
  :type '(repeat string))

(defcustom consult-ls-git-tracked-files-command-options nil
  "List of command line options passed to git ls-files to determine candidates."
  :group 'consult-ls-git
  :type '(repeat string))

(defcustom consult-ls-git-project-prompt-function
  (if (version< emacs-version "28.1")
      (lambda () (cdr (funcall #'consult--directory-prompt "Select project: " 'ask)))
    #'project-prompt-project-dir)
  "Function to ask for a project root if not in a git repository."
  :group 'consult-ls-git
  :type 'function)

(defvar consult-ls-git--source-tracked-files
  (list :name     "Tracked Files"
        :narrow   '(?f . "Tracked Files")
        :category 'file
        :face     'consult-file
        :history  'file-name-history
        :state    #'consult--file-state
        :items
        (lambda ()
          (consult-ls-git--candidates-from-git-command
           "ls-files" default-directory
           consult-ls-git-tracked-files-command-options))))

(defvar consult-ls-git--source-status-files
  (list :name     "Status"
        :narrow   '(?s . "Status")
        :category 'consult-ls-git-status
        :history  'file-name-history
        :state    #'consult--file-state
        :annotate #'consult-ls-git--status-annotate-candidate
        :items    #'consult-ls-git--status-candidates))

(defvar consult-ls-git--source-stash
  (list :name     "Stash"
        :narrow   '(?z . "stash")
        :category 'consult-ls-git-stash
        :history  'file-name-history
        :action   #'consult-ls-git--stash-action
        :items
        (lambda ()
          (consult-ls-git--candidates-from-git-command
           "stash list" default-directory consult-ls-git-stash-command-options))))

(defun consult-ls-git--execute-git-command (cmd root)
  "Execute CMD git ROOT."
  (shell-command-to-string
   (format "git -C %s %s" (shell-quote-argument root) cmd)))

(defun consult-ls-git--split-null-string (str)
  "Split STR  with null byte as separator into individual parts.

Empty strings are omitted."
  (split-string str "\000" 'omit-nulls))

(defun consult-ls-git--candidates-from-git-command (cmd root options)
  "Create list of candidates from the result of running git CMD in ROOT.

Empty strings are omitted.
OPTIONS is a list of additional command line options for CMD."
  (let ((command (concat cmd " -z " (mapconcat #'identity options " "))))
    (consult-ls-git--split-null-string
     (consult-ls-git--execute-git-command command root))))

(defun consult-ls-git--get-project-root ()
  "Return git project root.

If `default-directory' isn't inside a git repository, call
`project-root' to select a project.  Returns nil in case no valid
project root was found."
  (or (locate-dominating-file default-directory ".git")
      (locate-dominating-file (funcall consult-ls-git-project-prompt-function) ".git")
      (user-error "Not a git repository")))

(defun consult-ls-git--status-annotate-candidate (cand)
  "Create status annotation for CAND."
  (symbol-name (get-text-property 0 'consult-ls-git-status cand)))

(defun consult-ls-git--status-candidates ()
  "Return a list of paths that are considered modified in some way by git."
  (let* ((options (append `(,(when consult-ls-git-show-untracked-files "-uno")
                            "--porcelain")
                          consult-ls-git-status-command-options))
         (candidates (consult-ls-git--candidates-from-git-command
                      "status" default-directory options)))
    (save-match-data
      (cl-loop for cand in candidates
               collect
               (let* ((status (cdr (cl-find-if (lambda (status)
                                                 (string-match (car status) cand))
                                               consult-ls-git-status-types)))
                      (path (if (eq status 'unknown) cand (match-string 2 cand))))
                 (propertize path 'consult-ls-git-status status))))))

(defun consult-ls-git--stash-action (cand)
  "Try to apply or pop a selected CAND."
  (let* ((stash (substring cand 0 (cl-search ":" cand)))
         (actions (mapcar #'car consult-ls-git-stash-actions))
         (action (completing-read "Action: " actions nil t)))
    (apply (cdr (assoc action consult-ls-git-stash-actions)) `(,stash))))

;;;###autoload
(defun consult-ls-git ()
  "Create a multi view for current git repository."
  (interactive)
  (let* ((default-directory (expand-file-name (consult-ls-git--get-project-root))))
    (consult--multi consult-ls-git-sources
                    :prompt "Switch to: "
                    :require-match t
                    :sort nil)))

(defun consult-ls-git-other-window ()
  "Create a multi view for current git repository.

Selected files are opened in another window."
  (interactive)
  (let* ((default-directory (expand-file-name (consult-ls-git--get-project-root)))
         (consult--buffer-display #'switch-to-buffer-other-window))
    (consult--multi consult-ls-git-sources
                    :prompt "Switch to: "
                    :require-match t
                    :sort nil)))

;;;###autoload
(defun consult-ls-git-ls-files ()
  "Select a tracked file from a git repository."
  (interactive)
  (let ((consult-ls-git-sources '(consult-ls-git--source-tracked-files)))
    (call-interactively #'consult-ls-git)))

;;;###autoload
(defun consult-ls-git-ls-files-other-window ()
  "Select a tracked file from a git repository and open it in another window."
  (interactive)
  (let ((consult-ls-git-sources '(consult-ls-git--source-tracked-files)))
    (call-interactively #'consult-ls-git-other-window)))

;;;###autoload
(defun consult-ls-git-ls-status ()
  "Select a file from a git repository considered to be modified or untracked.

Untracked files are only included if `consult-ls-git-show-untracked-files' is t."
  (interactive)
  (let ((consult-ls-git-sources '(consult-ls-git--source-status-files)))
    (call-interactively #'consult-ls-git)))

;;;###autoload
(defun consult-ls-git-ls-status-other-window ()
  "Open a modified/untracked file from a git repository in another window.

Untracked files are only included if
`consult-ls-git-show-untracked-files' is t."
  (interactive)
  (let ((consult-ls-git-sources '(consult-ls-git--source-status-files)))
    (call-interactively #'consult-ls-git-other-window)))

;;;###autoload
(defun consult-ls-git-ls-stash ()
  "Select a stash from a git repository and apply, pop or drop it."
  (interactive)
  (let ((consult-ls-git-sources '(consult-ls-git--source-stash)))
    (call-interactively #'consult-ls-git)))

(provide 'consult-ls-git)
;;; consult-ls-git.el ends here
