;;; saveplace-pdf-view.el --- Save place in pdf-view buffers -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Nicolai Singh

;; Author: Nicolai Singh <nicolaisingh at pm.me>
;; URL: https://github.com/nicolaisingh/saveplace-pdf-view
;; Package-Version: 20201216.934
;; Package-Commit: b0370912049222f3a4c943856de3d69d48d53a35
;; Version: 1.0.3
;; Keywords: files, convenience
;; Package-Requires: ((emacs "24.1") (pdf-tools "1.0"))

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

;; Adds support for pdf-view (from `pdf-tools') buffers in
;; `save-place-mode'.
;;
;; If using pdf-view-mode, this package will automatically persist
;; between Emacs sessions the current PDF page, size and other
;; information returned by `pdf-view-bookmark-make-record' using
;; `save-place-mode'.  Visiting the same PDF file will restore the
;; previously displayed page and size.

;;; Code:

(require 'saveplace)
(require 'pdf-tools)

(defun saveplace-pdf-view-find-file ()
  "Restore the saved place for the PDF file, if there is one."
  (or save-place-loaded (load-save-place-alist-from-file))
  (let* ((cell (assoc buffer-file-name save-place-alist)))
    (when (and cell
               (listp (cdr cell))
               (assq 'pdf-view-bookmark (cdr cell)))
      (pdf-view-bookmark-jump (cdr (assq 'pdf-view-bookmark (cdr cell)))))
    (setq save-place-mode t)))

(defun saveplace-pdf-view-to-alist ()
  "Save the PDF file's place using pdf-view's `pdf-view-bookmark-make-record'."
  (or save-place-loaded (load-save-place-alist-from-file))
  (let ((item buffer-file-name))
    (when (and item
               (or (not save-place-ignore-files-regexp)
                   (not (string-match save-place-ignore-files-regexp
                                      item))))
      (let* ((cell (assoc item save-place-alist))
             (bookmark (pdf-view-bookmark-make-record))
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
                  (cons (cons item `((pdf-view-bookmark . ,bookmark)))
                        save-place-alist))))))))

(defun saveplace-pdf-view-find-file-advice (orig-fun &rest args)
  "Function to advice around `save-place-find-file-hook'.
If the buffer being visited is not in `pdf-view-mode', call the
original function ORIG-FUN with the ARGS."
  (if (not (derived-mode-p 'pdf-view-mode))
      (apply orig-fun args)
    (saveplace-pdf-view-find-file)))

(defun saveplace-pdf-view-to-alist-advice (orig-fun &rest args)
  "Function to advice around `save-place-to-alist'.
If the buffer being visited is not in `pdf-view-mode', call the
original function ORIG-FUN with the ARGS."
  (if (not (derived-mode-p 'pdf-view-mode))
      (apply orig-fun args)
    (saveplace-pdf-view-to-alist)))

(advice-add 'save-place-find-file-hook :around #'saveplace-pdf-view-find-file-advice)
(advice-add 'save-place-to-alist :around #'saveplace-pdf-view-to-alist-advice)

(provide 'saveplace-pdf-view)
;;; saveplace-pdf-view.el ends here
