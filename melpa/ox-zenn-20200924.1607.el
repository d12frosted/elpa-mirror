;;; ox-zenn.el --- Zenn flavored markdown backend for org export engine  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20200924.1607
;; Package-Commit: b53bd82116c9f7dbb5b476d2cfcc8ed0f3bc9c78
;; Keywords: convenience
;; Package-Requires: ((emacs "27.1") (org "9.0"))
;; URL: https://github.com/conao3/ox-zenn.el

;; This program is free software: you can redistribute it and/or modify
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

;; Zenn flavored markdown backend for org export engine.
;; Zenn: https://zenn.dev/


;;; Code:

(require 'cl-lib)
(require 'ox-md)
(require 'ox-publish)

(defgroup org-export-zennmd nil
  "Zenn flavored markdown backend for org export engine.
Zenn: https://zenn.dev/"
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/ox-zenn.el"))

(org-export-define-derived-backend 'zennmd 'md
  :menu-entry
  '(?z "Export to Zenn Flavored Markdown"
       ((?Z "To temporary buffer"
            (lambda (a s v b) (org-zenn-export-as-markdown a s v)))
        (?z "To file"
            (lambda (a s v b) (org-zenn-export-to-markdown a s v)))
        (?o "To file and open"
            (lambda (a s v b)
              (if a
                  (org-zenn-export-to-markdown t s v)
                (org-open-file (org-zenn-export-to-markdown nil s v)))))))
  :translate-alist
  '((headline . org-zenn-headline)
    (paragraph . org-zenn-paragraph)
    (strike-through . org-zenn-strike-through)
    (src-block . org-zenn-src-block)
    (link . org-zenn-link)
    (quote-block . org-zenn-quote-block)
    (latex-fragment . org-zenn-latex-fragment)
    (footnote-reference . org-zenn-footnote-reference)
    (table-cell . ox-zenn-table-cell)
    (table-row . ox-zenn-table-row)
    (table . ox-zenn-table)
    (inner-template . org-zenn-inner-template)
    (template . org-zenn-template))
  :options-alist
  ;; KEY KEYWORD OPTION DEFAULT BEHAVIOR
  '((:last-modified "LAST_MODIFIED" nil (format-time-string "<%Y-%m-%d %a>"))
    (:with-last-modified nil "last-modified" org-zenn-with-last-modified)
    (:gfm-headline-offset nil "headline-offset" org-zenn-headline-offset)
    (:gfm-layout "GFM_LAYOUT" nil org-zenn-layout)
    (:gfm-category "GFM_CATEGORY" nil org-zenn-category)
    (:gfm-tags "GFM_TAGS" nil org-zenn-tags)
    (:gfm-preamble "GFM_PREAMBLE" nil org-zenn-preamble)
    (:gfm-postamble "GFM_POSTAMBLE" nil org-zenn-postamble)
    (:gfm-custom-front-matter "GFM_CUSTOM_FRONT_MATTER" nil nil space)))


;;; variables

(defcustom org-zenn-headline-offset 0
  "Headline offset."
  :group 'org-export-zennmd
  :type 'integer)

(defcustom org-zenn-date-format "%Y-%m-%d"
  "Date format for `org-zenn--create-date-string'."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-layout ""
  "Default layout for GFM frontmatter."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-preamble ""
  "Default header."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-postamble ""
  ;; "\
  ;; <!--
  ;; This file is generated from org file.
  ;; Please edit that org source instead of this file.

  ;; ;; Local Variables:
  ;; ;; buffer-read-only: t
  ;; ;; End:
  ;; -->"
  "Default footer."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-category ""
  "Default gfm category."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-tags ""
  "Default gfm tags devided by spaces."
  :group 'org-export-zennmd
  :type 'string)

(defcustom org-zenn-with-last-modified t
  "Non-nil means adding `last_modefied' property in frontmatter."
  :group 'org-export-zennmd
  :type 'boolean)


;;; functions

(defun org-zenn--make-string (n string)
  "Build a string by concatenating N times STRING."
  (if (<= n 0)
      ""
    (let (out) (dotimes (_ n out) (setq out (concat string out))))))

(defun org-zenn--parse-property-arguments (str)
  "Return an alist converted from a string STR of Hugo property value.

STR is of type \":KEY1 VALUE1 :KEY2 VALUE2 ..\".  Given that, the
returned value is ((KEY1 . VALUE1) (KEY2 . VALUE2) ..).

Example: Input STR \":foo bar :baz 1 :zoo \\\"two words\\\"\" would
convert to ((foo . \"bar\") (baz . 1) (zoo . \"two words\"))."
  (mapcar
   (lambda (elm)
     `(,(intern (substring (symbol-name (car elm)) 1)) . ,(cdr elm)))
   (org-babel-parse-header-arguments str)))

(defun org-zenn-headline (headline contents info)
  "Make HEADLINE string.
CONTENTS is the headline contents.
INFO is a plist used as a communication channel."
  (cl-flet ((parsenum (elm) (or (and (numberp elm) elm)
                                (and (stringp elm) (string-to-number elm))
                                0)))
    (let* ((num (plist-get info :gfm-headline-offset))
           (info (if (= 0 num)
                     info
                   (plist-put info :headline-offset num))))
      (org-zenn--md-headline headline contents info))))

(defun org-zenn--md-headline (headline contents info)
  "Transcode HEADLINE element into Markdown format.
CONTENTS is the headline contents.  INFO is a plist used as
a communication channel.

see `org-md-headline'."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((level (org-export-get-relative-level headline info))
	   (title (org-export-data (org-element-property :title headline) info))
	   (todo (when (plist-get info :with-todo-keywords)
		   (let ((todo (org-element-property :todo-keyword headline)))
		     (and todo (concat (org-export-data todo info) " ")))))
	   (tags (when (plist-get info :with-tags)
		   (let ((tag-list (org-export-get-tags headline info)))
		     (when tag-list
		       (concat "     " (org-make-tag-string tag-list))))))
	   (priority (when (plist-get info :with-priority)
		       (let ((char (org-element-property :priority headline)))
		         (when char
                           (format "[#%c] " char)))))
	   ;; Headline text without tags.
	   (heading (concat todo priority title))
	   (style (plist-get info :md-headline-style)))
      (cond
       ;; Cannot create a headline.  Fall-back to a list.
       ((or (org-export-low-level-p headline info)
	    (not (memq style '(atx setext)))
	    (and (eq style 'atx) (> level 6))
	    (and (eq style 'setext) (> level 2)))
	(let ((bullet
	       (if (not (org-export-numbered-headline-p headline info))
                   "-"
		 (concat
                  (number-to-string
		   (car (last (org-export-get-headline-number headline info))))
		  "."))))
	  (concat
           bullet
           (make-string (- 4 (length bullet)) ?\s)
           heading
           tags "\n\n"
	   (and contents (replace-regexp-in-string "^" "    " contents)))))
       (t
	(concat
         (org-md--headline-title style level heading nil tags)
	 contents))))))

(defun org-zenn--md--headline-referred-p (headline info)
  "Non-nil when HEADLINE is being referred to.
INFO is a plist used as a communication channel.  Links and table
of contents can refer to headlines.

see `ox-md--headline-referred-p'."
  (unless (org-element-property :footnote-section-p headline)
    (or
     ;; Global table of contents includes HEADLINE.
     (when (plist-get info :with-toc)
       (memq headline
	     (org-export-collect-headlines info (plist-get info :with-toc))))
     ;; A local table of contents includes HEADLINE.
     (cl-some
      (lambda (h)
	(let ((section (car (org-element-contents h))))
	  (and
	   (eq 'section (org-element-type section))
	   (org-element-map section 'keyword
	     (lambda (keyword)
	       (when (equal "TOC" (org-element-property :key keyword))
		 (let ((case-fold-search t)
		       (value (org-element-property :value keyword)))
		   (when (string-match-p "\\<headlines\\>" value)
		     (let ((n (and
			       (string-match "\\<[0-9]+\\>" value)
			       (string-to-number (match-string 0 value))))
			   (local? (string-match-p "\\<local\\>" value)))
		       (memq headline
			     (org-export-collect-headlines
			      info n (and local? keyword))))))))
	     info t))))
      (org-element-lineage headline))
     ;; A link refers internally to HEADLINE.
     (org-element-map (plist-get info :parse-tree) 'link
       (lambda (link)
	 (eq headline
             ;; <FIXPOINT>

             ;; (pcase (org-element-property :type link)
	     ;;   ((or "custom-id" "id") (org-export-resolve-id-link link info))
	     ;;   ("fuzzy" (org-export-resolve-fuzzy-link link info))
	     ;;   (_ nil))

             (let ((transcoder (org-export-transcoder link info)))
               (when transcoder
                 (funcall transcoder headline nil info)))

             ;; <FIXPOINT>
             ))
       info t))))

(defun org-zenn-link (link contents info)
  "Transcode LINK object into Markdown format.
CONTENTS is the link's description.  INFO is a plist used as
a communication channel."
  (let* ((type (org-element-property :type link))
         (path (org-element-property :path link))
         (parent (org-export-get-parent link))
         (attr (org-export-read-attribute :attr_html parent))
         (urlp (member type '("http" "https" "ftp" "mailto"))))
    (cond
     ((org-export-inline-image-p link org-html-inline-image-rules)
      (format "![%s](%s%s)"
              (or (plist-get attr :alt) "")
              (if urlp (concat type ":" path) path)
              (let ((width (plist-get attr :width)))
                (or (when width
                      (concat
                       " ="
                       (replace-regexp-in-string "px" "x" width)))
                    ""))))
     ((string= type "fuzzy")
      (or (when (string-match "\\([a-z0-9-]+\\)://\\(.*\\)" path)
            (let ((scheme (match-string 1 path))
                  (value (match-string 2 path)))
              (format "@[%s](%s)" scheme value)))
          (org-md-link link contents info)))
     (t
      (org-md-link link contents info)))))

(defun org-zenn-quote-block (quote-block contents info)
  "Transcode QUOTE-BLOCK element into Markdown format.
CONTENTS is the quote-block contents.  INFO is a plist used as
a communication channel."
  (let ((attr (org-export-read-attribute :attr_html quote-block)))
    (pcase (plist-get attr :x-type)
      ("message"
       (concat ":::message\n" contents ":::"))
      ("alert"
       (concat ":::message alert\n" contents ":::"))
      ("details"
       (concat
        (format ":::details %s\n" (or (plist-get attr :x-summary) "details"))
        contents
        ":::"))
      (_
       (org-md-quote-block quote-block contents info)))))

(defun org-zenn-latex-fragment (latex-fragment _contents _info)
  "Transcode a LATEX-FRAGMENT object from Org to HTML.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (org-element-property :value latex-fragment))

(defun org-zenn-strike-through (_strike-through contents _info)
  "Transcode STRIKE-THROUGH from Org to Markdown (GFM).
CONTENTS is the text with strike-through markup.  INFO is a plist
holding contextual information."
  (format "~~%s~~" contents))

(defun org-zenn-src-block (src-block _contents info)
  "Transcode SRC-BLOCK element into Github Flavored Markdown format.
CONTENTS is nil.  INFO is a plist used as a communication channel."
  (let* ((lang (org-element-property :language src-block))
         (body (org-export-format-code-default src-block info)))
    (format "```%s\n%s```" lang body)))

(defun org-zenn-paragraph (paragraph contents info)
  "Transcode PARAGRAPH element into Github Flavoured Markdown format.
CONTENTS is the paragraph contents.  INFO is a plist used as a
communication channel."
  (unless (plist-get info :preserve-breaks)
    (setq contents (concat (mapconcat 'identity (split-string contents) " ") "\n")))
  (let ((first-object (car (org-element-contents paragraph))))
    ;; If paragraph starts with a #, protect it.
    (if (and (stringp first-object) (string-match "\\`#" first-object))
        (replace-regexp-in-string "\\`#" "\\#" contents nil t)
      contents)))

(defun org-zenn-toc (depth info &optional scope)
  "Build a table of contents.
DEPTH is an integer specifying the depth of the table.  INFO is
a plist used as a communication channel.  Optional argument SCOPE
is an element defining the scope of the table.  Return the table
of contents as a string, or nil if it is empty."
  (let ((headlines (org-export-collect-headlines info depth scope)))
    (when headlines
      (string-join
       (mapcar
        (lambda (headline)
	  (let* ((headline-number (org-export-get-headline-number headline info))
	         (todo (when (plist-get info :with-todo-keywords)
		         (let ((todo (org-element-property :todo-keyword headline)))
		           (when todo (org-export-data todo info)))))
	         (todo-type (when todo (org-element-property :todo-type headline)))
	         (priority (when (plist-get info :with-priority)
			     (org-element-property :priority headline)))
	         (text (org-export-data-with-backend
		        (org-export-get-alt-title headline info)
		        (org-export-toc-entry-backend 'html)
		        info))
	         (tags (when (eq (plist-get info :with-tags) t)
		         (org-export-get-tags headline info))))
            (format "%s- [%s](#%s)"
                    (org-zenn--make-string
                     (+ -3
                        (plist-get info :html-toplevel-hlevel)
                        (org-export-get-relative-level headline info))
                     "  ")
	            (concat
	             (unless (org-export-low-level-p headline info)
		       (org-export-numbered-headline-p headline info)
		       (concat
                        (mapconcat #'number-to-string headline-number ".")
			". "))
	             (apply (plist-get info :html-format-headline-function)
		            todo todo-type priority text tags :section-number nil))
	            (let ((title (car-safe (org-element-property :title headline))))
                      (if (not title)
                          ""
                        (url-hexify-string
                         (replace-regexp-in-string
                          " " "-" (downcase title))))))))
	headlines)
       "\n"))))

(defvar ox-zenn-width-cookies nil)
(defvar ox-zenn-width-cookies-table nil)

(defun ox-zenn-table-col-width (table column info)
  "Return width of TABLE at given COLUMN.
INFO is a plist used as communication channel.
Width of a column is determined either by inquerying `ox-zenn-width-cookies'
in the column, or by the maximum cell with in the column."
  (let ((cookie (when (hash-table-p ox-zenn-width-cookies)
                  (gethash column ox-zenn-width-cookies))))
    (if (and (eq table ox-zenn-width-cookies-table)
             cookie)
        cookie
      (unless (and (eq table ox-zenn-width-cookies-table)
                   (hash-table-p ox-zenn-width-cookies))
        (setq ox-zenn-width-cookies (make-hash-table))
        (setq ox-zenn-width-cookies-table table))
      (let ((max-width 0)
            (specialp (org-export-table-has-special-column-p table)))
        (org-element-map table 'table-row
          (lambda (row)
            (setq max-width
                  (max max-width
                       (length
                        (org-export-data
                         (org-element-contents
                          (nth column
                               (if specialp
                                   (car (org-element-contents row))
                                 (org-element-contents row))))
                         info)))))
          info)
        (puthash column max-width ox-zenn-width-cookies)))))

(defun ox-zenn-table-cell (table-cell contents info)
  "Transcode TABLE-CELL element from Org into GFM.
CONTENTS is content of the cell.
INFO is a plist used as a communication channel."
  (let* ((table (org-export-get-parent-table table-cell))
         (column (cdr (org-export-table-cell-address table-cell info)))
         (width (ox-zenn-table-col-width table column info))
         (contents* (or contents "")))
    (concat
     (if (org-export-table-cell-starts-colgroup-p table-cell info) "| " " ")
     contents*
     (org-zenn--make-string (- width (string-width contents*)) " ")
     " |")))

(defun ox-zenn-table-row (table-row contents info)
  "Transcode TABLE-ROW element from Org into GFM.
CONTENTS is cell contents of TABLE-ROW.
INFO is a plist used as a communication channel."
  (let ((table (org-export-get-parent-table table-row)))
    (if (not (and (eq 'rule (org-element-property :type table-row))
                  ;; In GFM, rule is valid only at second row.
                  (= 1 (cl-position
                        table-row
                        (org-element-map table 'table-row 'identity info)))))
        contents
      (concat
       "| "
       (mapconcat
        (lambda (col)
          (let ((width (max 3 (ox-zenn-table-col-width table col info))))
            (make-string (if (< width 1) 1 width) ?-)))
        (number-sequence 0 (- (cdr (org-export-table-dimensions table info)) 1))
        " | ")
       " |"))))

(defun ox-zenn-table (_table contents _info)
  "Transcode TABLE element into Github Flavored Markdown table.
CONTENTS is the contents of the table.
INFO is a plist holding contextual information."
  (replace-regexp-in-string "\n\n" "\n" contents))

(defun org-zenn-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to HTML.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format "[^%d]" (org-export-get-footnote-number footnote-reference info)))

(defun org-zenn-footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (concat
   (mapconcat
    (lambda (definition)
      (pcase definition
        (`(,n ,_ ,def)
	 ;; `org-export-collect-footnote-definitions' can return
	 ;; two kinds of footnote definitions: inline and blocks.
	 ;; Since this should not make any difference in the HTML
	 ;; output, we wrap the inline definitions within
	 ;; a "footpara" class paragraph.
	 (format "[^%d]: %s" n (org-trim (org-export-data def info))))))
    (org-export-collect-footnote-definitions info)
    "\n")
   "\n"))

(defun org-zenn-inner-template (contents info)
  "Return body of document after converting it to Markdown syntax.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; Table of contents.
   (let ((depth (plist-get info :with-toc)))
     (when depth
       (concat (org-zenn-toc depth info) "\n\n")))

   ;; Document contents.
   contents

   ;; Footnotes section.
   (when (org-export-collect-footnote-definitions info)
     (concat
      "\n\n"
      (org-zenn-footnote-section info)))))

(defun org-zenn-template (contents info)
  "Add frontmatter in Zenn Flavoured Markdown format.
CONTENTS is GFM formart string, INFO is communication channel."
  (cl-flet ((strgen (key fmt &optional fn)
                    (let ((val (plist-get info key)))
                      (when (and val
                                 (if (stringp val)
                                     (not (string-empty-p val))
                                   t))
                        (format fmt (funcall (or fn 'identity) (plist-get info key)))))))
    (concat
     "---\n"
     ;; TODO: Currently, Zenn requires specifing only what it needs.
     ;; (strgen :gfm-layout "layout: %s\n")
     ;; (strgen :author "author: %s\n"
     ;;         (lambda (elm)
     ;;           (if (= 1 (length elm))
     ;;               (car elm)
     ;;             (format "[%s]" (string-join elm ", ")))))
     (strgen :title "title: \"%s\"\n" (lambda (elm) (car elm)))
     ;; (strgen :description "description: \"%s\"\n")
     ;; (strgen :gfm-category "category: %s\n")
     (strgen :gfm-tags "topics: [%s]\n"
             (lambda (elm) (string-join (split-string elm " " 'omit) ", ")))
     ;; (strgen :keywords "keywords: [%s]\n"
     ;;         (lambda (elm) (string-join (split-string elm " " 'omit) ", ")))
     ;; (strgen :date "date: %s\n"
     ;;         (lambda (elm)
     ;;           (let ((val (if (listp elm) (car elm) elm)))
     ;;             (if (eq 'timestamp (car-safe val))
     ;;                 (org-timestamp-format val org-zenn-date-format)
     ;;               (format-time-string org-zenn-date-format val)))))
     ;; (when (plist-get info :with-last-modified)
     ;;   (strgen :last-modified "last_modified: %s\n"
     ;;           (lambda (elm)
     ;;             (let ((val (if (listp elm) (car elm) elm)))
     ;;               (if (eq 'timestamp (car-safe val))
     ;;                   (org-timestamp-format val org-zenn-date-format)
     ;;                 (format-time-string org-zenn-date-format (date-to-time val)))))))
     (strgen :gfm-custom-front-matter
             "%s\n"
             (lambda (elm)
               (mapconcat
                (lambda (elm)
                  (format "%s: %s" (car elm) (cdr elm)))
                (org-zenn--parse-property-arguments elm)
                "\n")))
     "---\n"
     (or (strgen :gfm-preamble "%s\n") "\n")
     contents
     (strgen :gfm-postamble "\n\n%s\n"))))


;;; frontend

;;;###autoload
(defun org-zenn-export-as-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Zenn Flavored Markdown buffer.

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

Export is done in a buffer named \"*Org GFM Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'zennmd "*Org ZennMD Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-zenn-convert-region-to-md ()
  "Assume `org-mode' syntax, and convert it to Zenn Flavored Markdown.
This can be used in any buffer.  For example, you can write an
itemized list in `org-mode' syntax in a Markdown buffer and use
this command to convert it."
  (interactive)
  (org-export-replace-region-by 'zennmd))

;;;###autoload
(defun org-zenn-export-to-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Zenn Flavored Markdown file.

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
  (let ((outfile (org-export-output-file-name ".md" subtreep)))
    (org-export-to-file 'zennmd outfile async subtreep visible-only)))

;;;###autoload
(defun org-zenn-publish-to-markdown (plist filename pub-dir)
  "Publish an org file to Markdown.
FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.
Return output file name."
  (org-publish-org-to 'zennmd filename ".md" plist pub-dir))

(provide 'ox-zenn)

;;; ox-zenn.el ends here
