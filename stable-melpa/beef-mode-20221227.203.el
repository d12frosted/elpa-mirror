;;; beef-mode.el --- A major mode for the Beef programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221227.203
;; Package-Commit: 20906b41630d74eba56504fbb9fabb79562e0d6e
;; Author: XXIV
;; Keywords: files, beef
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/beef-mode

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

;; A major mode for the Beef programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET beef-mode RET` to install the mode.
;; Use `M-x beef-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/beef-mode.git

;; Then add path to beef-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/beef-mode/")
;; (require 'beef-mode)

;; Use `M-x beef-mode` to change your current mode.

;;; Code:

(defconst beef-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst beef-keywords
  '("alignof" "append" "as" "asm" "base" "break"
    "case" "catch" "checked" "continue" "const"
    "default" "defer" "delegate" "delete" "do"
    "else" "finally" "fixed" "for" ;; "false"
    "function" "if" "implicit" "in" "internal"
    "is" "isconst" "new" "mixin" "null" "offsetof"
    "out" "params" "readonly" "ref" "rettype" "return"
    "sealed" "sizeof" "scope" "static" "strideof" "struct"
    "switch" "try" "typeof" "unchecked" ;; "true"
    "using" "var" "virtual" "volatile" "where" "while"
    "alloctype" "comptype" "decltype" "nullable" "abstract"
    "class" "extern" "enum" "explicit" "extension"
    "interface" "namespace" "operator" "override"
    "private" "protected" "public" "readonly"
    "rettype" "this" "typealias" "let"))

(defconst beef-primitive-data-types
  `(
    ;; Integer types
    "int" "int8" "int16" "int32" "int64"
    "uint" "uint8" "uint16" "uint32" "uint64"

    ;; Floating point types
    "float" "double"

    ;; Character types
    "char8" "char16" "char32"

    ;; Valueless type
    "void"

    ;; Boolean type
    "bool"))


(defconst beef-operators
  '(
    ;; Primary operators
    "." ".."

    ;; Unary operators
    "++" "--" "~" "!" "&" "*"

    ;; Multiplicative operators
    "*" "&*" "/" "%"

    ;; Additive operators
    "+" "&+" "-" "&-"

    ;; Shift operators
    "<<" ">>"

    ;; Spaceship operator
    "<=>"

    ;; Comparison operators
    "<" ">" "<=" ">=" ;; "is" "as"

    ;; Logical AND operator
    "&"

    ;; Logical XOR operator
    "^"

    ;; Logical OR operator
    "|"

    ;; Equality operator
    "==" "===" "!=" "!=="

    ;; Conditional AND operator
    "&&"

    ;; Conditional OR operator
    "||"

    ;; Null-coalescing operator
    "??"

    ;; Conditional operator
    "?" ":"

    ;; Assignment operators
    "=" "+=" "-=" "*=" "/=" "%=" "|="
    "^=" "<<=" ">>=" "??=" "=>"

    ;; Type attribute operators
    ;; "sizeof" "alignof" "strideof"
    ;; "alloctype" "comptype" "decltype"
    ;; "nullable" "rettype" "typeof"
    ;; "offsetof" "nameof"

    ;; Ref operators
    ;; "ref" "out" "var" "let"

    ;; Params operator
    ;; "params"

    ;; Range operators
    "..." "..<" "...^"

    ;; Index from end operator
    "^"))


(defconst beef-constants
  '("true" "false"))


(defconst beef-font-lock-keywords
  (list
   `(,(regexp-opt beef-constants 'words) . font-lock-constant-face)
   `(,(regexp-opt beef-primitive-data-types 'symbols) . font-lock-type-face)
   `(,(regexp-opt beef-keywords 'symbols) . font-lock-keyword-face)
   `(,(regexp-opt beef-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode beef-mode prog-mode "Beef"
  "A major mode for the Beef programming language."
  :syntax-table beef-mode-syntax-table
  (setq-local font-lock-defaults '(beef-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bf\\'" . beef-mode))

(provide 'beef-mode)

;;; beef-mode.el ends here
