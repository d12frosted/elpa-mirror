;;; ox-trac.el --- Org Export Backend to Trac WikiFormat

;; Copyright (C) 2015  Brian J. Carlson

;; URL: https://github.com/JalapenoGremlin/ox-trac
;; Package-Version: 20171026.1823
;; Package-Commit: 5ac6c81bbc18db6c17e267d6399778c3fb5bf1ee
;; Author: Brian J. Carlson <hacker (at) abutilize (dot) com>
;; Package-Requires: ((org "9.0"))
;; Keywords: org-mode trac

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements a Trac WikiFormat back-end for
;; Org exporter, derived from `ascii' back-end.
;; See Org manual for more information.

;;; Code:

;;; TODO List
;; * org-trac-link is little more than a rudimentary (slightly
;;   modified) version link org-md-link by only changing order of description and
;;   path

(eval-when-compile (require 'cl))
(require 'ox-ascii)
(require 'ox-publish)
(require 'rx)


;;; User-Configurable Variables

(defgroup org-export-trac nil
  "Options specific to Trac export back-end."
  :tag "Org Trac WikiFormat"
  :group 'org-export
  :version "24.4"
  :package-version '(Org . "8.0"))

(defcustom org-trac-wiki-max-heading-level 6
  "Maximum Heading level of Trac WikiFormat."
  :group 'org-export-trac
  :type 'integer
  :safe 'integerp)

;; TODO: Right now only bullet is allowed
(defcustom org-trac-wiki-extra-heading-format 'bullet
  "Style used to format high level heading level(s).

This setting is valid when the heading  level is
* greater than `org-trac-wiki-max-heading-level' or
* greater than the `org-export-headline-levels'"
  :group  'org-export-trac
  :type '(choice
          (const :tag "Use bullets" bullet)
          ;;          (const :tag "Use raw equal" raw)
          ))

(defcustom org-trac-lang-alist '(("emacs-lisp" . "elisp") )
  "Alist of languages that are not recognized by Trac, to languages that are.
Emacs Lisp is a good example of this, where Trac needs 'elisp' ('cl' works well, too) as a nice replacement."
  :group 'org-export-trac)

(defcustom org-trac-footnote-separator "^, ^"
  "Text used to separate footnotes."
  :group 'org-export-trac
  :type 'string)

(defcustom org-trac-footnote-level 1
  "Heading level of Footnote block."
  :group 'org-export-trac
  :type 'integer
  :safe 'integerp)

;;; Define Back-End
(org-export-define-derived-backend
    'trac 'ascii
  :filters-alist '((:filter-parse-tree . org-trac-separate-elements))
  :menu-entry
  '(?T "Export to Trac Wiki Formatting"
       ((?T "To temporary buffer"
            (lambda (a s v b) (org-trac-export-as-tracwiki a s v)))
        (?t "To file" (lambda (a s v b) (org-trac-export-to-tracwiki a s v)))
        (?o "To file and open"
            (lambda (a s v b)
              (if a (org-trac-export-to-tracwiki t s v)
                (org-open-file (org-trac-export-to-tracwiki nil s v)))))))
  :translate-alist
  '((bold . org-trac-bold)
    ;; center-block
    ;; clock
    (code . org-trac-verbatim)
    ;; drawer
    ;; dynamic-block
    (entity . org-trac-entity)
    (example-block . org-trac-example-block)
    (export-block . org-trac-export-block)
    ;; (export-snippet . org-trac-export-snippet)
    (fixed-width . org-trac-example-block)
    (footnote-definition . org-trac-footnote-definition)
    (footnote-reference . org-trac-footnote-reference)
    (headline . org-trac-headline)
    (horizontal-rule . org-trac-horizontal-rule)
    (inline-src-block . org-trac-verbatim)
    ;; (inlinetask . org-trac-inlinetask)
    (inner-template . org-trac-inner-template)
    (italic . org-trac-italic)
    (item . org-trac-item)
    (keyword . org-trac-keyword)
    (latex-environment . org-trac-latex-environment)
    (latex-fragment . org-trac-latex-fragment)
    (line-break . org-trac-line-break)
    (link . org-trac-link)
    (node-property . org-trac-node-property)
    (paragraph . org-trac-paragraph)
    (plain-list . org-trac-plain-list)
    (plain-text . org-trac-plain-text)
    (property-drawer . org-trac-property-drawer)
    (quote-block . org-trac-quote-block)
    ;; (radio-target . org-trac-radio-target)
    (section . org-trac-section)
    ;; (special-block . org-trac-special-block)
    (src-block . org-trac-src-block)
    ;; (statistics-cookie . org-trac-statistics-cookie)
    (strike-through . org-trac-strike-through)
    (subscript . org-trac-subscript)
    (superscript . org-trac-superscript)
    (table . org-trac-table)
    (table-cell . org-trac-table-cell)
    (table-row . org-trac-table-row)
    ;; (target . org-trac-target)
    (template . org-trac-template)
    ;; (timestamp . org-trac-timestamp)
    (underline . org-trac-underline)
    (verbatim . org-trac-verbatim)
    (verse-block . org-trac-verse-block)
    )
  :options-alist
  '((:trac-footnote-separator nil nil org-trac-footnote-separator)
    (:trac-footnote-level nil nil org-trac-footnote-level)))


;;; Filters

(defun org-trac-separate-elements (tree backend info)
  "Fix blank lines between elements.

TREE is the parse tree being exported.  BACKEND is the export
back-end used.  INFO is a plist used as a communication channel.

Enforce a blank line between elements.  There are two exceptions
to this rule:

  1. Preserve blank lines between sibling items in a plain list,

  2. In an item, remove any blank line before the very first
     paragraph and the next sub-list when the latter ends the
     current item.

Assume BACKEND is `trac'."
  (org-element-map tree (remq 'item org-element-all-elements)
    (lambda (e)
      (org-element-put-property
       e :post-blank
       (if (or (and (eq (org-element-type e) 'paragraph)
                    (eq (org-element-type (org-element-property :parent e)) 'item)
                    (org-export-first-sibling-p e info)
                    (let ((next (org-export-get-next-element e info)))
                      (and (eq (org-element-type next) 'plain-list)
                           (not (org-export-get-next-element next info)))))
               (eq (org-element-type e) 'table-row)
               )
	   0
	 1))))
  ;; Return updated tree.
  tree)



;;; Transcode Functions

;;;; Bold
(defun org-trac-bold (bold contents info)
  "Transcode BOLD object into Trac WikiFormat format.
CONTENTS is the text within bold markup.  INFO is a plist used as
a communication channel."
  (format "**%s**" contents))

;;;; Center-Block
;;;; Clock
;;;; Code  @see org-trac-verbatim
;;;; Drawer
;;;; Dynamic Block

;;; Entity
(defun org-trac-entity (entity contents info)
  "Transcode an ENTITY object from Org to Trac.
CONTENTS are the definition itself.  INFO is a plist holding
contextual information."
  (concat "\\(" (org-element-property :latex entity) "\\)" ))

;;;; Example Block
(defun org-trac-example-block (example-block contents info)
  "Transcode EXAMPLE-BLOCK element into Trac WikiFormat format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  ;; (concat (replace-regexp-in-string
  ;;          "^" "{{{\n"
  ;;          (org-remove-indentation
  ;;           (org-export-format-code-default example-block info))) "\n}}}")
  (concat  "{{{\n" (org-remove-indentation
                    (org-export-format-code-default example-block info)) "}}}")
  )

;;; Export Block
(defun org-trac-export-block (export-block contents info)
  "Transcode a EXPORT-BLOCK element from Org to Trac WikiFormat.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (if (member (org-element-property :type export-block) '("TRACWIKI" "TRAC"))
      (org-remove-indentation (org-element-property :value export-block))))

;;;; Export Snippet
;;;; Fixed Width  @see org-trac-example-block)

