;;; ox-rst.el --- Export reStructuredText using org-mode. -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2019  Masanao Igarashi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Author: Masanao Igarashi <syoux2@gmail.com>
;; Keywords: org, rst, reST, reStructuredText
;; Package-Version: 20200815.1511
;; Package-Commit: 99fa790da55b57a3f2e9aa187493ba434a64250e
;; Version: 0.3
;; URL: https://github.com/msnoigrs/ox-rst
;; Package-Requires: ((emacs "25.1") (org "8.3"))

;;; Commentary:
;; This library implements an reStructuredText back-end for
;; Org generic exporter.

;;; Code:

(require 'cl-lib)
(require 'ox)
(require 'ox-publish)


;;; Define Back-End
(org-export-define-backend 'rst
  '((bold . org-rst-bold)
    (center-block . org-rst-center-block)
    (clock . org-rst-clock)
    (code . org-rst-code)
    (drawer . org-rst-drawer)
    (dynamic-block . org-rst-dynamic-block)
    (entity . org-rst-entity)
    (example-block . org-rst-example-block)
    (export-block . org-rst-export-block)
    (export-snippet . org-rst-export-snippet)
    (fixed-width . org-rst-example-block)
    (footnote-reference . org-rst-footnote-reference)
    (headline . org-rst-headline)
    (horizontal-rule . org-rst-horizontal-rule)
    (inline-src-block . org-rst-inline-src-block)
    (inlinetask . org-rst-inlinetask)
    (inner-template . org-rst-inner-template)
    (italic . org-rst-italic)
    (item . org-rst-item)
    (keyword . org-rst-keyword)
    (latex-environment . org-rst-latex-environment)
    (latex-fragment . org-rst-latex-fragment)
    (line-break . org-rst-line-break)
    (link . org-rst-link)
    (node-property . org-rst-node-property)
    (paragraph . org-rst-paragraph)
    (plain-list . org-rst-plain-list)
    (plain-text . org-rst-plain-text)
    (planning . org-rst-planning)
    (property-drawer . org-rst-property-drawer)
    (quote-block . org-rst-quote-block)
    (radio-target . org-rst-radio-target)
    (section . org-rst-section)
    (special-block . org-rst-special-block)
    (src-block . org-rst-src-block)
    (statistics-cookie . org-rst-statistics-cookie)
    (strike-through . org-rst-strike-through)
    (subscript . org-rst-subscript)
    (superscript . org-rst-superscript)
    (table . org-rst-table)
    (table-cell . org-rst-table-cell)
    (table-row . org-rst-table-row)
    (target . org-rst-target)
    (template . org-rst-template)
    (timestamp . org-rst-timestamp)
    (underline . org-rst-underline)
    (verbatim . org-rst-verbatim)
    (verse-block . org-rst-verse-block)
    ;; Pseudo objects and elements.
    (latex-math-block . org-rst-math-block))
  :menu-entry
  '(?r "Export to reStructuredText"
	   ((?R "As reStructuredText buffer" org-rst-export-as-rst)
		(?r "As reStructuredText file" org-rst-export-to-rst)))
  :options-alist
  '((:subtitle "SUBTITLE" nil nil parse)
    (:rst-link-use-abs-url nil "rst-link-use-abs-url" org-rst-link-use-abs-url)
    (:rst-inline-images nil nil org-rst-inline-images)
    (:rst-inline-image-rules nil nil org-rst-inline-image-rules)
    (:rst-link-org-files-as-rst nil nil org-rst-link-org-files-as-rst)
    (:rst-link-home "RST_LINK_HOME" nil org-rst-link-home)
    (:rst-link-use-ref-role nil nil org-rst-link-use-ref-role)
    (:rst-extension nil nil org-rst-extension)
    (:rst-file-link-use-ref-role nil nil org-rst-file-link-use-ref-role)
    (:rst-text-markup-alist nil nil org-rst-text-markup-alist)
    (:rst-quote-margin nil nil org-rst-quote-margin)
    (:rst-headline-underline-characters nil nil org-rst-headline-underline-characters)
    (:rst-headline-spacing nil nil org-rst-headline-spacing)
    (:rst-paragraph-spacing nil nil org-rst-paragraph-spacing)
    (:rst-format-drawer-function nil nil org-rst-format-drawer-function)
    (:rst-format-inlinetask-function nil nil org-rst-format-inlinetask-function)
    (:rst-code-block nil nil org-rst-code-block)
    (:rst-pygments-langs nil nil org-rst-pygments-langs))
  :filters-alist '((:filter-options . org-rst-math-block-options-filter)
                   (:filter-headline . org-rst-filter-headline-blank-lines)
				   (:filter-parse-tree org-rst-math-block-tree-filter
                                       org-rst-separate-elements
									   org-rst-filter-paragraph-spacing)
				   (:filter-section . org-rst-filter-headline-blank-lines)))


;;; Internal Variables



;;; User Configurable Variables

