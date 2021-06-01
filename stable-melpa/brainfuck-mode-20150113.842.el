;;; brainfuck-mode.el --- Brainfuck mode for Emacs

;; Copyright (C) 2013, 2014  by Tomoya Tanjo

;; Author: Tomoya Tanjo <ttanjo@gmail.com>
;; URL: https://github.com/tom-tan/brainfuck-mode/
;; Package-Version: 20150113.842
;; Package-Commit: 36e69552bb3b97a4f888d362c59845651bd0d492
;; Package-Requires: ((langdoc "20130601.1450"))
;; Keywords: brainfuck, langdoc

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

;; This library helps you to write brainfuck in Emacs.
;; This is also an example to define help document functions by using langdoc.
;;
;; Requirements:
;;   * Emacs 24 or later
;;   * langdoc.el
;;
;; To use this package, add the following line to your .emacs file:
;;     (require 'brainfuck-mode)
;; brainfuck-mode highlights some keywords for usability.
;; By using M-x eldoc-mode, you can see the help string in minibuffer.
;; Also, by using M-x bf-help-describe-symbol (or C-c f), you can see
;; more documents for each command.

;;; Code:

(require 'langdoc)
(require 'generic)

(defvar bf-syntax-table
  (let ((table (make-syntax-table)))
    ;; Emacs' default syntax table treats " as a string delimiter, but
    ;; we treat it as just a normal character.
    (modify-syntax-entry ?\" "." table)
    table))

;;;###autoload
(define-derived-mode brainfuck-mode prog-mode "Brainfuck"
  "Major mode for brainfuck"
  :syntax-table bf-syntax-table
  (font-lock-add-keywords
   nil
   (list
    (cons (rx (any "[" "]"))
          font-lock-keyword-face)
    (cons (rx (not (any "[" "]" ">" "<" "+" "-" "." ",")))
          font-lock-comment-face)))
  (define-bf-keymap)
  (bf-help-doc-fun))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bf\\'" . brainfuck-mode))

(defvar brainfuck-mode-local-map nil "Keymap for brainfuck-mode.")

(defun define-bf-keymap ()
  (setq brainfuck-mode-local-map (make-keymap))
  (define-key brainfuck-mode-local-map
      "\C-cf" 'bf-help-describe-symbol)
  (use-local-map brainfuck-mode-local-map))

;;;###autoload
(langdoc-define-help-mode bf-help "Major mode for brainfuck help" "*Brainfuck Help*"
                          'bf-help-sym-called-at-point
                          '(">" "<" "+" "-" "." "," "[" "]")
                          'bf-help-lookup-doc
                          "`\\([^']+\\)'"
                          (lambda (a b) b) (lambda (a b) b)
                          "`" "'")

(defun bf-help-doc-fun ()
  (make-local-variable 'eldoc-documentation-function)
  (setq eldoc-documentation-function
        'bf-help-minibuffer-help-string))

(defun bf-help-sym-called-at-point ()
  (unless (eobp)
    (buffer-substring-no-properties (point) (1+ (point)))))

(defun bf-help-minibuffer-help-string ()
  (interactive)
  (let* ((sym (bf-help-sym-called-at-point))
         (doc (when sym (bf-help-lookup-doc sym))))
    (when doc (bf-help-summerize-doc sym doc))))

(defun bf-help-lookup-doc (sym)
  "Return document string for SYM."
  (pcase sym
    (">" "Increment the pointer.")
    ("<" "Decrement the pointer.")
    ("+" "Increment the value indicated by the pointer.")
    ("-" "Decrement the value indicated by the pointer.")
    ("." "Print the value indicated by the pointer.")
    ("," "Read one byte from input and store it in the indicated value.")
    ("[" "Jump to the matching `]' if the indicated value is zero.")
    ("]" "Jump to the matching `[' if the indicated value is not zero.")))

(defun bf-help-summerize-doc (sym doc)
  (concat sym " : " (car (split-string doc "[\n\r]+"))))

(provide 'brainfuck-mode)
;;; brainfuck-mode.el ends here
