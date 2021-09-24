;;; janet-mode.el --- Defines a major mode for Janet -*- lexical-binding: t; -*-

;; Copyright (c) 2019 Adam Schwalm

;; Author: Adam Schwalm <adamschwalm@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20210924.44
;; Package-Commit: 9e3254a0249d720d5fa5603f1f8c3ed0612695af
;; URL: https://github.com/ALSchwalm/janet-mode
;; Package-Requires: ((emacs "24.3"))

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

;; Defines a major mode for the janet language: https://janet-lang.org/

;;; Code:

(require 'cl-lib)

(defgroup janet nil
  "A mode for Janet"
  :group 'languages)

(defvar janet-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; Comments start with a '#' and end with a newline
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)

    ;; For keywords, make the ':' part of the symbol class
    (modify-syntax-entry ?: "_" table)

    ;; Backtick is a string delimiter
    (modify-syntax-entry ?` "\"" table)

    ;; Other chars that are allowed in symbols
    (modify-syntax-entry ?? "_" table)
    (modify-syntax-entry ?! "_" table)
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?@ "_" table)

    table))

(defconst janet-symbol '(one-or-more (or (syntax word) (syntax symbol)))
  "Regex representation of a Janet symbol.
A Janet symbol is a collection of words or symbol characters as determined by
the syntax table.  This allows us to keep things like '-' in the symbol part of
the syntax table, so `forward-word' works as expected.")

(defconst janet-start-of-sexp '("(" (zero-or-more (or space "\n"))))

(defconst janet-macro-decl-forms '("defmacro" "defmacro-"))

(defconst janet-normal-function-decl-forms '("defn" "defn-"))

(defconst janet-function-decl-forms
  `(,@janet-normal-function-decl-forms ,@janet-macro-decl-forms "varfn" "fn"))

(defconst janet-function-pattern
  (rx-to-string `(sequence ,@janet-start-of-sexp
                  (or ,@janet-function-decl-forms)
                  (one-or-more space) (group ,janet-symbol) symbol-end))
  "The regex to identify janet function names.")

(defconst janet-var-decl-forms
  '("var" "var-" "def" "def-" "defglobal" "varglobal" "default" "dyn"))

(defconst janet-variable-declaration-pattern
  (rx-to-string `(sequence ,@janet-start-of-sexp
                  (or ,@janet-var-decl-forms)
                  (one-or-more space) (group ,janet-symbol)))
  "The regex to identify variable declarations.")

(defconst janet-keyword-pattern
  (rx-to-string `(group symbol-start ":" ,janet-symbol)))

(defconst janet-error-pattern
  (rx-to-string `(sequence ,@janet-start-of-sexp (group symbol-start "error" symbol-end))))

(defconst janet-constant-pattern
  (rx-to-string `(group symbol-start (group (or "true" "false" "nil")) symbol-end)))

(defconst janet-imenu-generic-expression
  `((nil
     ,(rx-to-string `(sequence line-start ,@janet-start-of-sexp
                               (or ,@janet-normal-function-decl-forms)
                               (one-or-more space)
                               (group ,janet-symbol)))
     1)
    ("Variables"
     ,(rx-to-string `(sequence line-start ,@janet-start-of-sexp
                               (or ,@janet-var-decl-forms)
                               (one-or-more space)
                               (group ,janet-symbol)))
     1)
    ("Macros"
     ,(rx-to-string `(sequence line-start ,@janet-start-of-sexp
                               (or ,@janet-macro-decl-forms)
                               (one-or-more space)
                               (group ,janet-symbol)))
     1)))

(defcustom janet-special-forms
  `(
    ;; Not all explicitly special forms, but included for
    ;; symmetry with other lisp-modes

    "->"
    "->>"
    "-?>"
    "-?>>"
    "as->"
    "as?->"
    "break"
    "cond"
    "coro"
    "do"
    "each"
    "fn"
    "for"
    "generate"
    "if"
    "if-let"
    "if-not"
    "import"
    "let"
    "loop"
    "match"
    "quasiquote"
    "quote"
    "require"
    "seq"
    "set"
    "setdyn"
    "splice"
    "try"
    "unless"
    "unquote"
    "var"
    "when"
    "when-let"
    "while"
    "with"
    "with-dyns"
    "with-syms"
    "with-vars"

    ,@janet-var-decl-forms
    ,@janet-function-decl-forms)
  "List of Janet special forms."
  :type '(repeat string)
  :group 'janet)

(defconst janet-special-form-pattern
  (let ((builtins (cons 'or janet-special-forms)))
    (rx-to-string `(sequence ,@janet-start-of-sexp (group ,builtins) symbol-end)))
  "The regex to identify builtin Janet special forms.")

(defconst janet-highlights
  `((,janet-special-form-pattern . (1 font-lock-keyword-face))
    (,janet-function-pattern . (1 font-lock-function-name-face))
    (,janet-variable-declaration-pattern . (1 font-lock-variable-name-face))
    (,janet-error-pattern . (1 font-lock-warning-face))
    (,janet-constant-pattern . (1 font-lock-constant-face))
    (,janet-keyword-pattern . (1 font-lock-builtin-face))))

;; The janet-mode indentation logic borrows heavily from
;; racket-mode and clojure-mode

(defcustom janet-indent 2
  "The number of spaces to add per indentation level."
  :type 'integer
  :group 'janet)

(defcustom janet-indent-sequence-depth 1
  "To what depth should `janet-indent-line' search.
This affects the indentation of forms like '() `() and {},
but not () or ,@().  A zero value disables, giving the normal
indent behavior of Emacs `lisp-mode' derived modes.  Setting this
to a high value can make indentation noticeably slower."
  :type 'integer
  :group 'janet)

(defun janet--ppss-containing-sexp (xs)
  "The start of the innermost paren grouping containing the stopping point.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 1))

(defun janet--ppss-last-sexp (xs)
  "The character position of the start of the last complete subexpression.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 2))

(defun janet--ppss-string-p (xs)
  "Non-nil if inside a string.
More precisely, this is the character that will terminate the
string, or t if a generic string delimiter character should
terminate it.
XS must be a `parse-partial-sexp' -- NOT `syntax-ppss'."
  (elt xs 3))

(defun janet-indent-line ()
  "Indent current line as Janet code."
  (interactive)
  (pcase (janet--calculate-indent)
    (`()  nil)
    ;; When point is within the leading whitespace, move it past the
    ;; new indentation whitespace. Otherwise preserve its position
    ;; relative to the original text.
    (amount (let ((pos (- (point-max) (point)))
                  (beg (progn (beginning-of-line) (point))))
              (skip-chars-forward " \t")
              (unless (= amount (current-column))
                (delete-region beg (point))
                (indent-to amount))
              (when (< (point) (- (point-max) pos))
                (goto-char (- (point-max) pos)))))))

(defun janet--calculate-indent ()
  "Calculate the appropriate indentation for the current Janet line."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
          (state        nil))
      (janet--plain-beginning-of-defun)
      (while (< (point) indent-point)
        (setq state (parse-partial-sexp (point) indent-point 0)))
      (let ((strp (janet--ppss-string-p state))
            (last (janet--ppss-last-sexp state))
            (cont (janet--ppss-containing-sexp state)))
        (cond
         (strp                  nil)
         ((and (janet--looking-at-keyword-p last)
               (not (janet--line-closes-delimiter-p indent-point)))
          (goto-char (1+ cont)) (+ (current-column) janet-indent))
         ((and state last cont) (janet-indent-function indent-point state))
         (cont                  (goto-char (1+ cont)) (current-column))
         (t                     (current-column)))))))

(defun janet--looking-at-keyword-p (point)
  "Is the given POINT the start of a keyword?"
  (when point
    (save-excursion
      (goto-char point)
      (looking-at (rx-to-string `(group ":" ,janet-symbol))))))

