;;; cfml-mode.el --- Emacs mode for editing CFML files

;; Copyright 2019 Andrew Myers

;; Author: Andrew Myers <am2605@gmail.com>
;; URL: https://github.com/am2605/cfml-mode
;; Package-Version: 20190617.1130
;; Package-Commit: b06d7cee2af0ed5d55a94f0db80fc1f429a1829a
;; Version: 1.2.0
;; Package-Requires: ((emacs "25"))

;;{{{ GPL

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;}}}

;;; Commentary:

;; This file provides syntax highlighting for CFML (also known as ColdFusion) source files.

;; Usage:

;; Install the cfml-mode package.  CFML files should now open in cfml-mode

;;; Code:

(require 'mhtml-mode)
(require 'js)

(defgroup cfml nil
  "Major mode for cfml files"
  :prefix "cfml-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/am2605/cfml-mode")
  :link '(emacs-commentary-link :tag "Commentary" "cfml-mode"))

(defconst cfml-html-empty-tags
  '("area" "base" "basefont" "br" "col" "frame" "hr" "img" "input"
	"isindex" "link" "meta" "param" "wbr"))

(defconst cfml-html-unclosed-tags 
  '("body" "colgroup" "dd" "dt" "head" "html" "li" "option"
	"p" "tbody" "td" "tfoot" "th" "thead" "tr"))

