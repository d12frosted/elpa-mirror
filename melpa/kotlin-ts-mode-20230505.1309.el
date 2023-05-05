;;; kotlin-ts-mode.el --- A mode for editing Kotlin files based on tree-sitter  -*- lexical-binding: t; -*-

;; Copyright 2022 Alex Figl-Brick

;; Author: Alex Figl-Brick <alex@alexbrick.me>
;; Version: 0.1
;; Package-Version: 20230505.1309
;; Package-Commit: b5ebf49c7b29a49151ff000ba5d040ea0801a9c7
;; Package-Requires: ((emacs "29"))
;; URL: https://gitlab.com/bricka/emacs-kotlin-ts-mode

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package uses the `treesit' functionality added in Emacs 29 to
;; provide a nice mode for editing Kotlin code.

;;; Code:

(require 'treesit)
(require 'project)
(eval-when-compile
  (require 'subr-x))

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-defun-name "treesit.c")
(declare-function treesit-node-next-sibling "treesit.c")
(declare-function treesit-node-end "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-child "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-search-subtree "treesit.c")
(declare-function treesit-thing-at-point "treesit.c")

(defvar kotlin-ts-mode-indent-offset 4)

(defvar kotlin-ts-mode-syntax-table
  (let ((st (make-syntax-table)))

    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\' "\"" st)
    (modify-syntax-entry ?` "\"" st)

    ;; `_' and `@' as being a valid part of a symbol
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?@ "_" st)

    ;; b-style comment
    (modify-syntax-entry ?/ ". 124" st)
    (modify-syntax-entry ?* ". 23b" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\r "> b" st)
    st))

(defconst kotlin-ts-mode--special-string-child-node-types
  '("interpolated_identifier" "interpolated_expression" "${" "}" "$")
  "Node types that appear in a string that have a special face.")

