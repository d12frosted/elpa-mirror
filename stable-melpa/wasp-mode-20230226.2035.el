;;; wasp-mode.el --- A major mode for the Wasp programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20230226.2035
;; Package-Commit: 00fc41ecfe0291cc32e012a074d8a3a65e1bfd64
;; Author: XXIV
;; Keywords: files, wasp
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/wasp-mode

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

;; A major mode for the Wasp programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET wasp-mode RET` to install the mode.
;; Use `M-x wasp-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/wasp-mode.git

;; Then add path to wasp-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/wasp-mode/")
;; (require 'wasp-mode)

;; Use `M-x wasp-mode` to change your current mode.

;;; Code:

(defconst wasp-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst wasp-keywords
  '("import" "from" "action"
    "app" "entity" "job"
    "page" "query" "route"))


(defconst wasp-builtins
  '("=json" "json="
    "=psl" "psl="))


(defconst wasp-constants
  '("true" "false"))

(defconst wasp-prisma-attributes
  `("id" "map" "default" "relation"
    "unique" "ignore"))

(defconst wasp-prisma-attributes-2
  `("id" "map" "unique" "ignore"
    "index" "fulltext"))

(defconst wasp-prisma-functions
  `("autoincrement" "cuid" "uuid" "now" "env"
    "dbgenerated"))

(defconst wasp-prisma-types
  `("Int" "Stwasp" "Boolean" "DateTime" "Float" "Decimal" "Json"))

(defconst wasp-prisma-constants
  `( ;; true, false
    "null"))

(defconst wasp-font-lock-keywords
  (list
   `(,(regexp-opt wasp-prisma-constants 'symbols) . font-lock-constant-face)
   `(,(regexp-opt wasp-constants 'symbols) . font-lock-constant-face)
   `(,(regexp-opt wasp-keywords 'symbols) . font-lock-keyword-face)
   `(,(regexp-opt wasp-builtins 'symbols) . font-lock-builtin-face)
   `(,(regexp-opt wasp-prisma-types 'symbols) . font-lock-type-face)
   `(,(concat "\\(@@" (mapconcat #'identity wasp-prisma-attributes-2 "\\|@@") "\\)") . font-lock-preprocessor-face)
   `(,(concat "\\(@" (mapconcat #'identity wasp-prisma-attributes "\\|@") "\\)") . font-lock-preprocessor-face)
   `(,(concat "\\(" (mapconcat #'identity wasp-prisma-functions "\\|") "\\)[[:space:]]*(") . (1 font-lock-function-name-face))
   `(,(concat "\\<" (regexp-opt wasp-keywords t) "[[:space:]]*\\([a-zA-Z_0-9_-]*\\)\\>") . (2 font-lock-type-face))
   `("import[[:space:]]*{[[:space:]]*\\<\\([a-zA-Z_0-9-]*\\)\\>[[:space:]]*}[[:space:]]*from" . (1 font-lock-type-face))
   `("import[[:space:]]*\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*from" . (1 font-lock-type-face))
   `("\\<\\([a-zA-Z0-9_]*\\)\\>[[:space:]]*:" . (1 font-lock-variable-name-face))))


;;;###autoload
(define-derived-mode wasp-mode prog-mode "Wasp"
  "A major mode for the Wasp programming language."
  :syntax-table wasp-mode-syntax-table
  (setq-local font-lock-defaults '(wasp-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wasp\\'" . wasp-mode))

(provide 'wasp-mode)

;;; wasp-mode.el ends here