(defgroup org-export-rst nil
  "Options for exporting Org mode files to reStructuredText."
  :tag "Org RST"
  :group 'org-export)


(defcustom org-rst-extension "rst"
  "The extension for exported reStructuredText files."
  :group 'org-export-rst
  :type 'string)


(defcustom org-rst-link-org-files-as-rst t
  "Non-nil means make file links to `file.org' point to `file.rst'.
When `org-mode' is exporting an `org-mode' file to reStructuredText,
links to non-rst files are directly put into a href tag in
reStructuredText.
However, links to other Org mode files (recognized by the extension
`.org.) should become links to the corresponding reStructuredText
file, assuming that the linked `org-mode' file will also be
converted to reStructuredText.
When nil, the links still point to the plain \".org\" file."
  :group 'org-export-rst
  :type 'boolean)


(defcustom org-rst-link-home ""
  "Where should the \"HOME\" link of exported rst files lead?"
  :group 'org-export-rst
  :type '(string :tag "File or URL"))


(defcustom org-rst-link-use-abs-url nil
  "Should we prepend relative links with RST_LINK_HOME?"
  :group 'org-export-rst
  :type 'boolean)

;;;; Links :: Inline images

(defcustom org-rst-inline-images t
  "Non-nil means inline images into exported reStructuredText.
This is done using an image directive or an figure directive.
When nil, an anchor with reference is used to link to the image."
  :group 'org-export-rst
  :type 'boolean)

(defcustom org-rst-inline-image-rules
  '(("file" . "\\.\\(jpeg\\|jpg\\|png\\|webp\\|gif\\|svg\\|svgz\\|swf\\)\\'")
    ("attachment" . "\\.\\(jpeg\\|jpg\\|png\\|webp\\|gif\\|svg\\|svgz\\|swf\\)\\'")
    ("http" . "\\.\\(jpeg\\|jpg\\|png\\|webp\\|gif\\|svg\\|svgz\\|swf\\)\\'")
    ("https" . "\\.\\(jpeg\\|jpg\\|png\\|webp\\|gif\\|svg\\|svgz\\|swf\\)\\'"))
  "Rules characterizing image files that can be inlined into reStructuredText.
A rule consists in an association whose key is the type of link
to consider, and value is a regexp that will be matched against
link's path."
  :group 'org-export-rst
  :type '(alist :key-type (string :tag "Type")
		:value-type (regexp :tag "Path")))

(defcustom org-rst-link-use-ref-role nil
  "Non-nil means export internal links using :ref: role."
  :group 'org-export-rst
  :type 'boolean)

(defcustom org-rst-file-link-use-ref-role nil
  "Non-nil means export internal file links using :ref: role."
  :group 'org-export-rst
  :type 'boolean)

(defcustom org-rst-text-markup-alist '((bold . "**%s**")
									   (code . verb)
									   (italic . "*%s*")
									   (verbatim . verb))
  "Alist of reStructredText expressions to convert text markup.

The key must be a symbol among `bold', `code', `italic',
`verbatim'.  The value is a formatting string to
wrap fontified text with.

Value can also be set to the following symbols: `verb'.

If no association can be found for a given markup, text will be
returned as-is."
  :group 'org-export-rst
  :type 'alist
  :options '(bold code italic verbatim))


(defcustom org-rst-quote-margin 4
  "Width of margin used for quoting text, in characters.
This margin is applied on left side of the text."
  :group 'org-export-rst
  :type 'integer)


(defcustom org-rst-headline-spacing '(1 . 1)
  "Number of blank lines inserted around headlines.

This variable can be set to a cons cell.  In that case, its car
represents the number of blank lines present before headline
contents whereas its cdr reflects the number of blank lines after
contents.

A nil value replicates the number of blank lines found in the
original Org buffer at the same place."
  :group 'org-export-rst
  :type '(choice
	  (const :tag "Replicate original spacing" nil)
	  (cons :tag "Set a uniform spacing"
		(integer :tag "Number of blank lines before contents")
		(integer :tag "Number of blank lines after contents"))))


(defcustom org-rst-paragraph-spacing 'auto
  "Number of white lines between paragraphs.
If the value is an integer, add this number of blank lines
between contiguous paragraphs.  If is it the symbol `auto', keep
the same number of blank lines as in the original document."
  :group 'org-export-rst
  :type '(choice
	  (integer :tag "Number of blank lines")
	  (const :tag "Preserve original spacing" auto)))


(defcustom org-rst-headline-underline-characters '(?- ?~ ?^ ?: ?' ?\ ?_)
  "List of underline characters for each headline level."
  :group 'org-export-rst
  :type 'list)

;;;; Drawers

(defcustom org-rst-format-drawer-function nil
  "Function called to format a drawer in reStructuredText code.

The function must accept two parameters:
  NAME      the drawer name, like \"LOGBOOK\"
  CONTENTS  the contents of the drawer.

The function should return the string to be exported.

For example, the variable could be set to the following function
in order to mimic default behaviour:

\(defun org-rst-format-drawer-default \(name contents\)
  \"Format a drawer element for reStructuredText export.\"
  contents\)"
  :group 'org-export-rst
  :type 'function)


;;;; Inlinetasks

(defcustom org-rst-format-inlinetask-function nil
  "Function called to format an inlinetask in reStructuredText code.

The function must accept six parameters:
  TODO      the todo keyword, as a string
  TODO-TYPE the todo type, a symbol among `todo', `done' and nil.
  PRIORITY  the inlinetask priority, as a string
  NAME      the inlinetask name, as a string.
  TAGS      the inlinetask tags, as a list of strings.
  CONTENTS  the contents of the inlinetask, as a string.

The function should return the string to be exported."
  :group 'org-export-rst
  :type 'function)


;;;; Src blocks

(defcustom org-rst-code-block 'code
  "The directive used to export SRC-BLOCKs."
  :group 'org-export-rst
  :type '(choice
          (const :tag "Use a code-block directive" code-block)
          (const :tag "Use a code directive" code)
          (const :tag "Use a literal block" nil))
  :safe (lambda (s) (memq s '(code-block code nil)))
  )

(defcustom org-rst-pygments-langs
  '((emacs-lisp "common-lisp") (lisp "common-lisp")
    (cc "c++")
    (cperl "perl")
    (latex "tex")
    (shell-script "bash")
    (caml "ocaml")
    (sqlite3 "sqlite"))
  "Alist mapping languages to their listing language counterpart.
The key is a symbol, the major mode symbol without the \"-mode\".
The value is the string that should be inserted as the language
parameter for the listings package.  If the mode name and the
listings name are the same, the language does not need an entry
in this list - but it does not hurt if it is present."
  :group 'org-export-rst
  :type '(repeat
	  (list
	   (symbol :tag "Major mode       ")
	   (string :tag "Pygments language"))))



;;; Internal Functions

(defun org-rst--justify-lines (s text-width how)
  "Justify all lines in string S.
TEXT-WIDTH is an integer specifying maximum length of a line.
HOW determines the type of justification: it can be `left',
`right', `full' or `center'."
  (with-temp-buffer
    (insert s)
    (goto-char (point-min))
    (let ((fill-column text-width)
	  ;; Disable `adaptive-fill-mode' so it doesn't prevent
	  ;; filling lines matching `adaptive-fill-regexp'.
	  (adaptive-fill-mode nil))
      (while (< (point) (point-max))
	(justify-current-line how)
	(forward-line)))
    (buffer-string)))


(defun org-rst--indent-string (s width)
  "Indent string S by WIDTH white spaces.
Empty lines are not indented."
  (when (stringp s)
    (replace-regexp-in-string
     "\\(^\\)\\(?:.*\\S-\\)" (make-string width ? ) s nil nil 1)))


(defun org-rst--make-attribute-string (attributes)
  "Return a list of attributes, as a string.
ATTRIBUTES is a plist where values are either strings or nil. An
attributes with a nil value will be omitted from the result."
  (let (output)
    (dolist (item attributes (mapconcat 'identity (nreverse output) "\n"))
      (cond ((null item) (pop output))
            ((symbolp item) (push (substring (symbol-name item) 1) output))
            (t (let ((key (org-trim (car output)))
                     (value (replace-regexp-in-string "\"" "\\\""
							 (replace-regexp-in-string
							  "\\\\" "\\\\" (org-trim item)))))
                 (setcar output (format "    :%s: %s" key value))))))))


(defun org-rst--build-title
  (element info &optional underline notags toc)
  "Format ELEMENT title and return it.

ELEMENT is either an `headline' or `inlinetask' element.  INFO is
a plist used as a communication channel.

When optional argument UNDERLINE is non-nil, underline title,
without the tags, according to `org-rst-underline'
specifications.

If optional argument NOTAGS is non-nil, no tags will be added to
the title.

When optional argument TOC is non-nil, use optional title if
possible.  It doesn't apply to `inlinetask' elements."
  (let* ((headlinep (eq (org-element-type element) 'headline))
		 (numbers
		  ;; Numbering is specific to headlines.
		  (and headlinep (org-export-numbered-headline-p element info)
			   ;; All tests passed: build numbering string.
			   (concat
				(mapconcat
				 'number-to-string
				 (org-export-get-headline-number element info) ".")
				" ")))
		 (text
		  (org-trim
		   (org-export-data
			(if (and toc headlinep) (org-export-get-alt-title element info)
			  (org-element-property :title element))
			info)))
		 (todo
		  (and (plist-get info :with-todo-keywords)
			   (let ((todo (org-element-property :todo-keyword element)))
				 (and todo (concat (org-export-data todo info) " ")))))
		 (tags (and (not notags)
					(plist-get info :with-tags)
					(let ((tag-list (org-export-get-tags element info)))
					  (and tag-list
                           (org-make-tag-string tag-list)))))
		 (priority
		  (and (plist-get info :with-priority)
			   (let ((char (org-element-property :priority element)))
				 (and char (format "(#%c) " char)))))
		 (first-part (concat numbers todo priority text)))
    (concat
     first-part
     ;; Align tags, if any.
     (when tags
       (format
		(format " %%%ds" (string-width tags))
		tags))
     ;; Maybe underline text, if ELEMENT type is `headline' and an
     ;; underline character has been defined.
     (when (and underline headlinep)
       (let ((under-char
			  (nth (1- (org-export-get-relative-level element info))
				   org-rst-headline-underline-characters)))
		 (and under-char
			  (concat "\n"
					  (make-string (string-width first-part) under-char))))))))


(defun org-rst--text-markup (text markup info)
  "Format TEXT depending on MARKUP text markup.
See `org-rst-text-markup-alist' for details."
  (let ((fmt (cdr (assq markup (plist-get info :rst-text-markup-alist))))
        (text (replace-regexp-in-string "[ \t\n]+" " " text)))
    (cond
     ;; No format string: Return raw text.
     ((not fmt) text)
     ;; Handle the `verb' special case: Protect some
     ;; special chars and use "\\" escape.
     ((eq 'verb fmt)
      (let ((rtn "")
	    char)
		(while (string-match "\\`*" text)
		  (setq char (match-string 0 text))
		  (when (> (match-beginning 0) 0)
			  (setq rtn (concat rtn (substring text 0 (match-beginning 0)))))
		  (setq text (substring text (1+ (match-beginning 0))))
		  (setq char (concat "\\" char)
				rtn (concat rtn char)))
		(setq text (concat rtn text)
			  fmt "``%s``")
		(format fmt text)))
     ;; Else use format string.
     (t (format fmt text)))))


(defun org-rst--checkbox (item _info)
  "Return checkbox string for ITEM or nil.
INFO is a plist used as a communication channel."
  ;(let ((utf8p (eq (plist-get info :ascii-charset) 'utf-8)))
  ;  (case (org-element-property :checkbox item)
  ;    (on (if utf8p "☑ " "[X] "))
  ;    (off (if utf8p "☐ " "[ ] "))
  ;    (trans (if utf8p "☒ " "[-] ")))))
  (cl-case (org-element-property :checkbox item)
	(on "☑ ")
	(off "☐ ")
	(trans "☒ ")))



;;; Template

(defun org-rst-template--document-title (info)
  "Return document title, as a string.
INFO is a plist used as a communication channel."
  (let* (;; Links in the title will not be resolved later, so we make
		 ;; sure their path is located right after them.
         (with-title (plist-get info :with-title))
		 (title (if with-title
                    (org-export-data (plist-get info :title) info)
                  ""))
		 (subtitle (if with-title
                       (org-export-data (plist-get info :subtitle) info)
                     ""))
		 (author (and (plist-get info :with-author)
					  (let ((auth (plist-get info :author)))
						(and auth (org-export-data auth info)))))
		 (email (and (plist-get info :with-email)
					 (org-export-data (plist-get info :email) info)))
		 (date (and (plist-get info :with-date)
					(org-export-data (org-export-get-date info) info)))
         (titleline (make-string (string-width title) ?=))
         (subtitleline (make-string (string-width subtitle) ?-))
         (title (if (not (string= title ""))
                    (concat titleline "\n"
                            title "\n"
                            titleline "\n") ""))
         (subtitle (if (not (string= subtitle ""))
                       (concat subtitleline "\n"
                               subtitle "\n"
                               subtitleline "\n") "")))
    (cond
     ((string= title "")
      (concat
       (when (org-string-nw-p author) (concat "    :Author: " author "\n"))
       (when (org-string-nw-p email) (concat "    :Contact: " email "\n"))
       (when (org-string-nw-p date) (concat "    :Date: " date "\n"))))
     (t
      (concat
       title
       subtitle
       (when (org-string-nw-p author) (concat "\n    :Author: " author))
       (when (org-string-nw-p email) (concat "\n    :Contact: " email))
       (when (org-string-nw-p date) (concat "\n    :Date: " date))
       "\n")))))


(defun org-rst-template (contents info)
  "Return complete document string after reStructuredText conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; Build title block.
   (concat (org-rst-template--document-title info)
           "\n"
		   ;; 2. Table of contents.
		   (let ((depth (plist-get info :with-toc)))
			 (when depth ".. contents::\n\n")))
   ;; Document's body.
   contents
   ;; Creator.  Justify it to the bottom right.
   (and (plist-get info :with-creater)
        (concat
         "\n    :Creator: "
         (plist-get info :creator) "\n"))))



;;; Transcode Functions

;;;; Bold

(defun org-rst-bold (_bold contents info)
  "Transcode BOLD from Org to reStructuredText.
CONTENTS is the text with bold markup.  INFO is a plist holding
contextual information."
  (org-rst--text-markup contents 'bold info))


;;;; Center Block

(defun org-rst-center-block (_center-block contents _info)
  "Transcode a CENTER-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the center block.  INFO is a plist
holding contextual information."
  contents)


;;;; Clock

(defun org-rst-clock (clock _contents _info)
  "Transcode a CLOCK object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (concat org-clock-string " "
		  (org-translate-time
		   (org-element-property :raw-value
								 (org-element-property :value clock)))
		  (let ((time (org-element-property :duration clock)))
			(and time
				 (concat " => "
						 (apply 'format
								"%2s:%02s"
								(org-split-string time ":")))))))


;;;; Code

(defun org-rst-code (code _contents info)
  "Transcode a CODE object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (org-rst--text-markup (org-element-property :value code) 'code info))


;;;; Drawer

(defun org-rst-drawer (drawer contents _info)
  "Transcode a DRAWER element from Org to reStructuredText.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((name (org-element-property :drawer-name drawer))
	 (output (if (functionp org-rst-format-drawer-function)
		     (funcall org-rst-format-drawer-function
			      name contents)
		   ;; If there's no user defined function: simply
		   ;; display contents of the drawer.
		   contents)))
    output))


;;;; Dynamic Block

(defun org-rst-dynamic-block (_dynamic-block contents _info)
  "Transcode a DYNAMIC-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  contents)


;;;; Entity

(defun org-rst-entity (entity _contents _info)
  "Transcode an ENTITY object from Org to reStructuredText.
CONTENTS are the definition itself.  INFO is a plist holding
contextual information."
  (let ((ent (org-element-property :latex entity)))
    (if (org-element-property :latex-math-p entity)
        (format ":math:`%s`" ent)
      (org-element-property :utf-8 entity))))


;;;; Example Block

(defun org-rst-example-block (example-block _contents _info)
  "Transcode an EXAMPLE-BLOCK element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let* ((example (org-remove-indentation
				   (org-element-property :value example-block)))
		 (label (org-element-property :name example-block))
		 (attributes
		  (org-export-read-attribute :attr_rst example-block))
		 (class (plist-get attributes :class)))
	(when example
	  (concat
	   "::\n"
	   (when class (format "    :class: %s\n" class))
	   (when label (format "    :name: %s\n" label))
	   "\n"
	   (org-rst--indent-string example org-rst-quote-margin)))))


;;;; Export Block

(defun org-rst-export-block (export-block _contents _info)
  "Transcode a EXPORT-BLOCK element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (when (member (org-element-property :type export-block) '("RST" "REST" "RESTRUCTUREDTEXT"))
    (org-element-property :value export-block)))


;;;; Export Snippet

(defun org-rst-export-snippet (export-snippet _contents _info)
  "Transcode a EXPORT-SNIPPET object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (when (eq (org-export-snippet-backend export-snippet) 'rst)
    (org-element-property :value export-snippet)))


;;;; Footnote Definition

;(defun org-rst-footnote-definition (footnote-definition contents info)
;  "Transcode a FOOTNOTE-DEFINITION element from Org to reStructuredText.
;CONTENTS is nil.  INFO is a plist holding contextual information."
;  (replace-regexp-in-string
;   "^" ".. "
;   (org-remove-indentation
;	(org-element-property :value footnote-definition))))


;;;; Footnote Reference

(defun org-rst-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format " [%s]_ " (org-export-get-footnote-number footnote-reference info)))


;;;; Headline

(defun org-rst-headline (headline contents info)
  "Transcode a HEADLINE element from Org to reStructuredText.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  ;; Don't export footnote section, which will be handled at the end
  ;; of the template.
  (unless (org-element-property :footnote-section-p headline)
    (let* (;; Blank lines between headline and its contents.
           ;; `org-rst-headline-spacing', when set, overwrites
           ;; original buffer's spacing.
           (pre-blanks
            (make-string
             (if org-rst-headline-spacing (car org-rst-headline-spacing)
               (org-element-property :pre-blank headline)) ?\n))
           (id (org-element-property :ID headline))
           (customid (org-element-property :CUSTOM_ID headline)))
      (concat
       (if customid
           (format ".. _%s:\n\n" customid)
         (if id (format ".. _%s:\n\n" id) ""))
       (org-rst--build-title headline info 'underline)
       "\n" pre-blanks
       contents))))


;;;; Horizontal Rule

(defun org-rst-horizontal-rule (_horizontal-rule _contents _info)
  "Transcode an HORIZONTAL-RULE object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  "\n------------\n")

;;;; Inline Src Block

(defun org-rst-inline-src-block (inline-src-block _contents info)
  "Transcode an INLINE-SRC-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (org-rst--text-markup
   (org-element-property :value inline-src-block) 'verbatim info))


;;;; Inlinetask

(defun org-rst-inlinetask (inlinetask contents info)
  "Transcode an INLINETASK element from Org to reStructuredText.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let ((title (org-export-data (org-element-property :title inlinetask) info))
		(todo (and (plist-get info :with-todo-keywords)
				   (let ((todo (org-element-property :todo-keyword inlinetask)))
					 (and todo (org-export-data todo info)))))
		(todo-type (org-element-property :todo-type inlinetask))
		(tags (and (plist-get info :with-tags)
				   (org-export-get-tags inlinetask info)))
		(priority (and (plist-get info :with-priority)
					   (org-element-property :priority inlinetask))))
    ;; If `org-rst-format-inlinetask-function' is provided, call it
    ;; with appropriate arguments.
    (if (functionp org-rst-format-inlinetask-function)
		(funcall org-rst-format-inlinetask-function
				 todo todo-type priority title tags contents)
      ;; Otherwise, use a default template.
       (let ((full-title
			  (concat
			   (when todo (format "%s" todo))
			   (when priority (format "\#%c " priority))
			   title
			   (when tags (format ":%s:"
								  (mapconcat 'identity tags ":"))))))
		 (format (concat "%s\n\n"
						 "%s\n")
				 full-title contents)))))


;;;; Inner template

(defun org-rst-inner-template (contents info)
  "Return complete document string after reStructuredText conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (org-element-normalize-string
   (concat
	;; 1. Document's body.
	contents
	;; 2. Footnote definitions.
	(let ((definitions (org-export-collect-footnote-definitions info)))
	  (when definitions
		(concat
		 "\n\n"
		 (mapconcat
		  (lambda (ref)
			(let* ((id (format ".. [%s] " (car ref)))
                   (def (nth 2 ref))
                   (lines (split-string (org-export-data def info) "\n+[ \t\n]*"))
                   (fntext (concat (car lines) "\n"
                                   (apply 'concat (mapcar
                                                   '(lambda (x) (if (> (length x) 0)
                                                                    (concat (org-rst--indent-string x org-rst-quote-margin) "\n")))
                                                 (cdr lines)))))
                   )
               (concat id fntext)))
		  definitions "\n")))))))


;;;; Italic

(defun org-rst-italic (_italic contents info)
  "Transcode ITALIC from Org to reStructuredText.
CONTENTS is the text with italic markup.  INFO is a plist holding
contextual information."
  (org-rst--text-markup contents 'italic info))


;;;; Item

(defun org-rst-item (item contents info)
  "Transcode ITEM element into reStructuredText format.
CONTENTS is the item contents.  INFO is a plist used as
a communication channel."
  (let* ((checkbox (org-rst--checkbox item info))
		 (list-type (org-element-property :type (org-export-get-parent item)))
		 (tag (let
				  ((tag (org-element-property :tag item)))
				(and tag (concat (org-export-data tag info) checkbox))))
		 (bullet
		  ;; First parent of ITEM is always the plain-list.  Get
		  ;; `:type' property from it.
		  (org-list-bullet-string
		   (cond
			((eq list-type 'ordered)
			 ;; Return correct number for ITEM, paying attention to
			 ;; counters.
			 (let* ((struct (org-element-property :structure item))
					(bul (org-element-property :bullet item))
					(num (number-to-string
						  (car (last (org-list-get-item-number
									  (org-element-property :begin item)
									  struct
									  (org-list-prevs-alist struct)
									  (org-list-parents-alist struct)))))))
			   (replace-regexp-in-string "[0-9]+" num bul)))
			(tag "")
			(t "-"))))
		 (width (if tag 4 (string-width bullet)))
		 )
    (concat
     (if tag tag (concat bullet checkbox))
     (let ((contents (org-rst--indent-string contents width)))
       (if (and (not tag)
				(eq (org-element-type (car (org-element-contents item))) 'paragraph))
		   (org-trim contents)
		 (concat "\n" contents))))))


;;;; Keyword

(defun org-rst-keyword (keyword _contents _info)
  "Transcode a KEYWORD element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((key (org-element-property :key keyword))
	(value (org-element-property :value keyword)))
    (cond
     ((string= key "RST") value))))


;;;; Latex Environment

(defun org-rst-latex-environment (latex-environment _contents info)
  "Transcode a LATEX-ENVIRONMENT element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (when (plist-get info :with-latex)
    (org-remove-indentation (org-element-property :value latex-environment))))


;;;; Latex Fragment

(defun org-rst-latex-fragment (latex-fragment _contents _info)
  "Transcode a LATEX-FRAGMENT object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((value (org-element-property :value latex-fragment)))
    (cond
     ((string-match "\\`\\(\\$\\{2\\}\\)\\([^\000]*\\)\\1\\'" value)
      (format ".. math::\n\n%s"
              (org-rst--indent-string
               (org-trim (match-string 2 value)) org-rst-quote-margin)))
     ((string-match "\\`\\(\\$\\{1\\}\\)\\([^\000]*\\)\\1\\'" value)
      (format ":math:`%s`" (org-trim (match-string 2 value))))
     ((string-match "\\`\\\\(\\([^\000]*\\)\\\\)\\'" value)
      (format ":math:`%s`" (org-trim (match-string 1 value))))
     ((string-match "\\`\\\\\\[\\([^\000]*\\)\\\\\\]\\'" value)
      (format "\.. math::\n\n%s"
              (org-rst--indent-string
               (org-trim (match-string 1 value)) org-rst-quote-margin)))
     (t value))))


;;;; Line Break

(defun org-rst-line-break (_line-break _contents _info)
  "Transcode a LINE-BREAK object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
  information."
  hard-newline)


;;;; Link

(defun org-rst-inline-image-p (link info)
  "Non-nil when LINK is meant to appear as an image.
INFO is a plist used as a communication channel.  LINK is an
inline image when it has no description and targets an image
file (see `org-rst-inline-image-rules' for more information), or
if its description is a single link targeting an image file."
  (if (not (org-element-contents link))
      (org-export-inline-image-p
       link (plist-get info :rst-inline-image-rules))
    (not
     (let ((link-count 0))
       (org-element-map (org-element-contents link)
		   (cons 'plain-text org-element-all-objects)
		 (lambda (obj)
		   (cl-case (org-element-type obj)
			 (plain-text (org-string-nw-p obj))
			 (link (if (= link-count 1) t
					 (cl-incf link-count)
					 (not (org-export-inline-image-p
						   obj (plist-get info :rst-inline-image-rules)))))
			 (otherwise t)))
         info t)))))


(defun my-org-export-inline-image-p (link &optional rules)
  (let ((case-fold-search t)
        (rules (or rules org-export-default-inline-image-rule)))
    (catch 'exit
      (mapc
       (lambda (rule)
         (if (string-match (cdr rule) link)
              (throw 'exit t)))
       rules)
      ;; Return nil if no rule matched.
      nil)))


(defun org-rst-link (link desc info)
  "Transcode a LINK object from Org to reStructuredText.

DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information."
  (let* ((home (when (plist-get info :rst-link-home)
				 (org-trim (plist-get info :rst-link-home))))
		 (use-abs-url (plist-get info :rst-link-use-abs-url))
		 (link-org-files-as-rst-maybe
		  (function
		   (lambda (raw-path info)
			 "Treat links to `file.org' as links to `file.rst', if needed.
           See `org-rst-link-org-files-as-rst'."
			 (cond
			  ((and (plist-get info :rst-link-org-files-as-rst)
					(string= ".org"
							 (downcase (file-name-extension raw-path "."))))
			   (concat (file-name-sans-extension raw-path) "."
					   (plist-get info :rst-extension)))
			  (t raw-path)))))
		 (type (org-element-property :type link))
		 (search-option (org-element-property :search-option link))
		 (raw-path (org-element-property :path link))
		 ;; Ensure DESC really exists, or set it to nil.
		 (desc (and (not (string= desc "")) desc))
		 (path (cond
				((member type '("http" "https" "ftp" "mailto"))
				 (url-encode-url
				   (concat type ":" raw-path)))
				((string= type "file")
				 ;; Treat links to ".org" files as ".rst", if needed.
				 (setq raw-path
					   (funcall link-org-files-as-rst-maybe raw-path info))
				 (cond ((and home use-abs-url)
						(setq raw-path
							  (concat (file-name-as-directory home) raw-path)))
                       (t raw-path)))
				(t raw-path)))
		 (attributes-plist
		  (org-combine-plists
		   ;; Extract attributes from parent's paragraph.  HACK: Only
		   ;; do this for the first link in parent (inner image link
		   ;; for inline images).  This is needed as long as
		   ;; attributes cannot be set on a per link basis.
		   (let* ((parent (org-export-get-parent-element link))
				  (link (let ((container (org-export-get-parent link)))
						  (if (and (eq 'link (org-element-type container))
								   (org-rst-inline-image-p link info))
							  container
							link))))
			 (and (eq link (org-element-map parent 'link #'identity info t))
				  (org-export-read-attribute :attr_rst parent)))
		   ;; Also add attributes from link itself.	 Currently, those
		   ;; need to be added programmatically before `org-rst-link'
		   ;; is invoked, for example, by backends building upon HTML
		   ;; export.
		   (org-export-read-attribute :attr_rst link)))
		 (attributes
		  (let ((attr (org-rst--make-attribute-string attributes-plist)))
			(if (org-string-nw-p attr) (concat "\n" attr "\n") ""))))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link desc 'rst))
     ;; Image file.
     ((and (plist-get info :rst-inline-images)
           (org-export-inline-image-p
            link (plist-get info :rst-inline-image-rules)))
	  (let* ((ipath (if (not (file-name-absolute-p raw-path)) raw-path
					 (expand-file-name raw-path)))
             (caption (org-export-get-caption
					  (org-export-get-parent-element link)))
             (linkname
              (org-element-property :name (org-export-get-parent-element link)))
             (label (if linkname (format ".. _%s:\n\n" linkname) "")))
		(if caption (format "%s.. figure:: %s%s\n\n    %s\n"
                            label ipath attributes
							(org-export-data caption info))
		  (format "%s.. image:: %s%s\n" label ipath attributes))))
     ((and (plist-get info :rst-inline-images)
           desc
           (my-org-export-inline-image-p
            desc (plist-get info :rst-inline-image-rules)))
      (format ".. image:: %s\n    :target: %s%s" desc path attributes))
     ;; Radio link: Transcode target's contents and use them as link's
     ;; description.
     ((string= type "radio")
      (let ((destination (org-export-resolve-radio-link link info)))
		(when destination
			(format "`%s <%s>`_"
					path
					(org-export-data (org-element-contents destination) info)))))
     ;; Links pointing to a headline: Find destination and build
     ;; appropriate referencing command.
     ((member type '("custom-id" "fuzzy" "id"))
      (let ((destination (if (string= type "fuzzy")
							 (org-export-resolve-fuzzy-link link info)
						   (org-export-resolve-id-link link info))))
		(cl-case (org-element-type destination)
		  ;; Id link points to an external file.
		  (plain-text
		   (if desc (format "`%s <%s>`_" desc destination)
			 (format "`%s`_" destination)))
		  ;; Fuzzy link points nowhere.
		  ('nil
		   (let ((rawlink
				  (org-export-data (org-element-property :raw-link link) info)))
			 (if desc (format "`%s <%s>`_" desc rawlink)
			   (format "`%s`_" rawlink))))
		  ;; LINK points to a headline.
		  (headline
             (if (member type '("custom-id" "id"))
                 (if (plist-get info :rst-link-use-ref-role)
                     (if desc (format " :ref:`%s <%s>`" desc raw-path)
                       (format " :ref:`%s`" raw-path))
                   (format "`%s`_" raw-path))
               (format "`%s`_" (org-rst--build-title destination info nil))))
          ;; Fuzzy link points to a target.
		  (otherwise
           (if (not desc) (format "`%s`_" path)
             (format "`%s <%s>`_" desc path))))))
     ;; Coderef: replace link with the reference name or the
     ;; equivalent line number. It is not supported in ReST.
     ((string= type "coderef")
      (format (org-export-get-coderef-format path desc)
			  (org-export-resolve-coderef path info)))
     ((and (plist-get info :rst-file-link-use-ref-role)
           (string= type "file")
           search-option)
      (let ((ref (replace-regexp-in-string "^#" "" search-option)))
        (if desc
            (format ":ref:`%s <%s>`" desc ref)
          (format ":ref:`%s`" ref))))
     ;; Link type is handled by a special function.
     ;((functionp (setq protocol (nth 2 (assoc type org-link-protocols))))
     ; (funcall protocol (org-link-unescape path) desc 'latex))
     ;; External link with a description part.
     ((and path desc) (format "`%s <%s>`_" desc path))
     ;; External link without a description part.
     (path (format "`%s <%s>`_"
                   (replace-regexp-in-string "^//" "" path) path))
     ;; No path, only description.  Try to do something useful.
     (t (format "`%s <%s>`_" desc desc)))))


;;;; Node Property

(defun org-rst-node-property (node-property _contents _info)
  "Transcode a NODE-PROPERTY element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format "%s:%s"
          (org-element-property :key node-property)
          (let ((value (org-element-property :value node-property)))
            (if value (concat " " value) ""))))


;;;; Paragraph

(defun org-rst-paragraph (_paragraph contents info)
  "Transcode a PARAGRAPH element from Org to reStructuredText.
CONTENTS is the contents of the paragraph, as a string.  INFO is
the plist used as a communication channel."
  (when (plist-get info :preserve-breaks)
    (let ((lines (split-string contents "\n+[ \t\n]*")))
      (cond ((> (length lines) 2)
             (setq contents (apply 'concat (mapcar
                                            '(lambda (x) (if (> (length x) 0) (concat "| " x "\n") x))
                                            lines)))))))
  contents)


;;;; Plain List

(defun org-rst-plain-list (_plain-list contents _info)
  "Transcode a PLAIN-LIST element from Org to reStructuredText.
CONTENTS is the contents of the list.  INFO is a plist holding
contextual information."
  contents)


;;;; Plain Text

(defun org-rst-plain-text (text info)
  "Transcode a TEXT string from Org to reStructuredText.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  (when (plist-get info :with-smart-quotes)
    (setq text (org-export-activate-smart-quotes text :utf-8 info)))
  ;; Protect `, *, _ and \
  (setq text (replace-regexp-in-string "[`*_\\]" "\\\\\\&" text))
  ;; Protect ..
  (setq text (replace-regexp-in-string "^[\s-]*\\.\\. [^\\[]" "\\\\\\&" text))
  ;; Protect ::
  (setq text (replace-regexp-in-string "::" "\\\\:\\\\:" text))
  ;; Return value.
  text)


;;;; Planning

(defun org-rst-planning (planning _contents _info)
  "Transcode a PLANNING element from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (mapconcat
   'identity
   (delq nil
	 (list (let ((closed (org-element-property :closed planning)))
		 (when closed
		   (concat org-closed-string " "
			   (org-translate-time
			    (org-element-property :raw-value closed)))))
	       (let ((deadline (org-element-property :deadline planning)))
		 (when deadline
		   (concat org-deadline-string " "
			   (org-translate-time
			    (org-element-property :raw-value deadline)))))
	       (let ((scheduled (org-element-property :scheduled planning)))
		 (when scheduled
		   (concat org-scheduled-string " "
			   (org-translate-time
			    (org-element-property :raw-value scheduled)))))))
   " "))


;;;; Property Drawer

(defun org-rst-property-drawer (_property-drawer contents _info)
  "Transcode a PROPERTY-DRAWER element from Org to reStructuredText.
CONTENTS holds the contents of the drawer.  INFO is a plist
holding contextual information."
  (when (org-string-nw-p contents)
	(concat
	 "::\n\n"
	 (org-rst--indent-string contents org-rst-quote-margin))))


;;;; Pseudo Object: LaTeX Math Block

;; `latex-math-block' objects have the following property:
;; `:post-blank'.

(defun org-rst--wrap-latex-math-block (data info)
  "Merge contiguous math objects in a pseudo-object container.
DATA is a parse tree or a secondary string.  INFO is a plist
containing export options.  Modify DATA by side-effect and return it."
  (let ((valid-object-p
         (function
          ;; Non-nil when OBJ can be added to the latex math block.
          (lambda (obj)
            (cl-case (org-element-type obj)
              (entity (org-element-property :latex-math-p obj))
              (latex-fragment
               (let ((value (org-element-property :value obj)))
                 (or (string-match-p "\\`\\\\([^\000]*\\\\)\\'" value)
                     (string-match-p "\\`\\$[^\000]*\\$\\'" value)
                     (string-match-p "\\`\\\\\\[[^\000]*\\\\\\]\\'" value))))
              ((subscript superscript) t))))))
    (org-element-map data '(entity latex-fragment subscript superscript)
      (lambda (object)
        ;; Skip objects already wrapped.
        (when (and (not (eq (org-element-type
                             (org-element-property :parent object))
                            'latex-math-block))
                   (funcall valid-object-p object))
          (let ((math-block (list 'latex-math-block nil))
                (next-elements (org-export-get-next-element object info t))
                (last object))
            ;; Wrap MATH-BLOCK around OBJECT in DATA.
            (org-element-insert-before math-block object)
            (org-element-extract-element object)
            (org-element-adopt-elements math-block object)
            (when (zerop (or (org-element-property :post-blank object) 0))
              ;; MATH-BLOCK swallows consecutive math objects.
              (catch 'exit
                (dolist (next next-elements)
                  (if (not (funcall valid-object-p next)) (throw 'exit nil)
                    (org-element-extract-element next)
                    (org-element-adopt-elements math-block next)
                    ;; Eschew the case: \beta$x$ -> \(\betax\).
                    (unless (memq (org-element-type next)
                                  '(subscript superscript))
                      (org-element-put-property last :post-blank 1))
                    (setq last next)
                    (when (> (or (org-element-property :post-blank next) 0) 0)
                      (throw 'exit nil))))))
            (org-element-put-property
             math-block :post-blank (org-element-property :post-blank last)))))
      info nil '(subscript superscript latex-math-block) t)
    ;; Return updated DATA.
    data))

(defun org-rst-math-block-tree-filter (tree _backend info)
  (org-rst--wrap-latex-math-block tree info))

(defun org-rst-math-block-options-filter (info _backend)
  (dolist (prop '(:author :date :title) info)
    (plist-put info prop
	       (org-rst--wrap-latex-math-block (plist-get info prop) info))))

(defun org-rst-math-block (_math-block contents _info)
  "Transcode a MATH-BLOCK object from Org to reStructuredText.
CONTENTS is a string.  INFO is a plist used as a communication
channel."
  (let* ((value (org-trim contents))
         (value
          (if (> (string-width value) 2)
              (if (string= ".." (substring value 0 2))
                  (format "\n\n%s\n\n" value)
                value))))
    (format "%s" value)))


;;;; Quote Block

(defun org-rst-quote-block (quote-block contents _info)
  "Transcode a QUOTE-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((attributes
		  (org-export-read-attribute :attr_rst quote-block))
		 (directive (plist-get attributes :directive))
		 (title (plist-get attributes :title))
		 (subtitle (plist-get attributes :subtitle))
		 (margin (plist-get attributes :margin))
		 (class (plist-get attributes :class))
		 (label (org-element-property :name quote-block)))
	(cond ((and margin contents)
		   (org-rst--indent-string contents (string-to-number margin)))
		  (directive
		   (concat
			(format ".. %s::" directive)
			(when title (format " %s" title))
			"\n"
			(when (and subtitle (string= "sidebar" directive))
			  (format "    :subtitle: %s\n" subtitle))
			(when (and class (not (string= "container" directive)))
			  (format "    :class: %s\n" class))
			(when label (format "    :name: %s\n" label))
			"\n"
			(when contents
			  (org-rst--indent-string contents org-rst-quote-margin))))
		  (t
		   (concat
			"::\n"
			(when class (format "    :class: %s\n" class))
			(when label (format "    :name: %s\n" label))
			"\n"
			(when contents
			  (org-rst--indent-string contents org-rst-quote-margin)))))))


;;;; Radio Target

(defun org-rst-radio-target (_radio-target contents _info)
  "Transcode a RADIO-TARGET object from Org to reStructuredText.
CONTENTS is the contents of the target.  INFO is a plist holding
contextual information."
  contents)


;;;; Section

(defun org-rst-section (_section contents _info)
  "Transcode a SECTION element from Org to reStructuredText.
CONTENTS holds the contents of the section.  INFO is a plist
holding contextual information."
  contents)


;;;; Special Block

(defun org-rst-special-block (special-block contents _info)
  "Transcode a SPECIAL-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((attributes
          (org-export-read-attribute :attr_rst special-block))
		 (title (plist-get attributes :title))
         (class (plist-get attributes :class))
		 (label (org-element-property :name special-block))
         (type (org-element-property :type special-block)))
    (concat
     (format ".. %s::" type)
     (when title (format " %s" title))
     "\n"
     (when class (format "    :class: %s\n" class))
     (when label (format "    :name: %s\n" label))
     "\n"
     (when contents
       (org-rst--indent-string contents org-rst-quote-margin)))))

;;;; Src Block

(defun org-rst-src-block (src-block _contents info)
  "Transcode a SRC-BLOCK element from Org to reStructuredText.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (when (org-string-nw-p (org-element-property :value src-block))
    (let* ((lang (org-element-property :language src-block))
		   (label (org-element-property :name src-block))
		   (value (org-remove-indentation
				   (org-element-property :value src-block)))
           (num-start (org-export-get-loc src-block info))
           (codeblockd (plist-get info :rst-code-block))
		   (attributes
			(org-export-read-attribute :attr_rst src-block))
		   (class (plist-get attributes :class)))
      (cond
       ;; Case 1.
       ((eq codeblockd 'code-block)
		(let ((lst-lang
			   (or (cadr (assq (intern lang) org-rst-pygments-langs)) lang)))
		  (concat
		   (format ".. code-block:: %s\n" lst-lang)
		   (when num-start (format "    :lineno-start: %s\n" (1+ num-start)))
		   (when class (format "    :class: %s\n" class))
		   (when label (format "    :name: %s\n" label))
		   "\n"
		   (org-rst--indent-string value org-rst-quote-margin))))
	   ;; Case 2. code.
	   ((eq codeblockd 'code)
		(let ((lst-lang
			   (or (cadr (assq (intern lang) org-rst-pygments-langs)) lang)))
		  (concat
		   (format ".. code:: %s\n" lst-lang)
		   (when num-start (format "    :number-lines: %s\n" (1+ num-start)))
		   (when class (format "    :class: %s\n" class))
		   (when label (format "    :name: %s\n" label))
		   "\n"
		   (org-rst--indent-string value org-rst-quote-margin))))
       (t
        (concat
         "::\n"
         (when class (format "    :class: %s\n" class))
         (when label (format "    :name: %s\n" label))
         "\n"
         (org-rst--indent-string value org-rst-quote-margin)))))))


;;;; Statistics Cookie

(defun org-rst-statistics-cookie (statistics-cookie _contents _info)
  "Transcode a STATISTICS-COOKIE object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (org-element-property :value statistics-cookie))


;;;; Strike-Through

(defun org-rst-strike-through (_strike-through contents _info)
  "Transcode STRIKE-THROUGH from Org to reStructuredText.
CONTENTS is the text with strike-through markup.  INFO is a plist
holding contextual information."
  contents)


;;;; Subscript

(defun org-rst-subscript (_subscript contents _info)
  "Transcode a SUBSCRIPT object from Org to reStructuredText.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (format "\\ :sub:`%s`\\ " contents))


;;;; Superscript

(defun org-rst-superscript (_superscript contents _info)
  "Transcode a SUPERSCRIPT object from Org to reStructuredText.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (format "\\ :sup:`%s`\\ " contents))


;;;; Table

(defun org-rst-table-first-row-data-cells (table info)
  "Transcode the first row of TABLE.
INFO is a plist used as a communication channel."
  (let ((table-row
         (org-element-map table 'table-row
           (lambda (row)
             (unless (eq (org-element-property :type row) 'rule) row))
           info 'first-match))
        (special-column-p (org-export-table-has-special-column-p table)))
    (if (not special-column-p) (org-element-contents table-row)
      (cdr (org-element-contents table-row)))))

(defun org-rst-table (table contents info)
  "Transcode a TABLE element from Org to reStructuredText.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (let* ((caption (org-export-get-caption table))
		 (attributes
		  (org-export-read-attribute :attr_rst table))
		 (class (plist-get attributes :class))
		 (label (org-element-property :name table)))
    (concat
     (if caption (format ".. table:: %s\n" (org-export-data caption info))
	   ".. table::\n")
	 (when class (format "    :class: %s\n" class))
	 (when label (format "    :name: %s\n" label))
	 "\n"
	 (org-rst--indent-string contents org-rst-quote-margin))))


;;;; Table Cell

(defun org-rst--table-cell-width (table-cell info)
  "Return width of TABLE-CELL.

INFO is a plist used as a communication channel.

Width of a cell is determined either by a width cookie in the
same column as the cell, or by the maximum cell's length in that
column."
  (let* ((row (org-export-get-parent table-cell))
	 (table (org-export-get-parent row))
	 (col (let ((cells (org-element-contents row)))
		(- (length cells) (length (memq table-cell cells)))))
	 (cache
	  (or (plist-get info :rst-table-cell-width-cache)
	      (plist-get (setq info
			       (plist-put info :rst-table-cell-width-cache
					  (make-hash-table :test 'equal)))
			 :rst-table-cell-width-cache)))
	 (key (cons table col)))
    (or (gethash key cache)
	(puthash
	 key
	 (let ((cookie-width (org-export-table-cell-width table-cell info)))
	   (or cookie-width
	       (let ((contents-width
		      (let ((max-width 0))
			(org-element-map table 'table-row
			  (lambda (row)
			    (setq max-width
				  (max (string-width
					(org-export-data
					 (org-element-contents
					  (elt (org-element-contents row) col))
					 info))
				       max-width)))
			  info)
			max-width)))
		 (cond ((not cookie-width) contents-width)
		       (t cookie-width)))))
	 cache))))


(defun org-rst-table-cell (table-cell contents info)
  "Transcode a TABLE-CELL object from Org to reStructuredText.
CONTENTS is the cell contents.  INFO is a plist used as
a communication channel."
  (let ((width (org-rst--table-cell-width table-cell info)))
    ;; Align contents correctly within the cell.
    (let* ((indent-tabs-mode nil)
	   (data
	    (if contents
	      (org-rst--justify-lines
	       contents width
	       (org-export-table-cell-alignment table-cell info)) "\\")))
      (setq contents (concat data
                             (make-string (- width (string-width data)) ? ))))
    ;; Return cell.
    (concat (format " %s " contents)
			(when (org-export-get-next-element table-cell info) "|"))))


;;;; Table Row

(defun org-rst-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to reStructuredText.
CONTENTS is the row contents.  INFO is a plist used as
a communication channel."
  (let ((borders (org-export-table-cell-borders
                  (org-element-map table-row 'table-cell 'identity info t)
                  info)))
    (if (not (and (memq 'bottom borders) (memq 'top borders)))
        (let* ((rowgroup-number (org-export-table-row-group table-row info))
               (row-number (org-export-table-row-number table-row info))
               (line-bit
                (cond
                 ((not (= 1 rowgroup-number))
                  ?-)
                 ((org-export-table-has-header-p
                   (org-export-get-parent-table table-row) info)
                  ?=)
                 (t ?-)))
               (makeline
                (function
                 (lambda (_rowcontents linebit)
                   (format "+%s+"
                           (mapconcat
                            'identity
                            (mapcar
                             (lambda (table-cell)
                               (make-string (string-width table-cell)
                                            linebit))
                             (split-string contents "|"))
                               "+")))))
               (hline (format "+%s+"
                              (mapconcat
                               'identity
                               (mapcar
                                (lambda (table-cell)
                                  (make-string (string-width table-cell)
                                               line-bit))
                                (split-string contents "|"))
                               "+"))))
          (concat
           (when (= 0 row-number)
             (concat (funcall makeline contents ?-) "\n"))
           "|" contents "|\n" hline))
      nil
      )))


;;;; Target

(defun org-rst-target (target _contents _info)
  "Transcode a TARGET object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format " _`%s` " (org-element-property :value target)))


;;;; Timestamp

(defun org-rst-timestamp (timestamp _contents info)
  "Transcode a TIMESTAMP object from Org to reStructuredText.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (org-rst-plain-text (org-timestamp-translate timestamp) info))


;;;; Underline

(defun org-rst-underline (_underline contents _info)
  "Transcode UNDERLINE from Org to reStructuredText.
CONTENTS is the text with underline markup.  INFO is a plist
holding contextual information."
  contents)


;;;; Verbatim

(defun org-rst-verbatim (verbatim _contents info)
  "Transcode a VERBATIM object from Org to reStructredText.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (org-rst--text-markup (org-element-property :value verbatim) 'verbatim info))


;;;; Verse Block

(defun org-rst-verse-block (_verse-block contents _info)
  "Transcode a VERSE-BLOCK element from Org to reStructuredText.
CONTENTS is verse block contents.  INFO is a plist holding
contextual information."
  (let ((lines (split-string contents "\n")))
    (cond ((> (length lines) 0)
           (mapconcat
            (function (lambda (x) (if (> (string-width x) 0)
                                      (concat "| " x "\n") ""))) lines "")))))


;;; Filters

(defun org-rst-separate-elements (tree _backend _info)
  "Make sure elements are separated by at least one blank line.

TREE is the parse tree being exported.  BACKEND is the export
back-end used.  INFO is a plist used as a communication channel.

Assume BACKEND is `rst'."
  (org-element-map tree org-element-all-elements
    (lambda (elem)
      (unless (or (eq (org-element-type elem) 'org-data)
				  (eq (org-element-type elem) 'table-row))
		(org-element-put-property
		 elem :post-blank
		 (let ((post-blank (org-element-property :post-blank elem)))
		   (if (not post-blank) 1 (max 1 post-blank)))))))
  ;; Return updated tree.
  tree)

(defun org-rst-filter-headline-blank-lines (headline _back-end _info)
  "Filter controlling number of blank lines after a headline.

HEADLINE is a string representing a transcoded headline.
BACK-END is symbol specifying back-end used for export.  INFO is
plist containing the communication channel.

This function only applies to `rst' back-end.  See
`org-rst-headline-spacing' for information."
  (if (not org-rst-headline-spacing) headline
    (let ((blanks (make-string (1+ (cdr org-rst-headline-spacing)) ?\n)))
      (replace-regexp-in-string "\n\\(?:\n[ \t]*\\)*\\'" blanks headline))))

(defun org-rst-filter-paragraph-spacing (tree _back-end info)
  "Filter controlling number of blank lines between paragraphs.

TREE is the parse tree.  BACK-END is the symbol specifying
back-end used for export.  INFO is a plist used as
a communication channel.

See `org-rst-paragraph-spacing' for information."
  (when (wholenump org-rst-paragraph-spacing)
    (org-element-map tree 'paragraph
      (lambda (p)
		(when (eq (org-element-type (org-export-get-next-element p info))
				  'paragraph)
		  (org-element-put-property
		   p :post-blank org-rst-paragraph-spacing)))))
  tree)



;;; End-user functions

;;;###autoload
(defun org-rst-export-as-rst
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a reStructuredText buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named \"*Org RST Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'rst "*Org RST Export*"
    async subtreep visible-only body-only ext-plist (lambda () (rst-mode))))

;;;###autoload
(defun org-rst-convert-region-to-rst ()
  "Assume the current region has Org syntax, and convert it to
reStructuredText.
This can be used in any buffer.  For example, you can write an
itemized list in Org syntax in a Markdown buffer and use this command
to convert it."
  (interactive)
  (org-export-replace-region-by 'rst))


;;;###autoload
(defun org-rst-export-to-rst
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a reStructuredText file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (let* ((extension (concat "." (or (plist-get ext-plist :rst-extension)
                                    org-rst-extension
                                    "rst")))
         (file (org-export-output-file-name extension subtreep)))
    (org-export-to-file 'rst file
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun org-rst-publish-to-rst (plist filename pub-dir)
  "Publish an org file to reStructuredText.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'rst filename ".rst" plist pub-dir))


;;; provide

(provide 'ox-rst)

;;; ox-rst.el ends here
