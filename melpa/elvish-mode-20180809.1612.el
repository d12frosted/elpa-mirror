;;; elvish-mode.el --- Defines a major mode for Elvish

;; Copyright (c) 2017 Adam Schwalm

;; Author: Adam Schwalm <adamschwalm@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20180809.1612
;; Package-Commit: a13fcaf209d803e2e450ca2bf80dea94b40a0141
;; URL: https://github.com/ALSchwalm/elvish-mode
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

;; Defines a major mode for the elvish language: http://elvish.io

;;; Code:

(defgroup elvish-mode nil
  "A mode for Elvish"
  :prefix "elvish-mode-"
  :group 'languages)

(defvar elvish-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; Don't consider the '&' as part of a symbol
    (modify-syntax-entry ?& "." table)

    ;; Comments start with a '#' and end with a newline
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)

    ;; Strings can be single-quoted
    (modify-syntax-entry ?' "\"" table)
    table))

(defcustom elvish-keywords
  '("fn" "elif" "if" "else" "try" "except" "finally" "use" "return"
    "while" "for" "break" "continue" "del" "and" "or" "fail" "multi-error")
  "Elvish keyword list."
  :type 'list
  :group 'elvish-mode)

(defconst elvish-symbol '(one-or-more (or (syntax word) (syntax symbol)))
  "Regex representation of an Elvish symbol.
An Elvish symbol is a collection of words or symbol characters as determined by
the syntax table.  This allows us to keep things like '-' in the symbol part of
the syntax table, so `forward-word' works as expected.")

(defconst elvish-start-of-statement '(sequence (or line-start "{" "(" ";" "|") (zero-or-more space))
  "Regex to match the beginning of an Elvish statement.")

(defconst elvish-keyword-pattern
  (let ((keywords (cons 'or elvish-keywords)))
    (eval `(rx symbol-start (group ,keywords) symbol-end)))
  "The regex to identify Elvish keywords.")

(defconst elvish-function-pattern
  (eval `(rx "fn" (one-or-more space) (group ,elvish-symbol) symbol-end))
  "The regex to identify elvish function names.")

(defconst elvish-variable-usage-pattern
  (eval `(rx "$" (optional "@") (zero-or-more ,elvish-symbol ":")
             (group ,elvish-symbol) symbol-end))
  "The regex to identify variable usages.")

(defconst elvish-map-key-pattern
  (eval `(rx "&" (group ,elvish-symbol) "="))
  "The regex to identify map keys.")

(defcustom elvish-auto-variables
  '("_" "pid" "ok" "true" "false" "paths" "pwd")
  "Elvish special variable names."
  :type 'list
  :group 'elvish-mode)

(defconst elvish-auto-variables-pattern
  (let ((vars (cons 'or elvish-auto-variables)))
    (eval `(rx "$" (group ,vars) symbol-end)))
  "Regex to identify Elvish special variables.")

