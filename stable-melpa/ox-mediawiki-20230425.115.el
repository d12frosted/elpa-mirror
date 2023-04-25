;;; ox-mediawiki.el --- Mediawiki Back-End for Org Export Engine

;; Copyright (C) 2012, 2013  Free Software Foundation, Inc.

;; Author: Tom Alexander <tomalexander@paphus.com>
;; Author: Tim Visher <tim.visher@gmail.com>
;; Package-Requires: ((cl-lib "0.5") (s "1.9.0"))
;; Package-Version: 20230425.115
;; Package-Commit: fa4954c12ab339ac8adf2830141390e71ee13067
;; Keywords: org, wp, mediawiki
;; Homepage: https://github.com/tomalexander/orgmode-mediawiki

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements a Mediawiki back-end for
;; Org exporter, based on `html' back-end.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-mw-export-as-mediawiki' (temporary buffer) and
;; `org-mw-export-to-mediawiki' ("mw" file).

;;; Code:

(eval-when-compile (require 'cl))
(require 's)
(require 'ox-html)

;;; User-Configurable Variables

(defgroup org-export-mw nil
  "Options specific to Mediawiki export back-end."
  :tag "Org Mediawiki"
  :group 'org-export
  :version "24.4"
  :package-version '(Org . "8.0"))

(defcustom org-mw-headline-style 'atx
  "Style used to format headlines.
This variable can be set to either `atx' or `setext'."
  :group 'org-export-mw
  :type '(choice
          (const :tag "Use \"atx\" style" atx)
          (const :tag "Use \"Setext\" style" setext)))

;;Define the default table class
(defcustom org-mw-default-table-class "wikitable"
  "The CSS class for table export.
Setting this to nil means to exclude any class definition."
  :group 'org-export-mw
  :type 'string)

;;
;; Footnotes.
;;
;; TODO: Currently footnotes are just exported as plain text. It would be really
;;        nice if we have a variable that let the user tell us if they wanted to
;;        export using the Cite syntax for footnotes.
;;
;;        http://www.mediawiki.org/wiki/Help:Extension:Cite
;;
(defcustom org-mw-footnote-format "[%s]"
  "The format for the footnote reference.
%s will be replaced by the footnote reference itself."
  :group 'org-export-mw
  :type 'string)

(defcustom org-mw-footnote-separator ", "
  "Text used to separate footnotes."
  :group 'org-export-mw
  :type 'string)

(defcustom org-mw-footnotes-section "\n----\n=== %s ===\n%s"
  "Format for the footnotes section.
Should contain a two instances of %s.  The first will be replaced with the
language-specific word for \"Footnotes\", the second one will be replaced
by the footnotes themselves."
  :group 'org-export-mw
  :type 'string)

(defcustom org-mw-filename-extension ".mw"
  "Extension to use for file names when exporting."
  :group 'org-export-mw
  :type 'string)


;;; Define Back-End

(org-export-define-derived-backend 'mw 'html
  :filters-alist '((:filter-parse-tree . org-mw-separate-elements))
  :menu-entry
  '(?m "Export to Mediawiki"
       ((?M "To temporary buffer"
            (lambda (a s v b) (org-mw-export-as-mediawiki a s v)))
        (?m "To file" (lambda (a s v b) (org-mw-export-to-mediawiki a s v)))
        (?o "To file and open"
            (lambda (a s v b)
              (if a (org-mw-export-to-mediawiki t s v)
                (org-open-file (org-mw-export-to-mediawiki nil s v)))))))
  :translate-alist '((bold . org-mw-bold)
                     (code . org-mw-code)
                     (underline . org-mw-underline)
                     (comment . (lambda (&rest args) ""))
                     (comment-block . (lambda (&rest args) ""))
                     (example-block . org-mw-example-block)
                     (fixed-width . org-mw-example-block)
                     (footnote-definition . ignore)
                     (footnote-reference . org-mw-footnote-reference)
                     (headline . org-mw-headline)
                     (horizontal-rule . org-mw-horizontal-rule)
                     (inline-src-block . org-mw-code)
                     (italic . org-mw-italic)
                     (item . org-mw-item)
                     (line-break . org-mw-line-break)
                     (link . org-mw-link)
                     (paragraph . org-mw-paragraph)
                     (plain-list . org-mw-plain-list)
                     (plain-text . org-mw-plain-text)
                     (quote-block . org-mw-quote-block)
                     (quote-section . org-mw-example-block)
                     (section . org-mw-section)
                     (src-block . org-mw-example-block)
                     (inner-template . org-mw-inner-template)
                     (template . org-mw-template)
                     (verbatim . org-mw-verbatim)
                     (table . org-mw-table)
                     (table-cell . org-mw-table-cell)
                     (table-row . org-mw-table-row)))

;;
;; Footnote support
;;
(defun org-mw-format-footnote-reference (n def refcnt)
  "Format footnote reference N. DEF and REFCNT are ignored."
  (format org-mw-footnote-format
          n))

(defun org-mw-footnote-reference (footnote-reference contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to MW.  CONTENTS is nil.
INFO is a plist holding contextual information."
  (concat
   ;; Insert separator between two footnotes in a row.
   (let ((prev (org-export-get-previous-element footnote-reference info)))
     (when (eq (org-element-type prev) 'footnote-reference)
       org-mw-footnote-separator))
   (cond
    ((not (org-export-footnote-first-reference-p footnote-reference info))
     (org-mw-format-footnote-reference
      (org-export-get-footnote-number footnote-reference info)
      "IGNORED" 2))
    ;; Inline definitions are secondary strings.
    ((eq (org-element-property :type footnote-reference) 'inline)
     (org-mw-format-footnote-reference
      (org-export-get-footnote-number footnote-reference info)
      "IGNORED" 1))
    ;; Non-inline footnotes definitions are full Org data.
    (t (org-mw-format-footnote-reference
        (org-export-get-footnote-number footnote-reference info)
        "IGNORED" 1)))))

(defun org-mw--translate (s info)
  "Translate string S according to specified language.
INFO is a plist used as a communication channel."
  (org-export-translate s :ascii info))

(defun org-mw-format-footnotes-section (section-name definitions)
  "Format DEFINITIONS in section SECTION-NAME."
  (if (not definitions) ""
    (format org-mw-footnotes-section section-name definitions)))

(defun org-mw-format-footnote-definition (fn)
  "Format the footnote definition FN."
  (let ((n (car fn)) (def (cdr fn)))
    (format "[%s] %s\n"
            n
            def)))

(defun org-mw-footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (let* ((fn-alist (org-export-collect-footnote-definitions
                    info (plist-get info :parse-tree)))
         (fn-alist
          (cl-loop for (n type raw) in fn-alist collect
                (cons n (if (eq (org-element-type raw) 'org-data)
                            (org-trim (org-export-data raw info))
                          (format "%s"
                                  (org-trim (org-export-data raw info))))))))
    (when fn-alist
      (org-mw-format-footnotes-section
       (org-mw--translate "Footnotes" info)
       (format
        "\n%s\n"
        (mapconcat 'org-mw-format-footnote-definition fn-alist "\n"))))))

;;; Filters
(defun org-mw-separate-elements (tree backend info)
  "Make sure elements are separated by at least one blank line.

TREE is the parse tree being exported.  BACKEND is the export
back-end used.  INFO is a plist used as a communication channel.

Assume BACKEND is `mw'."
  (org-element-map tree org-element-all-elements
    (lambda (elem)
      (unless (eq (org-element-type elem) 'org-data)
        (org-element-put-property
         elem :post-blank
         (let ((post-blank (org-element-property :post-blank elem)))
           (if (not post-blank) 1 (max 1 post-blank)))))))
  ;; Return updated tree.
  tree)


;;; Transcode Functions

;;;; Bold

(defun org-mw-bold (bold contents info)
  "Transcode BOLD object into Mediawiki format.
CONTENTS is the text within bold markup.  INFO is a plist used as
a communication channel."
  (format "'''%s'''" contents))

(defun org-mw-inline-formatter (value fmt1 fmt2)
  "Format VALUE using FMT1 or FMT2."
  (format (cond ((not (string-match "`" value)) fmt2)
                ((or (string-match "\\``" value)
                     (string-match "`\\'" value))
                 fmt1)
                (t fmt2))
          value))

;;;; Code and Inline source block
(defun org-mw-code (code contents info)
  "Transcode CODE and INLINE-SRC-BLOCK object into Mediawiki format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (org-mw-inline-formatter
   (org-element-property :value code)
   "<code> %s </code>"
   "<code>%s</code>"))

;;;; Verbatim
(defun org-mw-verbatim (verbatim contents info)
  "Transcode VERBATIM object into Mediawiki format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (org-mw-inline-formatter
   (org-element-property :value verbatim)
   "<tt> %s </tt>"
   "<tt>%s</tt>"))

;;;; underline
(defun org-mw-underline (underline contents info)
  "Transcode UNDERLINE object into Mediawiki format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (format  "<u>%s</u>"  (org-element-property :value underline)))

;;;; Example Block and Src Block

(defun org-mw-example-block (example-block contents info)
  "Transcode EXAMPLE-BLOCK element into Mediawiki format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (replace-regexp-in-string
   "^" "    "
   (org-remove-indentation
    (org-element-property :value example-block))))


;;;; Headline

(defun org-mw-headline (headline contents info)
  "Transcode HEADLINE element into Mediawiki format.
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

           ;; Headline text without tags.
           (heading (concat todo priority title))) ;; End of Let*

      (cond
       ;; Use "Setext" style.
       ((eq org-mw-headline-style 'setext)
        (concat heading tags "\n"
                (make-string (length heading) (if (= level 1) ?= ?-))
                "\n\n"
                contents))
       ;; Use "atx" style.
       (t (concat (make-string level ?=) " " heading tags " "
                  (make-string level ?=) "\n" contents))))))


;;;; Horizontal Rule

(defun org-mw-horizontal-rule (horizontal-rule contents info)
  "Transcode HORIZONTAL-RULE element into Mediawiki format.
CONTENTS is the horizontal rule contents.  INFO is a plist used
as a communication channel."
  "----")


;;;; Italic

(defun org-mw-italic (italic contents info)
  "Transcode ITALIC object into Mediawiki format.
CONTENTS is the text within italic markup.  INFO is a plist used
as a communication channel."
  (format "''%s''" contents))


;;;; Item
(defun org-mw-item-get-depth (item)
  "Calculate the bullet depth of ITEM."
  (let ((depth 0))
    (while item
      (setq item (org-export-get-parent item))
      (if (equal (car item) 'plain-list)
          (setq depth (+ depth 1))))
    depth))

(defun org-mw-paragraph-to-oneline(contents)
  "Replace newline + spaces in CONTENTS with just a space.
This makes paragraphs spread across multiple lines into a single
line, a format that mediawiki likes better."
  (replace-regexp-in-string "\n*$" "\n"
                            (replace-regexp-in-string "\n\s*\\([^*]\\)" " \\1"
                                                      contents)))

(defun org-mw-item (item contents info)
  "Transcode ITEM element into Mediawiki format.
CONTENTS is the item contents.  INFO is a plist used as
a communication channel."
  (let* ((type (org-element-property :type (org-export-get-parent item)))
         (contents-oneline (org-mw-paragraph-to-oneline contents))
         (struct (org-element-property :structure item))
         (level (org-mw-item-get-depth item))
         (bullet (make-string (or level 1) (if (not (eq type 'ordered)) ?*
                                      ?#)))
         (the-item (org-trim contents-oneline)))
    (format "%s%s" bullet the-item)))

;;;; Line Break

(defun org-mw-line-break (line-break contents info)
  "Transcode LINE-BREAK object into Mediawiki format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  "<br />")

;;;; Link
;; craftkiller: todo: revisit
(defun org-mw-link (link contents info)
  "Transcode LINK object into Mediawiki format.
CONTENTS is the link's description.  INFO is a plist used as
a communication channel."
  (let ((--link-org-files-as-html-maybe
         (function
          (lambda (raw-path info)
            ;; Treat links to `file.org' as links to `file.html', if
            ;; needed.  See `org-html-link-org-files-as-html'.
            (cond
             ((and org-html-link-org-files-as-html
                   (string= ".org"
                            (downcase (file-name-extension raw-path "."))))
              (concat (file-name-sans-extension raw-path) "."
                      (plist-get info :html-extension)))
             (t raw-path)))))
        (type (org-element-property :type link)))
    (cond ((member type '("custom-id" "id"))
           (let ((destination (org-export-resolve-id-link link info)))
             (if (stringp destination)	; External file.
                 (let ((path (funcall --link-org-files-as-html-maybe
                                      destination info)))
                   (if (not contents) (format "<%s>" path)
                     (format "[%s](%s)" contents path)))
               (concat
                (and contents (concat contents " "))
                (format "(%s)"
                        (format
                         (org-export-translate "See section %s" :html info)
                         (mapconcat 'number-to-string
                                    (org-export-get-headline-number
                                     destination info)
                                    ".")))))))
          ((org-export-inline-image-p link org-html-inline-image-rules)
           (let ((path (let ((raw-path (org-element-property :path link)))
                         (if (not (file-name-absolute-p raw-path)) raw-path
                           (expand-file-name raw-path)))))
             (format "![%s](%s)"
                     (let ((caption (org-export-get-caption
                                     (org-export-get-parent-element link))))
                       (when caption (org-export-data caption info)))
                     path)))
          ((string= type "coderef")
           (let ((ref (org-element-property :path link)))
             (format (org-export-get-coderef-format ref contents)
                     (org-export-resolve-coderef ref info))))
          ((equal type "radio")
           (let ((destination (org-export-resolve-radio-link link info)))
             (org-export-data (org-element-contents destination) info)))
          ((equal type "fuzzy")
           (let ((destination (org-export-resolve-fuzzy-link link info)))
             (if (org-string-nw-p contents) contents
               (when destination
                 (let ((number (org-export-get-ordinal destination info)))
                   (when number
                     (if (atom number) (number-to-string number)
                       (mapconcat 'number-to-string number "."))))))))
          (t (let* ((raw-path (org-element-property :path link))
                    (path (cond
                           ((member type '("http" "https" "ftp"))
                            (concat type ":" raw-path))
                           ((equal type "file")
                            ;; Treat links to ".org" files as ".html",
                            ;; if needed.
                            (setq raw-path
                                  (funcall --link-org-files-as-html-maybe
                                           raw-path info))
                            ;; If file path is absolute, prepend it
                            ;; with protocol component - "file://".
                            (if (not (file-name-absolute-p raw-path)) raw-path
                              (concat "file://" (expand-file-name raw-path))))
                           (t raw-path))))
               (if (not contents) (format "%s" path)
                 (format "[%s %s]" path
                         (s-join " " (s-split "\n" contents)))))))))


;;;; Paragraph

(defun org-mw-paragraph (paragraph contents info)
  "Transcode PARAGRAPH element into Mediawiki format.
CONTENTS is the paragraph contents.  INFO is a plist used as
a communication channel."
  (let ((first-object (car (org-element-contents paragraph))))
    ;; If paragraph starts with a #, protect it.
    (if (and (stringp first-object) (string-match "\\`#" first-object))
        (replace-regexp-in-string "\\`#" "\\#" contents nil t)
      contents)))


;;;; Plain List

(defun org-mw-plain-list (plain-list contents info)
  "Transcode PLAIN-LIST element into Mediawiki format.
CONTENTS is the plain-list contents.  INFO is a plist used as
a communication channel."
  contents)

;;;; Plain Text

(defun org-mw-plain-text (text info)
  "Transcode a TEXT string into Mediawiki format.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  (when (plist-get info :with-smart-quotes)
    (setq text (org-export-activate-smart-quotes text :html info)))
  ;; Protect ambiguous #.  This will protect # at the beginning of
  ;; a line, but not at the beginning of a paragraph.  See
  ;; `org-mw-paragraph'.
  (setq text (replace-regexp-in-string "\n#" "\n\\\\#" text))
  ;; Protect ambiguous !
  (setq text (replace-regexp-in-string "\\(!\\)\\[" "\\\\!" text nil nil 1))
  ;; Protect `, *, _ and \
  (setq text (replace-regexp-in-string "[`*_\\]" "\\\\\\&" text))
  ;; Handle special strings, if required.
  (when (plist-get info :with-special-strings)
    (setq text (org-html-convert-special-strings text)))
  ;; Handle break preservation, if required.
  (when (plist-get info :preserve-breaks)
    (setq text (replace-regexp-in-string "[ \t]*\n" "  \n" text)))
  ;; Return value.
  text)


;;;; Quote Block

(defun org-mw-quote-block (quote-block contents info)
  "Transcode QUOTE-BLOCK element into Mediawiki format.
CONTENTS is the quote-block contents.  INFO is a plist used as
a communication channel."
  ;;(replace-regexp-in-string
  ;; "^" "> "
  (concat
   "<blockquote>"
   (replace-regexp-in-string "\n\\'" "" contents) "</blockquote>"))


;;;; Section

(defun org-mw-section (section contents info)
  "Transcode SECTION element into Mediawiki format.
CONTENTS is the section contents.  INFO is a plist used as
a communication channel."
  contents)


;;;; Template

(defun org-mw-template (contents info)
  "Return complete document string after Mediawiki conversion.
CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  contents)

(defun org-mw-inner-template (contents info)
  "Return complete document string after Mediawiki conversion.
CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  (concat
   contents
   ;; Footnotes section.
   (org-mw-footnote-section info)))

;;;; Tabel Cell

(defun org-mw-table-cell (table-cell contents info)
  "Transcode a TABLE-CELL element from Org to HTML.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (concat "|" contents "\n"))

;;;; Table Row

(defun org-mw-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to HTML.
CONTENTS is the contents of the row.  INFO is a plist used as a
communication channel."
  (concat "|-\n" contents))

;;;; Table

(defun org-mw-table-first-row-data-cells (table info)
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

(defun org-mw-table--table.el-table (table info)
  "Format table.el TABLE into HTML.
INFO is a plist used as a communication channel."
  (when (eq (org-element-property :type table) 'table.el)
    (require 'table)
    (let ((outbuf (with-current-buffer
                      (get-buffer-create "*org-export-table*")
                    (erase-buffer) (current-buffer))))
      (with-temp-buffer
        (insert (org-element-property :value table))
        (goto-char 1)
        (re-search-forward "^[ \t]*|[^|]" nil t)
        (table-generate-source 'html outbuf))
      (with-current-buffer outbuf
        (prog1 (org-trim (buffer-string))
          (kill-buffer) )))))

(defun org-mw-table (table contents info)
  "Transcode a TABLE element from Org to HTML.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (cl-case (org-element-property :type table)
    ;; Case 1: table.el table.  Convert it using appropriate tools.
    (table.el (org-mw-table--table.el-table table info))
    ;; Case 2: Standard table.
    (t
     (let* ((label (org-element-property :name table))
            (caption (org-export-get-caption table))
            (alignspec
             (if (and (boundp 'org-mw-format-table-no-css)
                      org-mw-format-table-no-css)
                 "align=\"%s\"" "class=\"%s\""))
            (table-column-specs
             (function
              (lambda (table info)
                (mapconcat
                 (lambda (table-cell)
                   (let ((alignment (org-export-table-cell-alignment
                                     table-cell info)))
                     ""
                     ))
                 (org-mw-table-first-row-data-cells table info)
                 "\n"))))) ;; End of Let*
       (format "{| %s\n%s\n%s\n%s\n|}"
               (if (not org-mw-default-table-class) ""
                 (format "class=%s"
                         org-mw-default-table-class))
               (if (not caption) ""
                 (format "|+ %s\n"
                         (org-export-data caption info)))
               (funcall table-column-specs table info)
               contents)))))

;;; Tables of Contents

(defun org-mw-toc (depth info)
  "Build a table of contents.
DEPTH is an integer specifying the depth of the table.  INFO is a
plist used as a communication channel.  Return the table of
contents as a string, or nil if it is empty."
  'nil)

;;; Interactive function

;;;###autoload
(defun org-mw-export-as-mediawiki (&optional async subtreep visible-only)
  "Export current buffer to a Mediawiki buffer.

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

Export is done in a buffer named \"*Org MW Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (if async
      (org-export-async-start
          (lambda (output)
            (with-current-buffer (get-buffer-create "*Org MW Export*")
              (erase-buffer)
              (insert output)
              (goto-char (point-min))
              (text-mode)
              (org-export-add-to-stack (current-buffer) 'mw)))
        `(org-export-as 'mw ,subtreep ,visible-only))
    (let ((outbuf (org-export-to-buffer
                      'mw "*Org MW Export*" subtreep visible-only)))
      (with-current-buffer outbuf (text-mode))
      (when org-export-show-temporary-export-buffer
        (switch-to-buffer-other-window outbuf)))))

;;;###autoload
(defun org-mw-convert-region-to-mw ()
  "Assume the current region has `org-mode` syntax, and convert it to Mediawiki.
This can be used in any buffer.  For example, you can write an
itemized list in `org-mode` syntax in a Mediawiki buffer and use
this command to convert it."
  (interactive)
  (org-export-replace-region-by 'mw))


;;;###autoload
(defun org-mw-export-to-mediawiki (&optional async subtreep visible-only)
  "Export current buffer to a Mediawiki file.

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
  (let ((outfile (org-export-output-file-name
                  org-mw-filename-extension subtreep)))
    (if async
 (org-export-async-start
            (lambda (f) (org-export-add-to-stack f 'mw))
          `(expand-file-name
            (org-export-to-file 'mw ,outfile ,subtreep ,visible-only)))
      (org-export-to-file 'mw outfile subtreep visible-only))))


(provide 'ox-mediawiki)

;; Local variables:
;; End:

;;; ox-mediawiki.el ends here
