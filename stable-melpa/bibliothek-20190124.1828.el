;;; bibliothek.el --- Managing a digital library of PDFs  -*- lexical-binding: t; -*-

;; Copyright (C) 2018, 2019  Göktuğ Kayaalp

;; Author: Göktuğ Kayaalp <self@gkayaalp.com>
;; Version: 0.2.0
;; Package-Version: 20190124.1828
;; Package-Commit: 8a3b529d5ece261a8847298ea03ed35615cc9bfa
;; Keywords: tools
;; URL: https://dev.gkayaalp.com/elisp/index.html#bibliothek-el
;; Package-Requires: ((emacs "24.4") (pdf-tools "0.70") (a "0.1.0alpha4"))

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

;; Bibliothek.el is a management tool for a library of PDFs.  Or it
;; aspires to be so.  It's quite fresh ATM, it'll grow as it gets
;; used more.

;; Presently, bibliothek.el displays PDF files from directories in
;; ‘bibliothek-path’ in a tabulated list,
;; (see (info "(elisp) Tabulated List Mode")).

;; The functionality provided by this program is as such:

;; - List PDF files from directories specified in ‘bibliothek-path’,
;;   recursively if ‘bibliothek-recursive’ is non-nil.

;;   This list includes three columns: title, author, path.  Sorting
;;   based on these via clicking the table headers is possible.

;; - Filter this list with ‘bibliothek-filter’

;;   Using this function, the list can be filtered.  Currently this is
;;   rather unsophisticated, and only allows matching a single regexp
;;   against all the metadata PDF-tools can fetch from a file, with a
;;   match being counted positive if any of the fields match.  More
;;   complex mechanisms for better filtering are planned.

;; - View metadata of file under cursor.

;; - Visit the file associated to the item under cursor.

;; See also the docstring for the ‘bibliothek’ command, which lists
;; the keybindings, besides additional info.



;;;; Installation:

;; Bibliothek.el depends on ‘pdf-tools’.

;; After putting a copy of bibliothek.el in a directory in the
;; ‘load-path’, bibliothek.el can be configured as such:

