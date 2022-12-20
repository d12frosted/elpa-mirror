;;; citar-denote.el --- Minor mode to integrate Citar and Denote -*- lexical-binding: t -*-

;; Copyright (C) 2022  Peter Prevos

;; Author: Peter Prevos <peter@prevos.net>
;; Maintainer: Peter Prevos <peter@prevos.net>
;; Homepage: https://github.com/pprevos/citar-denote
;; Version: 1.1.0
;; Package-Version: 20221219.2218
;; Package-Commit: 488af29418611f28637b715375137afa60e5d2f8
;; Package-Requires: ((emacs "28.1") (citar "1.0") (denote "1.2"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A minor-mode to integrate 'citar' and 'denote'.
;;
;; Provides the following functionality:
;; 
;; 1. Link notes to bibliographic entries with citation key in front matter.
;; 2. Use Citar to create and access bibliographic notes
;;
;;; Code:

(require 'citar)
(require 'denote)

(defgroup citar-denote ()
  "Creating and accessing bibliography files with Citar and Denote."
  :group 'files)

(defcustom citar-denote-keyword "bib"
  "Denote keyword (file tag) to indicate bibliographical notes."
  :group 'citar-denote
  :type '(repeat string))

(defvar citar-denote-file-type (or denote-file-type 'org)
  "File Type used by Citar-Denote.
Default is `denote-file-type' or org if the former is nil.  Users
can use another file type for their bibliographic notes.")

(defvar citar-denote-file-types
  `((org
     :reference-format "#+reference:  %s\n"
     :reference-regex "^#\\+reference\\s-*:")
    (markdown-yaml
     :reference-format "reference:  %s\n"
     :reference-regex "^reference\\s-*:")
    (markdown-toml
     :reference-format "reference  = %s\n"
     :reference-regex "^reference\\s-*=")
    (text
     :reference-format "reference:  %s\n"
     :reference-regex "^reference\\s-*:"))
  "Alist of `denote-file-type' and their format properties.

Each element is of the form (SYMBOL . PROPERTY-LIST).  SYMBOL is
one of those specified in `citar-denote-file-type'.

PROPERTY-LIST is a plist that consists of three elements:

- `:reference-format' Front matter identifier for citation key.
- `:reference-regex' Regexp to look for the citekey in a bibliographic notes.
- `:front-matter-end' Location to place citation key.")

(defvar citar-denote-files-regexp (concat "_" citar-denote-keyword)
  "Regexp used to look for file names of bibliographic notes.
The default assumes \"_bib\" tag is part of the file name.
Configurable with `citar-denote-keyword'.")

(defconst citar-denote-config
  (list :name "Denote"
        :category 'file
        :items #'citar-denote-get-notes
        :hasitems #'citar-denote-has-notes
        :open #'find-file
        :create #'citar-denote-create-note)
  "Instructing citar to use citar-denote functions.")

(defconst citar-denote-orig-source
  citar-notes-source
  "Store the `citar-notes-source' value prior to enabling citar-denote.")

(defvar citar-notes-source)

(defvar citar-notes-sources)

(defun citar-denote-reference-format (file-type)
  "Return the reference format associated to FILE-TYPE."
  (plist-get
   (alist-get file-type citar-denote-file-types)
   :reference-format))

(defun citar-denote-reference-regex (file-type)
  "Return the reference regex associated to FILE-TYPE."
  (plist-get
   (alist-get file-type citar-denote-file-types)
   :reference-regex))

(defun citar-denote-frontmatter-end (file-type)
  "Return the reference regex associated to FILE-TYPE."
  (plist-get
   (alist-get file-type citar-denote-file-types)
   :frontmatter-end))

(defun citar-denote-keywords-prompt ()
  "Prompt for one or more keywords and include `citar-denote-keyword'."
  (let ((choice (denote--keywords-crm (denote-keywords))))
    (unless (member citar-denote-keyword choice)
      (setq choice (append (list citar-denote-keyword) choice)))
    (if denote-sort-keywords
        (sort choice #'string-lessp)
      choice)))

(defun citar-denote-add-reference (key file-type)
  "Add reference property with KEY in front matter with FILE-TYPE."
  (save-excursion (goto-char (point-min))
  (re-search-forward "^\n" nil t)
  (forward-line -1)
  (if (not (eq file-type 'org))
      (forward-line -1))
  (insert (format (citar-denote-reference-format file-type) key))))

(defun citar-denote-create-note (key &optional _entry)
  "Create a bibliography note for `KEY' with properties `ENTRY'.
The file type for the note to be created is determined by user
option `denote-file-type'."
  (let ((denote-file-type citar-denote-file-type))
    (denote
     (read-string "Title: " (citar-get-value "title" key))
     (citar-denote-keywords-prompt))
    (citar-denote-add-reference key denote-file-type)))

(defun citar-denote-retrieve-reference-key-value (file file-type)
  "Return cite key value from FILE front matter per FILE-TYPE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward (citar-denote-reference-regex file-type) nil t 1)
      (funcall (denote--title-value-reverse-function file-type)
               (buffer-substring-no-properties (point) (line-end-position))))))

(defun citar-denote-get-notes (&optional keys)
  "Return Denote files associated with the `KEYS' list.
Return a hash table mapping elements of `KEY'` to associated notes.
If `KEYS' is omitted, return notes for all Denote files tagged with
`citar-denote-keyword'."
  (let ((files (make-hash-table :test 'equal)))
    (prog1 files
      (dolist (file (denote-directory-files-matching-regexp
                     citar-denote-files-regexp))
        ;; TODO: add denote-file-is-note-p to exclude attachments.
        (let ((key-in-file (citar-denote-retrieve-reference-key-value
                            file (denote-filetype-heuristics file))))
          (if keys (dolist (key keys)
                     (when (string= key key-in-file)
                       (push file (gethash key-in-file files))))
            ;; FIX: If optional arg keys are not provided.
            (push file (gethash key-in-file files)))))
      (maphash (lambda (key filelist)
                 (puthash key (nreverse filelist) files))
               files))))

(defun citar-denote-has-notes ()
  "Return predicate testing whether entry has associated denote files.
See documentation for `citar-has-notes'."
  (let ((notes (citar-denote-get-notes)))
    (unless (hash-table-empty-p notes)
      (lambda (citekey) (and (gethash citekey notes) t)))))

(defun citar-denote-dwim ()
  "Open the Citar menu related to the citation key in a bibliographic note.
This function provides access to related additional notes, attachments and URLs."
  (interactive)
  (if-let ((citekey (citar-denote-retrieve-reference-key-value
                     buffer-file-name
                     (denote-filetype-heuristics buffer-file-name))))
      (citar-run-default-action (list citekey))
    (user-error "No citation key found")))

(defun citar-denote-add-citekey ()
  "Select citation key and convert denote buffer to bibliographic note."
  (interactive)
  (let ((file-type (denote-filetype-heuristics buffer-file-name))
        (citekey (car (citar-select-refs))))
    (citar-denote-add-reference citekey file-type)
    (denote-keywords-add (list citar-denote-keyword))))

(defun citar-denote-setup ()
  "Setup `citar-denote-mode'."
  (citar-register-notes-source
   'citar-denote-source citar-denote-config)
  (setq citar-notes-source 'citar-denote-source))

(defun citar-denote-reset ()
  "Reset citar to default values."
  (setq citar-notes-source citar-denote-orig-source)
  (citar-remove-notes-source 'citar-denote))

;;;###autoload
(define-minor-mode citar-denote-mode
  "Toggle integration between Citar and Denote."
  :global t
  :group 'citar
  :lighter " citar-denote"
  (if citar-denote-mode
      (citar-denote-setup)
    (citar-denote-reset)))

(provide 'citar-denote)
;;; citar-denote.el ends here
