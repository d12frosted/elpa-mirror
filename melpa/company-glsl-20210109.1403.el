;;; company-glsl.el --- Support glsl in company-mode

;; Copyright (C) 2017 Guido Schmidt

;; Author: Guido Schmidt <git@guidoschmidt.cc>
;; Maintainer: Guido Schmidt <git@guidoschmidt.cc>
;; Original Author: Väinö Järvelä <vaino@jarve.la>
;; Created: 08 October 2017
;; Original Created: 11 January 2015
;; Version: 0.2
;; Package-Version: 20210109.1403
;; Package-Commit: 3a40501ba831a30a7fd3e8529b20d1305d0454aa
;; Package-Requires: ((company "0.9.4") (glsl-mode "2.4") (emacs "24.4"))
;; URL: https://github.com/guidoschmidt/company-glsl

;;; License:
;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Provides a company completion backend glslangValidator and filtered
;; lists provided by `glsl-mode'.
;;
;; Download & build `glslangValidator' from KhronosGroup:
;; https://github.com/KhronosGroup/glslang
;;
;; Setup:
;; (use-package company-glsl
;;   :config
;;   (when (executable-find "glslangValidator")
;;     (add-to-list 'company-backends 'company-glsl)))

;;; Change Log:
;; 0.2 (Guido Schmidt)
;; - Add glsl-mode type & builtin support
;; - Clean package (doc strings, commentary section)
;;
;; 0.1 (Väinö Järvelä)
;; - Basic symbol completion
;; - Reference to function names

;;; Code:
(require 'cl-lib)
(require 'company)
(require 'glsl-mode)

(defun company-glsl--is-anon (symbol)
  "Check if the given SYMBOL is prefixed with `anon@'."
  (string-prefix-p "anon@" symbol))

(defun company-glsl--has-block (type)
  "Check if the given TYPE is sourrounded by `block{}'."
  (string-match-p "block{" type))

(defun company-glsl--propertize (symbol type linenum)
  "Propertize a given SYMBOL with a TYPE and line number LINENUM."
  (propertize
   symbol
   'meta type
   'linenum linenum))

(defun company-glsl--parse-block (block linenum &optional parent)
  "Parse a BLOCK at line number LINENUM and optional argument PARENT."
  (with-temp-buffer
    (insert block)
    (goto-char (point-min))
    (re-search-forward "{" nil t)
    (cl-loop while
             (re-search-forward " ?\\([^,]+\\) \\([^,]+\\)[,}]" nil t)
             collect
             (company-glsl--propertize
              (if parent
                  (concat parent "." (match-string 2))
                (match-string 2))
              (match-string 1)
              linenum))))

(defun company-glsl--parse-match (symbol type linenum)
  "Parse a SYMBOL with TYPE at line number LINENUM."
  (if (company-glsl--is-anon symbol)
      (company-glsl--parse-block type linenum)
    (if (company-glsl--has-block type)
        (cons (company-glsl--propertize symbol type linenum)
              (company-glsl--parse-block type linenum symbol))
      (list (company-glsl--propertize symbol type linenum)))))

(defun company-glsl--parse-func (funcname linenum)
  "Propertize a function with its name FUNCNAME and its line number LINENUM."
  (company-glsl--propertize funcname "function" linenum))

(defun company-glsl--get-types (filename)
  "Get GLSL types from calling glslangValidator on FILENAME."
  (with-temp-buffer
    (call-process "glslangValidator" nil (list (current-buffer) nil) nil "-i" filename)
    (goto-char (point-min))
    (let ((vars
           (cl-reduce
            'append
            (cl-loop while
                     (re-search-forward "^.*:\\([0-9?]+\\) +'\\(.*\\)' \\(.*\\)$" nil t)
                     collect
                     (company-glsl--parse-match (match-string 2) (match-string 3) (match-string 1)))))
          (funcs
           (progn
             (goto-char (point-min))
             (cl-loop while
                      (re-search-forward "^.*:\\([0-9?]+\\) +Function Definition: \\([a-zA-Z0-9_]+\\)(" nil t)
                      collect
                      (company-glsl--parse-func (match-string 2) (match-string 1))))))
      (append funcs vars))))

(defun company-glsl--fuzzy-match-prefix (prefix candidate)
  "Fuzzy match a PREFIX to a CANDIDATE."
  (cl-subsetp (string-to-list prefix)
              (string-to-list candidate)))

(defun company-glsl--match-prefix (prefix candidate)
  "Match a PREFIX with a CANDIDATE."
  (string-prefix-p prefix candidate))

(defun company-glsl--property-linenum (prop)
  "Get the linenum by its PROP."
  (let ((linenum (get-text-property 0 'linenum prop)))
    (if (eq linenum "?")
        0
      (string-to-number linenum))))

(defun company-glsl--candidate-sorter (x y)
  "Sort parsed candidates X and Y by lineums."
  (if (string= x y)
      (< (company-glsl--property-linenum x) (company-glsl--property-linenum y))
    (string< x y)))

(defun company-glsl--candidates (arg)
 "Provide candidates pased on the prefix command ARG by parsing."
  (cl-stable-sort
   (cl-remove-if-not
    (lambda (c) (company-glsl--match-prefix arg c))
    (company-glsl--get-types buffer-file-name))
   'company-glsl--candidate-sorter))

(defun company-glsl--location (arg)
  "Get the location of an ARG."
  (let ((linenum (get-text-property 0 'linenum arg)))
    (if (not (eq "?" linenum))
        (cons buffer-file-name (string-to-number linenum))
      (cons buffer-file-name 0))))

(defun company-glsl--match-arg (arg type)
  "Check the company prefix ARG against a TYPE."
  (string-match-p (regexp-quote arg) type))

(defun company-glsl--extended-candidates (arg)
  "Extends parsed candidates based on ARG with type/modifier/builtin lists as provided by ‘glsl-mode’."
  (let ((candidates (append glsl-type-list
                            glsl-qualifier-list
                            glsl-deprecated-qualifier-list
                            glsl-builtin-list
                            glsl-deprecated-builtin-list
                            (company-glsl--candidates arg))))
    (cl-remove-if-not (lambda (type) (company-glsl--match-arg arg type))
                      candidates)))

;;;###autoload
(defun company-glsl (command &optional arg &rest ignored)
  "Provide GLSL completion info according to prefix COMMAND and ARG.  IGNORED is not used."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-glsl))
    (prefix (and (eq major-mode 'glsl-mode)
                 buffer-file-name
                 (or (company-grab-symbol-cons "\\." 1)
                     'stop)))
    (candidates (company-glsl--extended-candidates arg))
    (sorted t)
    (duplicates t)
    (meta (get-text-property 0 'meta arg))
    (annotation (concat " " (get-text-property 0 'meta arg)))
    (location (company-glsl--location arg))))

(provide 'company-glsl)
;;; company-glsl.el ends here