(defconst elvish-variable-declaration-pattern
  ;; Elvish requires spaces around the equal for multiple assignment.
  ;; For now, we require for single assignment as well (to avoid highlighting
  ;; arguments, etc).
  (eval `(rx (group (optional (one-or-more ,elvish-symbol (one-or-more space)))
                    ,elvish-symbol) (one-or-more space) "=" (one-or-more space)))
  "The regex to identify variable declarations.")

(defconst elvish-argument-declaration-pattern
  (eval `(rx "["
             (zero-or-more space)

             ;; 1st group is the normal arguments
             (group (optional ,elvish-symbol (zero-or-more (one-or-more space)
                                                           ,elvish-symbol)))

             (zero-or-more space)

             ;; Skip the optional arguments. They will be highlighted
             ;; by `elvish-map-key-pattern'.
             (optional (zero-or-more "&" ,elvish-symbol "=" (one-or-more (not space))
                                     (zero-or-more space)))

             ;; 2nd group is the (optional) 'rest argument'
             (optional "@" (group ,elvish-symbol))
             (zero-or-more space) "]{"))
  "The regex to identify function arguments.")

(defconst elvish-module-pattern
  (eval `(rx (group ,elvish-symbol) ":" symbol-start))
  "The regex to identify Elvish module prefixes.")

;;TODO: this doesn't support everything ParseFloat does (scientific notation, etc)
(defconst elvish-numeric-pattern
  (rx symbol-start
      (optional "-") (one-or-more digit)
      (optional "." (zero-or-more digit))
      symbol-end)
  "The regex to identify Elvish numbers.")

(defcustom elvish-builtin-functions
  '(
    ;; Trivial builtin
    "nop"
    ;; Introspection
    "kind-of" "is" "eq" "not-eq"
    ;; Value output
    "put"
    ;; Bytes output
    "print" "echo" "pprint" "repr"
    ;; Bytes to value
    "slurp" "from-lines" "from-json"
    ;; Value to bytes
    "to-lines" "to-json"
    ;; Misc functional
    "constantly"
    ;; Misc shell basic
    "-source"
    ;; Iterations.
    "each" "peach" "repeat"
    ;; Container primitives.
    "assoc"
    ;; Sequence primitives
    "explode" "take" "drop" "range" "count" "has-key" "has-value"
    ;; String
    "joins" "splits" "replaces"
    ;; String operations
    "ord" "base" "wcswidth" "-override-wcwidth"
    ;; Map operations
    "keys"
    ;; String predicates
    "has-prefix" "has-suffix"
    ;; String comparison
    "<s" "<=s" "==s" "!=s" ">s" ">=s"
    ;; eawk
    "eawk"
    ;; Directory
    "cd" "dir-history"
    ;; Path
    "path-abs" "path-base" "path-clean" "path-dir" "path-ext" "eval-symlinks" "tilde-abbr"
    ;; Boolean operations
    "bool" "not"
    ;; Arithmetics
    "+" "-" "*" "/" "^" "%"
    ;; Random
    "rand" "randint"
    ;; Numerical comparison
    "<" ">" "<=" "==" "!=" ">="
    ;; Command resolution
    "resolve" "has-external" "search-external"
    ;; File and pipe
    "fopen" "fclose" "pipe" "prclose" "pwclose"
    ;; Process control
    "fg" "exec" "exit"
    ;; Time
    "esleep" "-time"
    ;; Debugging
    "-gc" "-stack" "-log" "-ifaddrs")
  "List of Elvish built-in functions."
  :type 'list
  :group 'elvish-mode)

(defconst elvish-builtin-functions-pattern
  (let ((builtins (cons 'or elvish-builtin-functions)))
    (eval `(rx ,elvish-start-of-statement (group ,builtins) symbol-end)))
  "The regex to identify builtin Elvish functions.")

(defconst elvish-highlights
  `((,elvish-function-pattern . (1 font-lock-function-name-face))
    (,elvish-builtin-functions-pattern . (1 font-lock-builtin-face))
    (,elvish-auto-variables-pattern . (1 font-lock-constant-face))
    (,elvish-keyword-pattern . (1 font-lock-keyword-face))
    (,elvish-variable-usage-pattern . (1 font-lock-variable-name-face))
    (,elvish-map-key-pattern . (1 font-lock-variable-name-face))
    (,elvish-argument-declaration-pattern . ((1 font-lock-variable-name-face)
                                             (2 font-lock-variable-name-face nil lax)))
    (,elvish-variable-declaration-pattern . (1 font-lock-variable-name-face))
    (,elvish-module-pattern . (1 font-lock-constant-face))
    (,elvish-numeric-pattern . font-lock-constant-face)))

(defcustom elvish-indent 2
  "The number of spaces to add per indentation level."
  :type 'integer
  :group 'elvish-mode)

(defun elvish-current-line-empty-p ()
  "Test whether the current line contains only whitespace."
  (save-excursion
    (beginning-of-line)
    (looking-at (rx (zero-or-more space) eol))))

(defun elvish-lowest-indent-in-line ()
  "Return the smallest 'indent' value anywhere in the current line."
  (save-excursion
    (beginning-of-line)
    (let ((lowest (car (syntax-ppss)))
          (loop t))
      (while (and (not (eolp)) loop)
        (forward-char)
        (when (< (car (syntax-ppss)) lowest)
          (setq lowest (car (syntax-ppss))))
        (if (eolp)
            (setq loop nil)))
      lowest)))

(defun elvish-indent-function ()
  "This function is normally the value of 'indent-line-function' in Elvish.
The indent is currently calculated via 'syntax-ppss'.  Once the grammar is more
stable, this should probably be switched to using SMIE."
  (save-excursion
    (indent-line-to (* elvish-indent (elvish-lowest-indent-in-line))))
  (if (< (current-column)
	 (save-excursion
	   (back-to-indentation)
	   (current-column)))
      (back-to-indentation)))

;;;###autoload
(define-derived-mode elvish-mode prog-mode "elvish"
  "Major mode for the Elvish language"
  :syntax-table elvish-mode-syntax-table
  (setq-local font-lock-defaults '(elvish-highlights))
  (setq-local indent-line-function #'elvish-indent-function)
  (setq-local comment-start "#")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.elv\\'" . elvish-mode))

(provide 'elvish-mode)
;;; elvish-mode.el ends here
