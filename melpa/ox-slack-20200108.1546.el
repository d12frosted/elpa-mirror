;;; ox-slack.el --- Slack Exporter for org-mode -*- lexical-binding: t; -*-


;; Copyright (C) 2018 Matt Price

;; Author: Matt Price
;; Keywords: org, slack, outlines
;; Package-Commit: bd797dcc58851d5051dc3516c317706967a44721
;; Package-Version: 20200108.1546
;; Package-X-Original-Version: 0.1.1
;; Package-Requires: ((emacs "24") (org "9.1.4") (ox-gfm "1.0"))
;; URL: https://github.com/titaniumbones/ox-slack

;; This file is not part of GNU Emacs.

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

;; This library implements a Slack backend for the Org
;; exporter, based on the `md' and `gfm' back-ends.

;;; Code:

(require 'ox-gfm)

(org-export-define-derived-backend 'slack 'gfm
  ;; for now, I just have this commented out
  ;; might be better to create a defcustom to
  ;; decide whether to add this to the export dispatcher
  ;; :menu-entry
  ;; '(?s "Export to Slack syntax"
  ;;      ((?s "To temporary buffer"
  ;;           (lambda (a s v b) (org-slack-export-as-slack a s v)))
  ;;       (?S "To file" (lambda (a s v b) (org-slack-export-to-slack a s v)))
  ;;       (?o "To file and open"
  ;;           (lambda (a s v b)
  ;;             (if a (org-slack-export-to-slack t s v)
  ;;               (org-open-file (org-slack-export-to-slack nil s v)))))))
  :translate-alist
  '(
    (bold . org-slack-bold)
    (code . org-slack-code)
    (headline . org-slack-headline)
    (inner-template . org-slack-inner-template)
    (italic . org-slack-italic)
    (link . org-slack-link)
    (plain-text . org-slack-plain-text)
    (src-block . org-slack-src-block)
    (strike-through . org-slack-strike-through)
    (timestamp . org-slack-timestamp)))

;; timestamp
(defun org-slack-timestamp (timestamp contents info)
  "Transcode TIMESTAMP element into Slack format.
CONTENTS is the timestamp contents. INFO is a plist used as a
ocmmunications channel."
  (org-html-plain-text (org-timestamp-translate timestamp) info))

;; headline
(defun org-slack-headline (headline contents info)
  "Transcode HEADLINE element into Markdown format.
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
                             (concat "     " (org-make-tag-string tag-list))))))
           (priority
            (and (plist-get info :with-priority)
                 (let ((char (org-element-property :priority headline)))
                   (and char (format "[#%c] " char)))))
           ;; Headline text without tags.
           (heading (concat todo priority title)))
      (format "*%s*\n\n%s" title contents)
      )))

