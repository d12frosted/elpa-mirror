;;; bog.el --- Extensions for research notes in Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2013-2016 Kyle Meyer <kyle@kyleam.com>
;; Copyright (C) 2020 Basil L. Contovounesios <contovob@tcd.ie>

;; Author: Kyle Meyer <kyle@kyleam.com>
;; URL: https://github.com/kyleam/bog
;; Package-Version: 20201030.357
;; Package-Commit: af929c164c4ffaee0c33ba97c06733f0ce9431d4
;; Keywords: bib, outlines
;; Version: 1.3.2
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Bog provides a few convenience functions for taking research notes in
;; Org mode.  Many of these commands center around a citekey, the unique
;; identifier for a study.  See the README
;; (https://github.com/kyleam/bog) for more information.

;;; Code:

(require 'bibtex)
(require 'cl-lib)
(require 'dired)
(require 'org)
(require 'org-agenda)
(require 'org-compat)


;;; Customization

(defgroup bog nil
  "Extensions for research notes in Org mode"
  :group 'org)

(defcustom bog-citekey-format
  (rx
   word-start
   (group
    (one-or-more lower)
    (zero-or-more (any lower "-")))
   (group (= 4 digit))
   (group
    (one-or-more lower)
    (zero-or-more (any lower digit)))
   word-end)
  "Regular expression used to match study citekey.

By default, this matches any sequence of lower case
letters (allowing hyphenation) that is followed by 4 digits and
then lower case letters.

The format should be restricted to word characters and anchored
by word boundaries (i.e. '\\b..\\b' or '\\\\=<..\\>').
`bog-citekey-format-allow-at' controls whether '@' is considered
a word character.

This is case-sensitive (i.e., `case-fold-search' will be set to
nil).

The default format corresponds to the following BibTeX autokey
settings:

  (setq bibtex-autokey-year-length 4
        bibtex-autokey-titleword-length nil
        bibtex-autokey-titlewords-stretch 0
        bibtex-autokey-titlewords 1
        bibtex-autokey-year-title-separator \"\")"
  :type 'regexp)

(defcustom bog-citekey-format-allow-at t
  "Treat '@' as a word character, as it is in Org mode.

If this value is nil, Bog functions treat '@' as a punctuation
character, which allows them to work on Pandoc's @citekey format.

Warning: Setting this variable after Bog is loaded does not have
an effect.  However, it can be changed at any time through the
Customize interface."
  :package-version '(bog . "1.3.0")
  :set (lambda (var val)
         (set var val)
         (when (boundp 'bog-citekey-syntax-table)
           (modify-syntax-entry ?@ (if val "w" ".")
                                bog-citekey-syntax-table)))
  :type 'boolean)

(defcustom bog-citekey-web-search-groups '(1 2 3)
  "List of citekey subexpressions to use for web search.
The default groups correspond to the last name of the first
author, the publication year, and the first meaningful word in
the title."
  :type '(repeat integer))

(defcustom bog-citekey-property "CUSTOM_ID"
  "Property name used to store citekey.
The default corresponds to the default value of
`org-bibtex-key-property'."
  :type 'string)

(defcustom bog-root-directory "~/bib/"
  "Root directory for default values of other Bog directories."
  :type 'directory)

(defcustom bog-note-directory
  (expand-file-name "notes/" bog-root-directory)
  "Directory with Org research notes."
  :type 'directory)

(defcustom bog-file-directory
  (expand-file-name "citekey-files/" bog-root-directory)
  "Directory with citekey-associated files.
Files are stored in subdirectories if `bog-subdirectory-group' is
non-nil."
  :type 'directory)

(defcustom bog-stage-directory
  (expand-file-name "stage/" bog-root-directory)
  "Directory to search for new files.
`bog-rename-staged-file-to-citekey' and
`bog-rename-staged-bib-to-citekey' searches here for files to
rename."
  :type 'directory)

(defcustom bog-find-citekey-bib-func #'bog-find-citekey-bib-file
  "Function used to find BibTeX entry for citekey.

Default is `bog-find-citekey-bib-file', which locates single
entry BibTeX files in `bog-bib-directory'.

The other option is `bog-find-citekey-entry', which searches
within a single BibTeX file, `bog-bib-file', for the citekey
entry."
  :type 'function)

(defcustom bog-subdirectory-group nil
  "Regexp group from `bog-citekey-format' to use as subdirectory name.
If non-nil, use the indicated group to generate the subdirectory
name for BibTeX and citekey-associated files."
  :type '(choice (const :tag "Don't use subdirectories" nil)
                 (integer :tag "Regexp group number")))

(defcustom bog-bib-directory
  (expand-file-name "bibs/" bog-root-directory)
  "The name of the directory that BibTeX files are stored in.
This is only meaningful if `bog-find-citekey-bib-func' set to
`bog-find-citekey-bib-file'.  Files are stored in subdirectories
if `bog-subdirectory-group' is non-nil."
  :type 'directory)

(defcustom bog-bib-file nil
  "BibTeX file name.
This is only meaningful if `bog-find-citekey-bib-func' set to
`bog-find-citekey-entry'."
  :type '(choice (const :tag "Don't use single file" nil)
                 (file :tag "Single file")))

(defcustom bog-combined-bib-ignore-not-found nil
  "Whether `bog-create-combined-bib' ignores missing bib files.
If non-nil, `bog-create-combined-bib' does not ask whether to
continue when a citekey's bib file is not found."
  :package-version '(bog . "1.1.0")
  :type 'boolean)

(defcustom bog-citekey-file-name-separators "[-_]"
  "Regular expression matching separators in file names.
When `bog-find-citekey-file' is run on <citekey>, it will find
files with the format <citekey>.* and <citekey><sep>*.<ext>,
where <sep> is matched by this regular expression.."
  :type 'regexp)

(defcustom bog-file-renaming-func #'bog-file-ask-on-conflict
  "Function used to rename staged files.
This function should accept a file name and a citekey as
arguments and return the name of the final file.  Currently the
only built-in function is `bog-file-ask-on-conflict'."
  :type 'function)

(defcustom bog-file-secondary-name ".supplement"
  "Modification to make to file name on renaming conflict.

If <citekey>.<ext> already exists, `bog-file-ask-on-conflict'
prompts for another name.
<citekey>`bog-file-secondary-name'.<ext> is the default value for
the prompt.

For `bog-list-orphan-files' to work correctly, the first
character should be a non-word character according to
`bog-citekey-syntax-table'."
  :type 'string
  :package-version '(bog . "1.3.0"))

(defcustom bog-web-search-url
  "https://scholar.google.com/scholar?q=%s"
  "URL to use for CITEKEY search.
It should contain the placeholder \"%s\" for the query."
  :type 'string)

(defcustom bog-topic-heading-level 1
  "Consider headings at this level to be topic headings.
Topic headings for studies may be at any level, but
`bog-sort-topic-headings' and `bog-jump-to-topic-heading' use
this variable to determine what level to operate on."
  :type 'integer)

(defcustom bog-refile-maxlevel bog-topic-heading-level
  "Consider up to this level when refiling with `bog-refile'."
  :type 'integer)

(defcustom bog-keymap-prefix (kbd "C-c \"")
  "Bog keymap prefix."
  :type 'key-sequence)

(defcustom bog-use-citekey-cache nil
  "List indicating which citekey lists to cache.

Possible values are

  - headings         Citekeys for all headings in the notes
  - all-notes        All citekeys in the notes
  - files            Citekeys with associated files
  - bibs             Citekeys with BibTeX entries

If set to nil, disable cache completely.  If set to t, enable
cache for all categories.

Depending on the number of citekeys present for each of these
categories, enabling this can make functions that prompt with a
list of citekeys noticeably faster.  However, no attempt is made
to update the list of citekeys.  To see newly added citekeys,
clear the cache with `bog-clear-citekey-cache'.

This cache will not persist across sessions."
  :type '(choice
          (const :tag "Disable cache" nil)
          (const :tag "Cache all" t)
          (repeat :tag "Individual categories"
                  (choice
                   (const :tag "Cache citekeys for headings" headings)
                   (const :tag "Cache all citekeys in notes" all-notes)
                   (const :tag "Cache citekeys with associated files" files)
                   (const :tag "Cache citekeys with BibTeX entries" bibs)))))

(defcustom bog-keep-indirect nil
  "Keep the previous buffer from `bog-citekey-tree-to-indirect-buffer'.
Otherwise, each call to `bog-citekey-tree-to-indirect-buffer'
kills the indirect buffer created by the previous call."
  :type 'boolean)

(defvar bog-citekey-syntax-table
  (let ((st (make-syntax-table text-mode-syntax-table)))
    (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?@ (if bog-citekey-format-allow-at "w" ".") st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "_" st)
    (modify-syntax-entry ?~ "_" st)
    st)
  "Syntax table used when working with citekeys.
Like `org-mode-syntax-table', but hyphens and underscores are
treated as word characters.  '@' will be considered a word
character if `bog-citekey-format-allow-at' is non-nil.")

(defcustom bog-clean-bib-hook nil
  "Hook run during `bog-clean-and-rename-staged-bibs' call.
After each bib file is processed, functions in this hook will be
called in a buffer visiting the bib file."
  :package-version '(bog . "1.3.0")
  :type 'hook)


;;; Citekey methods

(defun bog-citekey-p (text)
  "Return non-nil if TEXT matches `bog-citekey-format'."
  (with-syntax-table bog-citekey-syntax-table
    (let ((case-fold-search nil))
      (string-match-p (format "\\`%s\\'" bog-citekey-format) text))))

(defun bog-citekey-at-point ()
  "Return citekey at point."
  (save-excursion
    (with-syntax-table bog-citekey-syntax-table
      (skip-syntax-backward "w")
      (let ((case-fold-search nil))
        (and (looking-at bog-citekey-format)
             (match-string-no-properties 0))))))

(defun bog-citekey-from-heading-title ()
  "Retrieve citekey from heading title."
  (when (derived-mode-p 'org-mode)
    (unless (org-before-first-heading-p)
      (let ((heading (org-no-properties (org-get-heading t t))))
        (and (bog-citekey-p heading)
             heading)))))

(defun bog-citekey-from-heading ()
  "Retrieve citekey from current heading title or property."
  (or (bog-citekey-from-heading-title)
      (bog-citekey-from-property)))

(defun bog-citekey-from-tree ()
  "Retrieve citekey from first parent heading associated with citekey."
  (when (derived-mode-p 'org-mode)
    (org-with-wide-buffer
     (let (maybe-citekey)
       (while (and (not (setq maybe-citekey (bog-citekey-from-heading)))
                   ;; This isn't actually safe in Org mode <= 8.2.10.
                   ;; Fixed in Org mode commit
                   ;; 9ba9f916e87297d863c197cb87199adbb39da894.
                   (ignore-errors (org-up-heading-safe))))
       maybe-citekey))))

(defun bog-citekey-from-surroundings ()
  "Get the citekey from the context of the Org file."
  (or (bog-citekey-at-point)
      (bog-citekey-from-tree)))

(defun bog-citekey-from-property ()
  "Retrieve citekey from `bog-citekey-property'."
  (when (derived-mode-p 'org-mode)
    (let ((ck (org-entry-get (point) bog-citekey-property)))
      (and ck (bog-citekey-p ck) ck))))

;;;; Collections

(defvar bog--citekey-cache nil
  "Alist of cached citekeys.
Keys match values in `bog-use-citekey-cache'.")

(defun bog--use-cache-p (key)
  "Return non-nil if cache should be used for KEY."
  (or (eq bog-use-citekey-cache t)
      (memq key bog-use-citekey-cache)))

(defmacro bog--with-citekey-cache (key &rest body)
  "Execute BODY, maybe using cached citekey values for KEY.
Use cached values if `bog-use-citekey-cache' is non-nil for KEY.
Cached values are updated to the return values of BODY."
  (declare (indent 1) (debug t))
  (let ((use-cache-p (make-symbol "use-cache-p")))
    `(let* ((,use-cache-p (bog--use-cache-p ,key))
            (citekeys (or (and ,use-cache-p
                               (cdr (assq ,key bog--citekey-cache)))
                          ,@body)))
       (when ,use-cache-p
         (setq bog--citekey-cache
               (cons (cons ,key citekeys)
                     (assq-delete-all ,key bog--citekey-cache))))
       citekeys)))

(defun bog-clear-citekey-cache (category)
  "Clear cache of citekeys for CATEGORY.
CATEGORY should be a key in `bog-use-citekey-cache' or t, which
indicates to clear all categories.  Interactively, clear all
categories when a single \\[universal-argument] is given.
Otherwise, prompt for CATEGORY."
  (interactive
   (progn
     (unless bog--citekey-cache
       (user-error "Citekey cache is empty"))
     (list (or (equal current-prefix-arg '(4))
               (let ((choice (and bog--citekey-cache
                                  (completing-read
                                   "Category: "
                                   (cons "*all*" bog--citekey-cache)))))
                 (if (equal choice "*all*") t (intern choice)))))))
  (setq bog--citekey-cache
        (and (not (eq category t))
             (assq-delete-all category bog--citekey-cache))))

(defvar bog--no-sort nil)
(defun bog--maybe-sort (values)
  "Sort VALUES by `string-lessp' unless `bog--no-sort' is non-nil."
  (or (and bog--no-sort values)
      (sort values #'string-lessp)))

(defun bog-citekeys-in-file (file)
  "Return all citekeys in FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (bog-citekeys-in-buffer)))

(defun bog-all-citekeys ()
  "Return all citekeys in notes."
  (bog--with-citekey-cache 'all-notes
    (bog--maybe-sort
     (let ((bog--no-sort t))
       (cl-mapcan #'bog-citekeys-in-file (bog-notes))))))

(defun bog-heading-citekeys-in-buffer ()
  "Return all heading citekeys in current buffer."
  (bog--maybe-sort (delq nil (org-map-entries #'bog-citekey-from-heading))))

(defun bog-heading-citekeys-in-file (file)
  "Return all citekeys in headings of FILE."
  (with-temp-buffer
    (let ((default-directory (file-name-directory file)))
      (insert-file-contents file)
      (org-mode)
      (bog-heading-citekeys-in-buffer))))

(defun bog-all-heading-citekeys ()
  "Return citekeys that have a heading in any note file."
  (bog--with-citekey-cache 'headings
    (bog--maybe-sort
     (let ((bog--no-sort t))
       (cl-mapcan #'bog-heading-citekeys-in-file (bog-notes))))))

(defun bog-citekeys-in-buffer ()
  "Return all citekeys in current buffer."
  (save-excursion
    (let ((case-fold-search nil)
          citekeys)
      (goto-char (point-min))
      (with-syntax-table bog-citekey-syntax-table
        (while (re-search-forward bog-citekey-format nil t)
          (push (match-string-no-properties 0) citekeys)))
      (bog--maybe-sort (delete-dups citekeys)))))

(defun bog-heading-citekeys-in-wide-buffer ()
  "Return all citekeys in current buffer, without any narrowing."
  (bog--maybe-sort
   (delq nil (org-map-entries #'bog-citekey-from-heading nil 'file))))

(defun bog-non-heading-citekeys-in-file (file)
  "Return all non-heading citekeys in FILE."
  (let ((case-fold-search nil)
        citekeys)
    (with-temp-buffer
      (let ((default-directory (file-name-directory file)))
        (insert-file-contents file)
        (org-mode)
        (with-syntax-table bog-citekey-syntax-table
          (while (re-search-forward bog-citekey-format nil t)
            (unless (or (org-at-heading-p)
                        (org-at-property-p))
              (push (match-string-no-properties 0) citekeys)))))
      (bog--maybe-sort (delete-dups citekeys)))))

;;;; Selection

(defmacro bog-selection-method (name context-method collection-method)
  "Create citekey selection function.
Create a function named bog-citekey-from-NAME with the following
behavior:
- Takes one argument (NO-CONTEXT).
- If NO-CONTEXT is nil, calls CONTEXT-METHOD with no arguments.
- If CONTEXT-METHOD returns nil or if NO-CONTEXT is non-nil,
  prompts with the citekeys gathered by COLLECTION-METHOD."
  `(defun ,(intern (concat "bog-citekey-from-" name)) (no-context)
     ,(format "Select citekey with `%s'.
Fall back on `%s'.
If NO-CONTEXT is non-nil, immediately fall back."
              context-method
              collection-method)
     (or (and no-context (bog-select-citekey (,collection-method)))
         (,context-method)
         (bog-select-citekey (,collection-method)))))

(bog-selection-method "surroundings-or-files"
                      bog-citekey-from-surroundings
                      bog-all-file-citekeys)

(bog-selection-method "surroundings-or-bibs"
                      bog-citekey-from-surroundings
                      bog-bib-citekeys)

(bog-selection-method "surroundings-or-all"
                      bog-citekey-from-surroundings
                      bog-all-citekeys)

(bog-selection-method "point-or-buffer-headings"
                      bog-citekey-at-point
                      bog-heading-citekeys-in-wide-buffer)

(bog-selection-method "point-or-all-headings"
                      bog-citekey-at-point
                      bog-all-heading-citekeys)

(defvar bog-citekey-history nil)

(defun bog-select-citekey (citekeys)
  "Prompt for citekey from CITEKEYS."
  (completing-read "Select citekey: " citekeys
                   nil t nil 'bog-citekey-history))

;;;; Other

;; `show-all' is obsolete as of Emacs 25.1.
(defalias 'bog--outline-show-all
  (if (fboundp 'outline-show-all)
      #'outline-show-all
    'show-all))

(defun bog--set-difference (list1 list2)
  (let ((sdiff (cl-set-difference list1 list2 :test #'string=)))
    ;; As of Emacs 25.1, `cl-set-difference' keeps the order of LIST1
    ;; rather than leaving it reversed.
    (if (string-lessp (nth 0 sdiff) (nth 1 sdiff))
        sdiff
      (nreverse sdiff))))

(defun bog-list-orphan-citekeys (&optional file)
  "List citekeys that appear in notes but don't have a heading.
With prefix argument FILE, include only orphan citekeys from that
file."
  (interactive (and current-prefix-arg
                    (list (bog-read-note-file-name))))
  (let ((files (if file (list file) (bog-notes)))
        (heading-cks (bog-all-heading-citekeys)))
    (with-current-buffer (get-buffer-create "*Bog orphan citekeys*")
      (erase-buffer)
      (dolist (file files)
        (let* ((text-cks (bog-non-heading-citekeys-in-file file))
               (nohead-cks (bog--set-difference text-cks heading-cks)))
          (when nohead-cks
            (insert (format "* %s\n\n%s\n\n"
                            (file-name-nondirectory file)
                            (mapconcat #'identity nohead-cks "\n"))))))
      (if (> (buffer-size) 0)
          (progn
            (org-mode)
            (bog-mode)
            (bog--outline-show-all)
            (goto-char (point-min))
            (pop-to-buffer (current-buffer)))
        (kill-buffer)
        (message "No orphans found")))))

(defun bog-list-duplicate-heading-citekeys (&optional clear-cache)
  "List citekeys that have more than one heading.
With prefix CLEAR-CACHE, reset cache of citekey headings (which
is only active if `bog-use-citekey-cache' is non-nil)."
  (interactive "P")
  (when clear-cache
    (bog-clear-citekey-cache 'headings))
  (let ((bufname "*Bog duplicate heading citekeys*")
        (dup-cks (bog--find-duplicates (bog-all-heading-citekeys))))
    (if (not dup-cks)
        (progn (message "No duplicate citekeys found")
               (and (get-buffer bufname)
                    (kill-buffer bufname)))
      (with-current-buffer (get-buffer-create bufname)
        (erase-buffer)
        (insert (mapconcat #'identity dup-cks "\n") ?\n)
        (org-mode)
        (bog-mode 1)
        (goto-char (point-min)))
      (pop-to-buffer bufname))))

(defun bog--find-duplicates (list)
  (let (dups uniqs)
    (dolist (it list)
      (cond
       ((member it dups))
       ((member it uniqs)
        (push it dups))
       (t
        (push it uniqs))))
    (nreverse dups)))


;;; Citekey-associated files

;;;###autoload
(defun bog-find-citekey-file (&optional no-context)
  "Open citekey-associated file.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys that have
an associated file in `bog-file-directory'.  Do the same if
locating a citekey from context fails.

If the citekey prompt is slow to appear, consider enabling the
`files' category in `bog-use-citekey-cache'."
  (interactive "P")
  (org-open-file
   (bog--get-citekey-file
    (bog-citekey-from-surroundings-or-files no-context))))

;;;###autoload
(defun bog-dired-jump-to-citekey-file (&optional no-context)
  "Jump to citekey file in Dired.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys that have
an associated file in `bog-file-directory'.  Do the same if
locating a citekey from context fails.

If the citekey prompt is slow to appear, consider enabling the
`files' category in `bog-use-citekey-cache'."
  (interactive "P")
  (dired-jump
   'other-window
   (bog--get-citekey-file
    (bog-citekey-from-surroundings-or-files no-context))))

(defun bog--get-citekey-file (citekey)
  (let* ((citekey-files (bog-citekey-files citekey))
         (num-choices (length citekey-files)))
    (cl-case num-choices
      (0 (user-error "No file found for %s" citekey))
      (1 (car citekey-files))
      (t
       (let* ((fname-paths
               (mapcar (lambda (path)
                         (cons (file-name-nondirectory path) path))
                       citekey-files))
              (fname (completing-read "Select file: " fname-paths)))
         (cdr (assoc-string fname fname-paths)))))))

(defun bog-citekey-files (citekey)
  "Return files in `bog-file-directory' associated with CITEKEY.
These should be named [<subdir>/]CITEKEY[<sep>*].<ext>, where
<sep> is a character in `bog-citekey-file-name-separators' and is
determined by `bog-subdirectory-group'."
  (let* ((subdir (bog--get-subdir citekey))
         (dir (file-name-as-directory
               (or (and subdir (expand-file-name subdir bog-file-directory))
                   bog-file-directory))))
    (directory-files dir t
                     (format "\\`%s\\(%s.*\\)?\\."
                             (regexp-quote citekey)
                             bog-citekey-file-name-separators))))

(defun bog--get-subdir (citekey)
  "Return subdirectory for citekey file.
Subdirectory is determined by `bog-subdirectory-group'."
  (with-syntax-table bog-citekey-syntax-table
    (let ((case-fold-search nil))
      (and bog-subdirectory-group
           (string-match bog-citekey-format citekey)
           (match-string-no-properties bog-subdirectory-group
                                       citekey)))))

;;;###autoload
(defun bog-rename-staged-file-to-citekey (&optional no-context)
  "Rename citekey file in `bog-stage-directory' with `bog-file-renaming-func'.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys present in
any note file.  Do the same if locating a citekey from context
fails.

If the citekey prompt is slow to appear, consider enabling the
`files' category in `bog-use-citekey-cache'."
  (interactive "P")
  (bog--rename-staged-file-to-citekey
   (bog-citekey-from-surroundings-or-all no-context)))

(defun bog--rename-staged-file-to-citekey (citekey)
  (let* ((staged-files (bog-staged-files))
         (staged-file-names (mapcar #'file-name-nondirectory staged-files))
         (num-choices (length staged-file-names))
         staged-file)
    (cl-case num-choices
      (0 (setq staged-file (read-file-name "Select file to rename: ")))
      (1 (setq staged-file (car staged-files)))
      (t (setq staged-file (expand-file-name
                            (completing-read "Select file to rename: "
                                             staged-file-names)
                            bog-stage-directory))))
    (bog--rename-file-to-citekey staged-file citekey)))

;;;###autoload
(defun bog-rename-citekey-file (&optional no-context)
  "Associate a citekey file with a new citekey.

This allows you to update a file's name if you change the
citekey.

The new citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys present in
any note file.  Do the same if locating a citekey from context
fails."
  (interactive "P")
  (let ((file-paths (mapcar (lambda (path)
                              (cons (file-name-nondirectory path) path))
                            (bog-all-citekey-files))))
    (bog--rename-file-to-citekey
     (cdr (assoc-string (completing-read "Rename file: " file-paths)
                        file-paths))
     (bog-citekey-from-surroundings-or-all no-context))))

(defun bog--rename-file-to-citekey (file citekey)
  (message "Renamed %s to %s" file
           (funcall bog-file-renaming-func file citekey)))

(defun bog-file-ask-on-conflict (staged-file citekey)
  "Rename citekey file, prompting for a new name if it already exists.
STAGED-FILE is renamed to <citekey>.<ext> within
`bog-file-directory' (and, optionally, within a subdirectory,
depending on `bog-subdirectory-group').  If this file already
exists, prompt for another name.  `bog-file-secondary-name'
controls the default string for the prompt."
  (let* ((ext (file-name-extension staged-file))
         (citekey-file (bog-citekey-as-file citekey ext))
         (dir (file-name-directory citekey-file)))
    (unless (file-exists-p dir)
      (make-directory dir))
    (condition-case nil
        (rename-file staged-file citekey-file)
      (file-already-exists
       (let ((dir (file-name-directory citekey-file))
             (new-file-name
              (file-name-nondirectory
               (bog-citekey-as-file (concat citekey bog-file-secondary-name)
                                    ext))))
         (setq new-file-name
               (read-string
                (format "File %s already exists.  Name to use instead: "
                        (file-name-base citekey-file))
                new-file-name))
         (setq citekey-file (expand-file-name new-file-name dir))
         (rename-file staged-file citekey-file))))
    citekey-file))

(defun bog-citekey-as-file (citekey ext)
  "Return name of associated file for CITEKEY.
Generate a file name with the form
`bog-file-directory'/[<subdir>/]CITEKEY.EXT, where the optional
<subdir> is determined by `bog-subdirectory-group'."
  (let* ((subdir (bog--get-subdir citekey))
         (dir (file-name-as-directory
               (or (and subdir (expand-file-name subdir bog-file-directory))
                   bog-file-directory))))
    (expand-file-name (concat citekey "." ext) dir)))

(defun bog-all-file-citekeys ()
  "Return a list of citekeys for files in `bog-file-directory'."
  (bog--with-citekey-cache 'files
    (bog--maybe-sort
     (delete-dups (delq nil (mapcar #'bog-file-citekey
                                    (bog-all-citekey-files)))))))

(defun bog-file-citekey (file)
  "Return leading citekey part from base name of FILE."
  (let ((fname (file-name-base file))
        (case-fold-search nil))
    ;; Use `org-mode-syntax-table' instead of
    ;; `bog-citekey-syntax-table' so the hyphens and underscores are
    ;; treated as word boundaries.
    (with-syntax-table org-mode-syntax-table
      (and (string-match (concat "\\`" bog-citekey-format) fname)
           (match-string 0 fname)))))

(defun bog-all-citekey-files ()
  "Return list of all files in `bog-file-directory'."
  (let (dirs)
    (if bog-subdirectory-group
        (dolist (df (directory-files bog-file-directory t
                                     directory-files-no-dot-files-regexp t))
          (when (and (file-readable-p df) (file-directory-p df))
            (push df dirs)))
      (push bog-file-directory dirs))
    (cl-mapcan
     (lambda (dir)
       (cl-remove-if #'file-directory-p
                     (directory-files
                      dir t directory-files-no-dot-files-regexp t)))
     dirs)))

(defun bog-staged-files ()
  "Return files in `bog-stage-directory'."
  (cl-remove-if (lambda (f) (or (file-directory-p f)
                                (backup-file-name-p f)))
                (directory-files bog-stage-directory
                                 t directory-files-no-dot-files-regexp)))

;;;###autoload
(defun bog-list-orphan-files ()
  "Find files in `bog-file-directory' without a citekey heading."
  (interactive)
  (let ((head-cks (bog-all-heading-citekeys)))
    (with-current-buffer (get-buffer-create "*Bog orphan files*")
      (erase-buffer)
      (setq default-directory bog-root-directory)
      (with-syntax-table bog-citekey-syntax-table
        (dolist (ck-file (bog-all-citekey-files))
          (let ((base-name (file-name-nondirectory ck-file))
                (case-fold-search nil))
            (unless (and (string-match (concat "\\`" bog-citekey-format)
                                       base-name)
                         (member (match-string-no-properties 0 base-name)
                                 head-cks))
              (insert (format "- [[file:%s]]\n"
                              (file-relative-name ck-file)))))))
      (goto-char (point-min))
      (org-mode)
      (if (> (buffer-size) 0)
          (pop-to-buffer (current-buffer))
        (message "No orphans found")
        (kill-buffer)))))


;;; BibTeX-related

;;;###autoload
(defun bog-find-citekey-bib (&optional no-context)
  "Open BibTeX file for a citekey.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

The variable `bog-find-citekey-bib-func' determines how the
citekey is found.

With prefix argument NO-CONTEXT, prompt with citekeys that have a
BibTeX entry.  Do the same if locating a citekey from context
fails.

If the citekey prompt is slow to appear, consider enabling the
`bib' category in `bog-use-citekey-cache'."
  (interactive "P")
  (funcall bog-find-citekey-bib-func
           (bog-citekey-from-surroundings-or-bibs no-context)))

(defun bog-find-citekey-bib-file (citekey)
  "Open BibTeX file of CITEKEY contained in `bog-bib-directory'."
  (let ((bib-file (bog-citekey-as-bib citekey)))
    (unless (file-exists-p bib-file)
      (user-error "%s does not exist" bib-file))
    (find-file-other-window bib-file)))

(defun bog-find-citekey-entry (citekey)
  "Search for CITEKEY in `bog-bib-file'."
  (find-file-other-window bog-bib-file)
  (bibtex-search-entry citekey))

;;;###autoload
(defun bog-clean-and-rename-staged-bibs ()
  "Clean and rename BibTeX files in `bog-stage-directory'.

Search for new BibTeX files in `bog-stage-directory', and run
`bibtex-clean-entry' on each file before it is moved to
`bog-bib-directory'/[<subdir>/]<citekey>.bib, where the optional
<subdir> is determined by `bog-subdirectory-group'.

This function is only useful if you use the non-standard setup of
one entry per BibTeX file."
  (interactive)
  (let ((staged (directory-files bog-stage-directory t "\\.bib\\'")))
    (dolist (file staged)
      (bog--prepare-bib-file file t))))

(defun bog--prepare-bib-file (file &optional new-key)
  (let (bib-file)
    (with-temp-buffer
      (bibtex-mode)
      (insert-file-contents file)
      ;; Make sure `bibtex-entry-head' is set since we're not visiting
      ;; a file.
      (unless bibtex-entry-head (bibtex-set-dialect nil 'local))
      (bibtex-skip-to-valid-entry)
      (bibtex-clean-entry new-key)
      (if (looking-at bibtex-entry-head)
          (setq bib-file (bog-citekey-as-bib (bibtex-key-in-head)))
        (error "BibTeX header line looks wrong"))
      (let ((dir (file-name-directory bib-file)))
        (unless (file-exists-p dir)
          (make-directory dir)))
      (write-file bib-file)
      (run-hooks 'bog-clean-bib-hook))
    ;; If a buffer was visiting the original bib file, point it to the
    ;; new file.
    (let ((file-buf (find-buffer-visiting file)))
      (when file-buf
        (with-current-buffer file-buf
          (when (get-buffer bib-file)
            (user-error "Buffer for %s already exists" bib-file))
          (rename-buffer bib-file)
          (set-visited-file-name bib-file nil t))))
    (delete-file file)))

;;;###autoload
(defun bog-create-combined-bib (&optional arg)
  "Create a buffer that has entries for a collection of citekeys.
If in Dired, collect citekeys from marked files.  Otherwise,
collect citekeys from the current buffer.  With prefix argument
ARG, reverse the meaning of `bog-combined-bib-ignore-not-found'."
  (interactive (list (if current-prefix-arg
                         (not bog-combined-bib-ignore-not-found)
                       bog-combined-bib-ignore-not-found)))
  (let ((bib-buffer-name "*Bog combined bib*")
        citekeys
        citekey-bibs)
    (let ((bog--no-sort t))
      (if (derived-mode-p 'dired-mode)
          (setq citekeys
                (delete-dups (cl-mapcan #'bog-citekeys-in-file
                                        (dired-get-marked-files))))
        (setq citekeys (bog-citekeys-in-buffer))))
    (setq citekeys (sort citekeys #'string-lessp))
    (setq citekey-bibs
          (mapcar (lambda (ck) (cons ck (bog-citekey-as-bib ck)))
                  citekeys))
    (with-current-buffer (get-buffer-create bib-buffer-name)
      (erase-buffer)
      (dolist (citekey-bib citekey-bibs)
        (cond
         ((file-exists-p (cdr citekey-bib))
          (insert "\n")
          (insert-file-contents (cdr citekey-bib))
          (goto-char (point-max)))
         ((or arg
              (y-or-n-p (format "No BibTeX entry found for %s.  Skip it? "
                                (car citekey-bib)))))
         (t
          (kill-buffer bib-buffer-name)
          (user-error "Aborting"))))
      (bibtex-mode)
      (goto-char (point-min)))
    (pop-to-buffer bib-buffer-name)))

(defun bog-citekey-as-bib (citekey)
  "Return file name `bog-bib-directory'/CITEKEY.bib."
  (let* ((subdir (bog--get-subdir citekey))
         (dir (file-name-as-directory
               (or (and subdir (expand-file-name subdir bog-bib-directory))
                   bog-bib-directory))))
    (expand-file-name (concat citekey ".bib") dir)))

(defun bog-bib-citekeys ()
  "Return a list citekeys for all BibTeX entries.
If `bog-bib-file' is non-nil, it returns citekeys from this file
instead of citekeys from file names in `bog-bib-directory'."
  (bog--with-citekey-cache 'bibs
    (if bog-bib-file
        (with-temp-buffer
          (bibtex-mode)
          (insert-file-contents bog-bib-file)
          (mapcar #'car (bibtex-parse-keys)))
      (let (dirs)
        (if bog-subdirectory-group
            (dolist (df (directory-files
                         bog-bib-directory t
                         directory-files-no-dot-files-regexp t))
              (when (and (file-readable-p df) (file-directory-p df))
                (push df dirs)))
          (push bog-bib-directory dirs))
        (bog--maybe-sort
         (mapcar #'file-name-sans-extension
                 (cl-mapcan
                  (lambda (dir) (directory-files dir nil "\\.bib\\'" t))
                  dirs)))))))

;;;###autoload
(defun bog-list-orphan-bibs ()
  "Find bib citekeys that don't have a citekey heading."
  (interactive)
  (let ((orphans (bog--set-difference (bog-bib-citekeys)
                                      (bog-all-heading-citekeys)))
        (orphan-bufname "*Bog orphan bibs*"))
    (if orphans
        (with-current-buffer (get-buffer-create orphan-bufname)
          (erase-buffer)
          (setq default-directory bog-root-directory)
          (insert (mapconcat #'identity orphans "\n") ?\n)
          (goto-char (point-min))
          (org-mode)
          (pop-to-buffer (current-buffer)))
      (let ((old-buf (get-buffer orphan-bufname)))
        (when old-buf
          (kill-buffer old-buf)))
      (message "No orphans found"))))

;;; Web

;;;###autoload
(defun bog-search-citekey-on-web (&optional no-context)
  "Open browser and perform query based for a citekey.

Take the URL from `bog-web-search-url'.

The citekey is split by groups in `bog-citekey-format' and joined by
\"+\" to form the query string.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys present in
any note file.  Do the same if locating a citekey from context
fails.

If the citekey file prompt is slow to appear, consider enabling
`bog-use-citekey-cache'.

If the citekey prompt is slow to appear, consider enabling the
`all-notes' category in `bog-use-citekey-cache'."
  (interactive "P")
  (bog--search-citekey-on-web
   (bog-citekey-from-surroundings-or-all no-context)))

(defun bog--search-citekey-on-web (citekey)
  (browse-url (bog-citekey-as-search-url citekey)))

(defun bog-citekey-as-search-url (citekey)
  "Return URL to use for CITEKEY search."
  (format bog-web-search-url
          (bog--citekey-groups-with-delim citekey "+")))

(defun bog--citekey-groups-with-delim (citekey delim)
  "Return expression groups CITEKEY, separated by DELIM.
Groups are specified by `bog-citekey-web-search-groups'."
  (with-syntax-table bog-citekey-syntax-table
    (let ((case-fold-search nil))
      (string-match bog-citekey-format citekey)
      (mapconcat (lambda (g) (match-string-no-properties g citekey))
                 bog-citekey-web-search-groups delim))))


;;; Notes-related

;;;###autoload
(defun bog-goto-citekey-heading-in-notes (&optional no-context)
  "Find citekey heading in notes.

The citekey is taken from the text under point if it matches
`bog-citekey-format'.

When the prefix argument NO-CONTEXT is given by a single
\\[universal-argument], prompt with citekeys that have a heading
in any note file.  Do the same if locating a citekey from context
fails.  With a double \\[universal-argument], restrict the prompt
to citekeys that have a heading in the current buffer.

If the citekey prompt is slow to appear, consider enabling the
`heading' category in `bog-use-citekey-cache'.

If the heading is found outside any current narrowing of the
buffer, the narrowing is removed."
  (interactive "P")
  (let* ((citekey (if (equal no-context '(16))
                      (bog-citekey-from-point-or-buffer-headings no-context)
                    (bog-citekey-from-point-or-all-headings no-context)))
         (marker (bog--find-citekey-heading-in-notes citekey)))
    (if (not marker)
        (message "Heading for %s not found in notes" citekey)
      (pop-to-buffer (marker-buffer marker))
      (when (or (< marker (point-min))
                (> marker (point-max)))
        (widen))
      (goto-char marker)
      (org-show-context))))

(defun bog--find-citekey-heading-in-buffer (citekey &optional pos-only)
  "Return the marker of heading for CITEKEY.
CITEKEY can either be the heading title or the property value of
the key `bog-citekey-property'.  If POS-ONLY is non-nil, return
the position instead of a marker."
  (or (org-find-exact-headline-in-buffer citekey nil pos-only)
      (bog--find-citekey-property-in-buffer citekey nil pos-only)))

(defun bog--find-citekey-property-in-buffer (citekey &optional buffer pos-only)
  "Return marker in BUFFER for heading with CITEKEY as a property value.
The property key must match `bog-citekey-property'.  If POS-ONLY
is non-nil, return the position instead of a marker."
  (with-current-buffer (or buffer (current-buffer))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (catch 'found
          (while (re-search-forward (concat "\\b" citekey "\\b") nil t)
            (save-excursion
              (beginning-of-line)
              (when (and (looking-at org-property-re)
                         (equal (downcase (match-string 2))
                                (downcase bog-citekey-property)))
                (org-back-to-heading t)
                (throw 'found
                       (if pos-only
                           (point)
                         (move-marker (make-marker) (point))))))))))))

(defun bog--find-citekey-heading-in-notes (citekey)
  "Return the marker of heading for CITEKEY in notes.
CITEKEY can either be the heading title or the property value of
the key `bog-citekey-property'.  When in a note file, search for
headings there first."
  (or (and (member (buffer-file-name (buffer-base-buffer))
                   (bog-notes))
           (bog--find-citekey-heading-in-buffer citekey))
      (org-find-exact-heading-in-directory citekey bog-note-directory)
      (bog--find-citekey-property-in-notes citekey)))

(defun bog--find-citekey-property-in-notes (citekey)
  "Return marker within notes for heading with CITEKEY as a property value.
If the current buffer is a note file, try to find the heading
there first."
  ;; Modified from `org-find-exact-heading-in-directory'.
  (let ((files (bog-notes))
        file visiting m buffer)
    (catch 'found
      (while (setq file (pop files))
        (message "Searching properties in %s" file)
        (setq visiting (org-find-base-buffer-visiting file))
        (setq buffer (or visiting (find-file-noselect file)))
        (setq m (bog--find-citekey-property-in-buffer citekey buffer))
        (when (and (not m) (not visiting)) (kill-buffer buffer))
        (and m (throw 'found m))))))

(defvar bog--last-indirect-buffer nil)

;;;###autoload
(defun bog-citekey-tree-to-indirect-buffer (&optional no-context)
  "Open subtree for citekey in an indirect buffer.

Unless `bog-keep-indirect' is non-nil, replace the indirect
buffer from the previous call.

The citekey is taken from the text under point if it matches
`bog-citekey-format'.

With prefix argument NO-CONTEXT, prompt with citekeys that have a
heading in any note file.  Do the same if locating a citekey from
context fails.

If the citekey prompt is slow to appear, consider enabling the
`heading' category in `bog-use-citekey-cache'."
  (interactive "P")
  (let* ((orig-buf (current-buffer))
         (citekey (bog-citekey-from-point-or-all-headings no-context))
         (marker (with-current-buffer (or (buffer-base-buffer)
                                          (current-buffer))
                   (bog--find-citekey-heading-in-notes citekey))))
    (if marker
        (with-current-buffer (marker-buffer marker)
          (org-with-wide-buffer
           (goto-char marker)
           (let ((org-indirect-buffer-display
                  (if (and (not bog-keep-indirect)
                           (eq bog--last-indirect-buffer orig-buf))
                      'current-window
                    'other-window)))
             (org-tree-to-indirect-buffer
              (or bog-keep-indirect
                  (not (buffer-live-p bog--last-indirect-buffer))))
             (setq bog--last-indirect-buffer org-last-indirect-buffer))))
      (message "Heading for %s not found in notes" citekey))))

;;;###autoload
(defun bog-refile ()
  "Refile heading within notes.
All headings from Org files in `bog-note-directory' at or above
level `bog-refile-maxlevel' are considered."
  (interactive)
  (let ((org-refile-targets `((bog-notes
                               :maxlevel . ,bog-refile-maxlevel))))
    (org-refile)))

(defun bog-notes ()
  "Return Org files in `bog-note-directory'."
  (directory-files bog-note-directory t
                   "\\`[^.].*\\.org\\'"))

(defun bog-read-note-file-name ()
  "Read name of Org file in `bog-note-directory'."
  (let ((note-paths (mapcar (lambda (path)
                              (cons (file-name-nondirectory path) path))
                            (bog-notes))))
    (cdr (assoc-string (completing-read "File: " note-paths)
                       note-paths))))

(defvar bog--agenda-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map org-agenda-mode-map)
    (define-key map "r" 'bog-agenda-redo)
    (define-key map "g" 'bog-agenda-redo)
    map)
  "Local keymap for Bog-related agendas.")

(defmacro bog--with-search-lprops (&rest body)
  "Execute BODY with Bog-related agenda values.
Restore the `org-lprops' property value for
`org-agenda-redo-command' after executing BODY."
  (declare (indent 0) (debug t))
  (let ((bog-lprops '((org-agenda-buffer-name "*Bog search*")
                      (org-agenda-files (bog-notes))
                      (org-agenda-text-search-extra-files ())
                      (org-agenda-sticky nil))))
    `(cl-letf (((get 'org-agenda-redo-command 'org-lprops) ',bog-lprops)
               ,@bog-lprops)
       (put 'org-agenda-files 'org-restrict nil)
       ,@body
       (use-local-map bog--agenda-map))))

;;;###autoload
(defun bog-search-notes (&optional todo-only string)
  "Search notes using `org-search-view'.
With prefix argument TODO-ONLY, search only TODO entries.  If
STRING is non-nil, use it as the search term (instead of
prompting for one)."
  (interactive "P")
  (bog--with-search-lprops
    (org-search-view todo-only string)))

;;;###autoload
(defun bog-search-notes-for-citekey (&optional todo-only)
  "Search notes for citekey using `org-search-view'.

With prefix argument TODO-ONLY, search only TODO entries.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.  If a citekey is
not found, prompt with citekeys present in any note file.

If the citekey prompt is slow to appear, consider enabling the
`all-notes' category in `bog-use-citekey-cache'."
  (interactive "P")
  (bog-search-notes todo-only
                    (bog-citekey-from-surroundings-or-all nil)))

(defun bog-agenda-redo (&optional all)
  (interactive "P")
  (bog--with-search-lprops
    (org-agenda-redo all)))

(defun bog-sort-topic-headings-in-buffer (&optional sorting-type)
  "Sort topic headings in this buffer.
SORTING-TYPE is a character passed to `org-sort-entries'.  If
nil, use ?a.  The level to sort is determined by
`bog-topic-heading-level'."
  (interactive)
  (org-map-entries (lambda () (bog-sort-if-topic-header sorting-type))))

(defun bog-sort-topic-headings-in-notes (&optional sorting-type)
  "Sort topic headings in notes.
Unlike `bog-sort-topic-headings-in-buffer', sort topic headings
in all note files."
  (interactive)
  (org-map-entries (lambda () (bog-sort-if-topic-header sorting-type))
                   nil (bog-notes)))

(defun bog-sort-if-topic-header (sorting-type)
  "Sort heading with `org-sort-entries' according to SORTING-TYPE.
Sorting is only done if the heading's level matches
`bog-topic-heading-level' and it isn't a citekey heading."
  (let ((sorting-type (or sorting-type ?a)))
    (when (and (= (org-current-level) bog-topic-heading-level)
               (not (bog-citekey-from-heading)))
      (org-sort-entries nil sorting-type))))

;;;###autoload
(defun bog-insert-heading-citekey (&optional current-buffer)
  "Select a citekey to insert at point.
By default, offer heading citekeys from all files.  With prefix
argument CURRENT-BUFFER, limit to heading citekeys from the
current buffer."
  (interactive "P")
  (let ((citekey-func (if current-buffer
                          #'bog-heading-citekeys-in-wide-buffer
                        #'bog-all-heading-citekeys)))
    (insert (bog-select-citekey (funcall citekey-func)))))

;;;###autoload
(defun bog-open-citekey-link (&optional no-context first)
  "Open a link for a citekey heading.

If FIRST is non-nil, open the first link under the heading.
Otherwise, if there is more than one link under the heading,
prompt with a list of links using the `org-open-at-point'
interface.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys that have a
heading in any note file.  Do the same if locating a citekey from
context fails.

If the citekey prompt is slow to appear, consider enabling the
`heading' category in `bog-use-citekey-cache'."
  (interactive "P")
  (let* ((citekey (bog-citekey-from-point-or-all-headings no-context))
         (marker (bog--find-citekey-heading-in-notes citekey)))
    (if marker
        (with-current-buffer (marker-buffer marker)
          (org-with-wide-buffer
           (goto-char marker)
           (org-narrow-to-subtree)
           (when first (org-next-link))
           (org-open-at-point)))
      (message "Heading for %s not found in notes" citekey))))

;;;###autoload
(defun bog-open-first-citekey-link (&optional no-context)
  "Open first link for a citekey heading.

The citekey is taken from the text under point if it matches
`bog-citekey-format' or from the current tree.

With prefix argument NO-CONTEXT, prompt with citekeys that have a
heading in any note file.  Do the same if locating a citekey from
context fails."
  (interactive "P")
  (bog-open-citekey-link no-context t))

;;;###autoload
(defun bog-next-non-heading-citekey (&optional arg)
  "Move forward to next non-heading citekey.
With argument ARG, do it ARG times."
  (interactive "p")
  (setq arg (or arg 1))
  (if (< arg 0)
      (bog-previous-non-heading-citekey (- arg))
    (with-syntax-table bog-citekey-syntax-table
      (skip-syntax-forward "w")
      (let ((case-fold-search nil))
        (while (and (> arg 0)
                    (re-search-forward bog-citekey-format nil t))
          (unless (org-at-heading-p)
            (setq arg (1- arg))))))
    (org-show-context)))

;;;###autoload
(defun bog-previous-non-heading-citekey (&optional arg)
  "Move backward to previous non-heading citekey.
With argument ARG, do it ARG times."
  (interactive "p")
  (setq arg (or arg 1))
  (with-syntax-table bog-citekey-syntax-table
    (let ((case-fold-search nil))
      (while (and (> arg 0)
                  (re-search-backward bog-citekey-format nil t))
        (unless (org-at-heading-p)
          (setq arg (1- arg)))))
    (skip-syntax-backward "w"))
  (org-show-context))

;;;###autoload
(defun bog-jump-to-topic-heading ()
  "Jump to topic heading.
Topic headings are determined by `bog-topic-heading-level'."
  (interactive)
  (let ((org-refile-targets
         `((bog-notes :level . ,bog-topic-heading-level))))
    (org-refile '(4))))


;;; Font-lock

(defface bog-citekey-face
  '((t :inherit org-link :underline nil))
  "Face used to highlight text that matches `bog-citekey-format'.")

(defun bog-fontify-non-heading-citekeys (limit)
  "Highlight non-heading citekeys."
  (let ((org-buffer-p (derived-mode-p 'org-mode)))
    (with-syntax-table bog-citekey-syntax-table
      (let ((case-fold-search nil))
        (while (re-search-forward bog-citekey-format limit t)
          (unless (and org-buffer-p
                       (save-match-data (org-at-heading-p)))
            (add-text-properties (match-beginning 0) (match-end 0)
                                 '(face bog-citekey-face))))))))

(defvar bog-citekey-font-lock-keywords
  '((bog-fontify-non-heading-citekeys . bog-citekey-face)))

(defalias 'bog--font-lock-function
  (if (fboundp 'font-lock-flush)
      #'font-lock-flush
    #'font-lock-fontify-buffer))


;;; Minor mode

;;;###autoload
(defvar bog-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map "b" 'bog-find-citekey-bib)
    (define-key map "c" 'bog-search-notes-for-citekey)
    (define-key map "f" 'bog-find-citekey-file)
    (define-key map "F" 'bog-dired-jump-to-citekey-file)
    (define-key map "g" 'bog-search-citekey-on-web)
    (define-key map "h" 'bog-goto-citekey-heading-in-notes)
    (define-key map "i" 'bog-citekey-tree-to-indirect-buffer)
    (define-key map "j" 'bog-jump-to-topic-heading)
    (define-key map "l" 'bog-open-citekey-link)
    (define-key map "L" 'bog-open-first-citekey-link)
    (define-key map "n" 'bog-next-non-heading-citekey)
    (define-key map "p" 'bog-previous-non-heading-citekey)
    (define-key map "r" 'bog-rename-staged-file-to-citekey)
    (define-key map "s" 'bog-search-notes)
    (define-key map "w" 'bog-refile)
    (define-key map "v" 'bog-view-mode)
    (define-key map "y" 'bog-insert-heading-citekey)
    map)
  "Keymap for Bog commands.
In Bog mode, these are under `bog-keymap-prefix'.
`bog-command-map' can also be bound to a key outside of Bog
mode.")

;;;###autoload
(fset 'bog-command-map bog-command-map)

(defvar bog-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map bog-keymap-prefix 'bog-command-map)
    map)
  "Keymap for Bog mode.")

;;;###autoload
(define-minor-mode bog-mode
  "Toggle Bog in this buffer.
With a prefix argument ARG, enable `bog-mode' if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil.

\\{bog-mode-map}"
  :lighter " Bog"
  (cond
   (bog-mode
    (if (derived-mode-p 'org-mode)
        (add-hook 'org-font-lock-hook #'bog-fontify-non-heading-citekeys nil t)
      (font-lock-add-keywords nil bog-citekey-font-lock-keywords)))
   (t
    (if (derived-mode-p 'org-mode)
        (remove-hook 'org-font-lock-hook #'bog-fontify-non-heading-citekeys t)
      (font-lock-remove-keywords nil bog-citekey-font-lock-keywords))
    (when (bound-and-true-p bog-view-mode)
      (bog-view-mode -1))))
  (when font-lock-mode
    (bog--font-lock-function)))


;;; View minor mode

(defvar bog-view-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "b" 'bog-find-citekey-bib)
    (define-key map "c" 'bog-search-notes-for-citekey)
    (define-key map "f" 'bog-find-citekey-file)
    (define-key map "F" 'bog-dired-jump-to-citekey-file)
    (define-key map "g" 'bog-search-citekey-on-web)
    (define-key map "h" 'bog-goto-citekey-heading-in-notes)
    (define-key map "i" 'bog-citekey-tree-to-indirect-buffer)
    (define-key map "j" 'bog-jump-to-topic-heading)
    (define-key map "l" 'bog-open-citekey-link)
    (define-key map "L" 'bog-open-first-citekey-link)
    (define-key map "n" 'bog-next-non-heading-citekey)
    (define-key map "p" 'bog-previous-non-heading-citekey)
    (define-key map "q" 'bog-view-quit)
    (define-key map "r" 'bog-rename-staged-file-to-citekey)
    (define-key map "s" 'bog-search-notes)
    map)
  "Keymap for Bog View mode.")

(defvar bog-view--old-buffer-read-only nil)
(defvar bog-view--old-bog-mode nil)

;;;###autoload
(define-minor-mode bog-view-mode
  "Toggle Bog View mode in this buffer.

With a prefix argument ARG, enable `bog-view-mode' if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil.

Turning on Bog View mode sets the buffer to read-only and gives
many of the Bog commands a single-letter key binding.

\\<bog-view-mode-map>\
To exit Bog View mode, type \\[bog-view-quit].

\\{bog-view-mode-map}"
  :lighter " Bog-view"
  (cond
   (bog-view-mode
    (setq bog-view--old-buffer-read-only buffer-read-only
          buffer-read-only t)
    (setq bog-view--old-bog-mode bog-mode)
    (bog-mode))
   (t
    (setq buffer-read-only bog-view--old-buffer-read-only)
    (unless bog-view--old-bog-mode
      (bog-mode -1)))))

(defun bog-view-quit ()
  "Leave Bog View mode."
  (interactive)
  (bog-view-mode -1))

(provide 'bog)

;;; bog.el ends here
