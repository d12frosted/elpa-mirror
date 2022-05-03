;;; ox-review.el --- Re:VIEW Back-End for Org Export Engine  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Masashi Fujimoto

;; Author: Masashi Fujimoto
;; Created: 2022-03-27
;; Version: 0.2.0
;; Package-Version: 20220502.1146
;; Package-Commit: 4abb1aa4665d246a38a9a53e5b365b3e57ec6d85
;; Keywords: outlines, hypermedia
;; URL: https://github.com/masfj/ox-review
;; Package-Requires: ((emacs "26.1") (org "9"))

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

;; This library implements a Re:VIEW back-end for Org exporter.

;;; Code:

(require 'cl-lib)
(require 'ox)
(require 'ox-publish)

;;; Define Back-End
(org-export-define-backend 'review
  '((bold . ox-review-bold)
    (center-block . ox-review-center-block)
    (clock . ox-review-clock)
    (code . ox-review-code)
    (drawer . ox-review-drawer)
    (dynamic-block . ox-review-dynamic-block)
    (entity . ox-review-entity)
    (example-block . ox-review-example-block)
    (export-block . ox-review-export-block)
    (export-snippet . ox-review-export-snippet)
    (fixed-width . ox-review-fixed-width)
    (footnote-definition . ox-review-footnote-definition)
    (footnote-reference . ox-review-footnote-reference)
    (headline . ox-review-headline)
    (horizontal-rule . ox-review-horizontal-rule)
    (inline-src-block . ox-review-inline-src-block)
    (inlinetask . ox-review-inlinetask)
    (inner-template . ox-review-inner-template)
    (italic . ox-review-italic)
    (item . ox-review-item)
    (keyword . ox-review-keyword)
    (latex-environment . ox-review-latex-environment)
    (latex-fragment . ox-review-latex-fragment)
    (line-break . ox-review-line-break)
    (link . ox-review-link)
    (node-property . ox-review-node-property)
    (paragraph . ox-review-paragraph)
    (plain-list . ox-review-plain-list)
    (plain-text . ox-review-plain-text)
    (planning . ox-review-planning)
    (property-drawer . ox-review-property-drawer)
    (quote-block . ox-review-quote-block)
    (radio-target . ox-review-radio-target)
    (section . ox-review-section)
    (special-block . ox-review-special-block)
    (src-block . ox-review-src-block)
    (statistics-cookie . ox-review-statistics-cookie)
    (strike-through . ox-review-strike-through)
    (subscript . ox-review-subscript)
    (superscript . ox-review-superscript)
    (table . ox-review-table)
    (table-cell . ox-review-table-cell)
    (table-row . ox-review-table-row)
    (target . ox-review-target)
    (template . ox-review-template)
    (timestamp . ox-review-timestamp)
    (underline . ox-review-underline)
    (verbatim . ox-review-verbatim)
    (verse-block . ox-review-verse-block)
    ;; Pseudo objects and elements.
    (latex-math-block . ox-review--empty)
    (latex-matrices . ox-review--empty))
  :menu-entry
  '(?r "Export to Re:VIEW file"
       ((?R "To temporary buffer" (lambda (a s v b)
                                    (ox-review-export-as-review a s v)))
        (?r "To file" ox-review-export-to-review)
        (?o "To file and open" (lambda (a s v b)
                                 (if a (ox-review-export-to-review t s v nil nil)
                                   (org-open-file (ox-review-export-to-review nil s v nil nil)))))))
  :options-alist
  '((:description "DESCRIPTION" nil nil space)
    (:keywords "KEYWORDS" nil nil space)
    (:subtitle "SUBTITLE" nil nil space)
    (:review-active-timestamp-format nil nil ox-review-active-timestamp-format)
    (:review-diary-timestamp-format nil nil ox-review-diary-timestamp-format)
    (:review-format-drawer-function nil nil ox-review-format-drawer-function)
    (:review-footnote-format nil nil ox-review-footnote-format)
    (:review-footnote-separator nil nil ox-review-footnote-separator)
    (:review-footnotes-section nil nil ox-review-footnotes-section)
    (:review-format-headline-function nil nil ox-review-format-headline-function)
    (:review-inactive-timestamp-format nil nil ox-review-inactive-timestamp-format)
    (:review-prefer-user-labels nil nil ox-review-prefer-user-labels)))