;; link
(defun org-slack-link (link contents info)
  "Transcode LINK object into Markdown format.
  CONTENTS is the link's description.  INFO is a plist used as
  a communication channel."
  (let ((link-org-files-as-md
         (lambda (raw-path)
           ;; Treat links to `file.org' as links to `file.md'.
           (if (string= ".org" (downcase (file-name-extension raw-path ".")))
               (concat (file-name-sans-extension raw-path) ".md")
             raw-path)))
        (type (org-element-property :type link)))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link contents 'md))
     ((member type '("custom-id" "id" "fuzzy"))
      (let ((destination (if (string= type "fuzzy")
                             (org-export-resolve-fuzzy-link link info)
                           (org-export-resolve-id-link link info))))
        (pcase (org-element-type destination)
          (`plain-text			; External file.
           (let ((path (funcall link-org-files-as-md destination)))
             (if (not contents) (format "%s>" path)
               (format "[%s](%s)" contents path))))
          (`headline
           (format
            ;; "[%s](#%s)"
            "[%s]"
            ;; Description.
            (cond ((org-string-nw-p contents))
                  ((org-export-numbered-headline-p destination info)
                   (mapconcat #'number-to-string
                              (org-export-get-headline-number destination info)
                              "."))
                  (t (org-export-data (org-element-property :title destination)
                                      info)))
            ;; Reference.
            ;; (or (org-element-property :CUSTOM_ID destination)
            ;;     (org-export-get-reference destination info))
            ))
          (_
           (let ((description
                  (or (org-string-nw-p contents)
                      (let ((number (org-export-get-ordinal destination info)))
                        (cond
                         ((not number) nil)
                         ((atom number) (number-to-string number))
                         (t (mapconcat #'number-to-string number ".")))))))
             (when description
               (format "[%s]"
                       description
                       ;; (org-export-get-reference destination info)
                       )))))))
     ((org-export-inline-image-p link org-html-inline-image-rules)
      (let ((path (let ((raw-path (org-element-property :path link)))
                    (cond ((not (equal "file" type)) (concat type ":" raw-path))
                          ((not (file-name-absolute-p raw-path)) raw-path)
                          (t (expand-file-name raw-path)))))
            (caption (org-export-data
                      (org-export-get-caption
                       (org-export-get-parent-element link)) info)))
        (format "![img](%s)"
                (if (not (org-string-nw-p caption)) path
                  (format "%s \"%s\"" path caption)))))
     ((string= type "coderef")
      (let ((ref (org-element-property :path link)))
        (format (org-export-get-coderef-format ref contents)
                (org-export-resolve-coderef ref info))))
     ((equal type "radio") contents)
     (t (let* ((raw-path (org-element-property :path link))
               (path
                (cond
                 ((member type '("http" "https" "ftp" "mailto"))
                  (concat type ":" raw-path))
                 ((string= type "file")
                  (org-export-file-uri (funcall link-org-files-as-md raw-path)))
                 (t raw-path))))
          (if (not contents) (format "%s" path)
            (format "*%s* (%s)" contents path)))))))

(defun org-slack-verbatim (_verbatim contents _info)
  "Transcode VERBATIM from Org to Slack.
  CONTENTS is the text with bold markup. INFO is a plist holding
  contextual information."
  (format "`%s`" contents))

(defun org-slack-code (code _contents info)
  "Return a CODE object from Org to SLACK.
  CONTENTS is nil.  INFO is a plist holding contextual
  information."
  (format "`%s`"
          (org-element-property :value code)))

  ;;;; Italic

(defun org-slack-italic (_italic contents _info)
  "Transcode italic from Org to SLACK.
  CONTENTS is the text with italic markup.  INFO is a plist holding
  contextual information."
  (format "_%s_" contents))

  ;;; Bold
(defun org-slack-bold (_bold contents _info)
  "Transcode bold from Org to SLACK.
  CONTENTS is the text with bold markup.  INFO is a plist holding
  contextual information."
  (format "*%s*" contents))


;;;; Strike-through
(defun org-slack-strike-through (_strike-through contents _info)
  "Transcode STRIKE-THROUGH from Org to SLACK.
  CONTENTS is text with strike-through markup.  INFO is a plist
  holding contextual information."
  (format "~%s~" contents))


(defun org-slack-inline-src-block (inline-src-block _contents info)
  "Transcode an INLINE-SRC-BLOCK element from Org to SLACK.
  CONTENTS holds the contents of the item.  INFO is a plist holding
  contextual information."
  (format "`%s`"
          (org-element-property :value inline-src-block)))

;;;; Src Block
(defun org-slack-src-block (src-block contents info)
  "Transcode SRC-BLOCK element into Github Flavored Markdown format.
  CONTENTS is nil. INFO is a plist used as a communication
  channel."
  (let* ((lang (org-element-property :language src-block))
         (code (org-export-format-code-default src-block info))
         (prefix (concat "```"  "\n"))
         (suffix "```"))
    (concat prefix code suffix)))

;;;; Quote Block
(defun org-slack-quote-block (_quote-block contents info)
  "Transcode a QUOTE-BLOCK element from Org to SLACK.
  CONTENTS holds the contents of the block.  INFO is a plist
  holding contextual information."
  (org-slack--indent-string contents (plist-get info :slack-quote-margin)))


(defun org-slack-inner-template (contents info)
  "Return body of document after converting it to Markdown syntax.
  CONTENTS is the transcoded contents string.  INFO is a plist
  holding export options."
  ;; Make sure CONTENTS is separated from table of contents and
  ;; footnotes with at least a blank line.
  (concat
   ;; Table of contents.
   ;; (let ((depth (plist-get info :with-toc)))
   ;;   (when depth
   ;;     (concat (org-md--build-toc info (and (wholenump depth) depth)) "\n")))
   ;; Document contents.
   contents
   "\n"
   ;; Footnotes section.
   (org-md--footnote-section info)))

;;;; Plain text
(defun org-slack-plain-text (text info)
  "Transcode a TEXT string into Markdown format.
  TEXT is the string to transcode.  INFO is a plist holding
  contextual information."
  ;; (when (plist-get info :with-smart-quotes)
  ;;   (setq text (org-export-activate-smart-quotes text :html info)))
  ;; The below series of replacements in `text' is order sensitive.
  ;; Protect `, *, _, and \
  ;; (setq text (replace-regexp-in-string "[`*_\\]" "\\\\\\&" text))
  ;; Protect ambiguous #.  This will protect # at the beginning of
  ;; a line, but not at the beginning of a paragraph.  See
  ;; `org-md-paragraph'.
  (setq text (replace-regexp-in-string "\n#" "\n\\\\#" text))
  ;; Protect ambiguous !
  (setq text (replace-regexp-in-string "\\(!\\)\\[" "\\\\!" text nil nil 1))
  ;; ;; Handle special strings, if required.
  ;; (when (plist-get info :with-special-strings)
  ;;   (setq text (org-html-convert-special-strings text)))
  ;; Handle break preservation, if required.
  (when (plist-get info :preserve-breaks)
    (setq text (replace-regexp-in-string "[ \t]*\n" "  \n" text)))
  ;; Return value.
  text)

;;; End-user functions

;;;###autoload
(defun org-slack-export-as-slack
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a text buffer.

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

  When optional argument BODY-ONLY is non-nil, strip title and
  table of contents from output.

  EXT-PLIST, when provided, is a property list with external
  parameters overriding Org default settings, but still inferior to
  file-local settings.

  Export is done in a buffer named \"*Org SLACK Export*\", which
  will be displayed when `org-export-show-temporary-export-buffer'
  is non-nil."
  (interactive)
  (org-export-to-buffer 'slack "*Org SLACK Export*"
    async subtreep visible-only body-only ext-plist (lambda () (text-mode))))

;;;###autoload
(defun org-slack-export-to-slack
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a text file.

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

  When optional argument BODY-ONLY is non-nil, strip title and
  table of contents from output.

  EXT-PLIST, when provided, is a property list with external
  parameters overriding Org default settings, but still inferior to
  file-local settings.

  Return output file's name."
  (interactive)
  (let ((file (org-export-output-file-name ".txt" subtreep)))
    (org-export-to-file 'slack file
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun org-slack-export-to-clipboard-as-slack ()
  "Export region to slack, and copy to the kill ring for pasting into other programs."
  (interactive)
  (let* ((org-export-with-toc nil)
         (org-export-with-smart-quotes nil))
    (kill-new (org-export-as 'slack) ))
  )

;; (org-export-register-backend 'slack)
(provide 'ox-slack)

;; Local variables:
;; coding: utf-8
;; End:

;;; ox-slack.el ends here
