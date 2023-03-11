;;; chaos-mode.el --- A major mode for the Chaos programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221227.223
;; Package-Commit: 801d869c461166eb2face2554b9b7883a26374c6
;; Author: XXIV
;; Keywords: files, chaos
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/chaos-mode

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

;; A major mode for the Chaos programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET chaos-mode RET` to install the mode.
;; Use `M-x chaos-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/chaos-mode.git

;; Then add path to chaos-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/chaos-mode/")
;; (require 'chaos-mode)

;; Use `M-x chaos-mode` to change your current mode.

;;; Code:

(defconst chaos-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst chaos-keywords
  '("def" "import" "break" "times"
    "do" "end" "continue" "default"
    "foreach" "as" "from" "del" "exit"
    "quit" "symbol_table" "function_table"
    "print" "echo" "pretty" "return"))


(defconst chaos-primitive-data-types
  `("bool" "num" "str" "any"
    "list" "dict" "void"))


(defconst chaos-operators
  '(;; Relational Operators
    "==" "!=" ">" "<" ">=" "<="

    ;; Logical Operators
    "&&" "and" "||" "or" "!" "not"

    ;; Bitwise Operators
    "&" "|" "^" "~" "<<" ">>"

    ;; Unary Operators
    "++" "--"

    ;; Assignment operator
    "="))


(defconst chaos-constants
  '("true" "false" "null" "INFINITE"))


(defconst chaos-font-lock-keywords
  (list
   `("\\(#.*\\)" . font-lock-comment-face)
   `(,(regexp-opt chaos-constants 'words). font-lock-constant-face)
   `(,(regexp-opt chaos-primitive-data-types 'symbols) . font-lock-type-face)
   `(,(regexp-opt chaos-keywords 'symbols) . font-lock-keyword-face)
   `("def[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*(" . (1 font-lock-function-name-face))
   `("\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*(" . (1 font-lock-function-name-face))
   `(,(concat "\\<\\(" (mapconcat 'identity chaos-primitive-data-types "\\|") "\\)[[:space:]]*\\([a-zA-Z0-9_]*\\)\\>") . (2 font-lock-variable-name-face))
   `("\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*=" . (1 font-lock-variable-name-face))
   `(,(regexp-opt chaos-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode chaos-mode prog-mode "Chaos"
  "A major mode for the Chaos programming language."
  :syntax-table chaos-mode-syntax-table
  (setq-local font-lock-defaults '(chaos-font-lock-keywords))
  (setq-local comment-start "# ")
  (setq-local comment-end ""))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.kaos\\'" . chaos-mode))

(provide 'chaos-mode)

;;; chaos-mode.el ends here