(defgroup ox-review nil
  "Options specific to Re:VIEW export backend."
  :tag "Org Re:VIEW"
  :group 'org-export
  :version "26.1"
  :package-version '(Org . "9.0"))

;;; Options
(defcustom ox-review-prefer-user-labels nil
  "When non-nil use user-defined names and ID over internal ones.

By default,
Org generates its own internal ID values during Re:VIEW export.

This process ensures that these values are unique and valid,
but the keys are not available in advance of the export process,
and not so readable.

When this variable is non-nil, Org will use NAME keyword, or
the real name of the target to create the ID attribute.

Independently of this variable, however,
CUSTOM_ID are always used as a reference."
  :group 'ox-review
  :package-version '(Org . "9.0")
  :type 'boolean
  :safe #'booleanp)


;;;; Drawers
(defcustom ox-review-format-drawer-function (lambda (_name contents) contents)
  "Function called to format a drawer in Re:VIEW.
The function must accept two parameters:
  NAME      the drawer name, like \"LOGBOOK\"
  CONTENTS  the contents of the drawer.
The function should return the string to be exported.
The default value simply returns the value of CONTENTS."
  :group 'ox-review
  :version "26.1"
  :package-version '(Org . "9.0")
  :type 'function)

;;;; footnote
(defcustom ox-review-footnotes-section "\n== %s\n%s"
  "Format for the footnotes section.
Should contain a two instances of %s.
The first will be replaced with the language-specific word for \"Footnotes\",
the second one will be replaced by the footnotes themselves."
  :group 'ox-review
  :type 'string)



(defcustom ox-review-footnote-format "@<fn>{%s}"
  "The format for the footnote reference.
%s will be replaced by the footnote reference itself."
  :group 'ox-review
  :type 'string)

(defcustom ox-review-footnote-separator "@<fn>{,}"
  "Text used to separate footnotes."
  :group 'ox-review
  :type 'string)


;;;; Headline
(defcustom ox-review-format-headline-function 'ox-review-format-headline-default-function
  "Function for formatting the headline's text.

This function will be called with six arguments:
TODO      the todo keyword (string or nil)
TODO-TYPE the type of todo (symbol: `todo', `done', nil)
PRIORITY  the priority of the headline (integer or nil)
TEXT      the main headline text (string)
TAGS      the tags (list of strings or nil)
INFO      the export options (plist)

The function result will be used in the section format string."
  :group 'ox-review
  :version "26.1"
  :package-version '(Org . "9.0")
  :type 'function)

;;;; Timestamp
(defcustom ox-review-active-timestamp-format "@<i>{%s}"
  "A printf format string to be applied to active timestamps."
  :group 'ox-review
  :type 'string)

(defcustom ox-review-inactive-timestamp-format "@<i>{%s}"
  "A printf format string to be applied to inactive timestamps."
  :group 'ox-review
  :type 'string)

(defcustom ox-review-diary-timestamp-format "@<i>{%s}"
  "A printf format string to be applied to diary timestamps."
  :group 'ox-review
  :type 'string)




;;; Utility
(defun ox-review--empty (_empty _contents _info)
  "Transcode a element from Org to empty string.
EMPTY is object.  CONTENTS is object.
INFO is a plit holding contextual information."
  "")

(defun ox-review--get-attributes (blob)
  "Return attributes list BLOB."
  (let ((attr (org-export-read-attribute :attr_review blob)))
    (if attr
        (progn
          attr)
      (let ((parent (org-export-get-parent blob)))
        (when parent
          (org-export-read-attribute :attr_review parent))))))


(defun ox-review--reference (datum info &optional named-only)
  "Return an appropriate reference for DATUM.
DATUM is an element or a `target' type object.
INFO is the current export state, as a plist.
When NAMED-ONLY is non-nil and DATUM has no NAME keyword,
return nil.
This doesn't apply to headlines, inline tasks,
radio targets and targets."
  (let* ((type (org-element-type datum))
	       (user-label
	        (org-element-property
	         (pcase type
	           ((or `headline `inlinetask) :CUSTOM_ID)
	           ((or `radio-target `target) :value)
	           (_ :name))
	         datum)))
    (cond
     ((and user-label
	         (or (plist-get info :review-prefer-user-labels)
	             (memq type '(headline inlinetask))))
      user-label)
     ((and named-only
	         (not (memq type '(headline inlinetask radio-target target)))
	         (not user-label))
      nil)
     (t
      (org-export-get-reference datum info)))))


(defun ox-review--footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (pcase (org-export-collect-footnote-definitions info)
    (`nil nil)
    (definitions
      (format
       (plist-get info :review-footnotes-section)
       (org-export-translate "Footnotes" :review info)
       (format
	      "\n%s\n"
	      (mapconcat
	       (lambda (definition)
	         (pcase definition
	           (`(,n ,_ ,def)
	            ;; `org-export-collect-footnote-definitions' can return
	            ;; two kinds of footnote definitions: inline and blocks.
	            ;; Since this should not make any difference in the HTML
	            ;; output, we wrap the inline definitions within
	            ;; a "footpara" class paragraph.
	            (let (
                    ;; (inline? (not (org-element-map def org-element-all-elements
				            ;;                 #'identity nil t)))
		                (fnref (format "fnr.%s" n))
		                (contents (org-trim (org-export-data def info))))
		            (format "//footnote[%s][%s]\n"
			                  fnref
                        contents)))))
	       definitions
	       "\n"))))))

;;; Transcode Functions
;;;; Bold
(defun ox-review-bold (_bold contents _info)
  "Transcode BOLD from Org to Re:VIEW.
CONTENTS is the text with bold markup.
INFO is a plist holding contextual information."
  (format "@<b>{%s}" contents))

;;;; Center block
(defun ox-review-center-block (_center-block contents _info)
  "Transcode a CENTER-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information."
  (format "%s" contents))

;;;; Clock
(defun ox-review-clock (clock _contents info)
  "Transcode a CLOCK object from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (format "//noindent\n@<b>{%s} %s"
          org-clock-string
          (format (plist-get info :review-inactive-timestamp-format)
                  (concat
                   (org-timestamp-translate (org-element-property :value clock))
	                 (let ((time (org-element-property :duration clock)))
	                   (if time
                         (format "%s" time)
                       ""))))))

;;;; Code
(defun ox-review-code (code _contents _info)
  "Transcode CODE from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (format "@<code>{%s}"
          (org-element-property :value code)))

;;;; Drawer
(defun ox-review-drawer (drawer contents info)
  "Transcode a DRAWER element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information."
  (funcall (plist-get info :review-format-drawer-function)
           (org-element-property :drawer-name drawer)
           contents))

;;;; Dynamic block
(defun ox-review-dynamic-block (_dynamic-block contents _info)
  "Transcode a DYNAMIC-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information.
See `org-export-data'."
  contents)

;;;; Entity
(defun ox-review-entity (entity _contents _info)
  "Transcode an ENTITY object from Org to Re:VIEW.
CONTENTS are the definition itself.
INFO is a plist holding contextual information."
  (org-element-property :review entity))

;;;; Example block
(defun ox-review-example-block (example-block _contents info)
  "Transcode a EXAMPLE-BLOCK element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (when (org-string-nw-p (org-element-property :value example-block))
    (format "//quote{\n%s\n//}" (org-export-format-code-default example-block info))))

;;;; Export block
(defun ox-review-export-block (export-block _contents _info)
  "Transcode a EXPORT-BLOCK element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (when (string= (org-element-property :type export-block) "REVIEW")
    (org-element-property :value export-block)))

;;;; Export snippet
(defun ox-review-export-snippet (export-snippet _contents _info)
  "Transcode a EXPORT-SNIPPET object from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (when (eq (org-export-snippet-backend export-snippet) 'review)
    (org-element-property :value export-snippet)))

;;;; Fixed width
(defun ox-review-fixed-width (fixed-width _contents _info)
  "Transcode a FIXED-WIDTH element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (format "//quote{\n%s\n//}"
          (org-remove-indentation (org-element-property :value fixed-width))))

;;;; Footnote definition

;;;; Footnote reference
(defun ox-review-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (concat
   (let ((prev (org-export-get-previous-element footnote-reference info)))
     (when (eq (org-element-type prev) 'footnote-reference)
       (plist-get info :review-footnote-separator)))
   (let* ((n (org-export-get-footnote-number footnote-reference info))
          (id (format "fnr.%d%s"
                      n
                      (if (org-export-footnote-first-reference-p footnote-reference info)
                          ""
                        ".100"))))
     (format
      (plist-get info :review-footnote-format) id))))

;;;; Headline
(defun ox-review-format-headline-default-function (todo _todo-type priority text tags _info)
  "Default format function for a headline.

This function will be called with six arguments:
TODO, TODO-TYPE, PRIORITY, TEXT, TAGS and INFO.

See `ox-review-format-headline-function' for details."
  (concat
   (and todo (format "@<b>{%s} " todo))
   (and priority (format "@<i>{%s} " priority))
   text
   (when tags
     (concat " "
             (mapconcat (lambda (tag)
                          (format "@<i>{%s}" tag))
                        tags
                        " ")))))

(defun ox-review--get-headline-type (headline)
  "Type of HEADLINE."
  (let ((type-string (downcase (or (org-element-property :HEADLINE_TYPE headline) ""))))
    (pcase type-string
      ("column" "[column]")
      ("nonum" "[nonum]")
      ("nodisp" "[nodisp]")
      ("notoc" "[notoc]")
      (_ ""))))

(defun ox-review-headline (headline contents info)
  "Transcode a HEADLINE element from Org to Re:VIEW.
CONTENTS holds the contents of the headline.
INFO is a plist holding contextual information."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((level (org-export-get-relative-level headline info))
           (todo (and (plist-get info :with-todo-keywords)
                      (let ((todo (org-element-property :todo-keyword headline)))
                        (and todo (org-export-data todo info)))))
           (todo-type (and todo (org-element-property :todo-type headline)))
           (priority (and (plist-get info :with-priority)
                          (org-element-property :priority headline)))
           (tags (and (plist-get info :with-tags)
                      (org-export-get-tags headline info)))
           (title (org-export-data (org-element-property :title headline) info))
           (full-title (funcall (plist-get info :review-format-headline-function)
                                todo todo-type priority title tags info)))
      (format "\n%s%s %s\n%s"
              (make-string level ?=)
              (ox-review--get-headline-type headline)
              full-title
              (or contents "")))))

;;;; Horizontal rule
(defun ox-review-horizontal-rule (_horizontal-rule _contents _info)
  "Transcode an HORIZONTAL_RULE object from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  "")

;;;; Inline src block
(defun ox-review-inline-src-block (inline-src-block _contents _info)
  "Transcode an INLINE-SRC-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the item.
INFO is a plist holding contextual information."
  (let ((code (org-element-property :value inline-src-block)))
    (format "%s" code)))

;;;; Inlinetask
(defun ox-review-inlinetask (inlinetask contents info)
  "Transcode an INLINETASK element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information."
  (let ((title (org-export-data (org-element-property :title inlinetask) info))
	      (todo (and (plist-get info :with-todo-keywords)
		               (let ((todo (org-element-property :todo-keyword inlinetask)))
		                 (and todo (org-export-data todo info)))))
	      (tags (and (plist-get info :with-tags)
		               (org-export-get-tags inlinetask info)))
	      (priority (and (plist-get info :with-priority)
		                   (org-element-property :priority inlinetask))))
    (format "%s %s %s %s %s" todo priority title tags contents)))

;;;; Inner template
(defun ox-review-inner-template (contents info)
  "Return body of document string after Re:VIEW conversion.
CONTENTS is the transcoded contents string.
INFO is a plist holding export options."
  (concat
   ;; Table of contents.
   ;; --
   ;; Document contents.
   contents
   ;; Footnotes section.
   (ox-review--footnote-section info)))


;;;; Italic
(defun ox-review-italic (_italic contents _info)
  "Transcode ITALIC from Org to Re:VIEW.
CONTENTS is the text with italic markup.
INFO is a plist holding contextual information."
  (format "@<i>{%s}" contents))

;;;; Item
(defun ox-review--get-item-depth (item)
  "Get the nested level of ITEM."
  (let ((parent (org-export-get-parent item)))
    (pcase (org-element-type parent)
      ('item (ox-review--get-item-depth parent))
      ('plain-list (1+ (ox-review--get-item-depth (org-export-get-parent parent))))
      (_ 0))))

(defun ox-review-item (item contents info)
  "Transcode an ITEM element from Org to Re:VIEW.
CONTENTS holds the contents of the item.
INFO is a plist holding contextual information."
  (let* ((type (org-element-property :type (org-export-get-parent item)))
         (depth (ox-review--get-item-depth item))
         (checkbox (org-element-property :checkbox item)))
    (pcase type
      ('ordered
       (if (= depth 1)
           (let* ((structure (org-element-property :structure item))
                  (num (car (last
                             (org-list-get-item-number (org-element-property :begin item)
                                                       structure
                                                       (org-list-prevs-alist structure)
                                                       (org-list-parents-alist structure))))))
             (format " %s. %s" num contents))
         (format "  %s" contents)))
      ('unordered
       (format " %s %s%s"
               (make-string depth ?*)
               (if (not checkbox)
                   ""
                 (format "[%s] "
                         (cl-case checkbox
                           (on "X")
                           (off " ")
                           (trans "-"))))
               contents))
      ('descriptive
       (let* ((term (org-element-property :tag item)))
         (when term
           (setq term (org-export-data term info)))
         (format " : %s\n      %s\n" term contents))))))

;;;; Keyword
(defun ox-review-keyword (_keyword _contents _info)
  "Transcode a KEYWORD element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  "")

;;;; Latex environment
(defun ox-review-latex-environment (_latex-environment _contents _info)
  "Transcode a LATEX-ENVIRONMENT element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  "")

;;;; Latex fragment
(defun ox-review-latex-fragment (_latex-fragment _contents _info)
  "Transcode a LATEX-FRAGMENT element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  "")

;;;; Line break
(defun ox-review-line-break (_line-break _contents _info)
  "Transcode a LINE-BREAK object from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  "@<br>{}")

;;;; Link
(defun ox-review-link (link contents info)
  "Transcode a LINK object from Org to Re:VIEW.
CONTENTS is the description part of the link, or the empty string.
INFO is a plist holding contextual information.
See `org-export-data'."
  (let* ((type (org-element-property :type link))
         (raw-path (org-element-property :path link))
         (desc (org-string-nw-p contents))
         (path (cond
                ((member type '("http" "https" "ftp" "mailto" "news"))
                 (url-encode-url (concat type ":" raw-path)))
                ((string= "file" type)
                 ;; During publishing, turn absolute file names belonging
	               ;; to base directory into relative file names.  Otherwise,
	               ;; append "file" protocol to absolute file name.
                 (setq raw-path (org-export-file-uri (org-publish-file-relative-name raw-path info))))
                (t
                 raw-path))))
    (cond
     ;; Link type is handled by a special function
     ((org-export-custom-protocol-maybe link desc 'review info))
     ;; Image file
     ((org-export-inline-image-p link)
      (let* ((id (file-name-base path))
             (caption (or (org-export-get-caption link)
                          (org-export-get-caption (org-export-get-parent link)))))
        (format "//image[%s][%s]{\n//}"
                (or id "")
                (if caption
                    (org-export-data caption info)
                  ""))))
     ;; Radio target
     ((string= "radio" type)
      desc)
     ;; Links pointing to a headline: Find destination and build
     ;; appropriate referencing command.
     ((member type '("custom-id" "fuzzy" "id"))
      (let ((destination (if (string= type "fuzzy")
                             (org-export-resolve-fuzzy-link link info)
                           (org-export-resolve-id-link link info))))
        (cl-case (org-element-type destination)
          ;; Id link points to an external file.
          (plain-text
           (if desc
               (format "@<href>{%s,%s}" destination desc)
             (format "@<href>{%s}" destination)))
          ;; Fuzzy link points nowhere.
          ((nil)
           (format "@<i>{%s}" (or desc
                                  (org-export-data
                                   (org-element-property :raw-link link) info))))
          ;; LINK points to a headline.  If headlines are numbered
	        ;; and the link has no description, display headline's
	        ;; number.  Otherwise, display description or headline's
	        ;; title.
          (headline
           (let ((ref (ox-review--reference destination info)))
             (if (and (not desc)
                      (org-export-numbered-headline-p destination info))
                 (format "@<href>{%s}" ref)
               (format "@<href>{%s,%s}" ref
                       (or desc
                           (org-export-data (org-element-property :title destination)
                                            info))))))
          (otherwise
           (let ((ref (ox-review--reference destination info t)))
             (if (not desc)
                 (format "@<href>{#%s}" ref)
               (format "@<href>{#%s,%s}" ref desc)))))))
     ;; Coderef: replace link with the reference name or the equivalent line number.
     ((string= "coderef" type)
      (format (org-export-get-coderef-format path desc)
              (org-export-resolve-coderef raw-path info)))
     ;; External link with a description part.
     ((and path desc)
      (format "@<href>{%s,%s}" path desc))
     ;; External link without a description part.
     (path
      (format "@<href>{%s}" path))
     ;; No path, only description.  Try to do someting useful.
     (t
      (format "@<i>{%s}" desc)))))

(defun ox-review-node-property (node-property _contents _info)
  "Transcode a NODE-PROPERTY element from Org to HTML.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format "%s:%s"
          (org-element-property :key node-property)
          (let ((value (org-element-property :value node-property)))
            (if value (concat " " value) ""))))

;;;; Paragraph
(defun ox-review-paragraph (_paragraph contents _info)
  "Transcode a PARAGRAPH element from Org to Re:VIEW.
CONTENTS is the contents of the paragraph, as a string.
INFO is the plist used as a communication channel."
  contents)


;;;; Plain list
(defun ox-review-plain-list (_plain-list contents _info)
  "Transcode a PLAIN-LIST element from Org to Re:VIEW.
CONTENTS is the contents of the list.
INFO is a plist holding contextual information."
  contents)

;;;; Plain text
(defun ox-review-plain-text (text _info)
  "Transcode a TEXT string from Org to Re:VIEW.
TEXT is the string to transcode.
INFO is a plist holding contextual information."
  text)

;;;; Planning
(defun ox-review-planning (planning _contents info)
  "Transcode a PLANNING element from Org to Re:VIEW.
CONTENTS is nil.
INFO is a plist holding contextual information."
  (concat "//noindent\n"
          (mapconcat
           #'identity
           (delq nil
                 (list
                  (let ((closed (org-element-property :closed planning)))
                    (when closed
                      (concat (format "@<b>{%s}" org-closed-string)
                              (format (plist-get info :review-inactive-timestamp-format)
                                      (org-timestamp-translate closed)))))
                  (let ((deadline (org-element-property :deadline planning)))
                    (when deadline
                      (concat (format "@<b>{%s}" org-deadline-string)
                              (format (plist-get info :review-inactive-timestamp-format)
                                      (org-timestamp-translate deadline)))))
                  (let ((scheduled (org-element-property :scheduled planning)))
                    (when scheduled
                      (concat (format "@<b>{%s}" org-scheduled-string)
                              (format (plist-get info :review-inactive-timestamp-format)
                                      (org-timestamp-translate scheduled)))))))
           " ")))

;;;; Property drawer
(defun ox-review-property-drawer (_property-drawer contents _info)
  "Transcode a PROPERTY-DRAWER element from Org to Re:VIEW.
CONTENTS holds the contents of the drawer.
INFO is a plist holding contextual information."
  (when (org-string-nw-p contents)
    (format "\n//quote{\n%s//}" contents)))

;;;; Quote block
(defun ox-review-quote-block (_quote-block contents _info)
  "Transcode a QUOTE-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information."
  (when (org-string-nw-p contents)
    (format "\n//quote{\n%s//}" contents)))

;;;; Radio target
(defun ox-review-radio-target (_radio-target text _info)
  "Transcode a RADIO-TARGET object from Org to Re:VIEW.
TEXT is the text of the target.  INFO is a plist holding
contextual information."
  (format "@<i>{%s}"
          text))

;;;; Section
(defun ox-review-section (_section contents _info)
  "Transcode a SECTION element from Org to Re:VIEW.
CONTENTS holds the contents of the section.
INFO is a plist holding contextual information."
  contents)

;;;; Special block
(defun ox-review-special-block (special-block contents info)
  "Transcode a SPECIAL-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the block.
INFO is a plist holding contextual information."
  (let ((block-type (org-element-property :type special-block)))
    (if (and block-type
             (stringp block-type)
             (member (downcase block-type) '("review-note" "review-memo"
                                             "review-tip" "review-info"
                                             "review-warning" "review-important"
                                             "review-caution" "review-notice"
                                             "review-lead")))
        (let* ((caption (org-export-get-caption special-block))
               (block-type (downcase block-type))
               (command (string-remove-prefix "review-" block-type))
               (caption-opt (if (and caption (not (string= command "lead")))
                                (format "[%s]" (org-export-data caption info))
                              ""))
               (fmt (concat "//" command caption-opt "{\n%s\n//}")))
          (format fmt contents))
      contents)))

;;;; Source code
(defun ox-review-src-block (src-block contents info)
  "Transcode a SRC-BLOCK element from Org to Re:VIEW.
CONTENTS holds the contents of the item.
INFO is a plist holding contextual information."
  (let ((value (org-element-property :value src-block)))
    (if (not (org-string-nw-p value))
        contents
      (let* ((language (org-element-property :language src-block))
             (caption (org-export-get-caption src-block))
             (caption (if caption
                          (org-export-data caption info)
                        "")))
        (format "\n//list%s[%s]%s[%s]{\n%s\n//}"
                ""
                (ox-review--reference src-block info)
                (if caption
                    (format "[%s]" caption)
                  "")
                language
                value)))))

;;;; Statistics cookie
(defun ox-review-statistics-cookie (statistics-cookie _contents _info)
  "Transcode a STATISTICS-COOKIE object from Org to Re:VIEW.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format "@<code>{%s}" (org-element-property :value statistics-cookie)))

;;;; Strike through
(defun ox-review-strike-through (_strike-through contents _info)
  "Transcode STRIKE-THROUGH from Org to Re:VIEW.
CONTENTS is the text with strike-through markup.
INFO is a plist holding contextual information."
  (format "@<del>{%s}" contents))

;;;; Subscript
(defun ox-review-subscript (_subscript contents _info)
  "Transcode a SUBSCRIPT object from Org to Re:VIEW.
CONTENTS is the contents of the object.
INFO is a plist holding contextual information."
  (format "@<sub>{%s}" contents))


;;;; Superscript
(defun ox-review-superscript (_superscript contents _info)
  "Transcode a SUPERSCRIPT object from Org to Re:VIEW.
CONTENTS is the contents of the object.
INFO is a plist holding contextual information."
  (format "@<sup>{%s}" contents))

;;;; Table
(defun ox-review-table (table contents info)
  "Transcode a TABLE element from Org to Re:VIEW.
CONTENTS is the contents of the table.
INFO is a plist holding contextual information."
  (let* ((type (org-element-property :type table))
         (caption (org-export-get-caption table))
         (caption (if caption
                      (org-export-data caption info)
                    ""))
         (id (ox-review--reference table info)))
    (if (not (eq type 'org))
        contents
      (format "\n//%stable%s%s{\n%s//}"
              (if id
                  ""
                "em")
              (if id
                  (format "[%s]" id)
                "")
              (if caption
                  (format "[%s]" (org-export-data caption info))
                "")
              contents))))


;;;; Table cell
(defun ox-review-table-cell (_table-cell contents _info)
  "Transcode a TABLE-CELL element from Org to Re:VIEW.
CONTENTS is the cell contents.
INFO is a plist used as a communication channel."
  (format "%s\t" (if (and contents (org-string-nw-p contents))
                     (if (string-prefix-p "." contents)
                         (format ".%s" contents)
                       contents)
                   ".")))

;;;; Table row
(defun ox-review-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to Re:VIEW.
CONTENTS is the contents of the row.
INFO is a plist used as a communication channel."
  ;; When a header delimiter line comes, both `org-export-table-row-group'
  ;; and `org-export-table-row-number' are set to nil.
  ;; If there is a header, the group of the first row is 1,
  ;; the header delimiter is nil, and the group of the following rows is 2.
  (if (null (org-export-table-row-group table-row info))
      (make-string 12 ?-)
    contents))

;;;; Target
(defun ox-review-target (target _contents info)
  "Transcode a TARGET object from Org to Re:VIEW.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((ref (ox-review--reference target info)))
    (format "@<href>{%s}" ref)))

;;;; Templete
(defun ox-review-template (contents _info)
  "Return complete document string after Re:VIEW conversion.
CONTENTS is the transcoded contents string.
INFO is a plist holding export options."
  contents)

;;;; Timestamp
(defun ox-review-timestamp (timestamp _contents info)
  "Transcode a TIMESTAMP object from Org to Re:VIEW.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((value (ox-review-plain-text (org-timestamp-translate timestamp) info)))
    (format
     (plist-get info
		            (cl-case (org-element-property :type timestamp)
		              ((active active-range) :review-active-timestamp-format)
		              ((inactive inactive-range) :review-inactive-timestamp-format)
		              (otherwise :review-diary-timestamp-format)))
     value)))

;;;; Verbatim
(defun ox-review-verbatim (verbatim _contents _info)
  "Transcode VERBATIM from Org to Re:VIEW.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format "\n//quote{\n%s\n//}"(org-element-property :value verbatim)))

;;;; Verse block
(defun ox-review-verse-block (_verse-block contents _info)
  "Transcode a VERSE-BLOCK element from Org to Re:VIEW.
CONTENTS is verse block contents.
INFO is a plist holding contextual information."
  (format "\n//quote{\n%s\n//}" contents))

;;;; Underline
(defun ox-review-underline (_underline contents _info)
  "Transcode UNDERLINE from Org to Re:VIEW.
CONTENTS is the text with underline markup.
INFO is a plist holding contextual information."
  (format "@<u>{%s}" contents))


;;; End-user functions
;;;###autoload
(defun ox-review-export-as-review (&optional async subtreep visible-only)
  "Export current buffer to an Re:VIEW buffer.

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

Export is done in a buffer named \"*Org Re:VIEW Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'review "*Org Re:VIEW Export*"
    async subtreep visible-only nil nil (lambda () (set-auto-mode t))))

;;;###autoload
(defun ox-review-convert-region-to-review ()
  "Assume the current region has Org syntax, and convert it to Re:VIEW.
This can be used in any buffer.
  For example, you can write an itemized list in Org syntax
in a Markdown buffer and use this command to convert it."
  (interactive)
  (org-export-replace-region-by 'review))

;;;###autoload
(defun ox-review-export-to-review (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a Re:VIEW file.

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

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".re" subtreep)))
    (org-export-to-file 'review
        outfile
      async
      subtreep
      visible-only
      body-only
      ext-plist)))

;;;###autoload
(defun ox-review-publish-to-review (plist filename pub-dir)
  "Publish an org file to Re:VIEW.

FILENAME is the filename of the Org file to be published.
PLIST is the property list for the given project.
PUB-DIR is the publishing directory."
  (org-publish-org-to 'review
                      filename
                      ".re"
                      plist
                      pub-dir))

(provide 'ox-review)
;;; ox-review.el ends here