(defun janet--plain-beginning-of-defun ()
  "Quickly move to the start of the function containing the point."
  (when (re-search-backward (rx bol (syntax open-parenthesis))
                            nil
                            'move)
    (goto-char (1- (match-end 0)))))

(defun janet--get-indent-function-method (symbol)
  "Retrieve the indent function for a given SYMBOL."
  (let ((sym (intern-soft symbol)))
    (get sym 'janet-indent-function)))

(defun janet-indent-function (indent-point state)
  "Called by `janet--calculate-indent' to get indent column.

INDENT-POINT is the position at which the line being indented begins.
STATE is the `parse-partial-sexp' state for that position.
There is special handling for:
  - Common Janet special forms
  - [], @[], {}, and @{} forms"
  (goto-char (janet--ppss-containing-sexp state))
  (let ((body-indent (+ (current-column) janet-indent)))
    (forward-char 1)
    (if (janet--data-sequence-p)
        (progn
          (backward-prefix-chars)
          ;; Don't indent the end of a data list
          (when (janet--line-closes-delimiter-p indent-point)
            (backward-char 1))
          (current-column))
      (let* ((head   (buffer-substring (point) (progn (forward-sexp 1) (point))))
             (method (janet--get-indent-function-method head)))
        (cond ((integerp method)
               (janet--indent-special-form method indent-point state))
              ((eq method 'defun)
               body-indent)
              (method
               (funcall method indent-point state))
              ((string-match (rx bos (or "def" "with-")) head)
               body-indent) ;just like 'defun
              (t
               (janet--normal-indent state)))))))

(defun janet--line-closes-delimiter-p (point)
  "Is the line at POINT ending an expression?"
  (save-excursion
    (goto-char point)
    (looking-at (rx (zero-or-more space) (syntax close-parenthesis)))))

(defun janet--data-sequence-p ()
  "Is the point in a data squence?

Data sequences consist of '(), {}, @{}, [], and @[]."
  (and (< 0 janet-indent-sequence-depth)
       (save-excursion
         (ignore-errors
           (let ((answer 'unknown)
                 (depth janet-indent-sequence-depth))
             (while (and (eq answer 'unknown)
                         (< 0 depth))
               (backward-up-list)
               (cl-decf depth)
               (cond ((or
                       ;; a quoted '( ) or quasiquoted `( ) list
                       (and (memq (char-before (point)) '(?\' ?\`))
                            (eq (char-after (point)) ?\())
                       ;; [ ]
                       (eq (char-after (point)) ?\[)
                       ;; { }
                       (eq (char-after (point)) ?{))
                      (setq answer t))
                     (;; unquote or unquote-splicing
                      (and (or (eq (char-before (point)) ?,)
                               (and (eq (char-before (1- (point))) ?,)
                                    (eq (char-before (point))      ?@)))
                           (eq (char-after (point)) ?\())
                      (setq answer nil))))
             (eq answer t))))))

(defun janet--normal-indent (state)
  "Calculate the correct indentation for a 'normal' Janet form.

STATE is the `parse-partial-sexp' state for that position."
  (goto-char (janet--ppss-last-sexp state))
  (backward-prefix-chars)
  (let ((last-sexp nil))
    (if (ignore-errors
          ;; `backward-sexp' until we reach the start of a sexp that is the
          ;; first of its line (the start of the enclosing sexp).
          (while (string-match (rx (not blank))
                               (buffer-substring (line-beginning-position)
                                                 (point)))
            (setq last-sexp (prog1 (point)
                              (forward-sexp -1))))
          t)
        ;; Here we've found an arg before the arg we're indenting
        ;; which is at the start of a line.
        (current-column)
      ;; Here we've reached the start of the enclosing sexp (point is
      ;; now at the function name), so the behavior depends on whether
      ;; there's also an argument on this line.
      (when (and last-sexp
                 (< last-sexp (line-end-position)))
        ;; There's an arg after the function name, so align with it.
        (goto-char last-sexp))
      (current-column))))

