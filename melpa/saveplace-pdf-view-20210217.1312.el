;;; saveplace-pdf-view.el --- Save place in pdf-view buffers -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Nicolai Singh

;; Author: Nicolai Singh <nicolaisingh at pm.me>
;; URL: https://github.com/nicolaisingh/saveplace-pdf-view
;; Package-Version: 20210217.1312
;; Package-Commit: 54ed966b842501c3c092dbf57b372e37b033c578
;; Version: 1.0.4
;; Keywords: files, convenience
;; Package-Requires: ((emacs "24.1"))

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

;; Adds support for pdf-view (from `pdf-tools') and DocView buffers in
;; `save-place-mode'.

;; If using pdf-view-mode or doc-view-mode, this package will
;; automatically persist between Emacs sessions the current PDF page,
;; size and other information from `pdf-view-bookmark-make-record' or
;; `doc-view-bookmark-make-record', depending on the mode used.  These
;; information are persisted using `save-place-mode'.  Visiting the
;; same PDF file will restore the previously displayed page and scale
;; amount (if available).

;;; Acknowledgements:

;; - João Pedro <jpedrodeamorim@gmail.com>, for making the package
;;   work with doc-view-mode

;;; Code:

(require 'bookmark)
(require 'saveplace)

(declare-function pdf-view-bookmark-jump "pdf-view")
(declare-function pdf-view-bookmark-make-record "pdf-view")
(declare-function doc-view-bookmark-make-record "doc-view")

(defun saveplace-pdf-view-find-file (save-place-alist-key bookmark-jump-function)
  "Restore the saved place for the document, if there is one.
BOOKMARK-JUMP-FUNCTION should be a function that can restore the
persisted bookmark under SAVE-PLACE-ALIST-KEY."
  (or save-place-loaded (load-save-place-alist-from-file))
  (let* ((cell (assoc buffer-file-name save-place-alist)))
    (when (and cell
               (listp (cdr cell))
               (assq save-place-alist-key (cdr cell)))
      (funcall bookmark-jump-function
               (cdr (assq save-place-alist-key (cdr cell)))))
    (setq save-place-mode t)))

(defun saveplace-pdf-view-to-alist (save-place-alist-key make-record-function)
  "Save the document's place using bookmarks.
MAKE-RECORD-FUNCTION should be a function that provides the
bookmark to be saved, while SAVE-PLACE-ALIST-KEY determines what
type of bookmark it is (i.e. pdf-view-bookmark or
doc-view-bookmark).

Currently only one type of bookmark can be saved for a file.  For
instance, if a file has an available pdf-view bookmark, saving a
doc-view bookmark will replace the file's pdf-view bookmark."
  (or save-place-loaded (load-save-place-alist-from-file))
  (let ((item buffer-file-name))
    (when (and item
               (or (not save-place-ignore-files-regexp)
                   (not (string-match save-place-ignore-files-regexp
                                      item))))
      (let* ((cell (assoc item save-place-alist))
             (bookmark (funcall make-record-function))
             (page (assoc 'page bookmark))
             (origin (assoc 'origin bookmark)))
        (with-demoted-errors
            "Error saving place: %S"
          (when cell
            (setq save-place-alist (delq cell save-place-alist)))
          (when (and save-place-mode
                     (not (and (listp page)
                               (listp origin)
                               (or (null (cdr page))
                                   (= 1 (cdr page)))
                               (or (null (cdr origin))
                                   (equal '(0.0 . 0.0) (cdr origin))))))
            (setq save-place-alist
                  (cons (cons item `((,save-place-alist-key . ,bookmark)))
                        save-place-alist))))))))

(defun saveplace-pdf-view-find-file-advice (orig-fun &rest args)
  "Function to advice around `save-place-find-file-hook'.
If the buffer being visited is not in `pdf-view-mode' or
`doc-view-mode', call the original function ORIG-FUN with the
ARGS."
  (cond ((derived-mode-p 'pdf-view-mode)
         (saveplace-pdf-view-find-file 'pdf-view-bookmark
                                       #'pdf-view-bookmark-jump))
        ((derived-mode-p 'doc-view-mode)
         (saveplace-pdf-view-find-file 'doc-view-bookmark
                                       #'bookmark-jump))
        (t
         (apply orig-fun args))))

(defun saveplace-pdf-view-to-alist-advice (orig-fun &rest args)
  "Function to advice around `save-place-to-alist'.
If the buffer being visited is not in `pdf-view-mode' or
`doc-view-mode', call the original function ORIG-FUN with the
ARGS."
  (cond ((derived-mode-p 'pdf-view-mode)
         (saveplace-pdf-view-to-alist 'pdf-view-bookmark
                                      #'pdf-view-bookmark-make-record))
        ((derived-mode-p 'doc-view-mode)
         (saveplace-pdf-view-to-alist 'doc-view-bookmark
                                      #'doc-view-bookmark-make-record))
        (t
         (apply orig-fun args))))

(advice-add 'save-place-find-file-hook :around #'saveplace-pdf-view-find-file-advice)
(advice-add 'save-place-to-alist :around #'saveplace-pdf-view-to-alist-advice)

(provide 'saveplace-pdf-view)
;;; saveplace-pdf-view.el ends here
