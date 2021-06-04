;;; ox-bb.el --- BBCode Back-End for Org Export Engine -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2021  Christian Garbs <mitch@cgarbs.de>
;; Licensed under GNU GPL v3 or later.

;; This file is part of ox-bb.

;; ox-bb is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ox-bb is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ox-bb.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Christian Garbs <mitch@cgarbs.de>
;; URL: https://github.com/mmitch/ox-bb
;; Package-Version: 20210222.2002
;; Package-Commit: 545d2e1547fdc48a5757152d19233effa11d9ee2
;; Keywords: bbcode, org, export, outlines
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (org "8.0"))

;;; Commentary:

;; This library implements a BBCode back-end for Org exporter.  Source
;; code snippets are exported for the GeSHi plugin.
;;
;; ox-bb provides three different commands for export:
;;
;; - `ox-bb-export-as-bbcode' exports to a buffer named "*Org BBCode
;;   Export*" and automatically applies `bbcode-mode' if it is
;;   available.
;;
;; - `ox-bb-export-to-kill-ring' does the same and additionally copies
;;   the exported buffer to the kill ring so that the generated BBCode
;;   is available in the Clipboard.
;;
;; - `ox-bb-export-to-bbcode' exports to a file with extension
;;   ".bbcode".

;;; Code:

(require 'ox)

;;; Backend definition

					; internal reminder: for Org format information see
					; https://orgmode.org/worg/dev/org-element-api.html

(org-export-define-backend 'bb
  '((bold . ox-bb-bold)
    (center-block . ox-bb-undefined)
    (clock . ox-bb-undefined)
    (code . ox-bb-code)
    (drawer . ox-bb-undefined)
    (dynamic-block . ox-bb-undefined)
    (entity . ox-bb-entity)
    (example-block . ox-bb-undefined)
    (export-block . ox-bb-undefined)
    (export-snippet . ox-bb-undefined)
    (fixed-width . ox-bb-fixed-width)
    (footnote-definition . ox-bb-footnote-definition)
    (footnote-reference . ox-bb-footnote-reference)
    (headline . ox-bb-headline)
    (horizontal-rule . ox-bb-undefined)
    (inline-src-block . ox-bb-undefined)
    (inlinetask . ox-bb-undefined)
    (inner-template . ox-bb-inner-template)
    (italic . ox-bb-italic)
    (item . ox-bb-item)
    ;; (keyword . ox-bb-undefined) ;; don't fail, just skip keywords
    (latex-environment . ox-bb-undefined)
    (latex-fragment . ox-bb-undefined)
    (line-break . ox-bb-line-break)
    (link . ox-bb-link)
    (node-property . ox-bb-undefined)
    (paragraph . ox-bb-paragraph)
    (plain-list . ox-bb-plain-list)
    (plain-text . ox-bb-plain-text)
    (planning . ox-bb-undefined)
    (property-drawer . ox-bb-undefined)
    (quote-block . ox-bb-quote-block)
    (radio-target . ox-bb-undefined)
    (section . ox-bb-section)
    (special-block . ox-bb-undefined)
    (src-block . ox-bb-geshi-block)
    (statistics-cookie . ox-bb-undefined)
    (strike-through . ox-bb-strike-through)
    (subscript . ox-bb-undefined)
    (superscript . ox-bb-undefined)
    (table . ox-bb-table)
    (table-cell . ox-bb-table-cell)
    (table-row . ox-bb-table-row)
    (target . ox-bb-undefined)
    (template . ox-bb-template)
    (timestamp . ox-bb-undefined)
    (underline . ox-bb-underline)
    (verbatim . ox-bb-verbatim)
    (verse-block . ox-bb-undefined))
  :menu-entry
  '(?b "Export to BBCode"
       ((?B "As BBCode buffer" ox-bb-export-as-bbcode)
	(?f "As BBCode file" ox-bb-export-to-bbcode)
	(?b "As BBCode buffer and to clipboard" ox-bb-export-to-kill-ring))))

;;; Helper methods

;; prevent bogus byte-compiler warning
(declare-function bbcode-mode "bbcode-mode" ())

(defun ox-bb--as-block (text)
  "Format TEXT as a block with leading and trailing newline."
  (concat "\n" text "\n"))

