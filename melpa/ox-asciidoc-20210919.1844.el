;;; ox-asciidoc.el --- AsciiDoc Back-End for Org Export Engine

;; Copyright (C) 2013  Free Software Foundation, Inc.

;; Author: Yasushi SHOJI <yasushi.shoji@gmail.com>
;; URL: https://github.com/yashi/org-asciidoc
;; Package-Version: 20210919.1844
;; Package-Commit: d60ac439278cec214882f92c47bc16e0f43ae98e
;; Package-Requires: ((org "8.1"))
;; Keywords: org, asciidoc

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements an AsciiDoc back-end for Org exporter.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-asciidoc-export-as-asciidoc' (temporary buffer) and
;; `org-asciidoc-export-to-asciidoc' (file).

;;; Code:
(require 'ox)
(require 'cl-lib)
(require 'ox-html)
(require 'ox-publish)

(defgroup org-export-asciidoc nil
  "Options for exporting Org mode files to Asciidoc."
  :tag "Org Export Asciidoc"
  :group 'org-export)

(org-export-define-backend 'asciidoc
  '((babel-call . org-asciidoc-identity)
    (bold . org-asciidoc-bold)
    (center-block . org-asciidoc-identity)
    (clock . org-asciidoc-identity)
    (code . org-asciidoc-code)
    (comment . (lambda (&rest args) ""))
    (comment-block . (lambda (&rest args) ""))
    (diary-sexp . org-asciidoc-identity)
    (drawer . (lambda (&rest args) ""))
    (dynamic-block . org-asciidoc-identity)
    (entity . org-asciidoc-identity)
    (example-block . org-asciidoc-example-block)
    (fixed-width . org-asciidoc-fixed-width)
    (footnote-definition . org-asciidoc-identity)
    (footnote-reference . org-asciidoc-footnote-reference)
    (headline . org-asciidoc-headline)
    (horizontal-rule . org-asciidoc-identity)
    (inline-babel-call . org-asciidoc-identity)
    (inline-src-block . org-asciidoc-identity)
    (inlinetask . org-asciidoc-identity)
    (italic . org-asciidoc-italic)
    (item . org-asciidoc-item)
    (keyword . (lambda (&rest args) ""))
    (latex-environment . org-asciidoc-identity)
    (latex-fragment . org-asciidoc-identity)
    (line-break . org-asciidoc-identity)
    (link . org-asciidoc-link)
    (node-property . org-asciidoc-identity)
    (paragraph . org-asciidoc-identity)
    (plain-list . org-asciidoc-plain-list)
    (plain-text . org-asciidoc-plain-text)
    (planning . org-asciidoc-identity)
    (property-drawer . (lambda (&rest args) ""))
    (quote-block . org-asciidoc-identity)
    (quote-section . org-asciidoc-identity)
    (radio-target . org-asciidoc-identity)
    (section . org-asciidoc-identity)
    (special-block . org-asciidoc-special-block)
    (src-block . org-asciidoc-src-block)
    (statistics-cookie . org-asciidoc-identity)
    (strike-through . org-asciidoc-strike-through)
    (subscript . org-asciidoc-identity)
    (superscript . org-asciidoc-identity)
    (table . org-asciidoc-table)
    (table-cell . org-asciidoc-table-cell)
    (table-row . org-asciidoc-table-row)
    (target . org-asciidoc-identity)
    (template . org-asciidoc-template)
    (timestamp . org-asciidoc-identity)
    (underline . org-asciidoc-underline)
    (verbatim . org-asciidoc-verbatim)
    (verse-block . org-asciidoc-identity))
  :options-alist
  '((:headline-levels nil nil 4 t)
    (:asciidoc-docinfo nil "asciidoc-docinfo" org-asciidoc-docinfo))
  :menu-entry
  '(?a "Export to Asciidoc"
       ((?a "As Asciidoc buffer"
	    (lambda (a s v b) (org-asciidoc-export-as-asciidoc a s v)))
	(?A "As Asciidoc file"
	    (lambda (a s v b) (org-asciidoc-export-to-asciidoc a s v)))
	(?o "As Asciidoc file and open"
	    (lambda (a s v b)
	      (if a (org-asciidoc-export-to-asciidoc t s v)
		(org-open-file (org-asciidoc-export-to-asciidoc nil s v))))))))

(defcustom org-asciidoc-docinfo nil
  "Whether to use ':docinfo:'"
  :group 'org-export-asciidoc
  :type 'boolean)

(defun org-asciidoc-identity (blob contents info)
  "Transcode BLOB element or object back into Org syntax.
CONTENTS is its contents, as a string or nil.  INFO is ignored."
  (org-export-expand blob contents))


;;; Inline Text Format
(defun org-asciidoc-bold (bold contents info)
  (concat "*" contents "*"))

(defun org-asciidoc-code (code contents info)
  (concat "`" (org-asciidoc-encode-plain-text (org-element-property :value code)) "`"))

(defun org-asciidoc-italic (italic contents info)
  (concat "_" contents "_"))

(defun org-asciidoc-strike-through (strike-through contents info)
  (concat "[line-through]#" contents "#"))

(defun org-asciidoc-underline (underline contents info)
  (concat "[underline]#" contents "#"))

(defun org-asciidoc-verbatim (verbatim contents info)
  (concat "`" (org-asciidoc-encode-plain-text (org-element-property :value verbatim)) "`"))


;;; Head Line
(defun org-asciidoc-headline (headline contents info)
  "Transcode HEADLINE element into AsciiDoc format.
CONTENTS is the headline contents."
  (if (org-element-property :footnote-section-p headline)
      ;; ignore the whole section
      nil
    (let* ((level (org-export-get-relative-level headline info))
           (title (org-export-data (org-element-property :title headline) info))
           (limit (plist-get info :headline-levels)))
      (if (org-export-low-level-p headline info)
          (concat (make-string (- level limit) ?*) " " title "\n" contents)
        (let ((delimiter (make-string (1+ level) ?=)))
          (concat "\n" delimiter " " title " " delimiter "\n" contents))))))


;;; Block helper
(defun org-asciidoc--get-block-title (block info)
  (let ((caption (org-export-get-caption block)))
    (when caption
      (concat "." (org-export-data caption info) "\n"))))


;;; List
(defun org-asciidoc-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST element into AsciiDoc format.
CONTENTS is the contents of the list.  INFO is a plist holding
contextual information."
  (let ((prev (org-export-get-previous-element plain-list info)))
    (concat
     (when (and prev
                (eq (org-element-type prev) 'paragraph)
                (not (eq (org-element-type (org-export-get-parent plain-list))
                         'item))
                (zerop (org-element-property :post-blank prev)))
       "\n")
     (when (and prev
                (eq (org-element-type prev) 'plain-list))
       "// ^\n\n")
     contents)))

(defun org-asciidoc-item-list-depth (item)
  (let ((parent item)
	(depth 0))
    (while (and (setq parent (org-export-get-parent parent))
		(cl-case (org-element-type parent)
		  (item t)
		  (plain-list (cl-incf depth)))))
    depth))

(defvar org-asciidoc-list-bullets
  '((unordered . ?*)
    (ordered . ?.)))

(defun org-asciidoc-list-item-delimiter (item)
  (let* ((plain-list (org-export-get-parent item))
	 (type (org-element-property :type plain-list))
	 (depth (org-asciidoc-item-list-depth item))
         (tag (let ((tag (org-element-property :tag item)))
                (and tag (org-export-data tag info))))
	 (bullet (cdr (assq type org-asciidoc-list-bullets))))
    (cond (bullet (make-string depth bullet))
          (tag (format "%s::" tag)))))

(defun org-asciidoc-item (item contents info)
  "Transcode an ITEM element into AsciiDoc format.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (let ((lines (split-string (replace-regexp-in-string "\n\\'" "" contents) "\n")))
    (format "%s %s"
            (org-asciidoc-list-item-delimiter item)
            (mapconcat (lambda (line)
                         (if (string= "" line) "+" line))
                       lines
                       "\n"))))


;;; Special Block
(defun org-asciidoc-special-block (special-block contents info)
  "Transcode a SPECIAL-BLOCK element into AsciiDoc format.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((contents (or contents ""))
         (type (org-element-property :type special-block))
         (caption (org-asciidoc--get-block-title special-block info)))
    (cond
     ((string= "sidebar" type)
      (concat
       (org-asciidoc--get-block-title special-block info)
       "****\n" contents "****"))
     (t
      contents))))


;;; Example Block
(defun org-asciidoc-example-block (example-block contents info)
  "Transcode a EXAMPLE-BLOCK element into AsciiDoc format.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((value (org-element-property :value example-block)))
    (concat
     (org-asciidoc--get-block-title example-block info)
     "....\n" value "....")))


;;; Source Block
(defun org-asciidoc-src-block (src-block contents info)
  "Transcode a SRC-BLOCK element into AsciiDoc format.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((value (org-element-property :value src-block))
        (lang (org-element-property :language src-block))
        (linum (if (org-element-property :number-lines src-block)
                   ",linenums" "")))
    (concat "[source," lang linum "]\n"
            (org-asciidoc--get-block-title src-block info)
            "----\n" value "----")))


;;; Fixed Width
(defun org-asciidoc-fixed-width (fixed-width contents info)
  (let ((value (org-element-property :value fixed-width)))
    (and value
         (concat "....\n" value "\n...."))))


;;; Plain Text
(defvar org-asciidoc-protect-char-alist
  '(("~" . "\\~"))
  "Alist of characters to be converted by `org-asciidoc-plain-text'.")

