;;; ox-pukiwiki.el --- Pukiwiki Back-End for Org Export Engine

;; Copyright (C) 2013  Free Software Foundation, Inc.

;; Author: Yasushi SHOJI <yasushi.shoji@gmail.com>
;; URL: https://github.com/yashi/org-pukiwiki
;; Package-Version: 20150124.1716
;; Package-Commit: b53920abf698fa6682623d671108393e92c68bd7
;; Package-Requires: ((org "8.1"))
;; Keywords: org, pukiwiki

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

;; This library implements an Pukiwiki back-end for Org exporter.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-pukiwiki-export-as-pukiwiki' (temporary buffer) and
;; `org-pukiwiki-export-to-pukiwiki' (file).

;;; Code:
(require 'ox)
(require 'cl-lib)

(defgroup org-export-pukiwiki nil
  "Options for exporting Org mode files to Pukiwiki."
  :tag "Org Export Pukiwiki"
  :group 'org-export)

(org-export-define-backend 'pukiwiki
  '((babel-call . org-pukiwiki-identity)
    (bold . org-pukiwiki-bold)
    (center-block . org-pukiwiki-identity)
    (clock . org-pukiwiki-identity)
    (code . org-pukiwiki-code)
    (comment . org-pukiwiki-comment)
    (comment-block . (lambda (&rest args) ""))
    (diary-sexp . org-pukiwiki-identity)
    (drawer . (lambda (&rest args) ""))
    (dynamic-block . org-pukiwiki-identity)
    (entity . org-pukiwiki-identity)
    (example-block . org-pukiwiki-example-block)
    (fixed-width . org-pukiwiki-identity)
    (footnote-definition . org-pukiwiki-identity)
    (footnote-reference . org-pukiwiki-identity)
    (headline . org-pukiwiki-headline)
    (horizontal-rule . org-pukiwiki-identity)
    (inline-babel-call . org-pukiwiki-identity)
    (inline-src-block . org-pukiwiki-identity)
    (inlinetask . org-pukiwiki-identity)
    (italic . org-pukiwiki-italic)
    (item . org-pukiwiki-item)
    (keyword . org-pukiwiki-keyword)
    (latex-environment . org-pukiwiki-identity)
    (latex-fragment . org-pukiwiki-identity)
    (line-break . org-pukiwiki-identity)
    (link . org-pukiwiki-link)
    (node-property . org-pukiwiki-identity)
    (paragraph . org-pukiwiki-identity)
    (plain-list . org-pukiwiki-plain-list)
    (planning . org-pukiwiki-identity)
    (property-drawer . (lambda (&rest args) ""))
    (quote-block . org-pukiwiki-identity)
    (quote-section . org-pukiwiki-identity)
    (radio-target . org-pukiwiki-identity)
    (section . org-pukiwiki-identity)
    (special-block . org-pukiwiki-identity)
    (src-block . org-pukiwiki-identity)
    (statistics-cookie . org-pukiwiki-identity)
    (strike-through . org-pukiwiki-strike-through)
    (subscript . org-pukiwiki-identity)
    (superscript . org-pukiwiki-identity)
    (table . org-pukiwiki-table)
    (table-cell . org-pukiwiki-table-cell)
    (table-row . org-pukiwiki-table-row)
    (target . org-pukiwiki-identity)
    (timestamp . org-pukiwiki-identity)
    (underline . org-pukiwiki-underline)
    (verbatim . org-pukiwiki-verbatim)
    (verse-block . org-pukiwiki-identity))
  :menu-entry
  '(?p "Export to Pukiwiki"
       ((?p "As Pukiwiki buffer"
	    (lambda (a s v b) (org-pukiwiki-export-as-pukiwiki a s v)))
	(?P "As Pukiwiki file"
	    (lambda (a s v b) (org-pukiwiki-export-to-pukiwiki a s v)))
	(?o "As Pukiwiki file and open"
	    (lambda (a s v b)
	      (if a (org-pukiwiki-export-to-pukiwiki t s v)
		(org-open-file (org-pukiwiki-export-to-pukiwiki nil s v))))))))

(defun org-pukiwiki-identity (blob contents info)
  "Transcode BLOB element or object back into Org syntax.
CONTENTS is its contents, as a string or nil.  INFO is ignored."
  (org-export-expand blob contents))


;;; Inline Text Format
(defun org-pukiwiki-bold (bold contents info)
  (concat "''" contents "''"))

(defun org-pukiwiki-code (code contents info)
  (org-element-property :value code))

(defun org-pukiwiki-italic (italic contents info)
  (concat "'''" contents "'''"))

(defun org-pukiwiki-strike-through (strike-through contents info)
  (concat "%%" contents "%%"))

(defun org-pukiwiki-underline (underline contents info)
  (concat "%%%" contents "%%%"))

(defun org-pukiwiki-verbatim (verbatim contents info)
  (org-element-property :value verbatim))


;;; List
(defvar org-pukiwiki-list-bullets
  '((unordered . ?-)
    (ordered . ?+)))

(defun org-pukiwiki-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST element into Pukiwiki format.
CONTENTS is the contents of the list.  INFO is a plist holding
contextual information."
  contents)

(defun org-pukiwiki-item-list-depth (item)
  (let ((parent item)
	(depth 0))
    (while (and (setq parent (org-export-get-parent parent))
		(cl-case (org-element-type parent)
		  (item t)
		  (plain-list (cl-incf depth)))))
    depth))

(defun org-pukiwiki-list-item-delimiter (item)
  (let* ((plain-list (org-export-get-parent item))
	 (type (org-element-property :type plain-list))
	 (depth (org-pukiwiki-item-list-depth item))
	 (bullet (cdr (assq type org-pukiwiki-list-bullets))))
    (when bullet
     (make-string depth bullet))))

(defun org-pukiwiki-item (item contents info)
  "Transcode an ITEM element into Pukiwiki format.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (format "%s %s" (org-pukiwiki-list-item-delimiter item) contents))

;;; Headline
(defun org-pukiwiki-headline (headline contents info)
  "Transcode HEADLINE element into Pukiwiki format.
CONTENTS is the headline contents."
  (let* ((level (org-export-get-relative-level headline info))
	 (title (org-export-data (org-element-property :title headline) info))
	 (limit (plist-get info :headline-levels)))
    (if (org-export-low-level-p headline info)
	(concat (make-string (- level limit) ?-) " " title "\n" contents)
      (concat "\n" (make-string level ?*) " " title "\n" contents))))


(defun org-pukiwiki-keyword (keyword contents info)
  "Transcode KEYWORD element into Pukiwiki format."
  (unless (member (org-element-property :key keyword)
		  (mapcar
		   (lambda (block-cons)
		     (and (eq (cdr block-cons) 'org-element-export-block-parser)
			  (car block-cons)))
		   org-element-block-name-alist))
    (org-element-keyword-interpreter keyword nil)))

(defvar ox-puki-a 0)
(defvar ox-puki-row 0)
(defvar ox-puki-cell 0)
(defvar ox-puki-header nil)

(defun org-pukiwiki-table (keyword contents info)
  "Transcode TABLE element into Pukiwiki format."
  (setq ox-puki-a (1+ ox-puki-a))
  contents)

(defun org-pukiwiki-table-row (keyword contents info)
  "Transcode TABLE ROW element into Pukiwiki format."
  (setq ox-puki-row (1+ ox-puki-row))
  ;; pukiwiki does not support holizontal separator, ignore it
  (when contents
    (if (org-export-table-row-ends-header-p keyword info)
	(concat contents " |h")
      (concat contents " |"))))

(defun org-pukiwiki-table-cell (keyword contents info)
  "Transcode TABLE CELL element into Pukiwiki format."
  (setq ox-puki-cell (1+ ox-puki-cell))
  (concat "| " contents " "))


;;; Example Block
(defun org-pukiwiki-example-block (example-block contents info)
  "Transcode a EXAMPLE-BLOCK element into Pukiwiki format.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((value (org-element-property :value example-block)))
    (concat " " (replace-regexp-in-string "\n" "\n " value))))


;;; Comment
(defun org-pukiwiki-comment (comment contents info)
  "Transcode a COMMENT element into Pukiwiki format.
CONTENS is the text in the comment.  INFO is a plist hodling
contextual information."
  (with-temp-buffer
    (insert (org-element-property :value comment))
    (goto-char (point-min))
    (while (not (eobp))
      (insert "// ")
      (forward-line))
    (buffer-string)))


;;; Links
(defun org-pukiwiki-link (link desc info)
  "Transcode a LINK object into Pukiwiki format.
DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.

Org's LINK object is documented in \"Hyperlinks\"."
  (let ((type (org-element-property :type link))
        (path (org-element-property :path link)))
    (when (string= type "fuzzy")
      (setq type nil))
    (concat "[["
            (when desc (concat desc ">"))
            (when type (concat type ":"))
            path
            "]]")))

;;;###autoload
(defun org-pukiwiki-export-as-pukiwiki (&optional async subtreep visible-only)
  "Export current buffer to a buffer in Pukiwiki format.

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

Export is done in a buffer named \"*Org PUKIWIKI Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'pukiwiki "*Org PUKIWIKI Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-pukiwiki-export-to-pukiwiki (&optional async subtreep visible-only)
  "Export current buffer to a Pukiwiki file.

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
    (org-export-to-file 'pukiwiki outfile async subtreep visible-only)))

(provide 'ox-pukiwiki)

;;; ox-pukiwiki.el ends here
