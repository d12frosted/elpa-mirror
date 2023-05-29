;;; project-treemacs.el --- Simple treemacs backend for project.el -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2023 Christopher McCloud

;; Author: Christopher McCloud
;; URL: https://github.com/cmccloud/project-treemacs
;; Package-Version: 20230529.1207
;; Package-Commit: 36bec1109ba0498c2d1ef29756c841d2e23b063e
;; Version: 0.1
;; Package-Requires: ((emacs "28.1") (treemacs "3.1"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simple treemacs backend for project.el

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Install these required packages:

;; `treemacs'

;; Then put this file in your load-path, and put this in your init
;; file:

;; (require 'project-treemacs)

;; Or using `use-package':

;; (use-package project-treemacs
;;   :demand t
;;   :after treemacs
;;   :load-path "path/to/project-treemacs")

;;;; Usage

;; Enable the backend with `project-treemacs-mode'
;; With the `treemacs' side panel visible, use any of the `project.el'
;; project management commands as you normally would.

;; Treemacs projects map to project.el projects
;; Treemacs workspaces map project.el projects + project external roots

;; `project-find-file', `project-switch-to-buffer', `project-find-regexp' et al
;; operate on the current treemacs project.

;; `project-or-external-find-file', and `project-or-external-find-regexp'
;; operate on the current treemacs workspace.

;;;; Tips
;; You can customize settings in the `project-treemacs' group.

;;; Code:

;;;; Requirements

(require 'seq)
(require 'treemacs)
(require 'project)

;;;; Customization

(defgroup project-treemacs nil
  "Project backend using `treemacs'."
  :group 'project)

(defcustom project-treemacs-ignores '("^\\.#" "^flycheck_" "~$" "\\.git/")
  "List of patterns to add to `project-ignores'.
Default value emulates `treemacs--std-ignore-file-predicate'."
  :type '(repeat string)
  :safe #'listp)

(defcustom project-treemacs-prefer-backend t
  "Whether or not to prefer the project-treemacs backend over others.

When t `project-treemacs-try' is placed at the front of
 `project-find-functions'.

When nil, `project-treemacs-try' is instead appended to the end
of `project-find-functions'."
  :type '(boolean))

;;;; Variables

(defvar project-treemacs--files-cache (make-hash-table)
  "Stores project-treemacs `project-files'.
Only used when `treemacs-filewatch-mode' is enabled.")

(defvar project-treemacs--idle-timer nil)

;;;; Functions

;;;;; Public

;;;###autoload
(defun project-treemacs-try (dir)
  "Treemacs backend for use in `project-find-functions'.

Tests whether DIR is a member of a visible `treemacs' project."
  (when (and (fboundp 'treemacs-current-visibility)
             (eq (treemacs-current-visibility) 'visible))
    (treemacs--find-project-for-path dir)))

;;;;; Private

(defun project-treemacs--clear-cache ()
  "Clears `project-treemacs--files-cache' and update when idle."
  (when treemacs-filewatch-mode
    (let (keys)
      (maphash (lambda (k _v) (push k keys)) project-treemacs--files-cache)
      (clrhash project-treemacs--files-cache)
      (unless project-treemacs--idle-timer
	;; Check to verify that we don't already have an idle-timer
	;; waiting up update the cache.
	(setq project-treemacs--idle-timer
	      (run-with-idle-timer 1 nil #'project-treemacs--update-cache keys))))))

(defun project-treemacs--update-cache (directories)
  "Update the cache for paths in given DIRECTORIES."
  (seq-each (lambda (d) (project-treemacs--get-files-for-dir d)) directories)
  (cancel-timer project-treemacs--idle-timer)
  (setq project-treemacs--idle-timer nil))

(defun project-treemacs--explore-dir-p (dir-name)
  "Test whether DIR-NAME matches against `project-ignores'."
  (not (seq-some (lambda (glob) (string-match-p glob dir-name))
                 (project-ignores (project-current) ""))))

(defun project-treemacs--ignore-file-p (project path)
  "Test whether file at PATH should be ignored within PROJECT."
  (seq-contains-p (project-ignores project nil) path #'string-match-p))

(defun project-treemacs--get-files-for-dir (dir)
  "Return value of DIR in cache."
  (or (and treemacs-filewatch-mode (gethash dir project-treemacs--files-cache))
      (puthash dir (directory-files-recursively dir ".*" nil #'project-treemacs--explore-dir-p nil)
	       project-treemacs--files-cache)))

(defun project-treemacs--update-cache-advice (&rest _r)
  "Clear cache after `treemacs--process-file-events' is run.

Attached when `project-treemacs-mode' is enabled.
Removed when `project-treemacs-mode' is disabled."
  (project-treemacs--clear-cache))

;;;;; project.el api

(cl-defmethod project-root ((project treemacs-project))
  "Return `project-root' for PROJECT of type TREEMACS-PROJECT."
  (concat (treemacs-project->path project) "/"))

(cl-defmethod project-files ((project treemacs-project) &optional dirs)
  "Return `project-files' for PROJECT of type TREEMACS-PROJECT.

Optionally accept external project root DIRS."
  (seq-remove (lambda (p) (project-treemacs--ignore-file-p project p))
              (seq-mapcat #'project-treemacs--get-files-for-dir
	                  (append (list (project-root project)) dirs))))

(cl-defmethod project-buffers ((project treemacs-project))
  "Return `project-buffers' for PROJECT of type TREEMACS-PROJECT."
  (let ((root (expand-file-name (file-name-as-directory (project-root project)))))
    (seq-filter
     (lambda (buf)
       (string-prefix-p root (buffer-local-value 'default-directory buf)))
     (buffer-list))))

(cl-defmethod project-ignores ((_project treemacs-project) _dir)
  "Return `project-ignores' in a TREEMACS-PROJECT."
  project-treemacs-ignores)

(cl-defmethod project-external-roots ((project treemacs-project))
  "Return `project-external-roots' for PROJECT of type TREEMACS-PROJECT."
  (remove (project-root project)
	  (mapcar #'project-root
		  (treemacs-workspace->projects (treemacs-current-workspace)))))

;;;;; Modes

;;;###autoload
(define-minor-mode project-treemacs-mode
  "Toggles treemacs backend for project.el.

When enabled, by default, treemacs backend is prefered over other backends, but
see `project-treemacs-prefer-backend' user option."
  :group 'project-treemacs
  :global t
  (if project-treemacs-mode
      (progn
        (advice-add 'treemacs--process-file-events
                    :after
                    #'project-treemacs--update-cache-advice)
        (add-hook 'treemacs-switch-workspace-hook
                  #'project-treemacs--clear-cache)
        (add-to-list 'project-find-functions
                     #'project-treemacs-try
                     (unless project-treemacs-prefer-backend t)))
    (advice-remove #'treemacs--process-file-events
                   'project-treemacs--update-cache-advice)
    (remove-hook 'treemacs-switch-workspace-hook
                 #'project-treemacs--clear-cache)
    (setq project-find-functions
          (remq #'project-treemacs-try
                project-find-functions))
    (clrhash project-treemacs--files-cache)
    (when project-treemacs--idle-timer
      (cancel-timer project-treemacs--idle-timer))))

;;;; Footer

(provide 'project-treemacs)

;;; project-treemacs.el ends here
