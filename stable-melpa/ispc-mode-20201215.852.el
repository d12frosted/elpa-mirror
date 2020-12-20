;;; ispc-mode.el --- Syntax coloring for ispc programs -*- lexical-binding: t; -*-

;; Copyright (c) 2020 - Philip Munksgaard <philip@munksgaard.me>
;;
;; Author: Philip Munksgaard <philip@munksgaard.me>
;; Keywords: c, ispc
;; Package-Version: 20201215.852
;; Package-Commit: 722fdc45da2714f8fe0757968589cdb5ccacc8a0
;; URL: https://github.com/Munksgaard/ispc-mode
;; Version: 0.1

;; Initially adapted from opencl-mode:
;; https://github.com/salmanebah/opencl-mode

;; This file is NOT part of GNU Emacs.

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

;;; Installation:

;; 1- Put ispc-mode.el in your load path or optionally add this line to your Emacs init file:
;;    (add-to-list 'load-path "/path/to/directory/where/ispc-mode.el/resides")
;; 2- Add these lines to your Emacs init file
;;    (require 'ispc-mode)

;;; Code:

;; for c-font-lock-keywords
(require 'cc-fonts)

(defvar ispc-keywords-regexp
  (regexp-opt
   '("break" "case" "cdo" "cfor" "cif" "cwhile" "continue" "default" "do" "else"
     "enum" "extern" "for" "foreach" "foreach_active" "foreach_tiled"
     "foreach_unique" "goto" "if" "in" "inline" "noinline" "__vectorcall"
     "launch" "print" "return" "sizeof" "soa" "static" "struct" "switch"
     "sync" "task" "typedef" "union" "while" "operator") 'words)
  "Regexp for ispc keywords.")

(defvar ispc-builtin-regexp
  (regexp-opt '("programCount" "programIndex" "false" "true" "taskCount"
                "taskCount0" "taskCount1" "taskCount3" "taskIndex" "taskIndex0"
                "taskIndex1" "taskIndex2") 'words)
  "Regexp for builtin ispc functions.")

(defvar ispc-constants-regexp
  (regexp-opt '("NULL") t)
  "Regexp for builtin ispc constants.")

(defvar ispc-types-regexp
  (regexp-opt '("export" "void" "bool" "int" "int8" "int16" "int32" "int64"
                "double" "float" "unsigned" "signed" "varying" "uniform"
                "size_t" "ptrdiff_t" "intptr_t" "uintptr_t" "const"
                "uint" "uint8" "uint16" "uint32" "uint64") t)
  "Regexp for ispc primitive types.")

(defvar ispc-font-lock-keywords
  `((,ispc-keywords-regexp . font-lock-keyword-face)
    (,ispc-types-regexp . font-lock-type-face)
    (,ispc-builtin-regexp . font-lock-builtin-face)
    (,ispc-constants-regexp . font-lock-constant-face))
  "Font-lock for ispc keywords.")

;;;###autoload
(define-derived-mode ispc-mode c-mode "ispc"
  "Major mode for ispc program editing."
  (font-lock-add-keywords nil ispc-font-lock-keywords))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ispc\\'" . ispc-mode))

(provide 'ispc-mode)
;;; ispc-mode.el ends here
