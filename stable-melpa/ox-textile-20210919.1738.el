;;; ox-textile.el --- Textile Back-End for Org Export Engine

;; Copyright (C) 2013  Yasushi SHOJI

;; Author: Yasushi SHOJI <yasushi.shoji@gmail.com>
;; URL: https://github.com/yashi/org-textile
;; Package-Version: 20210919.1738
;; Package-Commit: 5f2f61f572c24d702e922845c11a4c3da38ab261
;; Package-Requires: ((org "8.1"))
;; Keywords: org, textile

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

;; This library implements a textile back-end for Org exporter.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-textile-export-as-textile' (temporary buffer) and
;; `org-textile-export-to-textile' (file).

;;; Code:
(require 'ox)
(require 'ox-publish)

(defgroup org-export-textile nil
  "Options for exporting Org mode files to Textile."
  :tag "Org Export Textile"
  :group 'org-export)

(org-export-define-backend 'textile
  '((babel-call . org-textile-identity)
    (bold . org-textile-bold)
    (center-block . org-textile-identity)
    (clock . org-textile-identity)
    (code . org-textile-verbatim)
    (comment . (lambda (&rest args) ""))
    (comment-block . (lambda (&rest args) ""))
    (diary-sexp . org-textile-identity)
    (drawer . (lambda (&rest args) ""))
    (dynamic-block . org-textile-identity)
    (entity . org-textile-identity)
    (example-block . org-textile-example-block)
    (fixed-width . org-textile-identity)
    (footnote-definition . org-textile-identity)
    (footnote-reference . org-textile-identity)
    (headline . org-textile-headline)
    (horizontal-rule . org-textile-identity)
    (inline-babel-call . org-textile-identity)
    (inline-src-block . org-textile-identity)
    (inlinetask . org-textile-identity)
    (italic . org-textile-italic)
    (item . org-textile-item)
    (keyword . (lambda (&rest args) ""))
    (latex-environment . org-textile-identity)
    (latex-fragment . org-textile-identity)
    (line-break . org-textile-identity)
    (link . org-textile-link)
    (node-property . org-textile-identity)
    (paragraph . org-textile-identity)
    (plain-list . org-textile-plain-list)
    (planning . org-textile-identity)
    (property-drawer . (lambda (&rest args) ""))
    (quote-block . org-textile-identity)
    (quote-section . org-textile-identity)
    (radio-target . org-textile-identity)
    (section . org-textile-identity)
    (special-block . org-textile-identity)
    (src-block . org-textile-identity)
    (statistics-cookie . org-textile-identity)
    (strike-through . org-textile-strike-through)
    (subscript . org-textile-identity)
    (superscript . org-textile-identity)
    (table . org-textile-table)
    (table-cell . org-textile-table-cell)
    (table-row . org-textile-table-row)
    (target . org-textile-identity)
    (template . org-textile-template)
    (timestamp . org-textile-identity)
    (underline . org-textile-identity)
    (verbatim . org-textile-verbatim)
    (verse-block . org-textile-identity))
  :options-alist '((:headline-levels nil nil 5 t))
  :menu-entry
  '(?x "Export to Textile"
       ((?x "As Textile buffer"
	    (lambda (a s v b) (org-textile-export-as-textile a s v)))
	(?X "As Textile file"
	    (lambda (a s v b) (org-textile-export-to-textile a s v)))
	(?o "As Textile file and open"
	    (lambda (a s v b)
	      (if a (org-textile-export-to-textile t s v)
		(org-open-file (org-textile-export-to-textile nil s v))))))))

(defcustom org-textile-use-thead t
  "Whether to use <thead> constructs `|^.' and `|-.'"
  :group 'org-export-textile
  :type 'boolean)