(defun janet--indent-special-form (method indent-point state)
  "Calculate the correct indentation for a 'special' Janet form.

METHOD is the number of \"special\" args that get extra indent when
    not on the first line. Any additinonl args get normal indent
INDENT-POINT is the position at which the line being indented begins.
STATE is the `parse-partial-sexp' state for that position."
  (let ((containing-column (save-excursion
                             (goto-char (janet--ppss-containing-sexp state))
                             (current-column)))
        (pos -1))
    (condition-case nil
        (while (and (<= (point) indent-point)
                    (not (eobp)))
          (forward-sexp 1)
          (cl-incf pos))
      ;; If indent-point is _after_ the last sexp in the current sexp,
      ;; we detect that by catching the `scan-error'. In that case, we
      ;; should return the indentation as if there were an extra sexp
      ;; at point.
      (scan-error (cl-incf pos)))
    (cond ((= method pos)               ;first non-distinguished arg
           (+ containing-column janet-indent))
          ((< method pos)               ;more non-distinguished args
           (janet--normal-indent state))
          (t                            ;distinguished args
           (+ containing-column (* 2 janet-indent))))))

(defun janet--set-indentation ()
  "Set indentation for various Janet forms."
  (mapc (lambda (x)
          (put (car x) 'janet-indent-function (cadr x)))
        '((and  0)
          (defmacro defun)
          (defmacro- defun)
          (defn defun)
          (defn- defun)
          (case 1)
          (cond 0)
          (do  0)
          (each  2)
          (fn defun)
          (for 3)
          (if 1)
          (if-let 1)
          (if-not 1)
          (let 1)
          (loop 1)
          (match 1)
          (or 0)
          (reduce 0)
          (try 0)
          (unless 1)
          (varfn defun)
          (when 1)
          (when-let 1)
          (while 1))))

;;;###autoload
(define-derived-mode janet-mode prog-mode "janet"
  "Major mode for the Janet language"
  :syntax-table janet-mode-syntax-table
  (setq-local font-lock-defaults '(janet-highlights))
  (setq-local indent-line-function #'janet-indent-line)
  (setq-local lisp-indent-function #'janet-indent-function)
  (setq-local comment-start "#")
  (setq-local comment-start-skip "#+ *")
  (setq-local comment-use-syntax t)
  (setq-local comment-end "")
  (setq-local imenu-case-fold-search t)
  (setq-local imenu-generic-expression janet-imenu-generic-expression)
  (janet--set-indentation))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.janet\\'" . janet-mode))

;;;###autoload
(add-to-list 'interpreter-mode-alist '("janet" . janet-mode))

(provide 'janet-mode)
;;; janet-mode.el ends here