(defun kotlin-ts-mode--fontify-string (node override start end &rest _)
  "Fontify a string but not any substitutions inside of it.

See `treesit-font-lock-rules' for more details.  NODE is the string node.  START
and END mark the region to be fontified.  OVERRIDE is the override flag.

This function is heavily inspired by `js--fontify-template-string'."
  (let ((child (treesit-node-child node 0))
        (font-beg (treesit-node-start node)))
    (while child
      (let ((font-end (if (member (treesit-node-type child) kotlin-ts-mode--special-string-child-node-types)
                          (treesit-node-start child)
                        (treesit-node-end child))))
        (setq font-beg (max start font-beg))
        (when (< font-beg end)
          (treesit-fontify-with-override
           font-beg font-end 'font-lock-string-face override start end)))
      (setq font-beg (treesit-node-end child)
            child (treesit-node-next-sibling child)))))

(defun kotlin-ts-mode--fontify-not-is (node override start end &rest _)
  "Fontify the '!is' string inside of type checks.

See `treesit-font-lock-rules' for more details.  NODE is the string node.  START
and END mark the region to be fontified.  OVERRIDE is the override flag."
  (let ((start-pos (treesit-node-start node)))
    (treesit-fontify-with-override
     start-pos (1+ start-pos) 'font-lock-negation-char-face override start end)
    (treesit-fontify-with-override
     (1+ start-pos) (+ start-pos 3) 'font-lock-keyword-face override start end)))

;; Based on https://github.com/fwcd/tree-sitter-kotlin/pull/50
(defvar kotlin-ts-mode--treesit-settings
  (when (treesit-available-p)
    (treesit-font-lock-rules
     :language 'kotlin
     :feature 'keyword
     '(;; `it` keyword inside lambdas
       ;; FIXME: This will highlight the keyword outside of lambdas since tree-sitter
       ;;        does not allow us to check for arbitrary nestation
       ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "it"))

       ;; `field` keyword inside property getter/setter
       ;; FIXME: This will highlight the keyword outside of getters and setters
       ;;        since tree-sitter does not allow us to check for arbitrary nestation
       ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "field"))

       ;; `this` this keyword inside classes
       (this_expression "this") @font-lock-keyword-face

       ;; `super` keyword inside classes
       (super_expression) @font-lock-keyword-face

       ["val" "var" "enum" "class" "object" "interface"] @font-lock-keyword-face

       (package_header "package" @font-lock-keyword-face)

       ["import" "as"] @font-lock-keyword-face

       (primary_constructor "constructor" @font-lock-keyword-face)
       (constructor_delegation_call "this" @font-lock-keyword-face)
       (secondary_constructor "constructor" @font-lock-keyword-face)

       (type_alias "typealias" @font-lock-keyword-face)
       [
        (class_modifier)
        (member_modifier)
        (function_modifier)
        (property_modifier)
        (platform_modifier)
        (variance_modifier)
        (parameter_modifier)
        (visibility_modifier)
        (reification_modifier)
        (inheritance_modifier)
        ] @font-lock-keyword-face

       (companion_object "companion" @font-lock-keyword-face)
       (function_declaration "fun" @font-lock-keyword-face)

       (jump_expression ["throw" "return" "return@" "continue" "continue@" "break" "break@"] @font-lock-keyword-face)

       ["if" "else"] @font-lock-keyword-face
       (when_expression ["when"] @font-lock-keyword-face)
       (for_statement "for" @font-lock-keyword-face)
       (while_statement "while" @font-lock-keyword-face)
       (do_while_statement ["do" "while"] @font-lock-keyword-face)

       ["in" "throw"] @font-lock-keyword-face

       (infix_expression (simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "to"))

       (try_expression "try" @font-lock-keyword-face)
       (catch_block "catch" @font-lock-keyword-face)
       (finally_block "finally" @font-lock-keyword-face)

       "is" @font-lock-keyword-face
       "!is" @kotlin-ts-mode--fontify-not-is

       (prefix_expression "!" @font-lock-negation-char-face))

     :language 'kotlin
     :feature 'comment
     '([(comment) (shebang_line)] @font-lock-comment-face)

     :language 'kotlin
     :feature 'string
     '((character_literal) @font-lock-string-face
       [(line_string_literal) (multi_line_string_literal)] @kotlin-ts-mode--fontify-string
       (line_string_literal ["$" "${" "}"] @font-lock-builtin-face)
       (multi_line_string_literal ["$" "${" "}"] @font-lock-builtin-face))

     :language 'kotlin
     :feature 'escape-sequence
     :override t
     '((character_escape_seq) @font-lock-escape-face)

     :language 'kotlin
     :feature 'definition
     '((function_declaration (simple_identifier) @font-lock-function-name-face)
       (parameter (simple_identifier) @font-lock-variable-name-face)
       (class_parameter (simple_identifier) @font-lock-variable-name-face)
       (variable_declaration (simple_identifier) @font-lock-variable-name-face))

     :language 'kotlin
     :feature 'number
     '([(integer_literal) (long_literal) (hex_literal) (bin_literal) (unsigned_literal) (real_literal)] @font-lock-number-face)

     :language 'kotlin
     :feature 'type
     '((type_identifier) @font-lock-type-face
       (enum_entry (simple_identifier) @font-lock-type-face)
       (call_expression (simple_identifier) @font-lock-type-face
                        (:match "^[A-Z]" @font-lock-type-face))
       (navigation_expression (simple_identifier) @font-lock-type-face
                              (:match "^[A-Z]" @font-lock-type-face)))

     :language 'kotlin
     :feature 'function
     '((call_expression (navigation_expression (navigation_suffix (simple_identifier) @font-lock-function-name-face)))
       (call_expression (simple_identifier) @font-lock-function-name-face))

     :language 'kotlin
     :feature 'property
     '((navigation_expression (navigation_suffix (simple_identifier) @font-lock-property-face)))

     :language 'kotlin
     :feature 'constant
     :override t
     '(["null" (boolean_literal)] @font-lock-constant-face
       ((simple_identifier) @font-lock-constant-face
        (:match "^[A-Z_][A-Z_\\d]*$" @font-lock-constant-face)))

     :language 'kotlin
     :feature 'builtin
     :override t
     '((call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "listOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "arrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "arrayOfNulls"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "byteArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "shortArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "intArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "longArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "ubyteArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "ushortArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "uintArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "ulongArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "floatArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "doubleArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "booleanArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "charArrayOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "emptyArray"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "mapOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "setOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "listOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "emptyMap"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "emptySet"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "emptyList"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "mutableMapOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "mutableSetOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "mutableListOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "print"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "println"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "error"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "TODO"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "run"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "runCatching"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "repeat"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "lazy"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "lazyOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "enumValues"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "enumValueOf"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "assert"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "check"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "checkNotNull"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "require"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "requireNotNull"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "with"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "suspend"))
       (call_expression (simple_identifier) @font-lock-builtin-face
                        (:equal @font-lock-builtin-face "synchronized")))

     :language 'kotlin
     :feature 'variable
     '((simple_identifier) @font-lock-variable-name-face))))

(defconst kotlin-ts-mode--treesit-indent-rules
  (let ((offset kotlin-ts-mode-indent-offset))
    `((kotlin
       ((node-is "}") parent-bol 0)
       ((node-is ")") parent-bol 0)
       ((parent-is "statements") parent-bol 0)
       ((parent-is "catch_block") parent-bol ,offset)
       ((parent-is "class_body") parent-bol ,offset)
       ((parent-is "control_structure_body") parent-bol ,offset)
       ((parent-is "finally_block") parent-bol ,offset)
       ((parent-is "function_body") parent-bol ,offset)
       ((parent-is "lambda_literal") parent-bol ,offset)
       ((parent-is "primary_constructor") parent-bol ,offset)
       ((parent-is "secondary_constructor") parent-bol ,offset)
       ((parent-is "try_expression") parent-bol ,offset)
       ((parent-is "value_arguments") parent-bol ,offset)
       ((parent-is "when_expression") parent-bol ,offset)
       ((parent-is "comment") parent-bol 1)))))

;; Imenu

(defun kotlin-ts-mode--defun-name (node)
  "Return the name of the defun node if NODE is a defun node.

Else return nil."
  (pcase (treesit-node-type node)
    ("class_declaration"
     (treesit-node-text (treesit-search-subtree node (regexp-quote "type_identifier") nil nil 1) t))
    ("function_declaration"
     (treesit-node-text (treesit-search-subtree node (regexp-quote "simple_identifier") nil nil 1) t))))

(defun kotlin-ts-mode--imenu-1 (tree)
  "Helper for `kotlin-ts-mode--imenu'.

Take in a sparse tree TREE and map the symbols to their positions."
  (mapcar (lambda (child) (cons (treesit-defun-name child) (treesit-node-start child))) (flatten-list tree)))

(defun kotlin-ts-mode--imenu ()
  "Return Imenu alist for the current buffer."
  (let* ((root-node (treesit-buffer-root-node))
         (class-tree (treesit-induce-sparse-tree root-node "^class_declaration$" nil 10))
         (class-entries (kotlin-ts-mode--imenu-1 class-tree))
         (function-tree (treesit-induce-sparse-tree root-node "^function_declaration$" nil 10))
         (function-entries (kotlin-ts-mode--imenu-1 function-tree)))
    (append
     (when class-entries `(("Class" . ,class-entries)))
     (when function-entries `(("Function" . ,function-entries))))))

(defun kotlin-ts-mode-goto-test-file ()
  "Go from the current file to the test file."
  (interactive)
  (if (not (string-match-p (regexp-quote "src/main/kotlin") (buffer-file-name)))
      (warn "Could not find test file for %s" (buffer-file-name))
    (let* ((test-directory (file-name-directory (string-replace "src/main/kotlin" "src/test/kotlin" (buffer-file-name))))
           (file-name-as-test (concat (file-name-base (buffer-file-name)) "Test.kt"))
           (test-file-location (concat test-directory file-name-as-test)))
      (find-file test-file-location))))

(defun kotlin-ts-mode--get-package-name ()
  "Determine the name of the package of the current file."
  (let* ((root-node (treesit-buffer-root-node))
         (package-node (treesit-search-subtree root-node (regexp-quote "package_header"))))
    (when package-node
      (treesit-node-text (treesit-node-child package-node 1) t))))

(defun kotlin-ts-mode--get-class-name ()
  "Determine the name of the class containing point."
  (let ((class-node (treesit-thing-at-point (regexp-quote "class_declaration") 'nested)))
    (when class-node (treesit-defun-name class-node))))

(defun kotlin-ts-mode--get-function-name ()
  "Determine the name of the function containing point."
  (let ((function-node (treesit-thing-at-point (regexp-quote "function_declaration") 'nested)))
    (when function-node (treesit-defun-name function-node))))

(defun kotlin-ts-mode--qualify-name (&rest names)
  "Return a string that fully qualifies the given NAMES.

This function will strip out any surrounding backtick characters
in the individual names."
  (string-join (mapcar
                (lambda (name)
                  (replace-regexp-in-string "^`" "" (replace-regexp-in-string "`$" "" name)))
                names)
               "."))

(defun kotlin-ts-mode--in-gradle-project-p ()
  "Return t if the current buffer is in a project with a local Gradle installation."
  (file-exists-p (string-join `(,(project-root (project-current)) "gradlew") "/")))

(defun kotlin-ts-mode--run-gradle-command (task args)
  "Run the given Gradle TASK with the given ARGS."
  (let ((default-directory default-directory)
        (exec-path exec-path)
        (command "gradle")
        (buffer (get-buffer-create "*kotlin-ts-mode[gradle]*")))
    (when (kotlin-ts-mode--in-gradle-project-p)
      (setq default-directory (project-root (project-current))
            command "./gradlew"
            exec-path (list nil)))
    (with-current-buffer buffer
      (erase-buffer))
    (display-buffer buffer)
    (apply #'call-process command nil buffer t task args)))

(defun kotlin-ts-mode-run-current-test-function ()
  "Run the current test function."
  (interactive)
  (let* ((package-name (kotlin-ts-mode--get-package-name))
         (class-name (kotlin-ts-mode--get-class-name))
         (function-name (kotlin-ts-mode--get-function-name)))
    (if (not (and package-name class-name function-name))
        (warn "Could not find the package, class, and function name.")
      (kotlin-ts-mode--run-gradle-command
       "test"
       (list
        (concat
         "--tests="
         (kotlin-ts-mode--qualify-name
          package-name
          class-name
          function-name)))))))

;;;###autoload
(define-derived-mode kotlin-ts-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin using tree-sitter."
  (when (treesit-ready-p 'kotlin)
    (treesit-parser-create 'kotlin)

    (setq-local treesit-defun-name-function #'kotlin-ts-mode--defun-name)

    ;; Comments
    ;; Stolen from c-ts-mode
    (setq-local comment-start "/* ")
    (setq-local comment-end " */")
    (setq-local comment-start-skip (rx (or (seq "/" (+ "/"))
                                           (seq "/" (+ "*")))
                                       (* (syntax whitespace))))
    (setq-local comment-end-skip
                (rx (* (syntax whitespace))
                    (group (or (syntax comment-end)
                               (seq (+ "*") "/")))))

    ;; Electric
    (setq-local electric-indent-chars
                (append "{}():;," electric-indent-chars))

    ;; Syntax Highlighting
    (setq-local treesit-font-lock-settings kotlin-ts-mode--treesit-settings)
    (setq-local treesit-font-lock-feature-list '((comment number string definition)
                                                 (keyword builtin type constant variable)
                                                 (escape-sequence function property)))

    ;; Indent
    (setq-local treesit-simple-indent-rules kotlin-ts-mode--treesit-indent-rules)

    ;; Imenu
    (setq-local imenu-create-index-function #'kotlin-ts-mode--imenu)
    (setq-local which-func-functions nil)

    (treesit-major-mode-setup)

    :syntax-table kotlin-ts-mode-syntax-table))

(provide 'kotlin-ts-mode)
;;; kotlin-ts-mode.el ends here