;; TODO
;;;; Footnote Reference.
(defun org-trac-footnote-reference (footnote-reference contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to Trac WikiFormat.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (concat
   ;; Insert separator between two footnotes in a row.
   (let ((prev (org-export-get-previous-element footnote-reference info)))
     (when (eq (org-element-type prev) 'footnote-reference)
       (plist-get info :trac-footnote-separator)))
   (let* ((n (org-export-get-footnote-number footnote-reference info))
	  (id (format "fnr.%d%s"
		      n
		      (if (org-export-footnote-first-reference-p
			   footnote-reference info)
			  ""
			".100"))))
     (format
      "^%s^" ;; TODO fix me (plist-get info :trac-footnote-format)
      (org-trac--anchor
       id n (format "fn.%d" n) info)))))


;;;; Headline
(defun org-trac-headline (headline contents info)
  "Transcode HEADLINE element into Trac WikiFormat format.
CONTENTS is the headline contents.  INFO is a plist used as
a communication channel."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((level (org-export-get-relative-level headline info))
	   (title (org-export-data (org-element-property :title headline) info))
	   (todo (and (plist-get info :with-todo-keywords)
		      (let ((todo (org-element-property :todo-keyword
							headline)))
			(and todo (concat (org-export-data todo info) " ")))))
	   (tags (and (plist-get info :with-tags)
		      (let ((tag-list (org-export-get-tags headline info)))
			(and tag-list
			     (format "     :%s:"
				     (mapconcat 'identity tag-list ":"))))))
	   (priority
	    (and (plist-get info :with-priority)
		 (let ((char (org-element-property :priority headline)))
		   (and char (format "[#%c] " char)))))
	   (anchor
	    (and (or ;; TODO: should this be an option.....
                     ;; just having a toc doesn't necessitate extra tags on the headlines
                     ;; (plist-get info :with-toc)
                     (org-element-property :CUSTOM_ID headline))
		 (format " #%s"
			 (or (org-element-property :CUSTOM_ID headline)
			     (org-export-get-reference headline info)))))
	   ;; Headline text without tags.
	   (heading (concat todo priority title))
           )
      (cond
       ;; Cannot create a headline.  Fall-back to a list.
       ((or (org-export-low-level-p headline info)
	    (> level org-trac-wiki-max-heading-level))
	(let ((bullet
	       (if (not (org-export-numbered-headline-p headline info)) "-"
		 (concat (number-to-string
			  (car (last (org-export-get-headline-number
				      headline info))))
			 "."))))
	  (concat bullet (make-string (- 4 (length bullet)) ?\s) heading tags
		  "\n\n"
		  (and contents
		       (replace-regexp-in-string "^" "    " contents)))))
       (t (concat (make-string level ?=) " " heading tags anchor "\n"
		  contents))))))

;;;; Horizontal Rule
(defun org-trac-horizontal-rule (horizontal-rule contents info)
  "Transcode HORIZONTAL-RULE element into Trac WikiFormat format.
CONTENTS is the horizontal rule contents.  INFO is a plist used
as a communication channel."
  "-----")

;;;; Inline Src-Block @see org-trac-verbatim
;;;; Inline Task

;;;; Inner Template
(defun org-trac-inner-template (contents info)
  "Return body of document string after Trac WikiFormat conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; Table of contents.
   (let ((depth (plist-get info :with-toc)))
     (when depth "[[PageOutline]]\n"))
   ;; Document contents.
   "\n"
   contents
   "\n"
   ;; Footnotes section.
   ;; TODO
   ;;   (org-trac-footnote-section info)
   (org-trac-footnote-section info)
   ))

;;;; Italic
(defun org-trac-italic (italic contents info)
  "Transcode ITALIC object into Trac WikiFormat format.
CONTENTS is the text within italic markup.  INFO is a plist used
as a communication channel."
  (format "//%s//" contents))


;;;; Item
(defun org-trac-item (item contents info)
  "Transcode ITEM element into Trac WikiFormat format.
CONTENTS is the item contents.  INFO is a plist used as
a communication channel."
  (let* ((type (org-element-property :type (org-export-get-parent item)))
	 (struct (org-element-property :structure item))
	 (bullet (if (not (eq type 'ordered)) "*"
		   (concat (number-to-string
			    (car (last (org-list-get-item-number
					(org-element-property :begin item)
					struct
					(org-list-prevs-alist struct)
					(org-list-parents-alist struct)))))
			   ".")))
         (bullet-length (length bullet)))
    ;; TODO This is ugly. 'descriptive was barnacled onto this
    (cond ((eq type 'descriptive)
           (let ((tag (org-element-property :tag item)))
             (concat " " (or (org-export-data tag info) "(no_tag)") ":: "
                     (and contents
                          (org-trim (replace-regexp-in-string "^" (make-string (+ 3 (length tag)) ? ) contents))))))
          (t
           (concat bullet
                   " "
                   (case (org-element-property :checkbox item)
                     (on "[X] ")
                     (trans "[-] ")
                     (off "[ ] "))
                   (let ((tag (org-element-property :tag item)))
                     (and tag (format "**%s:** "(org-export-data tag info))))
                   (and contents
                        (org-trim (replace-regexp-in-string "^" (make-string (1+ bullet-length) ? ) contents))))))))

;;;; Keyword
(defun org-trac-keyword (keyword contents info)
  "Transcode a KEYWORD element into Trac WikiFormat format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (if (member (org-element-property :key keyword) '("TRACWIKI" "TRAC"))
      (org-element-property :value keyword)
    (org-export-with-backend 'trac keyword contents info)))

;;;; LaTeX Environment
(defun org-trac-latex-environment (latex-environment contents info)
  "Transcode a LATEX-ENVIRONMENT element from Org to Trac WikiFormat.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (concat "{{{\n#!Latex\n" (org-element-property :value latex-environment) "\n}}}"))

;;;; LaTeX Fragment
(defun org-trac-latex-fragment (latex-fragment contents info)
  "Transcode a LATEX-FRAGMENT object from Org to LaTeX.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((value (org-element-property :value latex-fragment)))
    (setq value (concat "\\(" (replace-regexp-in-string "\\$\\([^$]+\\)\\$" "\\1"  value)
                        "\\)")
                        )))

;;;; Line Break
(defun org-trac-line-break (line-break contents info)
  "Transcode LINE-BREAK object into Trac WikiFormat format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  ;;(org-element-remove-indentation (format "\\\\(%s %S) \n" contents (org-get-indentation))))
  "\\\\\n")

;;;; Link
(defun org-trac-link (link contents info)
  "Transcode LINK object into Trac WikiFormat format.
CONTENTS is the link's description.  INFO is a plist used as
a communication channel."
  (let ((link-org-files-as-trac
	 (lambda (raw-path)
	   ;; Treat links to `file.org' as links to `file.trac'.
	   (if (string= ".org" (downcase (file-name-extension raw-path ".")))
	       (concat (file-name-sans-extension raw-path) ".trac")
	     raw-path)))
	(type (org-element-property :type link)))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link contents 'trac))
     ((member type '("custom-id" "id" "fuzzy"))
      (let ((destination (if (string= type "fuzzy")
			     (org-export-resolve-fuzzy-link link info)
			   (org-export-resolve-id-link link info))))
	(case (org-element-type destination)
	  (plain-text			; External file.
	   (let ((path (funcall link-org-files-as-trac destination)))
	     (if (not contents) (format "<%s>" path)
	       (format "[[%s|%s]]" path contents))))
	  (headline
	   (format
	    "[[#%s|%s]]"

            ;; Reference.
	    (or (org-element-property :CUSTOM_ID destination)
		(org-export-get-reference destination info))
            ;; Description.
	    (cond ((org-string-nw-p contents))
		  ((org-export-numbered-headline-p destination info)
		   (mapconcat #'number-to-string
			      (org-export-get-headline-number destination info)
			      "."))
		  (t (org-export-data (org-element-property :title destination)
				      info)))


            ))
	  (t
	   (let ((description
		  (or (org-string-nw-p contents)
		      (let ((number (org-export-get-ordinal destination info)))
			(cond
			 ((not number) nil)
			 ((atom number) (number-to-string number))
			 (t (mapconcat #'number-to-string number ".")))))))
	     (when description
	       (format "[[%s|#%s]]"
		       (org-export-get-reference destination info)
                       description)))))))
     ;; TODO: Need to deal with inline images?
     ((string= type "coderef")
      (let ((ref (org-element-property :path link)))
	(format (org-export-get-coderef-format ref contents)
		(org-export-resolve-coderef ref info))))
     ((equal type "radio") contents)
     (t (let* ((raw-path (org-element-property :path link))
	       (path
		(cond
		 ((member type '("http" "https" "ftp"))
		  (concat type ":" raw-path))
		 ((string= type "file")
		  (org-export-file-uri (funcall link-org-files-as-trac raw-path)))
		 (t raw-path))))
	  (if (not contents) (format "<%s>" path)
	    (format "[[%s|%s]]" path contents)))))))

;;;; Node Property
(defun org-trac-node-property (node-property contents info)
  "Transcode a NODE-PROPERTY element into Trac WikiFormat syntax.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format "%s:%s"
          (org-element-property :key node-property)
          (let ((value (org-element-property :value node-property)))
            (if value (concat " " value) ""))))


;;;; Paragraph
(defun org-trac-paragraph (paragraph contents info)
  "Transcode PARAGRAPH element into Trac WikiFormat format.
CONTENTS is the paragraph contents.  INFO is a plist used as
a communication channel."
  (let ((first-object (car (org-element-contents paragraph))))
    ;; If paragraph starts with a #, protect it.
    (if (and (stringp first-object) (string-match "\\`#" first-object))
	(replace-regexp-in-string "\\`#" "\\#" contents nil t)
      contents)))

;;;; Plain List
(defun org-trac-plain-list (plain-list contents info)
  "Transcode PLAIN-LIST element into Trac WikiFormat format.
CONTENTS is the plain-list contents.  INFO is a plist used as
a communication channel."
  contents)


;;;; Plain Text
(defun org-trac-plain-text (text info)
  "Transcode a TEXT string into Trac WikiFormat format.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  (setq text (replace-regexp-in-string "\\^" "!^" text))
  (let ((case-fold-search nil))
    (unless (eq 'link (org-element-type (org-element-property :parent text)))
      (setq text (replace-regexp-in-string   (rx bow (group (and  upper (one-or-more lower) (+  (and upper (one-or-more lower))))) eow)
                                           "!\\1" text))))
  text)

;;;; Property Drawer
(defun org-trac-property-drawer (property-drawer contents info)
  "Transcode a PROPERTY-DRAWER element into Trac WikiFormat format.
CONTENTS holds the contents of the drawer.  INFO is a plist
holding contextual information."
  (and (org-string-nw-p contents)
       (replace-regexp-in-string "^" "    " contents)))


;;;; Quote Block
(defun org-trac-quote-block (quote-block contents info)
  "Transcode QUOTE-BLOCK element into Trac WikiFormat format.
CONTENTS is the quote-block contents.  INFO is a plist used as
a communication channel."
  (replace-regexp-in-string
   "^" "     "
   (replace-regexp-in-string "\n +'" " " contents)))

;;;; Radio Target

;;;; Section
(defun org-trac-section (section contents info)
  "Transcode SECTION element into Trac WikiFormat format.
CONTENTS is the section contents.  INFO is a plist used as
a communication channel."
  contents)

;;;; Special block

;;; Source Block
(defun org-trac-src-block (src-block contents info)
  "Transcode SRC-BLOCK element into Flavored Trac WikiFormat format.
CONTENTS is nil.  INFO is a plist used as a communication channel."
  (let* ((lang (org-element-property :language src-block))
         (lang (or (assoc-default lang org-trac-lang-alist) lang))
         (code (org-export-format-code-default src-block info))
         (prefix (concat "{{{\n#!" lang "\n"))
         (suffix "}}}"))
    (concat prefix code suffix)))

;;;; Statistics Cookie

;;;; Strike-through
(defun org-trac-strike-through (strikethrough contents info)
  "Transcode STRIKETHROUGH object into TRAC format.
CONTENTS is the text within STRIKETHROUGH markup.
INFO is a plist used as a communication channel."
  (format "~~%s~~" contents))

;;;; Subscript
(defun org-trac-subscript(subscript contents info)
  "Transcode a SUBSCRIPT object from Org to TRAC
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (format ",,%s,," contents))

;;;; Superscript
(defun org-trac-superscript (superscript contents info)
  "Transcode a SUPERSCRIPT object from Org to TRAC.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (format "^%s^" contents))

;;;; Table
(defun org-trac-table (table contents info)
  "Transcode a TABLE object from Org to TRAC.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
   contents)

;;;; Table Cell
(defun org-trac-table-cell  (table-cell contents info)
  "Transcode a TABLE-CELL object from Org to TRAC.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (let ((table-row (org-export-get-parent table-cell)))
    (concat ;;"[TABLE_CELL]"
     (if (org-export-table-row-starts-header-p table-row info)
         "="
       )
     (if (eq (length contents) 0)
         " ")
     contents
     (if (org-export-table-row-starts-header-p table-row info)
         "=||" "||")
     ;;     "[/TABLE_CELL]"
     )))

;;;; Table Row
(defun org-trac-table-row  (table-row contents info)
  "Transcode a TABLE-ROW object from Org to TRAC.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (concat "||" contents))

;;;; Target

;;;; Template
(defun org-trac-template (contents info)
  "Return complete document string after Trac WikiFormat conversion.
CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  contents)

;;;; Timestamp

;;;; Underline
(defun org-trac-underline (underline contents info)
  "Transcode UNDERLINE from Org to Trac WikiFormat.
CONTENTS is the text with underline markup.  INFO is a plist
holding contextual information."
  (format  "__%s__" contents))

;;;; Verbatim
(defun org-trac-verbatim (verbatim contents info)
  "Transcode VERBATIM object into Trac WikiFormat format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (let ((value (org-element-property :value verbatim)))
    (format (cond ((not (string-match "`" value)) "`%s`")
		  ((or (string-match "\\``" value)
		       (string-match "`\\'" value))
		   "`` %s ``")
		  (t "``%s``"))
	    value)))

;;;; Verse Block
(defun org-trac-verse-block (verse-block contents info)
  "Transcode a VERSE-BLOCK element from Org to TRAC.
CONTENTS is verse block contents.  INFO is a plist holding
contextual information."
  ;; Replace each white space at beginning of a line with a
  ;; non-breaking space.
  (while (string-match "^[ \t]+" contents)
    (let* ((num-ws (length (match-string 0 contents)))
           (ws (let (out) (dotimes (i num-ws out)
        		    (setq out (concat out (make-string 1 ?\xa0)))))))
      (setq contents (replace-match ws nil t contents))))
  ;; Replace each newline character with line break ([[BR]]).
  ;; Also replace each blank line with a line break. Do not add
  ;; a New-line "\\n" after the [[BR]]
  (setq contents (replace-regexp-in-string
		  "^ *\\\\\\\\$" "\\\\\\\\"
		  (replace-regexp-in-string
		   "\\(\\\\\\\\\\)?[ \t]*\n"
		   (format "%s" "\\\\\\\\") contents)))
  contents)



(defun org-trac--anchor (id desc attributes info)
  "Format a Trac WikiFormat anchor.
ID is the anchor name. DESC is description of the target anchor, ATTRIBUTES.
INFO is unused"
  (format "[=#%s][#%s %s]" id attributes desc))


(defun org-trac-footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."

  (let* ((fn-alist (org-export-collect-footnote-definitions info))
	 (fn-alist
	  (loop for (n type raw) in fn-alist collect
		(cons n (if (eq (org-element-type raw) 'org-data)
			    (org-trim (org-export-data raw info))
			  (format "%s"
				  (org-trim (org-export-data raw info))))))))
    (when fn-alist
      (format
       (concat (make-string (plist-get info :trac-footnote-level) ?= )
               " %s %s")
       (org-export-translate "Footnotes" :utf-8 info)
       (format
	"\n%s\n"
	(mapconcat
	 (lambda (fn)
	   (let ((n (car fn)) (def (cdr fn)))
	     (format
	      "%s %s\n"
	      (format
               "^%s^" ;; TODO (plist-get info :trac-footnote-format)
	       (org-trac--anchor
		(format "fn.%d" n)
		n
		(format "fnr.%d" n)
		info))
	      def)))
	 fn-alist
	 "\n"))))))



;;; Interactive function

;;;###autoload
(defun org-trac-export-as-tracwiki (&optional async subtreep visible-only)
  "Export current buffer to a Trac WikiFormat buffer.

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

Export is done in a buffer named \"*Org Trac Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'trac "*Org Trackwiki Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-trac-convert-region-to-trac ()
  "Assume the current region has 'org-mode' syntax, and convert it to Trac.
This can be used in any buffer.  For example, you can write an
itemized list in 'org-mode' syntax in a Trac WikiFormat buffer and use
this command to convert it."
  (interactive)
  (org-export-replace-region-by 'trac))


;;;###autoload
(defun org-trac-export-to-tracwiki (&optional async subtreep visible-only)
  "Export current buffer to a Trac WikiFormat file.

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
  (let ((outfile (org-export-output-file-name ".trac" subtreep)))
    (org-export-to-file 'trac outfile async subtreep visible-only)))

(provide 'ox-trac)
;;; ox-trac.el ends here

