;;; wren-mode.el --- A major mode for the Wren programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221227.227
;; Package-Commit: 70b1b89f565679a15c8c9c1a9bda98b0d163e83e
;; Author: XXIV
;; Keywords: files, wren
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/wren-mode

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for the Wren programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET wren-mode RET` to install the mode.
;; Use `M-x wren-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/wren-mode.git

;; Then add path to wren-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/wren-mode/")
;; (require 'wren-mode)

;; Use `M-x wren-mode` to change your current mode.

;;; Code:

(defconst wren-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23n" table) ;; Nested comments
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst wren-keywords
  '("as" "break" "class" "construct"
    "continue" "else" "for" ;; "true"
    "foreign" "if" "import" "in" ;; "null"
    "is" "return" "static" "super" ;; "false"
    "this" "var" "while"))


(defconst wren-builtins-getters
  '(;; Bool
    "toString"

    ;; Class
    "supertype"

    ;; Fiber
    "current" "error" "isDone"

    ;; Fn
    "arity"

    ;; List
    "count"

    ;; Map
    "keys" "values" ;; "count"

    ;; Num
    "infinity" "nan" "pi" "tau" ;; "toString"
    "largest" "smallest" "maxSafeInteger"
    "minSafeInteger" "abs" "acos" "asin"
    "atan" "cbrt" "ceil" "cos" "floor"
    "fraction" "isInfinity" "isInteger"
    "isNan" "log" "log2" "exp" "round"
    "sign" "sin" "sqrt" "tan" "truncate"

    ;; Object
    "type" ;; "toString"

    ;; Range
    "from" "to" "min" "max" "isInclusive"

    ;; Sequence
    "isEmpty" "toList" ;; "count"

    ;; String
    "bytes" "codePoints" ;; "count"

    ;; System
    "clock"))


(defconst wren-builtins-methods
  '(;; Fiber
    "abort" "new" "suspend" "yield" "call"
    "try" "transfer" "transferError"

    ;; Fn
    ;; "new" "call"

    ;; List
    "filled" "add" "addAll" "clear" ;; "new"
    "indexOf" "insert" "iterate" "iteratorValue"
    "remove" "removeAt" "sort" "swap"

    ;; Map
    ;; "new" "clear" "remove" "iterate" "iteratorValue"
    "containsKey"

    ;; Num
    "fromString" "atan" "min" "max" "clamp"
    "pow"

    ;; Object
    "same"

    ;; Range
    ;; "iterate" "iteratorValue"

    ;; Sequence
    "all" "any" "contains" "count" "each"
    "join" "map" "reduce" "skip" "take"
    "where"

    ;; String
    "fromCodePoint" "fromByte" "endsWith" ;; "contains" "indexOf"
    "replace" "split" "startsWith" "trim" ;; "iterate" "iteratorValue"
    "trimEnd" "trimStart"

    ;; System
    "gc" "print" "printAll" "write" "writeAll"))


(defconst wren-operators
  '(;; Prefix operators
    "!" "~" "-"

    ;; Infix operators
    "*" "/" "%" "+" "-" ".." "..."
    "<<" ">>" "<" "<=" ">" ;; is
    ">=" "==" "!=" "&" "^" "|"))


(defconst wren-constants
  '("true" "false" "null"))


(defconst wren-font-lock-keywords
  (list
   `(,(regexp-opt wren-constants 'words) . font-lock-constant-face)
   `(,(regexp-opt wren-keywords 'symbols) . font-lock-keyword-face)
    `("import[[:space:]]*\".*\"[[:space:]]*for[[:space:]]*\\<\\([a-zA-Z0-9_]*[a-zA-Z][a-zA-Z0-9_]*\\)\\>" . (1 font-lock-type-face)) ;; import "module" for <id>
   `("class[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*is[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>" (1 font-lock-type-face) (2 font-lock-type-face)) ;; class <id> is <id>
   `("class[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>" (1 font-lock-type-face)) ;; class <id>
   `("\\<\\([a-zA-Z0-9_]*[a-zA-Z][a-zA-Z0-9_]*\\)\\>[[:space:]]*\\.[[:space:]]*[a-zA-Z0-9_]*" . (1 font-lock-type-face)) ;; <id>.
   `(,(concat "\\.[[:space:]]*\\<\\(" (mapconcat 'identity wren-builtins-methods "\\|") "\\)\\>[[:space:]]*(") . (1 font-lock-builtin-face)) ;; .<id>(
   `(,(concat "\\.[[:space:]]*\\<\\(" (mapconcat 'identity wren-builtins-getters "\\|") "\\)\\>") . (1 font-lock-builtin-face)) ;; .<id>
   `("\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*(" (1 font-lock-function-name-face)) ;; <id> (
   `("\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*{" (1 font-lock-function-name-face)) ;; <id> {
   `("\\.[[:space:]]*\\<\\([a-zA-Z0-9_]*[a-zA-Z][a-zA-Z0-9_]*\\)\\>" (1 font-lock-function-name-face)) ;; .<id>
   `("\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*=[[:space:]]*(" (1 font-lock-variable-name-face)) ;; <id> = (
   `("var[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*=" (1 font-lock-variable-name-face)) ;; var <id> =
   `("var[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>\\>" (1 font-lock-variable-name-face)) ;; var <id>
   `("\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*=" (1 font-lock-variable-name-face)) ;; <id> =
   `("for[[:space:]]*([[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>\\>[[:space:]]*in" (1 font-lock-variable-name-face)) ;; for (<id> in
   `(,(regexp-opt wren-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode wren-mode prog-mode "Wren"
  "A major mode for the Wren programming language."
  :syntax-table wren-mode-syntax-table
  (setq-local font-lock-defaults '(wren-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wren\\'" . wren-mode))

(provide 'wren-mode)

;;; wren-mode.el ends here
