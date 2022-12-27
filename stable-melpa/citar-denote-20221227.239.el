;;; citar-denote.el --- Minor mode to integrate Citar and Denote -*- lexical-binding: t -*-

;; Copyright (C) 2022  Peter Prevos

;; Author: Peter Prevos <peter@prevos.net>
;; Maintainer: Peter Prevos <peter@prevos.net>
;; Homepage: https://github.com/pprevos/citar-denote
;; Version: 1.2.0
;; Package-Version: 20221227.239
;; Package-Commit: 4928ff861d96e597e420588078d0f44ea19d9a0a
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
;; 1. Create new bibliographic note: 'citar-create-note'.
;; 2. Open existing bibliographic notes: 'citar-open-notes'.
;; 3. Convert existing note to bibliographic note: 'citar-denote-add-citekey'.
;; 4. Open attachments, URLs or other associated notes: 'citar-denote-dwim'.
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

(defcustom citar-denote-file-type (or denote-file-type 'org)
  "File Type used by Citar-Denote.
Default is `denote-file-type' or org if the former is nil.  Users
can use another file type for their bibliographic notes."
  :group 'citar-denote
  :type '(choice
          (const :tag "Unspecified (defaults to Org)" nil)
          (const :tag "Org mode (default)" org)
          (const :tag "Markdown (YAML front matter)" markdown-yaml)
          (const :tag "Markdown (TOML front matter)" markdown-toml)
          (const :tag "Plain text" text)))

(defcustom citar-denote-subdir 'nil
  "Ask for a subdirectory when creating a new bibliographic note."
  :group 'citar-denote
  :type 'boolean)

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

;; Citar integration

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

;; Auxiliary functions

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

The file type for the note to be created is determined by `denote-file-type'.
When `citar-denote-subdir' is non-nil, prompt for a subdirectory."
  (denote
   (read-string "Title: " (citar-get-value "title" key))
   (citar-denote-keywords-prompt)
   citar-denote-file-type
   (when citar-denote-subdir (denote-subdirectory-prompt)))
  (citar-denote-add-reference key citar-denote-file-type))

(defun citar-denote-retrieve-keys (file)
  "Return cite key value(s) from FILE front matter."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((trims "[ \t\n\r]+")
          (file-type (denote-filetype-heuristics file)))
      (when (re-search-forward (citar-denote-reference-regex file-type) nil t 1)
        (split-string
         (string-trim
          (buffer-substring-no-properties (point) (line-end-position))
          trims trims) ";")))))

(defun citar-denote-get-notes (&optional keys)
  "Return Denote files associated with the `KEYS' citation keys.
If `KEYS' is omitted, return all Denote files tagged with
`citar-denote-keyword'."
  (let ((files (make-hash-table :test 'equal)))
    (prog1 files
      (dolist (file (denote-directory-files-matching-regexp
                     citar-denote-files-regexp))
        (let ((key-in-file (citar-denote-retrieve-keys file)))
          (dolist (key key-in-file)
            (if keys (dolist (k keys)
                       (when (string= k key)
                         (push file (gethash key files))))
              (push file (gethash key files))))))
      (maphash (lambda (key filelist)
                 (puthash key (nreverse filelist) files))
               files))))

(defun citar-denote-has-notes ()
  "Return predicate testing whether entry has associated denote files.
See documentation for `citar-has-notes'."
  (let ((notes (citar-denote-get-notes)))
    (unless (hash-table-empty-p notes)
      (lambda (citekey) (and (gethash citekey notes) t)))))

;; Interactive functions

(defun citar-denote-dwim ()
  "Open the Citar menu related to the citation key in a bibliographic note.
This function provides access to related additional notes, attachments and URLs."
  (interactive)
  ;; Any citation keys in the note?
  (if-let ((keys (citar-denote-retrieve-keys (buffer-file-name))))
      ;; Check if citation keys are in the bibliography
      (if-let
          (keys? (not (seq-every-p 'null
                                   (mapcar (lambda (key)
                                             (gethash key (citar-get-entries)))
                                           keys))))
          (citar-open keys)
        (user-error "Citation key(s) not in bibliography"))
    (user-error "No reference citation key found in current buffer")))

(defun citar-denote-add-citekey ()
  "Add citation key to existing or convert to bibliographic note."
  (interactive)
  (let ((file-type (denote-filetype-heuristics (buffer-file-name)))
        (citekeys (citar-select-refs)))
    ;; Check whether reference line already exists
    (if-let (keys (citar-denote-retrieve-keys (buffer-file-name)))
        ;; Append reference list
        (save-excursion
          (goto-char (point-min))
          (re-search-forward (citar-denote-reference-regex file-type))
          (end-of-line)
          (insert (concat ";" (mapconcat 'identity citekeys ";"))))
      ;; New citation keys
      (progn (citar-denote-add-reference
              (mapconcat 'identity citekeys ";") file-type)
             (denote-keywords-add (list citar-denote-keyword))))))

;; Initialise minor mode
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
