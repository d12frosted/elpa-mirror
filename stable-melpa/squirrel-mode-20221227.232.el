;;; squirrel-mode.el --- A major mode for the Squirrel programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221227.232
;; Package-Commit: 1af79dfe70c4c8e6f0f144bfd2eb65c077aca785
;; Author: XXIV
;; Keywords: files, squirrel
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/squirrel-mode

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

;; A major mode for the Squirrel programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET squirrel-mode RET` to install the mode.
;; Use `M-x squirrel-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/squirrel-mode.git

;; Then add path to squirrel-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/squirrel-mode/")
;; (require 'squirrel-mode)

;; Use `M-x squirrel-mode` to change your current mode.

;;; Code:

(defconst squirrel-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst squirrel-keywords
  `("base" "break" "case" "catch" "class" "clone" ;; "__LINE__"
    "continue" "const" "default" "delete" "else" "enum" ;; "__FILE__"
    "extends" "for" "foreach" "function" "if" "in" ;; "true"
    "local" "null" "resume" "return" "switch" "this" ;; "false"
    "throw" "try" "typeof" "while" "yield" "constructor"
    "instanceof" "static" "rawcall"))


(defconst squirrel-builtins
  `("array" "seterrorhandler" "callee" "setdebughook" "enabledebuginfo"
    "getroottable" "setroottable" "getconsttable" "setconsttable"
    "assert" "print" "error" "compilestring" "collectgarbage"
    "resurrectunreachable" "type" "getstackinfos" "newthread"))

(defconst squirrel-builtins-metamethods
  `("_set" "_get" "_newslot" "_delslot" "_add" "_sub"
    "_mul" "_div" "_modulo" "_unm" "_typeof" "_cmp"
    "_call" "_cloned" "_nexti" "_tostring" "_inherited"
    "_newmember"))

(defconst squirrel-builtins-default-delegates
  `(;; Integer
    "tofloat" "tostring" "tointeger" "tochar" "weakref"

    ;; Float
    ;;"tofloat" "tointeger" "tostring" "tochar" "weakref"

    ;; Bool
    ;;"tofloat" "tointeger" "tostring" "weakref"

    ;; String
    "len" "slice" ;; "tointeger" "tofloat" "tostring"
    "find" "tolower" "toupper" ;; "weakref"

    ;; Table
    "rawget" "rawset" "rawdelete" "rawin" ;; "len" "weakref"
    "clear" "setdelegate" "getdelegate" "filter" "keys" "values" ;; "tostring"

    ;; Array
    "append" "push" "extend" "pop" "top" "insert" ;; "len"
    "remove" "resize" "sort" "reverse" ;; "slice" "weakref"
    "map" "apply" "reduce" ;; "filter" "find" "tostring" "clear"

    ;; Function
    "call" "pcall" "acall" "pacall" ;; "weakref" "tostring"
    "setroot" "getroot" "bindenv" "getinfos"

    ;; Class
    "instance" "getattributes" "setattributes" ;; "rawin"
    "newmember" "rawnewmember" ;; "weakref" "tostring" "rawget" "rawset"

    ;; Class Instance
    "getclass" ;; "rawin" "weakref" "tostring" "rawget" "rawset"

    ;; Generator
    "getstatus" ;; "weakref" "tostring"

    ;; Thread
    "wakeup" "wakeupthrow" ;; "getstatus" "weakref" "call"
    "getstackinfos" ;; "tostring"

    ;; Weak Reference
    ;;"weakref" "tostring"
    "ref"))

(defconst squirrel-operators
  '("!" "!=" "||" "==" "&&" ">=" "<=" ">"
    "<=>" "+" "+=" "-" "-=" "/" "/=" "*"
    "*=" "%" "%=" "++" "--" "<-" "=" "&"
    "^" "|" "~" ">>" "<<" ">>>"))


(defconst squirrel-constants
  '("__LINE__" "__FILE__"
    "_version_" "_charsize_"
    "_intsize_" "_floatsize_"
    "_versionnumber_"
    "true" "false"))

(defconst squirrel-font-lock-keywords
  (list
   `("\\(#.*\\)" . font-lock-comment-face)
   `("\\(</\\)" . font-lock-doc-face)
   `("\\(/>\\)" . font-lock-doc-face)
   `(,(regexp-opt squirrel-constants 'symbols) . font-lock-constant-face)
   `(,(regexp-opt squirrel-keywords 'symbols) . font-lock-keyword-face)
   `(,(concat (regexp-opt squirrel-builtins 'symbols)  "[[:space:]]*(") . (1 font-lock-builtin-face ))
   `(,(concat (regexp-opt squirrel-builtins-default-delegates 'symbols)  "[[:space:]]*(") . (1 font-lock-builtin-face ))
   `(,(concat "function[[:space:]]*" (regexp-opt squirrel-builtins-metamethods 'symbols)  "[[:space:]]*(") . (1 font-lock-builtin-face ))
   `(,(concat  (regexp-opt squirrel-builtins-metamethods 'symbols)  "[[:space:]]*=[[:space:]]*function[[:space:]]*(") . (1 font-lock-builtin-face ))
   `("function[[:space:]]*\\<\\(.*\\)\\>[[:space:]]*(" . (1 font-lock-function-name-face))
   `("local[[:space:]]*\\<\\(.*\\)\\>[[:space:]]*=[[:space:]]*function[[:space:]]*(" . (1 font-lock-function-name-face))
   `("\\<\\(.*\\)\\>[[:space:]]*=[[:space:]]*function[[:space:]]*(" . (1 font-lock-function-name-face))
   `("\\<\\(.*\\)\\>[[:space:]]*<-[[:space:]]*function[[:space:]]*(" . (1 font-lock-function-name-face))
   `("class[[:space:]]*\\<\\(.*\\)\\>[[:space:]]*extends[[:space:]]*\\<\\(.*\\)\\>" (1 font-lock-type-face) (2 font-lock-type-face))
   `("class[[:space:]]*\\<\\(.*\\)\\>" . (1 font-lock-type-face))
   `("\\<\\(.*\\)\\>[[:space:]]*<-[[:space:]]*class" . (1 font-lock-type-face))
   `("local[[:space:]]*\\<\\(.*\\)\\>[[:space:]]*=" . (1 font-lock-variable-name-face))
   `("static[[:space:]]*\\<\\(.*\\)\\>[[:space:]]*=" . (1 font-lock-variable-name-face))
   `("\\<\\(.*\\)\\>[[:space:]]*=" . (1 font-lock-variable-name-face))
   `("\\<\\(.*\\)\\>[[:space:]]*<-" . (1 font-lock-variable-name-face))
   `(,(regexp-opt squirrel-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode squirrel-mode prog-mode "Squirrel"
  "A major mode for the Squirrel programming language."
  :syntax-table squirrel-mode-syntax-table
  (setq-local font-lock-defaults '(squirrel-font-lock-keywords))
  (setq-local comment-start "# ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.nut\\'" . squirrel-mode))

(provide 'squirrel-mode)

;;; squirrel-mode.el ends here