;; (require 'bibliothek)
;; (setq bibliothek-path (list "~/Documents"))

;; Then, the Bibliothek interface can be brought up via
;; M-x bibliothek RET.

;;; Code:

(require 'a)
(require 'pdf-info)
(require 'goto-addr)
(require 'cl-lib)
(require 'tabulated-list)
(require 'button)



;;;; Customisables:

(defgroup bibliothek
  nil
  "Customisations for bibliothek.el, digital PDF library manager."
  :group 'applications
  :prefix "bibliothek-")

(defcustom bibliothek-path nil
  "A list of directories to look for PDF files."
  :type '(repeat directory)
  ;; Should be a global variable.
  :risky t
  :group 'bibliothek)

(defcustom bibliothek-recursive nil
  "Recursively look for files in subdirectories."
  :type 'boolean
  :group 'bibliothek)



;;;; Helper functions:

(defun bibliothek--items ()
  "Extract all the PDF files from each directory in ‘bibliothek-path’."
  (let (items
        (file-pattern "\\.pdf\\'"))
    (dolist (directory bibliothek-path items)
      (when (file-exists-p directory)
        (let ((files (if bibliothek-recursive
                         (directory-files-recursively directory file-pattern)
                       (directory-files directory t file-pattern t))))
          (dolist (file files)
            (cl-pushnew (cons (cons 'bibliothek--filename file)
                              (pdf-info-metadata file))
                        items)))))))

(defun bibliothek--find (&optional marker)
  "Open the PDF file for the row under point.
Optional argument MARKER is passed in when this function is
called from a button."
  ;; This function caters to two cases: 1) when it's called from the
  ;; ‘tabulated-list-mode’ mechanism, where ‘marker’ will be set; and
  ;; 2) when it's called from a keyboard command, where it won't be,
  ;; and the point may or may not be on a button.  But then we can use
  ;; the row id.
  (interactive)
  (find-file
   (if marker
       (button-get (button-at marker) 'file)
     (tabulated-list-get-id))))

;; Adapted from ‘pdf-misc-display-metadata’.
(defun bibliothek--display-metadata (path)
  "Display PDF metadata for file at PATH."
  (interactive)
  (let* ((md (pdf-info-metadata path)))
    (switch-to-buffer
     (with-current-buffer (get-buffer-create "*Bibliothek Item Metadata*")
       (let* ((inhibit-read-only t)
              (pad (apply'
                    max (mapcar (lambda (d) (length (symbol-name (car d)))) md)))
              (fmt (format "%%%ds : %%s\n" pad)))
         (erase-buffer)
         (special-mode)
         (setq header-line-format path)
         (font-lock-mode 1)
         (font-lock-add-keywords
          nil '(("^ *\\(\\(?:\\w\\|-\\)+\\) :"
                 (1 font-lock-keyword-face))))
         (dolist (d md)
           (let ((key (car d))
                 (val (cdr d)))
             (cl-case key
               (keywords
                (setq val (mapconcat 'identity val ", "))))
             (let ((beg (+ (length (symbol-name key)) (point) 3))
                   (fill-prefix (make-string (+ pad 3) ?\s)))
               (insert (format fmt key val))
               (fill-region beg (point))))))
       (goto-char 1)
       (current-buffer)))
    nil))

(defun bibliothek--info ()
  "Show the metadata buffer for current row."
  (interactive)
  (bibliothek--display-metadata (tabulated-list-get-id)))



;;;; The major mode:

(defvar bibliothek-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map "f" #'bibliothek--find)
      (define-key map "s" #'bibliothek-filter)
      (define-key map "g" #'bibliothek)
      (define-key map "i" #'bibliothek--info))))

(define-derived-mode bibliothek-mode tabulated-list-mode
  "Bibliothek"
  "Bibliothek listing."
  (use-local-map bibliothek-mode-map)
  (tabulated-list-init-header)
  (tabulated-list-print t)
  (hl-line-mode))

(defvar bibliothek--filter-history nil
  "History of filters used by ‘bibliothek’.")

(defun bibliothek--prep-item (item)
  "Prepare ITEM to be used in the table."
  (list (a-get item 'bibliothek--filename)
        (let ((title (a-get item 'title))
              (path  (a-get item 'bibliothek--filename)))
          (when (string-empty-p (string-trim title))
            (setq title (concat "(" (file-name-nondirectory path) ")")))
          (vector
           (cons title
                 `(action bibliothek--find file ,path))
           (a-get item 'author)
           path))))

(defun biblothek--prepare-table-entries (items match)
  "Prepare ITEMS for the table, filter with MATCH if applicable."
  (let (table-entries)
    (dolist (item items table-entries)
      (when (cl-remove-if-not
             (lambda (field)
               (let ((value (cdr field)))
                 (when value
                   (cond ((stringp value)
                          (string-match match value))
                         ((listp value)
                          (cl-remove-if-not
                           (lambda (v) (string-match match v))
                           value))))))
             item)
        (cl-pushnew (bibliothek--prep-item item) table-entries)))))

;;;###autoload
(defun bibliothek-filter (match)
  "Limit results using MATCH, see ‘bibliothek’.

This can be used as an alternative entry point to the Bibliothek
library listing."
  (interactive (list (read-string
                      "Filter: "
                      nil 'bibliothek--filter-history "" t)))
  (bibliothek match))

;;;###autoload
(cl-defun bibliothek (&optional (match ""))
  "Show the library contents.

This is the main entry point to the Bibliothek package.  It shows a
tabulated list of metadata for all the PDF files found in the
directories under ‘bibliothek-path’.

MATCH is an optional argument, a string, used to filter the
library listing.  An entry is included if one or more of the
fields match.

The keybindings are as follows:

\\{bibliothek-mode-map}"
  (interactive)
  (switch-to-buffer
   (with-current-buffer (get-buffer-create "*Bibliothek*")
     (setq
      tabulated-list-entries
      (biblothek--prepare-table-entries (bibliothek--items) match)
      tabulated-list-format
      [("Title"  40 t)
       ("Author" 20 t)
       ("Path"   20 t)])
     (bibliothek-mode)
     (setq-local truncate-lines t)
     (current-buffer))))



;;; Footer:
(provide 'bibliothek)
;;; bibliothek.el ends here
