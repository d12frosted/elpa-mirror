;;; consult-projectile.el --- Consult integration for projectile  -*- lexical-binding: t; -*-

;; Copyright (C) 2021

;; Author:  Marco Pawłowski
;; Keywords: convenience
;; Package-Version: 20220617.1042
;; Package-Commit: 5ef1ada3be767ea766255801050210f5d796deec
;; Version: 0.7
;; Package-Requires: ((emacs "25.1") (consult "0.12") (projectile "2.5.0"))
;; URL: https://gitlab.com/OlMon/consult-projectile

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

;; A multiview for displaying open buffers, files and directories accociated with a project.
;; When no project is open in the current buffer display a list of known project.
;; and select a file from the selected project.
;;
;; Additionally seperate single source function are available.
;;
;; Just run the function `consult-projectile' and/or bind it to a hotkey.
;;
;; To filter the multiview use:
;; b - For project related buffers
;; d - For project related dirs
;; f - For project related files
;; p - For known projects
;; r - For project recent files
;;
;; The multiview includes initially buffers, files and known projects.  To include
;; recent files and directires add `consult-projectile--source-projectile-dir' and/or
;; `consult-projectile--source-projectile-recentf' to `consult-projectile-sources'.


;;; Code:

(require 'projectile)
(require 'consult)

(defface consult-projectile-projects
  '((t :inherit font-lock-constant-face))
  "Face used to highlight projects in `consult-projectile'."
  :group 'consult-projectile)

(defvar consult-projectile--project-history nil)

(defvar consult-projectile-display-info t
  "Settings to let `consult-projectile' display project information in the annotation.")

(defvar consult-projectile-use-projectile-switch-project nil
  "If non-nil will use `projectile-switch-project'
when switching from one project to an other.
This allows the use of `projectile-swtich-project-action'.
Default is to use `consult-projectile-find-file'.")

(defcustom consult-projectile-sources
  '(consult-projectile--source-projectile-buffer
    consult-projectile--source-projectile-file
    consult-projectile--source-projectile-project)
  "Sources used by `consult-projectile'.

See `consult--multi' for a description of the source values."
  :type '(repeat symbol)
  :group 'consult-projectile)

(defun consult-projectile--choose-file (root)
  "Create the list of files for the consult chooser based on projectile's notion of files for the project at ROOT."
  (let* ((inv-root (propertize root 'invisible t))
         (files (projectile-project-files (expand-file-name root))))
    (mapcar (lambda (f) (concat inv-root f)) files)))

(defun consult-projectile--file (selected-project)
  "Create a view for selecting project files for the project at SELECTED-PROJECT."
  (find-file (consult--read
              (consult-projectile--choose-file selected-project)
              :prompt "Project File: "
              :sort t
              :require-match t
              :category 'file
              :state (consult--file-preview)
              :history 'file-name-history)))

(defun consult-projectile--source-projectile-project-action (dir)
  "Function to choose file at project root DIR.
This function will call `projectile-switch-project' if
`consult-projectile-use-projectile-switch-project' is t."
  (if consult-projectile-use-projectile-switch-project
      (projectile-switch-project-by-name dir)
    (consult-projectile--file dir)))

(defvar consult-projectile-source-projectile-project-action
  'consult-projectile--source-projectile-project-action
  "Variable that stores the function that is called after selecting a project.
Function must take one argument, the selected project root directory.")

(defvar consult-projectile--source-projectile-buffer
  (list :name     "Project Buffer"
        :narrow   '(?b . "Buffer")
        :category 'buffer
        :face     'consult-buffer
        :history  'buffer-name-history
        :state    #'consult--buffer-state
        :enabled  #'projectile-project-root
        :items
        (lambda ()
          (when-let (root (projectile-project-root))
            (mapcar #'buffer-name
                    (seq-filter (lambda (x)
                                  (when-let (file (buffer-file-name x))
                                    (string-prefix-p root file)))
                                (consult--buffer-query :sort 'visibility)))))))

(defvar consult-projectile--source-projectile-dir
  (list :name     "Project Dir"
        :narrow   '(?d . "Dir")
        :category 'file
        :face     'consult-file
        :history  'file-name-history
        :action   (lambda (f) (consult--file-action (concat (projectile-acquire-root) f)))
        :enabled  #'projectile-project-root
        :items
        (lambda ()
          (let ((project-dirs (projectile-project-dirs (projectile-acquire-root))))
            (if projectile-find-dir-includes-top-level
                (append '("./") project-dirs)
              project-dirs)))))

(defvar consult-projectile--source-projectile-file
  (list :name     "Project File"
        :narrow   '(?f . "File")
        :category 'file
        :face     'consult-file
        :history  'file-name-history
        :action   (lambda (f) (consult--file-action (concat (projectile-acquire-root) f)))
        :enabled  #'projectile-project-root
        :items
        (lambda ()
          (projectile-project-files (projectile-acquire-root)))))

(defvar consult-projectile--source-projectile-recentf
  (list :name     "Project Recent File"
        :narrow   '(?r . "Recent File")
        :category 'file
        :face     'consult-file
        :history  'file-name-history
        :action   (lambda (f) (consult--file-action (concat (projectile-acquire-root) f)))
        :enabled  #'projectile-project-root
        :items    #'projectile-recentf-files))

(defvar consult-projectile--source-projectile-project
  (list :name     "Known Project"
        :narrow   '(?p . "Project")
        :category 'consult-projectile-project
        :face     'consult-projectile-projects
        :history  'consult-projectile--project-history
        :annotate (lambda (dir)
                    (when consult-projectile-display-info
                      (format "Project: %s [%s]"
                              (projectile-project-name dir)
                              (projectile-project-vcs dir))))
        :action   (lambda (dir) (funcall consult-projectile-source-projectile-project-action dir))
        :items    #'projectile-relevant-known-projects))

;;;###autoload
(defun consult-projectile-switch-to-buffer ()
  "Swith to a project buffer using `consult'."
  (interactive)
  (funcall-interactively #'consult-projectile '(consult-projectile--source-projectile-buffer)))

;;;###autoload
(defun consult-projectile-find-dir ()
  "Jump to a project's directory using `consult'."
  (interactive)
  (funcall-interactively #'consult-projectile '(consult-projectile--source-projectile-dir)))

;;;###autoload
(defun consult-projectile-find-file ()
  "Jump to a project's file using `consult'."
  (interactive)
  (funcall-interactively #'consult-projectile '(consult-projectile--source-projectile-file)))

;;;###autoload
(defun consult-projectile-recentf ()
  "Show a list of recently visited files in a project using `consult'."
  (interactive)
  (funcall-interactively #'consult-projectile '(consult-projectile--source-projectile-recentf)))

;;;###autoload
(defun consult-projectile-switch-project ()
  "Switch to a projectile visted before using `consult'."
  (interactive)
  (funcall-interactively #'consult-projectile '(consult-projectile--source-projectile-project)))

;;;###autoload
(defun consult-projectile (&optional sources)
  "Create a multi view with projectile integration.   Displays known projects when there are none or the buffers/files accociated with the project."
  (interactive)
  (when-let (buffer (consult--multi (or sources consult-projectile-sources)
                                    :prompt "Switch to: "
                                    :history 'consult-projectile--project-history
                                    :sort nil))
    ;; When the buffer does not belong to a source,
    ;; create a new buffer with the name.
    (unless (cdr buffer)
      (funcall consult--buffer-display (car buffer)))))


(provide 'consult-projectile)
;;; consult-projectile.el ends here
