;;; rbs-mode.el --- A major mode for RBS -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Masafumi Koba

;; Author: Masafumi Koba
;; Version: 0.3.1
;; Package-Version: 20210430.135
;; Package-Commit: fd766a943d5f1f0624e10ffce096b9aaba14a5f4
;; Package-Requires: ((emacs "24.5"))
;; Keywords: languages
;; URL: https://github.com/ybiquitous/rbs-mode

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

;; `rbs-mode' is a major mode for RBS (a type signature language for Ruby).
;; See also <https://github.com/ruby/rbs> for details about RBS.

;;; Code:
(require 'rx)

(defgroup rbs nil
  "Major mode for editing RBS code."
  :group 'languages
  :prefix "rbs-")

(defcustom rbs-indent-level 2
  "Indentation of RBS statements."
  :group 'rbs
  :type 'integer
  :safe 'integerp)

(defun rbs-indent-line ()
  "Correct the indentation of the current RBS line."
  (indent-line-to (rbs-calculate-indent-level)))

(defun rbs-calculate-indent-level ()
  "Return the proper indentation level of the current line."
  (save-excursion
    (let* ((prev-level (rbs-previous-indent-level))
           (block-start-line-re (concat "^[[:space:]]*" (regexp-opt '("class" "module" "interface") 'symbols)))
           (block-end-line-re (concat "^[[:space:]]*" (regexp-opt '("end") 'symbols))))
      (cond
        ((string-match-p block-start-line-re (rbs-previous-line))
          (+ prev-level rbs-indent-level))
        ((string-match-p block-end-line-re (rbs-current-line))
          (max 0 (- prev-level rbs-indent-level)))
        (t prev-level)))))

(defun rbs-current-line ()
  "Return the current line."
  (string-trim-right (thing-at-point 'line t)))

(defun rbs-previous-line ()
  "Return the previous line."
  (save-excursion
    (forward-line -1)
    (string-trim-right (thing-at-point 'line t))))

(defun rbs-previous-indent-level ()
  "Return the previous indent level."
  (save-excursion
    (forward-line -1)
    (current-indentation)))

(defconst rbs-mode--keyword-regexp
  (regexp-opt
    '("alias"
      "attr_accessor"
      "attr_reader"
      "attr_writer"
      "class"
      "def"
      "end"
      "extend"
      "extension"
      "in"
      "include"
      "interface"
      "module"
      "unchecked"
      "out"
      "prepend"
      "private"
      "public"
      "singleton"
      "super"
      "type")
    'symbols))

(defconst rbs-mode--builtin-type-regexp
  (rx
    (or symbol-start "?" "*")
    (group
      (or
        "any"
        "bool"
        "bool?"
        "boolish"
        "bot"
        "class"
        "class?"
        "encoding"
        "encoding?"
        "exception"
        "exception?"
        "false"
        "false?"
        "instance"
        "instance?"
        "int"
        "int?"
        "io"
        "io?"
        "nil"
        "real"
        "real?"
        "self"
        "self?"
        "string"
        "string?"
        "top"
        "true"
        "true?"
        "untyped"
        "void"))))

(defconst rbs-mode--core-type-regexp
  (rx
    (or space line-start "?" "*" "(" "[")
    (group
      (optional "::")
      (or
        "ArgumentError"
        "Array"
        "BasicObject"
        "BigDecimal"
        "Binding"
        "Class"
        "Comparable"
        "Complex"
        "Dir"
        "ENV"
        "Encoding"
        "EncodingError"
        "Enumerable"
        "Enumerator"
        "Errno"
        "Exception"
        "FalseClass"
        "File"
        "Float"
        "Hash"
        "IndexError"
        "Integer"
        "IO"
        "Kernel"
        "Logger"
        "Method"
        "Module"
        "NameError"
        "NilClass"
        "Numeric"
        "Object"
        "Pathname"
        "Proc"
        "Process"
        "Process::Status"
        "Random"
        "Random::Formatter"
        "Range"
        "RangeError"
        "Rational"
        "Regexp"
        "RuntimeError"
        "ScriptError"
        "SignalException"
        "StandardError"
        "String"
        "Struct"
        "Symbol"
        "SystemCallError"
        "Thread"
        "ThreadGroup"
        "Time"
        "TracePoint"
        "TrueClass"
        "UnboundMethod"
        "_Each"
        "_Exception"
        "_Reader"
        "_Writer"
        "_ToAry"
        "_ToHash"
        "_ToInt"
        "_ToI"
        "_ToInt"
        "_ToIO"
        "_ToPath"
        "_ToProc"
        "_ToS"
        "_ToStr"))))

(defconst rbs-mode--type-definition-regexp
  (rx
    symbol-start
    (or "class" "extension" "interface" "module" "type")
    (1+ space)
    (group (1+ (not (any space "["))))))

(defconst rbs-mode--inheritance-regexp
  (rx
    (1+ space)
    (or "<" ":")
    (1+ space)
    (group (1+ (not (any space "["))))))

(defconst rbs-mode--method-name-regexp
  (rx
    symbol-start
    "def"
    (1+ space)
    (optional (or "self" "self?") ".")
    (group (1+ (not (any ":" space))))
    ":"))

(defconst rbs-mode--alias-name-regexp
  (rx
    symbol-start
    "alias"
    (1+ space)
    (optional (or "self" "self?") ".")
    (group (1+ (not space)))
    (1+ space)
    (optional (or "self" "self?") ".")
    (group (1+ (not space)))))

;; Include global variables
(defconst rbs-mode--constant-regexp
  (rx
    (or space line-start)
    (group (or "$" ":" upper) (1+ (not space)))
    ":"
    (1+ space)))

(defconst rbs-mode--instance-variable-regexp
  (rx
    (or space line-start)
    (group "@" (1+ (not space)))
    ":"
    (1+ space)))

(defconst rbs-mode--font-lock-keywords
  `((,rbs-mode--keyword-regexp (1 font-lock-keyword-face))
    (,rbs-mode--type-definition-regexp (1 font-lock-type-face))
    (,rbs-mode--inheritance-regexp (1 font-lock-type-face))
    (,rbs-mode--method-name-regexp (1 font-lock-function-name-face))
    (,rbs-mode--alias-name-regexp (1 font-lock-function-name-face) (2 font-lock-function-name-face))
    (,rbs-mode--constant-regexp (1 font-lock-constant-face))
    (,rbs-mode--instance-variable-regexp (1 font-lock-variable-name-face))
    (,rbs-mode--builtin-type-regexp (1 font-lock-builtin-face))
    (,rbs-mode--core-type-regexp (1 font-lock-type-face))))

(defconst rbs-mode--syntax-table
  (let* ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\` "\"" table)
    table))

;;;###autoload
(define-derived-mode rbs-mode prog-mode "RBS"
  "Major mode for editing RBS code."
  :syntax-table rbs-mode--syntax-table
  (setq-local comment-start "#")
  (setq-local comment-start-skip "#+[ \t]*")
  (setq-local comment-end "")
  (setq-local comment-use-syntax t)
  (setq-local font-lock-defaults '(rbs-mode--font-lock-keywords))
  (setq-local indent-line-function #'rbs-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rbs\\'" . rbs-mode))

(provide 'rbs-mode)
;;; rbs-mode.el ends here