(defcustom org-textile-extension ".txt"
  "The extension used in file output"
  :group 'org-export-textile
  :type 'string)

(defsubst org-textile-trim (s &optional keep-lead)
  "This function is, shamelessly, a copy of org-trim taken from
Org version 9.0.  This function is to support Org v8.1, which has
the same function without optional `keep-lead` argument."
  (replace-regexp-in-string
   (if keep-lead "\\`\\([ \t]*\n\\)+" "\\`[ \t\n\r]+") ""
   (replace-regexp-in-string "[ \t\n\r]+\\'" "" s)))

(defun org-textile-identity (blob contents info)
  "Transcode BLOB element or object back into Org syntax.
CONTENTS is its contents, as a string or nil.  INFO is ignored."
  (org-export-expand blob contents))


;;; Inline Text Format
(defun org-textile-bold (bold contents info)
  (concat "*" contents "*"))

(defun org-textile-italic (italic contents info)
  (concat "__" contents "__"))

(defun org-textile-verbatim (code contents info)
  (concat "@" (org-element-property :value code) "@"))

(defun org-textile-strike-through (strike-through contents info)
  (concat "-" contents "-"))


;;; Head Line
(defun org-textile-headline (headline contents info)
  "Transcode HEADLINE element into Textile format.
CONTENTS is the headline contents."
  (let* ((level (org-export-get-relative-level headline info))
	 (title (org-export-data (org-element-property :title headline) info))
	 (limit (plist-get info :headline-levels)))
    (if (org-export-low-level-p headline info)
	(concat (make-string (- level limit) ?*) " " title "\n" contents)
      (concat "\nh" (number-to-string (1+ level)) ". " title "\n\n" contents))))


;;; List
(defun org-textile-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST element into Textile format.
CONTENTS is the contents of the list.  INFO is a plist holding
contextual information."
  (replace-regexp-in-string "\n\n" "\n" contents))

(defun org-textile-item-list-depth (item info)
  (let* ((headline (org-export-get-parent-headline item))
	 (parent item)
	 (depth (or (and headline
		     (org-export-low-level-p headline info))
		0 )))
    (while (and (setq parent (org-export-get-parent parent))
		(cl-case (org-element-type parent)
		  (item t)
		  (plain-list (cl-incf depth)))))
    depth))

(defvar org-textile-list-bullets
  '((unordered . ?*)
    (ordered . ?#)
    (descriptive . ?-)))

(defun org-textile-list-item-delimiter (type item info)
  (let ((depth (org-textile-item-list-depth item info))
	(bullet (cdr (assq type org-textile-list-bullets))))
    (when bullet
     (make-string depth bullet))))

(defun org-textile-item (item contents info)
  "Transcode an ITEM element into Textile format.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (let* ((plain-list (org-export-get-parent item))
         (type (org-element-property :type plain-list))
         (delim (org-textile-list-item-delimiter type item info)))
    (pcase type
      (`descriptive
       (format "%s %s :=%s"
               delim
               (org-export-data (org-element-property :tag item) info)
               (concat (if (string-match-p "\n" (org-textile-trim contents t)) "\n" " ")
                       contents)))
      (_
       (format "%s %s" delim contents)))))


;;; Example Block
(defun org-textile-example-block (example-block contents info)
  "Transcode a EXAMPLE-BLOCK element into Textile format.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((value (org-element-property :value example-block)))
    (concat "bc.. " value "\np. <!-- protecting the space after the dot -->")))


;;; Table
(defun org-textile-table (table contents info)
  "Transcode TABLE element into Textile format."
  (let ((has-header (org-export-table-has-header-p table info)))
    (concat contents)))

(defun org-textile-table-row (table-row contents info)
  "Transcode TABLE ROW element into Textile format."
  (let ((header-start (org-export-table-row-starts-header-p table-row info))
        (header-end (org-export-table-row-ends-header-p table-row info)))
    (when contents
     (concat
      (if header-start
          (concat
           (when org-textile-use-thead "|^.\n")
           (replace-regexp-in-string "|" "|_." contents))
        contents)
      " |\n"
      (when (and header-end org-textile-use-thead)
          "|-.\n")))))

(defun org-textile-table-cell (table-cell contents info)
  "Transcode TABLE CELL element into Textile format."
  (let ((first-col-p (= 0 (cdr (org-export-table-cell-address table-cell info)))))
    (format (concat (if first-col-p "" " ") "| %s")  (or contents ""))))


;;; Link
(defun org-textile-link (link desc info)
  "Transcode a LINK object into Textile format.
DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.

Org's LINK object is documented in \"Hyperlinks\"."
  (let ((type (org-element-property :type link))
	(path (org-element-property :path link)))
    (cond
     ((and (not desc) (org-file-image-p path))
      (format "!%s!" path))
     ((and (string= type "file"))
      (format "!%s(%s)!" path (or desc path)))
     (t
      (format "\"%s\":%s:%s" (or desc (format "%s:%s" type path)) type path)))))


;;; Template
(defun org-textile-make-withkey (key)
  (intern (concat ":with-" (substring (symbol-name key) 1))))

(defun org-textile-info-get-with (info key)
  "wrapper accessor to the communication channel.  Return the
  value if and only if \"with-key\" is set to t."
  (let ((withkey (org-textile-make-withkey key)))
    (and withkey
	 (plist-get info withkey)
	 (org-export-data (plist-get info key) info))))

(defun org-textile-info-get (info key)
  (org-export-data (plist-get info key) info))

(defun org-textile-template--document-title (info)
  (let ((title (org-textile-info-get info :title))
	(author (org-textile-info-get-with info :author))
	(email (org-textile-info-get-with info :email)))
    (concat
     ;; The first line, title
     (format "h1. %s\n\n" title)
     ;; The second line, name and email address "name <email@address>"
     ;; no email if no author
     (when author
       (concat
	"\n"
	author
	;; Put email address
	(and email (format " <%s>" email))
	"\n"))
     ;; add some new lines for preamble
     "\n\n")))

(defun org-textile-template (contents info)
  "Return complete document string after Textile conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; 1. Build title block.
   (org-textile-template--document-title info)
   ;; 2. Body
   contents))


;;;###autoload
(defun org-textile-export-as-textile (&optional async subtreep visible-only)
  "Export current buffer to a buffer in Textile format.

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

Export is done in a buffer named \"*Org TEXTILE Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'textile "*Org TEXTILE Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-textile-export-to-textile (&optional async subtreep visible-only)
  "Export current buffer to a Textile file.

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
  (let ((outfile (org-export-output-file-name org-textile-extension subtreep)))
    (org-export-to-file 'textile outfile async subtreep visible-only)))

;;;###autoload
(defun org-textile-publish-to-textile (plist filename pub-dir)
  "Publish an org file to Textile.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'textile filename org-textile-extension plist pub-dir))

(provide 'ox-textile)

;;; ox-textile.el ends here
