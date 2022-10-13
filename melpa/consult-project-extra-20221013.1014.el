;;; consult-project-extra.el --- Consult integration for project.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2021

;; Author:  Enrique Kessler Martínez
;; Keywords: convenience project management
;; Package-Version: 20221013.1014
;; Package-Commit: 9fdf45fa40471900b0b158d73c4b1521a13d47ef
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (consult "0.17") (project "0.8.1"))
;; URL: https://github.com/Qkessler/consult-project-extra

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

;; Creates an endpoint for accessing different project sources.  The consult view
;; can be narrowed to: (b) current project's buffers, (f) current project's files
;; and (p) to select from the list of known projects.

;; The buffer and project file sources are only enabled in case that the user is
;; in a project file/buffer.  See `project-current'.

;; A different action is issued depending on the source.  For both buffers and
;; project files, the default action is to visit the selected element.  When a
;; known project is selected, a list to select from is created with the selected
;; project's files.

;;; Code:

(require 'project)
(require 'consult)

(defface consult-project-extra-projects
  '((t :inherit font-lock-constant-face))
  "Face used to highlight projects in `consult-project-extra'."
  :group 'consult-project-extra)

(defvar consult-project-extra--project-history nil)

(defvar consult-project-extra-display-info t
  "Whether to display information about the project in the margin of the element.")

(defun consult-project-extra--project-with-root (root)
  "Return the project for a given project ROOT."
  (project--find-in-directory root))

(defun consult-project-extra--project-files (root)
  "Compute the project files given the ROOT."
  (let* ((project (consult-project-extra--project-with-root root))
         (files (project-files project)))
    (mapcar (lambda (f) (file-relative-name f root)) files)))

(defun consult-project-extra--file (selected-root)
  "Create a view for selecting project files for the project at SELECTED-ROOT."
  (let ((candidate (consult--read
              (consult-project-extra--project-files selected-root)
              :prompt "Project File: "
              :sort t
              :require-match t
              :category 'file
              :state (consult--file-preview)
              :history 'file-name-history)))
    (find-file (concat selected-root candidate))))

(defun consult-project-extra--find-with-concat-root (candidate)
  "Find-file concatenating root with CANDIDATE."
  (find-file (concat (project-root (project-current)) candidate)))

;; The default `consult--source-project-buffer' has the ?p as narrow key,
;; and therefore is in conflict with `consult-project-extra--source-project'.
(defvar consult-project-extra--source-buffer
  (let* ((unmodified consult--source-project-buffer)
         (modified-source (plist-put (plist-put unmodified :hidden nil) :narrow ?b)))
    modified-source))

(defvar consult-project-extra--source-file
  `(:name      "Project File"
               :narrow    (?f . "File")
               :category  file
               :face      consult-file
               :history   file-name-history
               :action    ,#'consult-project-extra--find-with-concat-root
               :enabled   ,#'project-current
               :items
               ,(lambda () (consult-project-extra--project-files (project-root (project-current))))))

(defvar consult-project-extra--source-project
  `(:name      "Known Project"
               :narrow    (?p . "Project")
               :category  'consult-project-extra-project
               :face      consult-project-extra-projects
               :history   consult-project-extra--project-history
               :annotate  ,(lambda (dir) (if consult-project-extra-display-info (progn
                                                                                  (format "Project: %s"
                                                                                          (file-name-nondirectory (directory-file-name dir))))))
               :action    ,#'consult-project-extra--file
               :items     ,#'project-known-project-roots))

(defcustom consult-project-extra-sources
  (list consult-project-extra--source-buffer
        consult-project-extra--source-file
        consult-project-extra--source-project)
  "Sources used by `consult-project-extra'.

See `consult--multi' for a description of the source values."
  :type '(repeat symbol)
  :group 'consult-project-extra)

;;;###autoload
(defun consult-project-extra-find ()
  "Create an endpoint for accessing different project sources.
The consult view can be narrowed to: (b) current project's buffers,(f) current
project's files and (p) to select from the list of known projects.

The buffer and project file sources are only enabled in case that the user is
in a project file/buffer.  See `project-current'.

A different action is issued depending on the source.  For both buffers and
project files, the default action is to visit the selected element.  When a
known project is selected, a list to select from is created with the selected
project's files"
  (interactive)
  (if (project-current) (let ((consult-project-buffer-sources consult-project-extra-sources))
                            (consult-project-buffer))
    (project-find-file)))

;;;###autoload
(defun consult-project-extra-find-other-window ()
  "Variant of `consult-project-extra' which opens in a second window."
  (interactive)
  (let ((consult--buffer-display #'switch-to-buffer-other-window))
    (consult-project-extra-find)))

(provide 'consult-project-extra)
;;; consult-project-extra.el ends here
