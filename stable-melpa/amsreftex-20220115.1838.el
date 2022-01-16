;;; amsreftex.el --- Add amsrefs bibliography support for reftex  -*- lexical-binding: t; -*-

;; Copyright (C) 2020, 2022  Fran Burstall

;; Author: Fran Burstall <fran.burstall@gmail.com>
;; Version: 0.2
;; Package-Version: 20220115.1838
;; Package-Commit: facf47b82572e3f62bd8d9b8d4f4d5258f6c8a38
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tex
;; URL: https://github.com/franburstall/amsreftex

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

;; Installation and activation:
;; - From MELPA: do
;;
;; (install-package 'amsreftex)
;; 
;; and activate with
;; 
;; (amsreftex-turn-on)
;;
;; or
;;
;; (use-package amsreftex
;;   :ensure t
;;   :config
;;   (amsreftex-turn-on))
;;
;; - Manually: download `amsreftex.el`, put it somewhere in your load-path
;; and then do
;; 
;; (require 'amsreftex)
;; (amsreftex-turn-on)
;; 
;; Usage:
;; 
;; Once `amsreftex` is activated, `reftex` should detect if you are
;; using `amsrefs` databases and Just Work.
;; 
;; It does this by checking for the existence of `\bibselect` or
;; `\bib` macros.  You may need to re-parse your document with `M-x
;; reftex-parse-all` after inserting these macros for the first time.
;; 
;; If, for any reason, you want to revert to vanilla `reftex`,
;; just do `M-x amsreftex-turn-off`.
;;
;; - Sorting:
;; Do `M-x amsreftex-sort-bibliography` to sort in-document
;; bibliographies or stand-alone `amsrefs` databases.
;; 
;; If point is in a `biblist` environment, that alone will be
;; sorted.  Otherwise, all `\bib` records in the buffer will be
;; sorted (after checking that you really want to do that).  In
;; this case, all text outside `\bib` records is left
;; untouched.
;;
;; Configuration:
;; - Database search path
;; By default, `amsreftex` inspects $TEXINPUTS to find the search-path
;; for `amsrefs` databases (.ltb files).  Customize
;; `reftex-ltbpath-environment-variables' to change this.
;; 
;; - Sort order
;; By default, `amsreftex-sort-bibliography` sorts by author
;; then year.  The list of fields to sort by is contained in
;; `amsreftex-sort-fields' so do
;;     (setq amsreftex-sort-fields '("author" "title"))
;; to sort by author then title.
;; 
;; You can choose how to sort names by setting
;; `amsreftex-sort-name-parts'.  By default, we sort by last
;; name then initial.  Do
;;     (setq amsreftex-sort-name-parts '(first last))
;; in the unlikely event that you want to sort by first name
;; then last name!

;; NEWS:
;; v0.2: -`amsreftex-sort-bibliography' added
;;       - Rename turn-on/off-amsreftex to amsreftex-turn-on/off to
;;         placate package-lint.
;; v0.1: initial release.

;; Implementation:
;; Vanilla reftex is mostly agnostic about the format of the
;; bibliography databases it uses.  It parses them into an internal
;; format with which it works from then on.  To adapt reftex to work
;; with amsrefs databases, we need only adjust the workings of 10
;; functions which make bibtex-specific assumptions (often in the shape
;; of regexps) to accomplish their ends.  These are:
;; `reftex-locate-bibliography-files'
;; `reftex-parse-bibtex-entry'
;; `reftex-get-crossref-alist'
;; `reftex-extract-bib-entries'
;; `reftex-extract-bib-entries-from-thebibliography'
;; `reftex-pop-to-bibtex-entry'
;; `reftex-echo-cite'
;; `reftex-end-of-bibentry'
;; `reftex-parse-from-file'
;; `reftex-bibtex-selection-callback'
;; We adjust these functions by advising them to call alternatives if
;; we are in an document using amsrefs.
;; 
;; We notify the presence of amsrefs databases by adding a cell to the
;; document's `reftex-docstruct-symbol' alist (with car 'database and
;; currently ignored cdr).  This is done by unconditionally replacing
;; `reftex-parse-from-file' by `amsreftex-parse-from-file' when
;; amsreftex is turned on.  Thereafter, most of the functions above
;; are advised to check for this cell and call an amsrefs-friendly
;; replacement if it is present.
;;
;; The only exceptions to this rule are `reftex-parse-from-file',
;; discussed above, `reftex-bibtex-selection-callback' and
;; `reftex-end-of-bib-entry'.  The latter are called from a selection
;; buffer where the docstruct alist is not available and so we
;; unconditionally replace them with versions that make its own test
;; for amsrefs.


;;; Code:

(require 'cl-lib)
(require 'reftex)
(require 'reftex-cite)
(require 'reftex-parse)
(require 'reftex-dcr)
(require 'sort)
(require 'subr-x)

;;* Vars

(defvar amsreftex-bib-start-re "^[ \t]*\\(\\\\bib[*]?\\){\\(\\(?:\\w\\|\\s_\\)+\\)}{\\(\\w+\\)}{"
  "Regexp matching start of amsrefs entry.")

(defvar amsreftex-kv-start-re "^[ \t]*\\(\\(?:\\w\\|-\\)+\\)[ \t\n\r]*=[ \t\n\r]*{"
  "Regexp matching start of key-val pair in amsrefs entry.")

(defvar amsreftex-biblist-start-re "^[^%\n\r]*\\\\begin{biblist}"
  "Regexp matching start of biblist environment.")

(defvar amsreftex-biblist-end-re "^[^%\n\r]*\\\\end{biblist}"
  "Regexp matching end of biblist environment.")

;; silence flycheck: this is defined in reftex-parse.
(defvar reftex--index-tags)

;; Fontification
(defvar amsreftex-font-lock-keywords
  `(
    (,amsreftex-bib-start-re (1 font-lock-keyword-face) (2 font-lock-type-face) (3 font-lock-function-name-face))
    (,amsreftex-kv-start-re (1 font-lock-variable-name-face))))

;; whether we are active
(defvar amsreftex-p nil
  "Non-nil if amsreftex is active.")

;;* Files and file search

;; amsrefs uses .ltb files for its databases.  These are essentially
;; LaTeX files so treat them as such:
(cl-pushnew '("\\.ltb\\'" . latex-mode) auto-mode-alist :test 'equal)


;; Searching for files: we setup the ltb file type for
;; reftex-locate-file.  For this, it suffices to setup the following
;; variables which MUST have the the form `reftex-*path-environment
;; variables` and `reftex-*-path`, package-lint notwithstanding:
(defcustom reftex-ltbpath-environment-variables '("TEXINPUTS")
  "List of specifications how to retrieve search path for .ltb database files.
Several entries are possible.
- If an element is the name of an environment variable, its content is used.
- If an element starts with an exclamation mark, it is used as a command
  to retrieve the path.  A typical command with the kpathsearch library would
  be `!kpsewhich -show-path=.tex'.
- Otherwise the element itself is interpreted as a path.
Multiple directories can be separated by the system dependent `path-separator'.
Directories ending in `//' or `!!' will be expanded recursively.
See also `reftex-use-external-file-finders'."
  :group 'reftex-citation-support
  :group 'reftex-finding-files
  :set 'reftex-set-dirty
  :type '(repeat (string :tag "Specification")))

(defvar reftex-ltb-path nil)
;; initialise them
(dolist (prop '(status master-dir recursive-path rec-type))
  (put 'reftex-ltb-path prop nil))
;; and register file extensions and external finders
(add-to-list 'reftex-file-extensions '("ltb"  ".ltb"))
(add-to-list 'reftex-external-file-finders '("ltb" . "kpsewhich %f.ltb"))

;; replacement for reftex-locate-bibliography-files
(defun amsreftex-locate-bibliography-files (master-dir &optional files)
  "Scan buffer for bibliography macros and return file list.

Use MASTER-DIR as root for relative paths during file-search.

If FILES is present, list these instead."
  (unless files
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
	      (concat 			;TODO: tidy up this regexp
	       "\\(^\\)[^%\n\r]*\\\\\\("
	       "bibselect[*]*"
	       "\\)\\(\\[.+?\\]\\)?{[ \t]*\\([^}]+\\)")
	      nil t)
	(setq files
	      (append files
		      (split-string (reftex-match-string 4)
				    "[ \t\n\r]*,[ \t\n\r]*"))))))
  (when files
    (setq files
          (mapcar
           (lambda (x)
             (reftex-locate-file x "ltb" master-dir))
           files))
    (delq nil files)))

;;* Parsing databases and extracting entries from them

;; We factor out the extraction of fields from \bib entries.
(defun amsreftex-extract-fields (blob &optional prefix)
  "Scan string BLOB for key-value pairs and collect these in an a-list.

Prefix key with string \"PREFIX-\" if PREFIX is non-nil.

Fields with keys 'author' or 'editor' are collected into a single BibTeX-style field."
  (with-temp-buffer
    (fundamental-mode)
    (set-syntax-table reftex-syntax-table-for-bib)
    (insert blob)
    (goto-char (point-min))
    (let (alist start key field authors editors)
      (while (re-search-forward amsreftex-kv-start-re nil t)
	(setq key (downcase (reftex-match-string 1)))
	;; (forward-char 1)
	(setq start (point))
	(condition-case nil
	    (up-list 1)
	  (error nil))
	;; extract field value
	(let ((stop (1- (point))))
	  (setq field (buffer-substring-no-properties start stop)))
	;; remove extra whitespace
	(while (string-match "[\n\t\r]\\|[ \t][ \t]+" field)
	  (setq field (replace-match " " nil t field)))
	;; collect fields
	(cond
	 ((equal key "author")
	  (push field authors))
	 ((equal key "editor")
	  (push field editors))
	 ((equal key "book")
	  ;; compound field so recurse
	  (setq alist (append (amsreftex-extract-fields field key) alist)))
	 ((and (equal key "title") prefix)
	  ;; booktitle comes from compound field
	  (push (cons "booktitle" field) alist))
	 ((equal key "date")
	  ;; amsrefs has a date field so extract the year
	  (let* ((date-fields (split-string field "-" t))
		 (year (nth 0 date-fields))
		 (month (nth 1 date-fields)))
	    (push (cons (concat prefix (when prefix "-") "year") year)
		  alist)
	    (when month
	      (push (cons (concat prefix (when prefix "-") "month") month)
		    alist))))
	 ((equal key "pages")
	  ;; strip amsrefs markup
	  (push (cons (concat prefix (when prefix "-") "pages")
		      (replace-regexp-in-string (regexp-quote "\\ndash ") "-" field))
		alist))
	 (t
	  (push (cons (concat prefix (when prefix "-") key) field) alist))))
      (when authors
	(push (cons (concat prefix (when prefix "-") "author")
		    (mapconcat #'identity  (nreverse authors) " and "))
	      alist))
      (when editors
	(push (cons (concat prefix (when prefix "-") "editor")
		    (mapconcat #'identity  (nreverse editors) " and "))
	      alist))
      (nreverse alist))))

;; Replacement for reftex-parse-bibtex-entry
(defun amsreftex-parse-entry (entry &optional from to)
  "Parse amsrefs ENTRY.
If ENTRY is nil then parse the entry in current buffer between FROM and TO."
  (let (alist thesis-type)
    (save-excursion
      (save-restriction
	(if entry
	    (progn
	      (set-buffer (get-buffer-create " *RefTeX-scratch*"))
	      (fundamental-mode)
	      (set-syntax-table reftex-syntax-table-for-bib)
	      (erase-buffer)
	      (insert entry))
	  (widen)
	  (if (and from to) (narrow-to-region from to)))
	(goto-char (point-min))
	(when (re-search-forward amsreftex-bib-start-re nil t)
	  (setq alist
		(list
		 (cons "&type" (downcase (reftex-match-string 3)))
		 (cons "&key" (reftex-match-string 2))))
	  (setq alist (append alist (amsreftex-extract-fields (buffer-string))))
	  ;; split thesis type into phdthesis and mastersthesis
	  (when (equal "thesis" (amsreftex-get-bib-field "&type" alist))
	    (if (and (setq thesis-type (amsreftex-get-bib-field "type" alist))
		     (string-match "m[.]*s[.]*c\\|master\\|diplom" thesis-type))
		(setf (cdr (assoc "&type" alist)) "mastersthesis")
	      ;; default to phdthesis
	      (setf (cdr (assoc "&type" alist)) "phdthesis"))
	    ;; bibtex's `school` is amsrefs `organization` in this
	    ;; case
	    (let ((school (amsreftex-get-bib-field "organization" alist)))
	      (if school (push (cons "school" school) alist))))

	  ;; turn articles into incollection if booktitle present
	  (if (assoc "booktitle" alist)
	      (setf (cdr (assoc "&type" alist)) "incollection"))

	  alist)))))

;; reftex-get-bib-field returns the empty string when the field is not
;; present.  This makes testing for presence more verbose.  So we
;; return nil in this case.
(defun amsreftex-get-bib-field (field entry)
  "Return value of field FIELD in ENTRY or nil if FIELD is not present."
  (cdr (assoc field entry)))

;; Replacement for reftex-get-crossref-alist
(defun amsreftex-get-crossref-alist (entry)
  "Return the alist from a crossref ENTRY."
  (let ((crkey (cdr (assoc "xref" entry)))
        start)
    (save-excursion
      (save-restriction
        (widen)
        (if (re-search-forward
             (concat "^[^%\n]*?\\(\\\\bib\\*\\)[ \t]*{"
		     (regexp-quote crkey)
		     "}[ \t]*{\\w+}[ \t]*{")
	     nil t)
            (progn
              (setq start (match-beginning 1))
              (condition-case nil
                  (up-list 1)
                (error nil))
              (amsreftex-extract-fields
	       (buffer-substring-no-properties start (point))
	       "book"))
          nil)))))

(defun amsreftex--extract-entries (re-list buffer)
  "Extract amsrefs entries that match all regexps in RE-LIST from BUFFER."
  (let (results match-point start-point end-point entry alist
		(first-re (car re-list))
		(re-rest (cdr re-list)))
    (with-current-buffer buffer
      (reftex-with-special-syntax-for-bib
       (save-excursion
	 (goto-char (point-min))
	 (while (re-search-forward first-re nil t)
	   (catch 'search-again
	     (setq match-point (point))
	     ;; look for start of \bib, taking care since the match
	     ;; could be the cite-key and so be missing by
	     ;; re-search-backward on amsreftex-bib-start-re
	     (unless (re-search-backward "^[^%\n]*?\\\\bib[ \t]*{" nil t)
	       (throw 'search-again nil))
	     (setq start-point (point))
	     ;; go to end of first line of entry
	     (re-search-forward amsreftex-bib-start-re nil t)
	     (condition-case nil
		 (up-list 1)
	       (error (goto-char match-point)
		      (throw 'search-again nil)))
	     (setq end-point (point))

	     (when (< end-point match-point) ;match not in entry
	       (goto-char match-point)
	       (throw 'search-again nil))
	     ;; we have an entry so check it against the remaining
	     ;; regexps
	     (setq entry (buffer-substring-no-properties start-point end-point))

	     (dolist (re re-rest)
	       (unless (string-match re entry) (throw 'search-again nil)))

	     (setq alist (amsreftex-parse-entry entry))
	     (push (cons "&entry" entry) alist)
	     ;; crossref stuff
	     (if (assoc "xref" alist)
		 (setq alist
		       (append
			alist (amsreftex-get-crossref-alist alist))))
	     (push (cons "&formatted" (reftex-format-bib-entry alist))
		   alist)
	     (push (amsreftex-get-bib-field "&key" alist) alist)

	     ;; add to the results
	     (push alist results))))))
    (nreverse results)))

;; Replacement for both reftex-extract-bib-entries and
;; reftex-extract-bib-entries-from-thebibliography

(defun amsreftex-extract-entries (buffers)
  "Prompt for regexp and return list of matching entries from BUFFERS.
BUFFERS is a list of buffers or file names."
  (let ((buffer-list (if (listp buffers) buffers (list buffers)))
	re-list
	buffer
	buffer1
	found-list
	default
	first-re)
    ;; Read a regexp, completing on known citation keys.
    (setq default (regexp-quote (reftex-get-bibkey-default)))
    (setq re-list (reftex--query-search-regexps default))

    (if (or (null re-list) (equal re-list '("")))
	(setq re-list (list default)))

    (setq first-re (car re-list))
    (if (string-match "\\`[ \t]*\\'" (or first-re ""))
	(user-error "Empty regular expression"))
    (if (string-match first-re "")
	(user-error "Regular expression matches the empty string"))

    (save-excursion
      (save-window-excursion

	;; Walk through all database files
	(while buffer-list
	  (setq buffer (car buffer-list)
		buffer-list (cdr buffer-list))
	  (if (and (bufferp buffer)
		   (buffer-live-p buffer))
	      (setq buffer1 buffer)
	    (setq buffer1 (reftex-get-file-buffer-force
			   buffer (not reftex-keep-temporary-buffers))))
	  (if (not buffer1)
	      (message "No such amsrefs database file %s (ignored)" buffer)
	    (message "Scanning bibliography database %s" buffer1)
	    (unless (verify-visited-file-modtime buffer1)
	      (when (y-or-n-p
		     (format "File %s changed on disk.  Reread from disk? "
			     (file-name-nondirectory
			      (buffer-file-name buffer1))))
		(with-current-buffer buffer1 (revert-buffer t t)))))
	  (setq found-list (append found-list (amsreftex--extract-entries re-list buffer1)))

	  (reftex-kill-temporary-buffers))))
    (setq found-list (nreverse found-list))

    ;; Sorting
    (cond
     ((eq 'author reftex-sort-bibtex-matches)
      (sort found-list 'reftex-bib-sort-author))
     ((eq 'year reftex-sort-bibtex-matches)
      (sort found-list 'reftex-bib-sort-year))
     ((eq 'reverse-year reftex-sort-bibtex-matches)
      (sort found-list 'reftex-bib-sort-year-reverse))
     (t found-list))))

;;* Parsing the source file

(defun amsreftex-using-amsrefs-p ()
  "Return non-nil if we seem to be using amsrefs databases."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward
     (concat
      "\\(^[^%\n]*?\\\\bibselect\\|"
      amsreftex-bib-start-re "\\)")
     nil t)))

;; reftex-parse-from-file is a big function but we only have to change
;; a tiny bit of it (see comment therein) to make it amsrefs-friendly.

;; Replacement for reftex-parse-from-file
(defun amsreftex-parse-from-file (file docstruct master-dir)
  "Scan the buffer of FILE for labels and save them in a list DOCSTRUCT.

Use MASTER-DIR as root for relative paths during file-search.

Additionally add amsref databases."
  (let ((regexp (reftex-everything-regexp))
        (bound 0)
        file-found tmp include-file
        (level 1)
        (highest-level 100)
        toc-entry index-entry next-buf buf)

    (catch 'exit
      (setq file-found (reftex-locate-file file "tex" master-dir))
      (if (and (not file-found)
               (setq buf (reftex-get-buffer-visiting file)))
          (setq file-found (buffer-file-name buf)))

      (unless file-found
        (push (list 'file-error file) docstruct)
        (throw 'exit nil))

      (save-excursion

        (message "Scanning file %s" file)
        (set-buffer
         (setq next-buf
               (reftex-get-file-buffer-force
                file-found
                (not (eq t reftex-keep-temporary-buffers)))))

        ;; Begin of file mark
        (setq file (buffer-file-name))
        (push (list 'bof file) docstruct)

        (reftex-with-special-syntax
         (save-excursion
           (save-restriction
             (widen)
             (goto-char 1)

             (while (re-search-forward regexp nil t)

	       (cond

		((match-end 1)
		 ;; It is a label
		 (when (or (null reftex-label-ignored-macros-and-environments)
			   ;; \label{} defs should always be honored,
			   ;; just no keyval style [label=foo] defs.
			   (string-equal "\\label{" (substring (reftex-match-string 0) 0 7))
			   (if (and (fboundp 'TeX-current-macro)
				    (fboundp 'LaTeX-current-environment))
			       (not (or (member (save-match-data (TeX-current-macro))
						reftex-label-ignored-macros-and-environments)
					(member (save-match-data (LaTeX-current-environment))
						reftex-label-ignored-macros-and-environments)))
			     t))
		   (push (reftex-label-info (reftex-match-string 1) file bound)
			 docstruct)))

		((match-end 3)
		 ;; It is a section

		 ;; Use the beginning as bound and not the end
		 ;; (i.e. (point)) because the section command might
		 ;; be the start of the current environment to be
		 ;; found by `reftex-label-info'.
		 (setq bound (match-beginning 0))
		 ;; The section regexp matches a character at the end
		 ;; we are not interested in.  Especially if it is the
		 ;; backslash of a following macro we want to find in
		 ;; the next parsing iteration.
		 (when (eq (char-before) ?\\) (backward-char))
		 ;; Insert in List
		 (setq toc-entry (funcall reftex-section-info-function file))
		 (when (and toc-entry
			    (eq ;; Either both are t or both are nil.
			     (= (char-after bound) ?%)
			     (string-suffix-p ".dtx" file)))
		   ;; It can happen that section info returns nil
		   (setq level (nth 5 toc-entry))
		   (setq highest-level (min highest-level level))
		   (if (= level highest-level)
		       (message
			"Scanning %s %s ..."
			(car (rassoc level reftex-section-levels-all))
			(nth 6 toc-entry)))

		   (push toc-entry docstruct)
		   (setq reftex-active-toc toc-entry)))

		((match-end 7)
		 ;; It's an include or input
		 (setq include-file (reftex-match-string 7))
		 ;; Test if this file should be ignored
		 (unless (delq nil (mapcar
				    (lambda (x) (string-match x include-file))
				    reftex-no-include-regexps))
		   ;; Parse it
		   (setq docstruct
			 (reftex-parse-from-file
			  include-file
			  docstruct master-dir))))

		((match-end 9)
		 ;; Appendix starts here
		 (reftex-init-section-numbers nil t)
		 (push (cons 'appendix t) docstruct))

		((match-end 10)
		 ;; Index entry
		 (when reftex-support-index
		   (setq index-entry (reftex-index-info file))
		   (when index-entry
		     (cl-pushnew (nth 1 index-entry) reftex--index-tags :test #'equal)
		     (push index-entry docstruct))))

		((match-end 11)
		 ;; A macro with label
		 (save-excursion
		   (let* ((mac (reftex-match-string 11))
			  (label (progn (goto-char (match-end 11))
					(save-match-data
					  (reftex-no-props
					   (reftex-nth-arg-wrapper
					    mac)))))
			  (typekey (nth 1 (assoc mac reftex-env-or-mac-alist)))
			  (entry (progn (if typekey
					    ;; A typing macro
					    (goto-char (match-end 0))
					  ;; A neutral macro
					  (goto-char (match-end 11))
					  (reftex-move-over-touching-args))
					(reftex-label-info
					 label file bound nil nil))))
		     (push entry docstruct))))
		(t (error "This should not happen (reftex-parse-from-file)"))))

	     ;; amsreftex changes start here
	     (cond
	      ((amsreftex-using-amsrefs-p)
	       (push (cons 'database "amsrefs") docstruct)
	       ;; Find amsrefs bibliography statement
	       (when (setq tmp (amsreftex-locate-bibliography-files master-dir))
		 (push (cons 'bib tmp) docstruct)))
	      (t
               ;; Find bib(la)tex bibliography statement
               (when (setq tmp (reftex-locate-bibliography-files master-dir))
		 (push (cons 'bib tmp) docstruct))))

             (goto-char 1)
             (when (re-search-forward
                    (concat  "\\(\\(\\`\\|[\n\r]\\)[ \t]*\\\\begin{thebibliography}\\)\\|\\("
			     amsreftex-bib-start-re
			     "\\)")
		    nil t)
               (push (cons 'thebib file) docstruct))
	     ;; amsreftex changes end here

	     ;; Find external document specifications
             (goto-char 1)
             (while (re-search-forward "[\n\r][ \t]*\\\\externaldocument\\(\\[\\([^]]*\\)\\]\\)?{\\([^}]+\\)}" nil t)
               (push (list 'xr-doc (reftex-match-string 2)
                           (reftex-match-string 3))
                     docstruct))

             ;; End of file mark
             (push (list 'eof file) docstruct)))))

      ;; Kill the scanned buffer
      (reftex-kill-temporary-buffers next-buf))

    ;; Return the list
    docstruct))

 


;;* Pop to entry and echo citations

;; Replace the callback...the issue here is that this callback may be
;; called in a context (the Ref-Select buffer) where we have no access
;; to the reftex-docstruct-symbol of the document buffer.  This means
;; our usual advice method applied to reftex-pop-to-bibtex-entry might
;; not work  so we must test for amsrefs in a different way
;; (by inpsecting the format of the entry) and manually choose the
;; function for popping to the entry.

(defun amsreftex-database-selection-callback (data _ignore no-revisit)
  "Display database entry corresponding to DATA.

If NO-REVISIT is non-nil, only search existing buffers.

Callback function to be called from the Reftex-Select selection, in
order to display context.  This function is relatively slow and not
recommended for follow mode.  It works OK for individual lookups.

This version also tests whether amsrefs databases are in use and
dispatches the pop-to-entry function based on that."
  (let ((win (selected-window))
        (key (reftex-get-bib-field "&key" data))
	(amsrefs (string-match amsreftex-bib-start-re
			       (reftex-get-bib-field "&entry" data)))
        bibfile-list item bibtype pop-fn)

    (setq pop-fn (if amsrefs
		     #'amsreftex-pop-to-database-entry
		   #'reftex-pop-to-bibtex-entry))

    (catch 'exit
      (with-current-buffer reftex-call-back-to-this-buffer
        (setq bibtype (reftex-bib-or-thebib))
        (cond
         ((eq bibtype 'bib)
          (setq bibfile-list (reftex-get-bibfile-list)))
         ((eq bibtype 'thebib)
          (setq bibfile-list
                (reftex-uniquify
                 (mapcar #'cdr
                         (reftex-all-assq
                          'thebib (symbol-value reftex-docstruct-symbol))))
                item t))
         (reftex-default-bibliography
          (setq bibfile-list (reftex-default-bibliography)))
         (t (ding) (throw 'exit nil))))

      (when no-revisit
        (setq bibfile-list (reftex-visited-files bibfile-list)))

      (condition-case nil
          (funcall pop-fn
		   key bibfile-list (not reftex-keep-temporary-buffers) t item)
        (error (ding))))

    (select-window win)))

;; Replacement for reftex-pop-to-bibtex-entry
(defun amsreftex-pop-to-database-entry (key file-list &optional mark-to-kill
					    highlight _ return)
  "Find amsrefs KEY in any file in FILE-LIST in another window.
If MARK-TO-KILL is non-nil, mark new buffer to kill.
If HIGHLIGHT is non-nil, highlight the match.
If RETURN is non-nil, just return the entry and restore point."
  (let* ((re (concat "\\\\bib[*]?{" (regexp-quote key) "}[ \t]*{\\(\\w+\\)}{"))
         (buffer-conf (current-buffer))
         file buf pos oldpos)

    (catch 'exit
      (while file-list
        (setq file (car file-list)
              file-list (cdr file-list))
        (unless (setq buf (reftex-get-file-buffer-force file mark-to-kill))
          (error "No such file %s" file))
        (set-buffer buf)
	(setq oldpos (point))
        (widen)
        (goto-char (point-min))
        (if (not (re-search-forward re nil t))
	    (goto-char oldpos) ;; restore previous position of point
          (goto-char (match-beginning 0))
          (setq pos (point))
          (when return
            ;; Just return the relevant entry
	    (setq return (buffer-substring
                          pos (reftex-end-of-bib-entry nil)))
	    (goto-char oldpos) ;; restore point.
            (set-buffer buffer-conf)
            (throw 'exit return))
          (switch-to-buffer-other-window buf)
          (goto-char pos)
          (recenter 0)
          (if highlight
              (reftex-highlight 0 (match-beginning 0) (match-end 0)))
          (throw 'exit (selected-window))))
      (set-buffer buffer-conf)
      (error "No amsrefs entry with citation key %s" key))))

;; Replacement for reftex-end-of-bib-entry
(defun amsreftex-end-of-bib-entry (item)
  "Find the end of a database entry, a \\bibitem if ITEM non-nil.

Assumes that point is at the start of the entry."
  (save-excursion
    (condition-case nil
        (cond
	 ((looking-at-p "[ \t]*\\\\bib[*]?{")
	  (forward-list 3)
	  (point))
	 (item
	  (end-of-line)
	  (re-search-forward
	   "\\\\bibitem\\|\\\\end{thebibliography}")
	  (1- (match-beginning 0)))
	 (t
	  (forward-list 1) (point)))
      (error (min (point-max) (+ 300 (point)))))))

;;* Subvert relevant reftex functions

;; Silence the byte-compiler: we shall define these functions by macro below.
(declare-function amsreftex-subvert-reftex-locate-bibliography-files "amsreftex" t)
(declare-function amsreftex-subvert-reftex-parse-bibtex-entry "amsreftex" t)
(declare-function amsreftex-subvert-reftex-get-crossref-alist "amsreftex" t)
(declare-function amsreftex-subvert-reftex-extract-bib-entries "amsreftex"  t)
(declare-function amsreftex-subvert-reftex-extract-bib-entries-from-thebibliography "amsreftex" t)
(declare-function amsreftex-subvert-reftex-pop-to-bibtex-entry "amsreftex" t)

(defmacro amsreftex-subvert-fn (old-fn new-fn)
  "If amsrefs databases are in use, advise OLD-FN so that it is replaced by NEW-FN."
  (let ((subvert-fn (intern (format "amsreftex-subvert-%s" old-fn))))
    `(progn
       (defun ,subvert-fn (old-fn &rest args)
	 ,(format "If amsrefs databases are in use, replace OLD-FN with `%s'.

Intended to advise `%s'" new-fn old-fn)
	 (if (assq 'database (symbol-value reftex-docstruct-symbol))
	     (apply #',new-fn args)
	   (apply old-fn args)))
       
       (advice-add ',old-fn :around #',subvert-fn))))

(defun amsreftex-set-last-arg-to-nil (args)
  "If amsrefs databases are in use, set last element of ARGS to nil."
  (when (assq 'database (symbol-value reftex-docstruct-symbol))
    (setf (car (last args)) nil))
  args)

;;* Sorting
;; This is shockingly easy in some ways, thanks to the 'sort' library.
;; The only thing that requires any thought is the sort predicate.
;; But that is where things get complicated: should we sort in utf-8
;; by locale collate order?  To do so, we must go down the rabbit hole
;; of converting TeX accents and special characters to utf-8.  On the
;; other hand, what do journals do?  A small sampling from MathSciNet
;; suggests that, for example, Ørsted gets sorted as if Orsted by
;; Trans. AMS and so we will do similarly.  We brutally strip out
;; accents and special characters as though it is still the 1980's and
;; ASCII is king.  We may return to this later and try to do better.

;;** Handling names

(defvar amsreftex-sort-fields '("author" "year")
  "List of \\bib fields to compare when sorting bibliographies.

The default is to sort by authors then year.")

(defvar amsreftex-sort-name-parts '(last initial)
  "Ordered list of parts of a name to compare when sorting.

Valid elements are 'first, 'last and 'initial.

Example: when set to '(first last) then \"Segal, Graeme\" will
sort before \"Atiyah, Michael\" while, with '(last first), the
converse is true.")

(defun amsreftex-strip-LaTeX (str)
  "Strip LaTeX accents from string STR."
  ;; accents
  (let ((re "\\\\[\"'.=^`~bcdHkrtuv] ?"))
    (while (string-match re str)
      (setq str (replace-match "" nil t str)))
    ;; any remaining backslashes
    (while (string-match "\\\\" str)
      (setq str (replace-match "" nil t str)))
    ;; leftover {}
    (while (string-match "[{}]" str)
      (setq str (replace-match "" nil t str)))
    str))

(defun amsreftex-get-name-parts (name)
  "Parse NAME into a list of parts according to `amsreftex-sort-name-parts'."
  (let* ((template (or amsreftex-sort-name-parts '(last first)))
	 (part-list (split-string name "," t "[ \t]+"))
	 (last (or (nth 0 part-list) ""))
	 (first (or (nth 1 part-list) ""))
	 (initial (if (> (length first) 0) (substring first 0 1) "")))
    (mapcar
     (lambda (part) (cond ((eq part 'last) last)
			  ((eq part 'first) first)
			  ((eq part 'initial) initial)))
     template)))

(defun amsreftex-get-bib-name-list (entry)
  "Get list of names from ENTRY.

Try author first and then editor."
  (let ((names (amsreftex-get-bib-field "author" entry)))
    (unless names (setq names (amsreftex-get-bib-field "editor" entry)))
    (if (not names)
	(list "")
      (thread-last (split-string names "\\band\\b" nil "[ \t]+")
	(mapcar #'amsreftex-strip-LaTeX)
	(mapcar #'downcase)
	(mapcar #'amsreftex-get-name-parts)))))

;;** Predicates

(defun amsreftex-compare-by-field (e1 e2 field)
  "Return non-nil if FIELD of E1 is less than that of E2.

Compares with `amsreftex-compare-FIELD' if this is fbound and `string<' otherwise."
  (let ((pred (intern (concat "amsreftex-compare-" field))))
    (if (fboundp pred)
	(funcall pred e1 e2)
      (string< (reftex-get-bib-field field e1)
	       (reftex-get-bib-field field e2)))))

(defun amsreftex-compare-lists (l1 l2 pred)
  "Return non-nil if L1 should sort before L2 according to PRED.

In more detail, return the value of PRED applied to the first
  pair of values in L1 and L2 that are not `equal'.  If there is
  no such pair, return non-nil if L1 is strictly shorter than
  L2."
  (while (and l1 l2 (equal (car l1) (car l2)))
    (pop l1)
    (pop l2))
  (cond ((and l1 l2)
	 (funcall pred (car l1) (car l2)))
	((or l1 l2)
	 (not l1))
	(t nil)))

(defun amsreftex-compare-author (e1 e2)
  "Return non-nil if authors/editors of E1 should sort before those of E2.

Compares names according to `amsreftex-sort-name-parts'."
  (let ((nl1 (amsreftex-get-bib-name-list e1))
	(nl2 (amsreftex-get-bib-name-list e2)))
   (amsreftex-compare-lists
     nl1
     nl2
     (lambda (n1 n2) (amsreftex-compare-lists n1 n2 #'string<)))))

(defun amsreftex-compare-year (e1 e2)
  "Return non-nil if year field of E1 should sort before that of E2."
  (let ((y1 (string-to-number (reftex-get-bib-field "year" e1)))
	(y2 (string-to-number (reftex-get-bib-field "year" e2))))
    (< y1 y2)))

;;** Sort (finally!)
;; We exploit the excellent `sort-subr' which needs the next three
;; functions:

(defun amsreftex-sort-nextrecfn ()
  "Move point to the the start of the next \\bib record.

Moves point to the end of the buffer if there is no next record."
  (let ((start-pos (re-search-forward amsreftex-bib-start-re nil t)))
    (if start-pos
	(goto-char (match-beginning 0))
      (goto-char (point-max)))))

(defun amsreftex-sort-endrecfn ()
  "Move point to end of the containing \\bib record.

If point is not in a record, move point to the end of the
previous \\bib record.  If this fails, leave point where it was
and signal an error."
  (let ((pos (point)))
    (end-of-line)     ;in case we are still at the start of the record
    (condition-case nil
	(progn
	  (re-search-backward amsreftex-bib-start-re)
	  (forward-list 3))
      (t (error "Malformed \\bib entry near position %S" pos)
	 (goto-char pos)))))

(defun amsreftex-sort-startkeyfn ()
  "Parse current \\bib record for use as sort key.

Assumes point is at the start of the record."
  (amsreftex-parse-entry nil
			 (point)
			 (amsreftex-end-of-bib-entry nil)))

(defun amsreftex-sort-buffer-by (pred)
  "Sort the \\bib records in the current buffer according to PRED."
  (let ((sort-fold-case t))
    (sort-subr nil
	       #'amsreftex-sort-nextrecfn
	       #'amsreftex-sort-endrecfn
	       #'amsreftex-sort-startkeyfn
	       nil
	       pred)))

;;;###autoload
(defun amsreftex-sort-bibliography ()
  "Sort bibliography at point by fields listed in `amsreftex-sort-fields'.

If point is not in a bibliography, ask whether to sort all \\bib
entries in the buffer.  If the buffer contains multiple
bibliographies, you probably do not want to do this."
  (interactive)
  (let ((field-list (reverse (or amsreftex-sort-fields '(author year))))
	biblist-start biblist-end pos)
    (catch 'bail
      (save-excursion
	(save-restriction
	  (widen)
	  ;; Find the biblist
	  (end-of-line)
	  (setq pos (point))
	  (setq biblist-start (re-search-backward amsreftex-biblist-start-re nil t))
	  (setq biblist-end (re-search-forward amsreftex-biblist-end-re nil t))
	  (if (and biblist-start biblist-end (<= biblist-start pos biblist-end))
	      ;; we have a biblist: narrow to it
	      (narrow-to-region biblist-start biblist-end)
	    (unless (y-or-n-p "No biblist env found around point: sort whole buffer? ")
	      (throw 'bail nil)))
	  ;; Sort it
	  (dolist (field field-list)
	    (goto-char (point-min))
	    (amsreftex-sort-nextrecfn)
	    (amsreftex-sort-buffer-by
	     (lambda (e1 e2) (amsreftex-compare-by-field e1 e2 field)))))))))

;;* Entry point

;;;###autoload
(defun amsreftex-turn-on ()
  "Turn on amsreftex.

This advises several reftex functions to make them work with
amsrefs databases and installs some font-locking for \\bib
macros."
  (interactive)
  ;; conditionally replace these fns with their amsreftex versions
  (amsreftex-subvert-fn reftex-locate-bibliography-files amsreftex-locate-bibliography-files)
  (amsreftex-subvert-fn reftex-parse-bibtex-entry amsreftex-parse-entry)
  (amsreftex-subvert-fn reftex-get-crossref-alist amsreftex-get-crossref-alist)
  (amsreftex-subvert-fn reftex-extract-bib-entries amsreftex-extract-entries)
  (amsreftex-subvert-fn reftex-extract-bib-entries-from-thebibliography amsreftex-extract-entries)
  (amsreftex-subvert-fn reftex-pop-to-bibtex-entry amsreftex-pop-to-database-entry)
  ;; reftex-echo-cite has an argument ITEM for dealing with the case of
  ;; on-board \bibitems.  We conditionally set this argument to nil.
  (advice-add 'reftex-echo-cite :filter-args #'amsreftex-set-last-arg-to-nil)
  ;; unconditionally replace three functions:
  ;; 1. Replace reftex-parse-from-file just to get off the ground.
  ;; This is what makes document buffers amsrefs-aware.
  ;; 2. reftex-bibtex-selection-callback and reftex-end-of-bib-entry
  ;; can be called from a buffer that is not amsrefs-aware.
  (advice-add 'reftex-parse-from-file :override #'amsreftex-parse-from-file)
  (advice-add 'reftex-bibtex-selection-callback :override #'amsreftex-database-selection-callback)
  (advice-add 'reftex-end-of-bib-entry :override #'amsreftex-end-of-bib-entry)
  ;; Add some fontification for \bib macros
  (font-lock-add-keywords 'latex-mode amsreftex-font-lock-keywords)
  
  (setq amsreftex-p t))

(defun amsreftex-turn-off ()
  "Turn off amsreftex, leaving almost no trace behind.

 We remove all advice added by `turn-on-amsrefs' and any font-locking installed."
  (interactive)
  (if (not amsreftex-p)
      (user-error "Amsreftex is not turned on!")
    (advice-remove 'reftex-locate-bibliography-files #'amsreftex-subvert-reftex-locate-bibliography-files)
    (advice-remove 'reftex-parse-bibtex-entry #'amsreftex-subvert-reftex-parse-bibtex-entry)
    (advice-remove 'reftex-get-crossref-alist #'amsreftex-subvert-reftex-get-crossref-alist)
    (advice-remove 'reftex-extract-bib-entries #'amsreftex-subvert-reftex-extract-bib-entries)
    (advice-remove 'reftex-extract-bib-entries-from-thebibliography
		   #'amsreftex-subvert-reftex-extract-bib-entries-from-thebibliography)
    (advice-remove 'reftex-pop-to-bibtex-entry #'amsreftex-subvert-reftex-pop-to-bibtex-entry)
    (advice-remove 'reftex-echo-cite #'amsreftex-set-last-arg-to-nil)
    (advice-remove 'reftex-end-of-bib-entry #'amsreftex-set-last-arg-to-nil)
    (advice-remove 'reftex-parse-from-file #'amsreftex-parse-from-file)
    (advice-remove 'reftex-bibtex-selection-callback #'amsreftex-database-selection-callback)

    (font-lock-remove-keywords 'latex-mode amsreftex-font-lock-keywords)

    (setq amsreftex-p nil)))

;; for the two users of v0.1:
(define-obsolete-function-alias 'turn-on-amsreftex 'amsreftex-turn-on "0.2"
  "Turn on amsreftex.

This advises several reftex functions to make them work with
amsrefs databases and installs some font-locking for \\bib
macros.")

(define-obsolete-function-alias 'turn-off-amsreftex #'amsreftex-turn-off "0.2"
  "Turn off amsreftex, leaving almost no trace behind.

 We remove all advice added by `turn-on-amsrefs' and any font-locking installed.")

(provide 'amsreftex)

;;* TO DO:
;; 
;; (a) Look into better formatting of \bib by auctex.  Best option is
;; no formatting.  Should add an entry to
;; LaTeX-indent-environment-list.  Learn about how filling works...


;;; amsreftex.el ends here