(defconst cfml-empty-tags
  '("cfabort" "cfargument" "cfbreak" "cfcontent" "cfcontinue" "cfcookie" "cfdirectory" "cfdump" "cffile" "cfflush" "cfftp" "cfheader" "cfhtmlhead" "cfhttpparam" "cfinclude" "cfinvokeargument" "cflocation" "cflog" "cfmodule" "cfparam" "cfproperty" "cfqueryparam" "cfrethrow" "cfreturn" "cfset" "cfsetting" "cfstoredproc" "cfthrow" "cftrace"))

(defconst cfml-unclosed-tags
  '("cfelse" "cfelseif"))

(defun cfml-get-previous-indentation ()
  "Get the column of the previous indented line"
  (interactive)
  (save-excursion
    (progn
      (move-beginning-of-line nil)
      (skip-chars-backward "\n \t")
      (back-to-indentation))
    (current-column)))

(defconst cfml-outdent-regexp
  "\\(<cfelse\\(if\\([^>]+\\)\\)?>\\)"
  )

(defconst cfml--cf-submode
  (mhtml--construct-submode 'js-mode
                            :name "cfscript"
                            :end-tag "</cfscript>"
                            :syntax-table js-mode-syntax-table
                            :propertize #'js-syntax-propertize
                            :keymap js-mode-map))

(defconst cfml-tab-width 4)

(defun cfml-indent-line ()
  (interactive)
  (mhtml-indent-line)
  (save-excursion
	(beginning-of-line)
	(back-to-indentation)
	(if
	 (looking-at cfml-outdent-regexp) (indent-line-to (max 0 (- (cfml-get-previous-indentation) cfml-tab-width))))))

(defun cfml-syntax-propertize (start end)
  ;; First remove our special settings from the affected text.  They
  ;; will be re-applied as needed.
  (remove-list-of-text-properties start end
                                  '(syntax-table local-map mhtml-submode))
  (goto-char start)
  ;; Be sure to look back one character, because START won't yet have
  ;; been propertized.
  (unless (bobp)
    (let ((submode (get-text-property (1- (point)) 'mhtml-submode)))
      (if submode
          (mhtml--syntax-propertize-submode submode end)
        ;; No submode, so do what sgml-mode does.
        (sgml-syntax-propertize-inside end))))
  (funcall
   (syntax-propertize-rules
    ("<style.*?>"
     (0 (ignore
         (goto-char (match-end 0))
         ;; Don't apply in a comment.
         (unless (syntax-ppss-context (syntax-ppss))
           (mhtml--syntax-propertize-submode mhtml--css-submode end)))))
    ("<script.*?>"
     (0 (ignore
         (goto-char (match-end 0))
         ;; Don't apply in a comment.
         (unless (syntax-ppss-context (syntax-ppss))
           (mhtml--syntax-propertize-submode mhtml--js-submode end)))))
    ("<cfscript>"
     (0 (ignore
         (goto-char (match-end 0))
         ;; Don't apply in a comment.
         (unless (syntax-ppss-context (syntax-ppss))
           (mhtml--syntax-propertize-submode cfml--cf-submode end)))))

    sgml-syntax-propertize-rules)
   
   ;; Make sure to handle the situation where
   ;; mhtml--syntax-propertize-submode moved point.
   (point) end))

(define-skeleton cfml-cfdump
  "CFML cfdump tag."
  nil
  "<cfdump var=\"#" (skeleton-read "var: ") "#\" abort=\"" (skeleton-read "abort: ")
  "\">")

(define-skeleton cfml-cfqueryparam
  "CFML cfqueryparam tag."
  nil
  "<cfqueryparam cfsqltype=\"" (skeleton-read "cfsqltype: ") "\" value=\"#" (skeleton-read "value: ")
  "#\">")


;;;###autoload
(define-derived-mode cfml-mode html-mode
  '((sgml-xml-mode "XHTML+" "cfml+") (:eval (mhtml--submode-lighter)))
  "Major mode based on `html-mode', but works with embedded JS and CSS.

Code inside a <script> element is indented using the rules from
`js-mode'; and code inside a <style> element is indented using
the rules from `css-mode'."
  (setq-local sgml-empty-tags (append cfml-html-empty-tags cfml-empty-tags))
  (setq-local sgml-unclosed-tags (append cfml-html-unclosed-tags cfml-unclosed-tags))
  (setq-local indent-line-function #'cfml-indent-line)
  (setq-local syntax-propertize-function #'cfml-syntax-propertize)
  (setq-local font-lock-fontify-region-function
              #'mhtml--submode-fontify-region)
  (setq-local font-lock-extend-region-functions
              '(mhtml--extend-font-lock-region))

  (font-lock-add-keywords nil `((,cfml--builtin-re . 'font-lock-builtin-face)))
  (font-lock-add-keywords nil `((,cfml--types-re . 'font-lock-type-face)))

  ;; Attach this to both pre- and post- hooks just in case it ever
  ;; changes a key binding that might be accessed from the menu bar.
  (add-hook 'pre-command-hook #'mhtml--pre-command nil t)
  (add-hook 'post-command-hook #'mhtml--pre-command nil t)

  ;; Make any captured variables buffer-local.
  (mhtml--mark-buffer-locals mhtml--css-submode)
  (mhtml--mark-buffer-locals mhtml--js-submode)
  (mhtml--mark-buffer-locals cfml--cf-submode)

  (mhtml--mark-crucial-buffer-locals mhtml--css-submode)
  (mhtml--mark-crucial-buffer-locals mhtml--js-submode)
  (mhtml--mark-crucial-buffer-locals cfml--cf-submode)
  (setq mhtml--crucial-variables (delete-dups mhtml--crucial-variables))

  ;; Hack
  (js--update-quick-match-re)

  ;; This is sort of a prog-mode as well as a text mode.
  (run-hooks 'prog-mode-hook))

(defvar cfml--types-re
  (concat "\\_<" (regexp-opt '(
                              "any"
                              "array"
                              "binary"
                              "boolean"
                              "date"
                              "numeric"
                              "query"
                              "string"
                              "struct"
                              "uuid"
                              "void"
                              "xml")
                            t) "\\_>"))

(defvar cfml--builtin-re
  (concat "\\_<" (regexp-opt '(
                              "arrayLen"
                              "arrayAppend"
                              "dateAdd"
                              "dateCompare"
                              "dateDiff"
                              "dateFormat"
                              "left"
                              "listAppend"
                              "mid"
                              "ormExecuteQuery"
                              "queryExecute"
                              "right"
                              "writeDump"
                              "writeOutput")
                            t) "\\_>"))

;;;###autoload
(define-derived-mode cfscript-mode js-mode "cfscript"
	(font-lock-add-keywords nil '(("\\<component\\>" . 'font-lock-keyword-face)))
    (font-lock-add-keywords nil `((,cfml--builtin-re . 'font-lock-builtin-face)))
    (font-lock-add-keywords nil `((,cfml--types-re . 'font-lock-type-face)))
)

;;;###autoload
(add-to-list 'magic-mode-alist
             '("<cfcomponent" . cfml-mode))
;;;###autoload
(add-to-list 'magic-mode-alist
             '("<!---" . cfml-mode))
;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.cfm\\'" . cfml-mode))		
;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.cfc\\'" . cfscript-mode))

(provide 'cfml-mode)

;;; cfml-mode.el ends here