(defun ox-bb--force-leading-newline (text)
  "Make TEXT start with exactly one newline."
  (replace-regexp-in-string "\\`\n*" "\n" text))

(defun ox-bb--format-headline (text level)
  "Format TEXT as a headline of the given LEVEL."
  (let ((indent (cl-case level
		  (0 "")
		  (1 "# ")
		  (2 "== ")
		  (3 "+++ ")
		  (4 ":::: ")
		  (5 "----- ")
		  (t (user-error "Headline level `%s' is not defined yet" level)))))
    (concat
     (ox-bb--put-in-tag
      "b" (ox-bb--put-in-tag
	   "u" (concat indent text)))
     "\n\n")))

(defun ox-bb--put-in-tag (tag contents &optional attributes)
  "Puts the BBcode tag TAG around the CONTENTS string.
Optional ATTRIBUTES for the tag can be given as an alist of
key/value pairs (both strings)."
  (let ((attribute-string (if attributes
			      (mapconcat (function (lambda (attribute)
						     (let ((key (car attribute))
							   (value (cadr attribute)))
						       (format " %s=\"%s\"" key value))))
					 attributes
					 "")
			    "")))
    (format "[%s%s]%s[/%s]" tag attribute-string contents tag)))

(defun ox-bb--put-in-value-tag (tag contents value)
  "Puts the BBcode tag TAG around the CONTENTS string.
The VALUE is assigned directly to the tag instead of a normal
key/value pair."
  (format "[%s=%s]%s[/%s]" tag value contents tag))

(defun ox-bb--fix-url (url)
  "Fix URL returned from `url-encode-url'.
Older versions of Emacs (eg. 24.3 used in the Travis CI minimal
image) prepend \"/\" to urls consisting only of an \"#anchor\"
part.  We don't want this, because we need relative anchors.  Fix
this the hard way."
  (if (string-prefix-p "/#" url)
      (substring url 1)
    url))

(defun ox-bb--put-url (contents href)
  "Puts the CONTENTS inside a [url] tag pointing to HREF.
Automagically escapes the target URL."
  (let* ((target (ox-bb--fix-url (url-encode-url (org-link-unescape href))))
	 (text   (or contents target)))
    (ox-bb--put-in-value-tag "url" text target)))

(defun ox-bb--remove-leading-newline (text)
  "Remove a leading empty line from TEXT."
  (replace-regexp-in-string "\\`\n" "" text))

(defun ox-bb--remove-trailing-newline (text)
  "Remove the trailing newline from TEXT."
  (replace-regexp-in-string "\n\\'" "" text))

(defun ox-bb--map-to-geshi-language (language)
  "Map LANGUAGE from Org to GeSHi."
  (cond ((string= language "elisp") "lisp")
	((string= language "shell") "bash")
	((string= language "sh")    "bash")
	((string= language "") "plaintext")
	(language)
	(t "plaintext")))

;;; Backend callbacks

(defun ox-bb-bold (_bold contents _info)
  "Transcode a BOLD element from Org to BBCode.
CONTENTS is the bold text, as a string.  INFO is
  a plist used as a communication channel."
  (ox-bb--put-in-tag "b" contents))

(defun ox-bb-code (code _contents _info)
  "Transcode a CODE element from Org to BBCode.
CONTENTS is nil.  INFO is a plist used as a communication channel."
  (ox-bb--put-in-value-tag "font" (org-element-property :value code) "monospace"))

(defun ox-bb-entity (entity _contents _info)
  "Transcode an ENTITY element from Org to BBCode.
CONTENTS is the definition itself.  INFO is a plist used as a
communication channel."
  (org-element-property :html entity))

(defun ox-bb-geshi-block (code-block _contents info)
  "Transcode a CODE-BLOCK element from Org to BBCode GeSHi plugin.
CONTENTS is nil.  INFO is a plist holding
contextual information."
  (format "[geshi lang=%s]%s[/geshi]"
	  (ox-bb--map-to-geshi-language (org-element-property :language code-block))
	  (ox-bb--remove-trailing-newline
	   (org-export-format-code-default code-block info))))

(defun ox-bb-fixed-width (fixed-width _contents _info)
  "Transcode a FIXED-WIDTH element from Org to BBCode.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (ox-bb--put-in-tag "code"
		     (concat "\n" (org-element-property :value fixed-width))))

