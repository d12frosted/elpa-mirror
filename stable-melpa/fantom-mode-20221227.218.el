;;; fantom-mode.el --- A major mode for the Fantom programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221227.218
;; Package-Commit: 51cd82d29a7dca7bfd043971ba1d0fd21ed11693
;; Author: XXIV
;; Keywords: files, fantom
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/fantom-mode

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

;; A major mode for the Fantom programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET fantom-mode RET` to install the mode.
;; Use `M-x fantom-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/fantom-mode.git

;; Then add path to fantom-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/fantom-mode/")
;; (require 'fantom-mode)

;; Use `M-x fantom-mode` to change your current mode.

;;; Code:

(defconst fantom-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst fantom-keywords
  '("abstract" "foreach" "return"
    "as" "if" "static"
    "assert" "internal" "super"
    "break" "is" "switch"
    "case" "isnot" "this"
    "catch" "it" "throw"
    "class" "mixin" ;; "true"
    "const" "native" "try"
    "continue" "new" "using"
    "default" "virtual" ;; "null"
    "do" "once" "volatile"
    "else" "override" "void"
    "private" "while" ;; "false"
    "final" "protected"
    "finally" "public"
    "for" "readonly"
    "enum" "facet"))


(defconst fantom-primitive-data-types
  '("Obj" "Str" "Int" "Decimal"
    "Uri" "Bool" "Void" "Weekday" 
    "DateTime" "Duration" "Enum"
    "Field" "Float" "List" "Map" 
    "Method" "Month" "Range" "Slot"))


(defconst fantom-operators
  '("." ";" "," ":"
    "::" "+" "-" "*"
    "/" "%" "#" "++"
    "--" "!" "?" "~"
    "|" "&" "^" "@"
    "||" "&&" "===" "!=="
    "==" "!=" "<=>" "<"
    "<=" ">" ">=" ".."
    "..<" ":=" "=" "+="
    "-=" "*=" "/=" "%="
    "->" "?:" "?." "?->"
    "$"))


(defconst fantom-constants
  '("true" "false" "null"))


(defconst fantom-font-lock-keywords
  (list
   `("\\(\\*\\*.*\\)" . font-lock-comment-face)
   `(,(regexp-opt fantom-constants 'words) . font-lock-constant-face)
   `(,(regexp-opt fantom-primitive-data-types 'symbols) . font-lock-type-face)
   `(,(regexp-opt fantom-keywords 'symbols) . font-lock-keyword-face)
   `("\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*(" . (1 font-lock-function-name-face))
   `(,(regexp-opt fantom-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode fantom-mode prog-mode "Fantom"
  "A major mode for the Fantom programming language."
  :syntax-table fantom-mode-syntax-table
  (setq-local font-lock-defaults '(fantom-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fan\\'" . fantom-mode))

(provide 'fantom-mode)

;;; fantom-mode.el ends here
