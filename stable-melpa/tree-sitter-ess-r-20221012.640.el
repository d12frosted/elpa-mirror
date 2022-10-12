;;; tree-sitter-ess-r.el --- R with tree-sitter  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2022  Shuguang Sun

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2021/11/30
;; Version: 1.0
;; Package-Version: 20221012.640
;; Package-Commit: 9eb7c35a11d917bc417d8b7b109ed336d58bea53
;; URL: https://github.com/ShuguangSun/tree-sitter-ess-r
;; Package-Requires: ((emacs "26.1") (ess "18.10.1") (tree-sitter "0.12.1") (tree-sitter-langs "0.12.0"))
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
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

;; R with tree-sitter

;; (require 'tree-sitter-ess-r)
;; (add-hook 'ess-r-mode-hook 'tree-sitter-ess-r-mode-activate)
;; or
;; M-x tree-sitter-ess-r-using-r-faces


;; Make tree-sitter to support r

;; Linux
;; 1. git clone https://github.com/r-lib/tree-sitter-r.git
;; 2. gcc ./src/parser.c ./src/scanner.cc -lstdc++ -fPIC -I./ -I./src/ -I./src/tree_sitter --shared -o r.so
;; 3. cp ./r.so /path/to/tree-sitter-langs/langs/bin (/path/to/tree-sitter-langs/ is path of your tree-sitter-langs package)
;; 4. mkdir /path/to/tree-sitter-langs/queries/r
;; 5. cp ./queries/* /path/to/tree-sitter-langs/queries/r


;; Windows (MINGW64)
;; 1. git clone https://github.com/r-lib/tree-sitter-r.git
;; 2. gcc ./src/parser.c ./src/scanner.cc -lstdc++ -fPIC -I./ -I./src/ -I./src/tree_sitter --shared -o r.dll
;; 3. cp ./r.dll /path/to/tree-sitter-langs/langs/bin (/path/to/tree-sitter-langs/ is path of your tree-sitter-langs package)
;; 4. mkdir /path/to/tree-sitter-langs/queries/r
;; 5. cp ./queries/* /path/to/tree-sitter-langs/queries/r


;;; Code:

(require 'ess-r-mode)
(require 'tree-sitter)
(require 'tree-sitter-hl)
(require 'tree-sitter-langs)
(require 'tree-sitter-query)

(defgroup tree-sitter-ess-r ()
  "R with tree-sitter support."
  :group 'tree-sitter
  :prefix "tree-sitter-ess-r-")

(defface tree-sitter-ess-r-matrix-face
  '((default :inherit ess-matrix-face))
  "Face for matrix."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-operator-face
  '((default :inherit ess-operator-face))
  "Face for operators."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-punctuation.bracket-face
  '((default :inherit ess-paren-face))
  "Face for brackets."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-repeat-face
  '((default :inherit ess-keyword-face))
  "Face for repeat keyword."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-assignment-face
  '((default :inherit ess-assignment-face)) ;; ess-assignment-face
  "Face for assignment."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-opspecial-face
  '((default :inherit ess-%op%-face))
  "Face for special `%...%'."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-operatorcomp-face
  '((default :inherit ess-operator-face))
  "Face for REL, OR and AND."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-operatorpipe-face
  '((default :inherit ess-%op%-face))
  "Face for `|>' operator."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-function-face
  '((default :inherit ess-function-call-face))
  "Face for function all."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-conditional-face
  '((default :inherit r-control-flow-keyword-face))
  "Face for control flow keyword."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-keyword.function-face
  '((default :inherit ess-keyword-face))
  "Face for keyword.function."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-float-face
  '((default :inherit ess-numbers-face))
  "Face for numbers."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-number-face
  '((default :inherit ess-numbers-face))
  "Face for numbers."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-modifier-face
  '((default :inherit ess-modifiers-face))
  "Face for modifiers."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-boolean-face
  '((default :inherit ess-constant-face))
  "Face for boolean."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-method-face
  '((default :inherit tree-sitter-ess-r-function-face))
  "Face for method declarations and definitions."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-namespace-face
  '((default :inherit ess-function-call-face))
  "Face for namespace."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-dollar-face
  '((default :inherit ess-operator-face))
  "Face for dollar."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-slot-face
  '((default :inherit ess-operator-face))
  "Face for slot."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-error-face
  '((default :inherit font-lock-warning-face))
  "Face for errors."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-comment-face
  '((default :inherit font-lock-comment-face))
  "Face for comments."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-string-face
  '((default :inherit font-lock-string-face))
  "Face for strings."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-doc-face
  '((default :inherit font-lock-doc-face))
  "Face for docs."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-operatorunary-face
  '((default :inherit font-lock-warning-face))
  "Face for some unary operator."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-parameter-face
  '((default :inherit font-lock-builtin-face)) ;;  :slant italic ;;  :weight normal
  "Face for parameters."
  :group 'tree-sitter-ess-r)

(defface tree-sitter-ess-r-varname-face
  '((default :inherit font-lock-variable-name-face)) ;;  :slant italic
  "Face for variable names."
  :group 'tree-sitter-ess-r)

(add-to-list 'tree-sitter-major-mode-language-alist '(ess-r-mode . r))

;; Some additional patterns.
(tree-sitter-hl-add-patterns 'r
  [;; (arguments "=" @operator)
   ;; (formal_parameters "=" @operator)
   (function_definition "function" @keyword.function)
   (["<-" "<<-" "->" "->>"] @assignment)
   (equals_assignment "=" @assignment)
   ;; (left_assignment name: (identifier) @varname)
   ;; (equals_assignment name: (identifier) @varname)
   ;; (right_assignment name: (identifier) @varname)
   (dollar "$" @dollar)
   (slot "@" @slot)
   (unary operator: ["-" "+" "!" "~"] @operatorunary)
   (binary operator: [
                      "<"
                      ">"
                      "<="
                      ">="
                      "=="
                      "!="
                      "||"
                      "|"
                      "&&"
                      "&"
                      ] @operatorcomp)
   (["|>"] @operatorpipe)
   (binary operator: [":" "~"] @opspecial)
   ((special) @opspecial)
   (call function: (identifier) @modifier
    (.match? @modifier "^(library|attach|detach|source|require|setwd|options|par|load|rm|message|warning|.Deprecated|signalCondition|withCallingHandlers)$"))
   ;; ((identifier) @modifier
   ;;  ;; (.match? @modifier `,(concat "^(" (mapconcat 'identity ess-R-modifiers "|") ")")))
   ;;  (.match? @modifier "^(library|attach|detach|source|require|setwd|options|par|load|rm|message|warning|.Deprecated|signalCondition|withCallingHandlers)$"))
   ])


(defun tree-sitter-ess-r-hl-face-from-ess-scope (capture-name)
  "Return the default face used to highlight CAPTURE-NAME."
  ;; TODO: If a scope does not have a corresponding face, check its ancestors.
  ;; (print capture-name)
  (pcase capture-name
    ("operator")
    (_ (intern (format "tree-sitter-ess-r-%s-face" capture-name)))))

(defun tree-sitter-ess-r-mode-activate ()
  "Hook to turn on tree-sitter-hl-mode."
  (setq-local tree-sitter-hl-face-mapping-function
              #'tree-sitter-ess-r-hl-face-from-ess-scope)
  (if (tree-sitter-require 'r)
      (tree-sitter-hl-mode 1)))

;;;###autoload
(defun tree-sitter-ess-r-using-r-faces ()
  "Turn on tree-sitter-hl-mode with ess-r-mode faces."
  (interactive)
  (add-hook 'ess-r-mode-hook #'tree-sitter-ess-r-mode-activate)
  (if (tree-sitter-require 'r)
      (tree-sitter-hl-mode 1)))


(provide 'tree-sitter-ess-r)
;;; tree-sitter-ess-r.el ends here
