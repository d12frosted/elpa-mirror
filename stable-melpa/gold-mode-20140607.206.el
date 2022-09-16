;;; gold-mode.el --- Major mode for editing .gold files

;; Copyright (C) 2014 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; URL: https://github.com/yuutayamada/gold-mode-el
;; Package-Version: 20140607.206
;; Package-Commit: 6d3aa59602b1b835495271c8c9741ac344c2eab1
;; Version: 0.0.1
;; Package-Requires: ((sws-mode "0"))
;; Keywords: golang template gold

;;; MIT License:
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;;; Code:
;;;
;;; Copied from https://github.com/brianc/jade-mode
;;; I almost copied jade-mode.el, thanks brianc!

(require 'font-lock)
(require 'sws-mode)

(defvar good-mode-hook '() "Hook for gold-mode.")

(defun gold-debug (string &rest args)
  "Prints a debug message with STRING and ARGS."
  (apply 'message (append (list string) args)))

(defmacro gold-line-as-string ()
  "Return the current line as a string."
  `(buffer-substring (point-at-bol) (point-at-eol)))

(defun gold-empty-line-p ()
  "If line is empty or not."
  (= (point-at-eol) (point-at-bol)))

(defun gold-blank-line-p ()
  "If line contain only spaces."
  (string-match-p "^[ ]*$" (gold-line-as-string)))

;; command to comment/uncomment text
(defun gold-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For detail, see `comment-dwim'.  The ARG passed to `comment-dwim' function."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-start "//") (comment-end ""))
    (comment-dwim arg)))

;; TODO: make sure whether below keywords are exist in gold
;; "if" "else" "for" "in" "each" "case" "when" "default" "include"
;; "yield" "mixin"
(defconst gold-keywords
  (eval-when-compile
    (concat "^[    ]+"
            (regexp-opt
             '("include" "style" "javascript" "block" "extends") 'words)))
  "Gold keywords.")

(defvar gold-font-lock-keywords
  `(;; keywords
    (,gold-keywords . font-lock-keyword-face)
    ;; {{}}'s face
    (,"{{\\.?\\(\\w\\|\\.\\| \\|_\\|-\\)*}}" . font-lock-preprocessor-face)
    ;; doctype
    (,"!!!\\|doctype\\( ?[A-Za-z0-9\-\_]*\\)?" 0 font-lock-comment-face)
    ;; id
    (,"#\\(\\w\\|_\\|-\\)*" . font-lock-variable-name-face)
    (,"\\(?:^[ {2,}]*\\(?:[a-z0-9_:\\-]*\\)\\)?\\(#[A-Za-z0-9\-\_]*[^ ]\\)"
     1 font-lock-variable-name-face)
    ;; class name
    (,"\\(?:^[ {2,}]*\\(?:[a-z0-9_:\\-]*\\)\\)?\\(\\.[A-Za-z0-9\-\_]*[^\\.]$\\)"
     1 font-lock-type-face)
    ;; tag name
    (,"^[ {2,}]*[a-z0-9_:\\-]*" 0 font-lock-function-name-face)))

;; syntax table
(defvar gold-syntax-table
  (let ((syn-table (make-syntax-table)))
    (modify-syntax-entry ?\/ ". 12b" syn-table)
    (modify-syntax-entry ?\n "> b" syn-table)
    (modify-syntax-entry ?' "\"" syn-table)
    syn-table)
  "Syntax table for `gold-mode'.")

(defun gold-region-for-sexp ()
  "Select the current sexp as the region."
  (interactive)
  (when (fboundp 'gold-next-line-indent)
    (beginning-of-line)
    (let ((ci (current-indentation)))
      (push-mark nil nil t)
      (while (> (gold-next-line-indent) ci)
        (line-move-1 1) ;; <- next-line
        (end-of-line)))))

(defvar gold-mode-map (make-sparse-keymap))
;;defer to sws-mode
;;(define-key gold-mode-map [S-tab] 'gold-unindent-line)

;; mode declaration
;;;###autoload
(define-derived-mode gold-mode sws-mode
  "Gold"
  "Major mode for editing .gold file templates"
  :syntax-table gold-syntax-table
  (setq tab-width 2)
  (setq mode-name "Gold")
  (setq major-mode 'gold-mode)
  ;; comment syntax
  (set (make-local-variable 'comment-start) "// ")
  ;; default tab width
  (setq sws-tab-width 2)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'sws-indent-line)
  (make-local-variable 'indent-region-function)
  (setq indent-region-function 'sws-indent-region)
  (setq indent-tabs-mode nil)
  ;; keymap
  (use-local-map gold-mode-map)
  ;; modify the keymap
  (define-key gold-mode-map [remap comment-dwim] 'gold-comment-dwim)
  ;; highlight syntax
  (setq font-lock-defaults '(gold-font-lock-keywords))
  (run-mode-hooks 'gold-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gold$" . gold-mode))

(provide 'gold-mode)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; gold-mode.el ends here
