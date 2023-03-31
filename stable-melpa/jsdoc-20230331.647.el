;;; jsdoc.el --- Insert JSDoc comments -*- lexical-binding: t -*-

;; Copyright (C) 2021 Isa Mert Gurbuz
;; Copyright (C) 2023 Demis Balbach, Isa Mert Gurbuz

;; Author: Isa Mert Gurbuz <isamertgurbuz@gmail.com>
;; Version: 0.3
;; Package-Version: 20230331.647
;; Package-Commit: 10606a37f70cbf419590bbbc292fe1e800435ed5
;; URL: https://github.com/isamert/jsdoc.el
;; Package-Requires: ((emacs "29.1") (dash "2.11.0") (s "1.12.0"))

;; This program is free software; you can redistribute it and/or modify
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

;; This package provides an easy way to insert JSDoc function comments
;; and typedefs.  It leverages a variety of techniques to generate
;; documentation as much as possible without human interaction,
;; including type inference and other similar approaches.

;;; Code:

(require 's)
(require 'dash)
(require 'treesit)

(defgroup jsdoc nil
  "A media player for Emacs."
  :group 'tools)

(defcustom jsdoc-append-dash t
  "Whether to append \" - \" after @param, @returns etc. to enhance readability."
  :type 'boolean
  :group 'jsdoc)

;;;###autoload
(defun jsdoc ()
  "Insert a JSDoc function comment or a typedef for an object."
  (interactive)
  (let* ((meta (jsdoc--generate))
         (col (current-indentation))
         (params (plist-get meta :params))
         (returns (plist-get meta :returns))
         (throws (plist-get meta :throws)))
    (jsdoc--insert-line col 'beg nil)
    (jsdoc--insert-line col 'empty nil)
    (--each params (jsdoc--insert-line col 'mid 'param it))
    (when throws
      (jsdoc--insert-line col 'mid 'throws throws))
    (when returns
      (jsdoc--insert-line col 'mid 'returns returns))
    (jsdoc--insert-line col 'end nil)))

;; Some important resources:
;; https://github.com/tree-sitter/tree-sitter-javascript/blob/master/src/grammar.json
;; https://github.com/tree-sitter/tree-sitter-javascript/blob/master/src/node-types.json

(defun jsdoc--insert-line (col-no w tag &optional it)
  (let* ((col (s-repeat col-no " "))
         (tag-text (pcase tag
                     ('param (jsdoc--format-param it))
                     ('throws (format "@throws {%s} " it))
                     ('returns (format "@returns {%s} " it))
                     (_ nil)))
         (tag-text-fixed (if (and jsdoc-append-dash tag-text)
                             (s-concat tag-text "- ")
                           tag-text))
         (start (pcase w
                  ('beg "/**" )
                  ('end " */")
                  ('empty " * ")
                  (_ " * "))))
    (move-beginning-of-line nil)
    (insert (format "%s%s%s\n" (or col "") (or start "") (or tag-text-fixed "")))))

(defun jsdoc--format-param (it)
  (format
   "@param {%s} %s "
   (plist-get it :type)
   (if (plist-get it :default)
       (format "[%s=%s]" (plist-get it :name) (plist-get it :default))
     (plist-get it :name))))

(defun jsdoc--generate ()
  (let* ((curr-node (treesit-node-parent (treesit-node-at (point))))
         (curr-node-type (treesit-node-type curr-node)))
    (pcase curr-node-type
      ("lexical_declaration"
       (jsdoc--parse-lexical-declaration curr-node))
      ((or "function_declaration" "method_definition")
       (jsdoc--parse-generic-function-declaration curr-node)))))

(defun jsdoc--parse-lexical-declaration (node)
  (let* ((fn-def (treesit-node-child node 0 t))
         (name (jsdoc--tsc-child-text fn-def "name"))
         (fn (treesit-node-child fn-def 1 t))
         (fn-type (treesit-node-type fn)))
    (pcase fn-type
      ((or "arrow_function" "function") (jsdoc--parse-generic-function fn name)))))

(defun jsdoc--parse-generic-function-declaration (node)
  (let* ((name (jsdoc--tsc-child-text node "name")))
    (jsdoc--parse-generic-function node name)))

(defun jsdoc--parse-method-definition (node)
  (let* ((name (jsdoc--tsc-child-text node "name")))
    (jsdoc--parse-generic-function node name)))

(defun jsdoc--parse-generic-function (fn name)
  (let* ((params (or (treesit-node-child-by-field-name fn "parameters") (treesit-node-child fn 0))))
    (list
     :name name
     :returns (jsdoc--get-return-type fn)
     :throws (jsdoc--get-throw-type fn)
     :params (--map (jsdoc--parse-param it) (or (jsdoc--tsc-named-children params) (list params))))))

(defun jsdoc--parse-param (param)
  "Parse PARAM and return it's name with type and the default value if it exists."
  (pcase (treesit-node-type param)
    ("identifier"
     (list
      :name (treesit-node-text param)
      :type "*"))
    ("shorthand_property_identifier_pattern"
     (list
      :name (treesit-node-text param)
      :type "*"))
    ("assignment_pattern"
     (list
      :name (plist-get (jsdoc--parse-param (treesit-node-child-by-field-name param "left")) :name)
      :default (treesit-node-text (treesit-node-child-by-field-name param "right"))
      :type (jsdoc--infer-type (treesit-node-child-by-field-name param "right"))))
    ("array_pattern"
     (list
      :name 'unnamed-param
      :type (jsdoc--infer-array-type (jsdoc--tsc-named-children param))))
    ("object_pattern"
     (list
      :name 'unnamed-param
      :type "Object"))
    ("rest_pattern"
     (list
      :name (treesit-node-text (treesit-node-child param 0 t))
      :type "...*"))))

(defun jsdoc--infer-type (node)
  (pcase (treesit-node-type node)
    ("identifier" (jsdoc--infer-identifier node))
    ("true" "boolean")
    ("false" "boolean")
    ("number" "number")
    ("string" "string")
    ("array" "*[]")
    ("object" "object")
    ("new_expression" (jsdoc--infer-type (treesit-node-child node 0 t)))
    ("call_expression" (jsdoc--infer-type (treesit-node-child node 0 t)))
    ("arrow_function" (jsdoc--infer-closure-type node))
    ("binary_expression" (jsdoc--infer-binary-expression node))
    (_ "*")))

(defun jsdoc--infer-closure-type (node)
  "Return the inferred type of the given closure NODE."
  (let* ((fn (jsdoc--parse-generic-function node ""))
         (params (s-join ", " (--map (plist-get it :type) (plist-get fn :params))))
         (returns (plist-get fn :returns)))
    (concat "function(" params "): " returns)))

(defun jsdoc--infer-array-type (node)
  "Return the inferred type of the given array NODE."
  (let* ((params (--reduce
                  (if (eq acc it)
                      acc
                    (s-concat acc "|" it))
                  (--map (plist-get (jsdoc--parse-param it) :type) node))))
    (if (string-match-p (regexp-quote "|") params)
        (concat "(" params ")" "[]")
      (concat params "[]"))))

(defun jsdoc--infer-binary-expression (_node)
  (format "TODO"))

(defun jsdoc--infer-identifier (node)
  "Return given identifier NODE type.  `X' if `X()', otherwise `*'."
  (let* ((next-sibling (treesit-node-next-sibling node t)))
    (if (and next-sibling
             (equal (treesit-node-type next-sibling) "arguments")
             (s-uppercase? (substring (treesit-node-text node) 0 1)))
        (treesit-node-text node)
      "*")))

(defun jsdoc--get-return-type (node)
  "Return the return type of given NODE."
  (-if-let (return-type (jsdoc--get-returned-type-of-statement node "return_statement"))
      (pcase (treesit-node-text (treesit-node-child node 0))
        ("async" (format "Promise<%s>" return-type))
        (_ return-type))
    (progn
      (jsdoc--infer-type (treesit-node-child-by-field-name node "body")))))

(defun jsdoc--get-throw-type (node)
  "Retun throw type of given NODE if it throws anythng.
Otherwise return nil."
  (--> (jsdoc--get-returned-type-of-statement node "throw_statement")
    (if (and it (s-contains? "|" it))
        (format "(%s)" it)
      it)))

(defun jsdoc--get-returned-type-of-statement (node stmt)
  "Find the STMT somewhere under NODE and return the type."
  (-->
   (jsdoc--tsc-find-descendants-with-type node stmt)
   (--map (jsdoc--infer-type (treesit-node-child it 1)) it)
   (-distinct it)
   (when it
     (--reduce (format "%s | %s" acc it) it))))


;;
;; tsc utils
;;

(defun jsdoc--tsc-child-text (node prop)
  (treesit-node-text (treesit-node-child-by-field-name node prop)))

(defun jsdoc--tsc-children (node)
  (--map (treesit-node-child node it) (number-sequence 0 (1- (treesit-node-child-count node)))))

(defun jsdoc--tsc-named-children (node)
  (--map (treesit-node-child node it t) (number-sequence 0 (1- (treesit-node-child-count node t)))))

(defun jsdoc--tsc-find-descendants-with-type (node type)
  (-flatten (--map (if (equal type (treesit-node-type it))
                       it
                     (jsdoc--tsc-find-descendants-with-type it type))
                   (jsdoc--tsc-children node))))

(provide 'jsdoc)
;;; jsdoc.el ends here
