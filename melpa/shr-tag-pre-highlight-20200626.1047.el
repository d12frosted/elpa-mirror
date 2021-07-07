;;; shr-tag-pre-highlight.el --- Syntax highlighting code block in HTML -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Chunyang Xu

;; Author: Chunyang Xu <mail@xuchunyang.me>
;; URL: https://github.com/xuchunyang/shr-tag-pre-highlight.el
;; Package-Version: 20200626.1047
;; Package-Commit: 931c447bc0d6c134ddc9657c664eeee33afbc54d
;; Package-Requires: ((emacs "25.1") (language-detection "0.1.0"))
;; Keywords: html
;; Version: 2

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

;; [![MELPA](https://melpa.org/packages/shr-tag-pre-highlight-badge.svg)](https://melpa.org/#/shr-tag-pre-highlight)
;;
;; This package adds syntax highlighting support for code block in
;; HTML, rendered by `shr.el'.  The probably most famous user of
;; `shr.el' is EWW (the Emacs Web Wowser).
;;
;; Example:
;;
;; | Before               | After                                 |
;; | ------               | -----                                 |
;; | ![](eww-default.png) | ![](eww-with-syntax-highlighting.png) |
;;
;; In above, I am using EWW to visit
;; https://emacs-china.org/t/eww/2949. And the color theme is
;; sanityinc-tomorrow-eighties, from Steve Purcell's
;; color-theme-sanityinc-tomorrow package

;; Installation:
;;
;; This package is available from MELPA. If you use
;; [use-package](https://github.com/jwiegley/use-package) to manage the init
;; file, use something like the following:
;;
;; (use-package shr-tag-pre-highlight
;;   :ensure t
;;   :after shr
;;   :config
;;   (add-to-list 'shr-external-rendering-functions
;;                '(pre . shr-tag-pre-highlight))
;;   (when (version< emacs-version "26")
;;     (with-eval-after-load 'eww
;;       (advice-add 'eww-display-html :around
;;                   'eww-display-html--override-shr-external-rendering-functions))))

;; Why is `eww-display-html' advised for Emacs version older than 26:
;;
;; Unfortunately, EWW always overrides
;; `shr-external-rendering-functions' until
;; [this commit](http://git.savannah.gnu.org/cgit/emacs.git/commit/?id=45ebbc0301c8514a5f3215f45981c787cb26f915)
;; (2015-12), but Emacs 25.2 (latest release - 2017-4) doesn't include
;; this commit.  Thus if you want syntax highlighting in EWW, you have
;; to use devel version of Emacs (also know as emacs-26 at this
;; moment) or advice `eww-display-html' as above.

;;; Code:

(require 'shr)
(require 'dom)                          ; 25.1+
(require 'language-detection)
(require 'cl-lib)


;;; Compatibility

(defun eww-display-html--override-shr-external-rendering-functions (orig-fun &rest r)
  "Use our own `shr-external-rendering-functions'.

In Emacs version <= 25.2, `eww-display-html' always overrides
`shr-external-rendering-functions' thus simply change this
variable won't work.  For later version of Emacs, you should
ignore this then customize `shr-external-rendering-functions'
directly."
  (let ((tmp-fun (symbol-function 'shr-insert-document)))
    (cl-letf (((symbol-function 'shr-insert-document)
               (lambda (dom)
                 (let ((shr-external-rendering-functions
                        '((title . eww-tag-title)
                          (form . eww-tag-form)
                          (input . eww-tag-input)
                          (button . eww-form-submit)
                          (textarea . eww-tag-textarea)
                          (select . eww-tag-select)
                          (link . eww-tag-link)
                          (meta . eww-tag-meta)
                          (a . eww-tag-a)
                          (pre . shr-tag-pre-highlight))))
                   (funcall tmp-fun dom)))))
      (apply orig-fun r))))


;;; Customization

(defcustom shr-tag-pre-highlight-lang-modes
  '(("ocaml" . tuareg) ("elisp" . emacs-lisp) ("ditaa" . artist)
    ("asymptote" . asy) ("dot" . fundamental) ("sqlite" . sql)
    ("calc" . fundamental) ("C" . c) ("cpp" . c++) ("C++" . c++)
    ("screen" . shell-script) ("shell" . sh) ("bash" . sh)
    ;; Used by language-detection.el
    ("emacslisp" . emacs-lisp)
    ;; Used by Google Code Prettify
    ("el" . emacs-lisp))
  "Adapted from `org-src-lang-modes'."
  :group 'shr
  :type '(repeat
	  (cons
	   (string "Language name")
	   (symbol "Major mode"))))


;;; Utility

(defun shr-tag-pre-highlight--get-lang-mode (lang)
  "Return major mode that should be used for LANG.
LANG is a string, and the returned major mode is a symbol.

Adapted from `org-src--get-lang-mode'."
  (intern
   (concat
    (let ((l (or (cdr (assoc lang shr-tag-pre-highlight-lang-modes)) lang)))
      (if (symbolp l) (symbol-name l) l))
    "-mode")))

(defun shr-tag-pre-highlight--match (regexp n-group string)
  (when (string-match regexp string)
    (match-string n-group string)))

(defun shr-tag-pre-highlight-guess-language-attr (pre)
  "Guess programming language base on the attributes of PRE."
  (let* ((pre-class (dom-attr pre 'class))
         (pre-attrs (dom-attributes pre))
         (code (car (dom-by-tag pre 'code)))
         (code-class (dom-attr code 'class))
         (code-attrs (dom-attributes code))
         lang)
    (cond
     ;; <pre class="src src-C"> (Org mode)
     ;; <pre class="brush: js"> (http://alexgorbatchev.com/SyntaxHighlighter)
     ;; <pre class="sh_cpp"> (http://shjs.sourceforge.net/)
     ((and pre-class
           (setq lang (shr-tag-pre-highlight--match
                       "\\(?:src src-\\|brush: \\|sh_\\)\\([-+a-zA-Z0-9]+\\)" 1 pre-class))))
     ;; <pre><code data-language="python" class="rainbow"> (https://craig.is/making/rainbows)
     ((and code
           (setq lang (dom-attr code 'data-language))))
     ;; <pre><code class="hljs clojure"> (https://highlightjs.org)
     ;; <pre><code class="sourceCode haskell"> (https://pandoc.org/)
     ;; <pre><code class="lang-csharp">
     ;; <pre><code class="language-pascal">
     ((and code-class
           (setq lang (shr-tag-pre-highlight--match
                       "\\(?:hljs \\|sourceCode \\|lang-\\|language-\\)\\([-+a-zA-Z0-9]+\\)" 1 code-class)))))
    (setq lang (and lang (downcase lang)))
    (cond ((equal "auto" lang) nil)
          (lang lang)
          ;; XXX Provide a generic fallback?
          ((or (string-match "elisp" (format "%s" pre-attrs))
               (string-match "elisp" (format "%s" code-attrs)))
           "elisp")
          ((or (string-match "lisp" (format "%s" pre-attrs))
               (string-match "lisp" (format "%s" code-attrs)))
           "lisp")
          ((or (string-match "python" (format "%s" pre-attrs))
               (string-match "python" (format "%s" code-attrs)))
           "python")
          ((or (string-match "ruby" (format "%s" pre-attrs))
               (string-match "ruby" (format "%s" code-attrs)))
           "ruby")
          (t nil))))

(defun shr-tag-pre-highlight-fontify (code mode)
  "Fontify CODE with Major MODE."
  (with-temp-buffer
    (insert code)
    (delay-mode-hooks (funcall mode))
    (if (fboundp 'font-lock-ensure)
        (font-lock-ensure)
      (with-no-warnings
        (font-lock-fontify-buffer)))
    (buffer-string)))

(defun shr-tag-pre-highlight (pre)
  "Highlighting code in PRE."
  (let* ((shr-folding-mode 'none)
         (shr-current-font 'default)
         (code (with-temp-buffer
                 (shr-generic pre)
                 (buffer-string)))
         (lang (or (shr-tag-pre-highlight-guess-language-attr pre)
                   (let ((sym (language-detection-string code)))
                     (and sym (symbol-name sym)))))
         (mode (and lang
                    (shr-tag-pre-highlight--get-lang-mode lang))))
    (shr-ensure-newline)
    (insert
     (or (and (fboundp mode)
              (with-demoted-errors "Error while fontifying: %S"
                (shr-tag-pre-highlight-fontify code mode)))
         code))
    (shr-ensure-newline)))

(provide 'shr-tag-pre-highlight)
;;; shr-tag-pre-highlight.el ends here