(defun org-asciidoc-encode-plain-text (text)
  (mapc
   (lambda (pair)
     (setq text (replace-regexp-in-string (car pair) (cdr pair) text t t)))
   org-asciidoc-protect-char-alist)
  text)

(defun org-asciidoc-plain-text (text info)
  "Transcode TEXT element into AsciiDoc format."
  (setq text (org-asciidoc-encode-plain-text text))
  text)


;;; Footnote
(defun org-asciidoc-footnote-reference (ref contents info)
  "Transcode a REF element from Org to AsciiDoc.  REF is a list
of footnote reference attributes.  CONTENTES is nil.  Info is a
plist holding contextual information."
  (let ((num (org-export-get-footnote-number ref info)))
    (cond
     ((org-export-footnote-first-reference-p ref info)
      (format "footnoteref:[%s, %s]" num
              (let ((def (org-export-get-footnote-definition ref info)))
                (org-trim (org-export-data def info)))))
     (t
      (format "footnoteref:[%s]" num)))))


;;; Table
(defvar org-asciidoc-table-width-in-percent 80)

(defun org-asciidoc-table (table contents info)
  "Transcode TABLE element into AsciiDoc format."
  (let* ((width (org-export-read-attribute :attr_asciidoc table :width))
         (cols (org-export-read-attribute :attr_asciidoc table :cols))
         (header (and (org-export-table-has-header-p table info) "header"))
         (pgwide (and (org-export-read-attribute :attr_asciidoc table :pgwide) "pgwide"))
         (options (remq nil (list header pgwide))))
    (concat (format "[width=\"%d%%\""
		    (or (and width (string-to-number width))
                        org-asciidoc-table-width-in-percent))
            (and cols
              (concat ",cols=\"" cols "\""))
            (and options
             (concat ",options=\""
                     (mapconcat 'identity options ",")
                     "\""))
            "]\n"
	    "|====\n"
	    contents
	    "|====")))

(defun org-asciidoc-table-row (table-row contents info)
  "Transcode TABLE ROW element into AsciiDoc format."
  (concat contents "\n"))

(defun org-asciidoc-table-cell (table-cell contents info)
  "Transcode TABLE CELL element into AsciiDoc format."
  (concat "| " contents))


;;; Link
(defun org-asciidoc-leading-slashp (str)
  (and (> (length str) 0) (eq (aref str 0) ?/)))

(defun org-asciidoc-link (link desc info)
  "Transcode a LINK object into AsciiDoc format.
DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.

Org's LINK object is documented in \"Hyperlinks\".

\"External Links\" are mostly converted to AsciiDoc's \"URL
Inline Macros\".

A relative path in the \"External Links\" with \"file\" schema is
converted to AsciiDoc's \"link\" inline macro. If the path does
not start with slash, we assume that the link is relative.

Image files without description should be inlined, so they will
be converted with AsciiDoc's image macro."
  (let ((type (org-element-property :type link))
	(path (org-element-property :path link)))
    (message (org-export-read-attribute :attr_asciidoc link))
    (cond
     ((and (not desc) (org-file-image-p path))
      (if (string= type "file")
          (if (org-html-standalone-image-p link info)
              (format "image::%s[scaledwidth=100%%]" path)
            (format "image:%s[]" path))
	(format "image:%s:%s[]" type path)))
     ((and (string= type "file") (not (org-asciidoc-leading-slashp path)))
      (format "link:%s[%s]" path (or desc path)))
     (t
      (format "%s:%s[%s]" type path (or desc (format "%s:%s" type path)))))))


;;; Template
(defun org-asciidoc-make-withkey (key)
  (intern (concat ":with-" (substring (symbol-name key) 1))))

(defun org-asciidoc-info-get-with (info key)
  "wrapper accessor to the communication channel.  Return the
  value if and only if \"with-key\" is set to t."
  (let ((withkey (org-asciidoc-make-withkey key)))
    (and withkey
	 (plist-get info withkey)
	 (org-export-data (plist-get info key) info))))

(defun org-asciidoc-info-get (info key)
  (org-export-data (plist-get info key) info))

(defun org-asciidoc-template--document-title (info)
  (let ((title (org-asciidoc-info-get info :title))
	(author (org-asciidoc-info-get-with info :author))
	(email (org-asciidoc-info-get-with info :email))
        (date (org-asciidoc-info-get-with info :date))
        (docinfo (plist-get info :asciidoc-docinfo)))
    (concat
     ;; The first line, title
     (format "= %s =\n" title)
     ;; The second line, name and email address "name <email@address>"
     ;; no email if no author
     (when (org-string-nw-p author)
       (concat author
               ;; Put email address
               (and (org-string-nw-p email) (concat " <" email ">"))
               "\n"))
     ;; The third line, rev number and date
     ;; (when date
     ;;   (concat date "\n"))
     (when (org-string-nw-p date)
       (concat date "\n"))
     ;; Add docinfo line if needed
     (when docinfo
       ":docinfo:\n")
     ;; add another new line for preamble
     "\n")))

(defun org-asciidoc-template (contents info)
  "Return complete document string after AsciiDoc conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; 1. Build title block.
   (org-asciidoc-template--document-title info)
   ;; 2. Body
   contents))


;;;###autoload
(defun org-asciidoc-export-as-asciidoc (&optional async subtreep visible-only)
  "Export current buffer to a buffer in Asciidoc format.

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

Export is done in a buffer named \"*Org ASCIIDOC Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'asciidoc "*Org ASCIIDOC Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-asciidoc-export-to-asciidoc (&optional async subtreep visible-only)
  "Export current buffer to a Asciidoc file.

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

Return output file name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".txt" subtreep)))
    (org-export-to-file 'asciidoc outfile async subtreep visible-only)))

;;;###autoload
(defun org-asciidoc-publish-to-asciidoc (plist filename pub-dir)
  "Publish an org file to Asciidoc.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'asciidoc filename ".txt" plist pub-dir))

(provide 'ox-asciidoc)

;;; ox-asciidoc.el ends here
