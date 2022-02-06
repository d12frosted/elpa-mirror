;;; clj-decompiler.el --- Clojure Java decompiler expansion -*- lexical-binding: t -*-

;; Copyright © 2020-2020 Ben Sless
;;
;; Author: Ben Sless <ben.sless@gmail.com>
;; Maintainer: Ben Sless <ben.sless@gmail.com>
;; URL: https://www.github.com/bsless/clj-decompiler.el
;; Keywords: languages, clojure, cider, java, decompiler
;; Package-Requires: ((emacs "26.1") (clojure-mode "5.12") (cider "1.2.0"))
;; Version: 0.0.1

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides interactive functions for decompiling Clojure on the JVM by
;; loading them in the REPL and decompiling them with
;; https://github.com/clojure-goes-fast/clj-java-decompiler

;;; Usage:

;; M-x clj-decompiler-decompile
;; M-x clj-decompiler-disassemble

;;; Code:

(defgroup clj-decompiler nil
  "Clojure Java decompiler dependency that rides on top of CIDER."
  :prefix "clj-decompiler-"
  :group 'applications
  :link '(url-link :tag "GitHub" "https://github.com/bsless/clj-decompiler.el"))

(require 'cider-mode)
(require 'subr-x)

(defconst clj-decompiler-decompile-buffer "*clj-decompile*")
(defconst clj-decompiler-disassemble-buffer "*clj-disassemble*")

(defcustom clj-decompiler-decompiler-artifact "com.clojure-goes-fast/clj-java-decompiler"
  "Coordinates for clj-java-decompiler."
  :type 'string
  :group 'clj-decompiler)

(defcustom clj-decompiler-decompiler-version "0.3.0"
  "Decompiler artifact version."
  :type 'string
  :group 'clj-decompiler)

(defcustom clj-decompiler-namespace "clj-java-decompiler.core"
  "Decompiler namespace containing decompile and disassemble macros."
  :type 'string
  :group 'clj-decompiler)

(defcustom clj-decompiler-disassemble-macro "disassemble"
  "Macro which runs disassemble."
  :type 'string
  :group 'clj-decompiler)

(defcustom clj-decompiler-decompile-macro "decompile"
  "Macro which runs decompile."
  :type 'string
  :group 'clj-decompiler)

(defcustom clj-decompiler-inject-dependencies-at-jack-in t
  "Flag controlling whether disassembler should be injected as a dependency on `cider-jack-in'."
  :type 'boolean
  :group 'clj-decompiler)

(defun clj-decompiler-ensure-decompiler-dependency ()
  "Ensure decompiler dependency will be jacked in."
  (when (and clj-decompiler-inject-dependencies-at-jack-in
             (boundp 'cider-jack-in-dependencies))
    (cider-add-to-alist
     'cider-jack-in-dependencies
     clj-decompiler-decompiler-artifact
     clj-decompiler-decompiler-version)))

(defun clj-decompiler-sync-request-eval-out (expr)
  "Eval the given EXPR and return the result from STDOUT."
  (cider-ensure-op-supported "eval")
  (let* ((resp (cider-nrepl-send-sync-request `("op" "eval" "code" ,expr))))
    (or
     (nrepl-dict-get resp "out")
     (nrepl-dict-get resp "err"))))

(defvar clj-decompiler-last-disassemble-expression nil
  "Specify the last disassembly preformed.
This variable specifies both what was disassembled and the disassembler.")

(defun clj-decompiler-disassemble-expr (expr)
  "Macroexpand, use EXPANDER, the given EXPR."
  (let* ((ns (cider-current-ns))
         (expr (format "(in-ns \'%s) (require '%s) (%s/%s %s)"
                       ns
                       clj-decompiler-namespace
                       clj-decompiler-namespace
                       clj-decompiler-disassemble-macro
                       expr)))
    (when-let* ((expansion (clj-decompiler-sync-request-eval-out expr)))
      (setq clj-decompiler-last-disassemble-expression expr)
      (clj-decompiler-initialize-disassemble-buffer expansion))))

(defvar clj-decompiler-last-decompile-expression nil
  "Specify the last decompilation preformed.
This variable specifies both what was decompiled and the decompiler.")

(defun clj-decompiler-decompile-expr (expr)
  "Macroexpand, use EXPANDER, the given EXPR."
  (let* ((ns (cider-current-ns))
         (expr (format "(in-ns \'%s) (require '%s) (%s/%s %s)"
                       ns
                       clj-decompiler-namespace
                       clj-decompiler-namespace
                       clj-decompiler-decompile-macro
                       expr)))
    (when-let* ((expansion (clj-decompiler-sync-request-eval-out expr)))
      (setq clj-decompiler-last-decompile-expression expr)
      (clj-decompiler-initialize-decompile-buffer expansion))))

;;;###autoload
(defun clj-decompiler-setup ()
  "Ensure decompiler dependencies are injected to cider."
  (interactive)
  (clj-decompiler-ensure-decompiler-dependency))

;;;###autoload
(defun clj-decompiler-disassemble ()
  "Invoke \\=`disassemble\\=` on the expression preceding point."
  (interactive)
  (clj-decompiler-disassemble-expr (cider-last-sexp)))

(defun clj-decompiler-initialize-disassemble-buffer (expansion)
  "Create a new Macroexpansion buffer with EXPANSION and namespace NS."
  (pop-to-buffer (clj-decompiler-create-disassemble-buffer))
  (setq buffer-undo-list nil)
  (let ((inhibit-read-only t)
        (buffer-undo-list t))
    (erase-buffer)
    (insert (format "%s" expansion))
    (goto-char (point-max))
    (delete-trailing-whitespace)))

;;;###autoload
(defun clj-decompiler-decompile ()
  "Invoke \\=`decompile\\=` on the expression preceding point."
  (interactive)
  (clj-decompiler-decompile-expr (cider-last-sexp)))

(defun clj-decompiler-initialize-decompile-buffer (expansion)
  "Create a new Macroexpansion buffer with EXPANSION and namespace NS."
  (pop-to-buffer (clj-decompiler-create-decompile-buffer))
  (setq buffer-undo-list nil)
  (let ((inhibit-read-only t)
        (buffer-undo-list t))
    (erase-buffer)
    (insert (format "%s" expansion))
    (goto-char (point-max))
    (delete-trailing-whitespace)))

(declare-function cider-mode "cider-mode")

(defun clj-decompiler-create-disassemble-buffer ()
  "Create a new macroexpansion buffer."
  (with-current-buffer (cider-popup-buffer clj-decompiler-disassemble-buffer 'select 'java-mode 'ancillary)
    (cider-mode -1)
    (current-buffer)))

(defun clj-decompiler-create-decompile-buffer ()
  "Create a new macroexpansion buffer."
  (with-current-buffer (cider-popup-buffer clj-decompiler-decompile-buffer 'select 'java-mode 'ancillary)
    (cider-mode -1)
    (current-buffer)))

(provide 'clj-decompiler)

;;; clj-decompiler.el ends here