(defun ox-bb-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to BBCode.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (if (eq (org-element-property :type footnote-reference) 'inline)
      (user-error "Inline footnotes not supported yet")
    (let ((n (org-export-get-footnote-number footnote-reference info)))
      (format "^%d " n))))

(defun ox-bb-format-footnote-definition (fn)
  "Format the footnote definition FN."
  (let ((n (car fn))
	(def (cdr fn)))
    (format "^%d: %s" n def)))

(defun ox-bb-footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (let* ((org-major (string-to-number (car (split-string (org-release) "\\."))))
	 (fn-alist (if (> org-major 8)
		       (org-export-collect-footnote-definitions
			info (plist-get info :parse-tree))
		     (org-export-collect-footnote-definitions
		      (plist-get info :parse-tree) info)))
	 (fn-alist
	  (cl-loop for (n _label raw) in fn-alist collect
		   (cons n (org-trim (org-export-data raw info)))))
	 (text (mapconcat #'ox-bb-format-footnote-definition fn-alist "\n")))
    (if fn-alist
	(concat "\n" (ox-bb--format-headline "Footnotes" 0) text)
      "")))

(defun ox-bb-headline (headline contents info)
  "Transcode HEADLINE element from Org to BBCode.
CONTENTS is the headline contents.  INFO is a plist used as
a communication channel."
  (let ((title (org-export-data (org-element-property :title headline) info))
	(level (org-export-get-relative-level headline info)))
    (if (org-element-property :footnote-section-p headline)
	""
      (concat
       (ox-bb--format-headline title level)
       contents))))

(defun ox-bb-inner-template (contents info)
  "Return body of document string after BBCode conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   contents
   (ox-bb-footnote-section info)))

(defun ox-bb-italic (_italic contents _info)
  "Transcode a ITALIC element from Org to BBCode.
CONTENTS is the italic text, as a string.  INFO is
  a plist used as a communication channel."
  (ox-bb--put-in-tag "i" contents))

(defun ox-bb-item (item contents info)
  "Transcode a ITEM element from Org to BBCode.
CONTENTS is the contents of the item, as a string.  INFO is
  a plist used as a communication channel."
  (let* ((plain-list (org-export-get-parent item))
	 (type (org-element-property :type plain-list))
	 (text (org-trim contents)))
    (concat
     "[*]"
     (pcase type
       (`descriptive
	(let ((term (let ((tag (org-element-property :tag item)))
		      (and tag (org-export-data tag info)))))
	  (concat
	   (ox-bb--put-in-tag "i" (concat (org-trim term) ":"))
	   " "))))
     text
     "\n")))

(defun ox-bb-line-break (_line-break _contents _info)
  "Transcode a LINE-BREAK object from Org to BBCode.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  "[br]_[/br]\n")

(defun ox-bb-link (link contents _info)
  "Transcode a LINK element from Org to BBCode.
CONTENTS is the contents of the link, as a string.  INFO is
  a plist used as a communication channel."
  (let ((type (org-element-property :type link))
	(path (org-element-property :path link))
	(raw  (org-element-property :raw-link link)))
    (cond
     ((string= type "fuzzy")
      (cond
       ((string-prefix-p "about:" raw)
	(ox-bb--put-url contents raw))
       (t (user-error "Unknown fuzzy LINK type encountered: `%s'" raw))))
     ((member type '("http" "https"))
      (ox-bb--put-url contents (concat type ":" path)))
     (t (user-error "LINK type `%s' not yet supported" type)))))

(defun ox-bb-paragraph (_paragraph contents _info)
  "Transcode a PARAGRAPH element from Org to BBCode.
CONTENTS is the contents of the paragraph, as a string.  INFO is
  a plist used as a communication channel."
  (org-trim contents))

(defun ox-bb-plain-list (plain-list contents _info)
  "Transcode a PLAIN-LIST element from Org to BBCode.
CONTENTS is the contents of the plain-list, as a string.  INFO is
  a plist used as a communication channel."
  (let ((type (org-element-property :type plain-list))
	(content-block (ox-bb--as-block (org-trim contents))))
    (concat
     (pcase type
       (`descriptive (ox-bb--put-in-tag "list" content-block))
       (`unordered (ox-bb--put-in-tag "list" content-block))
       (`ordered (ox-bb--put-in-value-tag "list" content-block "1"))
       (other (user-error "PLAIN-LIST type `%s' not yet supported" other)))
     "\n")))

(defun ox-bb-plain-text (text _info)
  "Transcode a TEXT string from Org to BBCode.
INFO is a plist used as a communication channel."
  text)

(defun ox-bb-quote-block (_quote-block contents _info)
  "Transcode a QUOTE-BLOCK element from Org to BBCode.
CONTENTS holds the contents of the block.  INFO is a plist used
as a communication channel."
  (ox-bb--put-in-tag "quote" (ox-bb--force-leading-newline contents)))

(defun ox-bb-section (_section contents _info)
  "Transcode a SECTION element from Org to BBCode.
CONTENTS is the contents of the section, as a string.  INFO is a
  plist used as a communication channel."
  (org-trim contents))

(defun ox-bb-strike-through (_strike-through contents _info)
  "Transcode a STRIKE-THROUGH element from Org to BBCode.
CONTENTS is the text with strike-through markup, as a string.
  INFO is a plist used as a communication channel."
  (ox-bb--put-in-tag "s" contents))

(defun ox-bb-table (_table contents _info)
  "Transcode a TABLE element from Org to BBCode.
CONTENTS contains the already rendered body of the table.  INFO
is a plist used as a communication channel."
  (ox-bb--put-in-tag "table" contents))

(defun ox-bb-table-row (_table-row contents _info)
  "Transcode a TABLE-ROW element from Org to BBCode.
CONTENTS contains the already rendered row content.  INFO is a
plist used as a communication channel."
  (if contents
      (ox-bb--put-in-tag "tr" contents)
    ""))

(defun ox-bb-table-cell (_table-cell contents _info)
  "Transcode a TABLE-CELL element from Org to BBCode.
CONTENTS contains the already rendered cell content.  INFO is a
plist used as a communication channel."
  (ox-bb--put-in-tag "td" contents))

(defun ox-bb-template (contents _info)
  "Return complete document string after BBCode conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  contents)

(defun ox-bb-undefined (element &optional _contents _info)
  "Throw an error when an unsupported ELEMENT is encountered."
  (user-error "ELEMENT type `%s' not implemented yet" (car element)))

(defun ox-bb-underline (_underline contents _info)
  "Transcode a UNDERLINE element from Org to BBCode.
CONTENTS is the underlined text, as a string.  INFO is
  a plist used as a communication channel."
  (ox-bb--put-in-tag "u" contents))

(defun ox-bb-verbatim (verbatim _contents _info)
  "Transcode a VERBATIM element from Org to BBCode.
CONTENTS is nil.  INFO is a plist used as a communication channel."
  (ox-bb--put-in-value-tag "font" (org-element-property :value verbatim) "monospace"))

;;; Export methods

;;;###autoload
(defun ox-bb-export-as-bbcode
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a BBCode buffer.

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

TODO: document BODY-ONLY

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org BBCode Export*\".  If
available, `bbcode-mode' is enabled in the buffer."
  (interactive)
  (org-export-to-buffer 'bb "*Org BBCode Export*"
    async subtreep visible-only body-only ext-plist
    (lambda () (when (featurep 'bbcode-mode) (bbcode-mode)))))

;;;###autoload
(defun ox-bb-export-to-bbcode
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a BBCode file.

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

TODO: document BODY-ONLY

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension ".bbcode")
	 (file (org-export-output-file-name extension subtreep))
	 (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'bb file
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun ox-bb-export-to-kill-ring
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a BBCode buffer and kill ring.

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

TODO: document BODY-ONLY

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org BBCode Export*\" which is
automatically copied to the kill ring (Clipboard)."
  (interactive)
  (let ((oldval org-export-copy-to-kill-ring))
    (progn
      (setq org-export-copy-to-kill-ring t)
      (ox-bb-export-as-bbcode async subtreep visible-only body-only ext-plist)
      (setq org-export-copy-to-kill-ring oldval))))

;;; Register file

(provide 'ox-bb)

;;; ox-bb.el ends here
