;;; project-mode-line-tag.el --- Display a buffer's project in its mode line -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/project-mode-line-tag
;; Package-Version: 20211013.1954
;; Package-Commit: e411432a33cd82f8a9ff95471c91e9fe1833841c
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Display information about a buffer's project (a "project tag") in its
;; mode line.

;;; Code:

(require 'project)
(require 'seq)

(eval-when-compile (require 'subr-x))

(defgroup project-mode-line-tag ()
  "Display information about a buffer's project in its mode line."
  :group 'project)

(defvar project-mode-line-tag--mode-line-construct
  '("" (:eval (project-mode-line-tag)) " ")
  "Mode line construct for the project tag.")

(defface project-mode-line-tag-project-tag
  '((t :inherit bold))
  "Mode line face for the project tag.")

(defcustom project-mode-line-tag-format-string
  "<%s>"
  "Format string to use for rendering the project tag in the mode line.

If the value is a string, use it as the format string.

If the value is a function, call it to generate the format string
to use.

The format string is expected to contain a single \"%s\", which
will be substituted with the styled project tag."
  :type '(choice string function))

(defvar project-mode-line-tag-style-functions
  '(project-mode-line-tag-propertize-project-tag)
  "List of functions to call to style the project tag for display.

Each function is expected to take PROJECT-TAG as its argument,
and to return a copy of the tag that was further styled for
display.")

(defun project-mode-line-tag-propertize-project-tag (project-tag)
  "Propertize PROJECT-TAG."
  (let ((project-tag (concat project-tag)))
    (font-lock-append-text-property 0 (length project-tag) 'face 'project-mode-line-tag-project-tag project-tag)
    project-tag))

(defun project-mode-line-tag--project-tag ()
  "Build project tag for the current buffer."
  (or (and (boundp 'project-mode-line-tag) project-mode-line-tag)
      (and (boundp 'project-name) project-name)
      (when-let ((project-current (project-current)))
        ;; Using obsolete function `project-roots` (vs `project-root`)
        ;; on purpose here to maintain support for Emacs versions down
        ;; to 25.1.
        (file-name-nondirectory (directory-file-name (car (project-roots project-current)))))))

(defun project-mode-line-tag ()
  "Compute project tag string to display in the mode line."
  (when-let ((project-tag (project-mode-line-tag--project-tag)))
    (format
     (cond ((functionp project-mode-line-tag-format-string)
            (funcall project-mode-line-tag-format-string project-tag))
           ((stringp project-mode-line-tag-format-string)
            project-mode-line-tag-format-string)
           (t "<%s>"))
     (seq-reduce (lambda (tag f) (funcall f tag)) project-mode-line-tag-style-functions project-tag))))

;;;###autoload
(define-minor-mode project-mode-line-tag-mode
  "Display the current buffer's project tag in its mode line."
  :group 'project
  :global t
  (if project-mode-line-tag-mode
      (add-to-list 'mode-line-misc-info project-mode-line-tag--mode-line-construct)
    (setq mode-line-misc-info (delete project-mode-line-tag--mode-line-construct mode-line-misc-info))))

(provide 'project-mode-line-tag)
;;; project-mode-line-tag.el ends here
