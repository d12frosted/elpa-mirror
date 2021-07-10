;;; flatbuffers-mode.el --- Major mode for editing flatbuffers  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Asal Mirzaieva

;; Author: Asal Mirzaieva <asalle.kim@gmail.com>
;; Created: 12-Nov-2019
;; Version: 0.2
;; Package-Version: 20210710.1004
;; Package-Commit: 8e7783db45a64c9456130fd0c108ac12d45a7789
;; Keywords: flatbuffers languages
;; Homepage: https://github.com/Asalle/flatbuffers-mode
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; FlatBuffers is an efficient cross platform serialization library for C++, C#, C, Go, Java, Kotlin, JavaScript, Lobster, Lua, TypeScript, PHP, Python, Rust and Swift. It was originally created at Google for game development and other performance-critical applications.
;; https://google.github.io/flatbuffers/

;; Installation:
;;   - Put `flatbuffers-mode.el' in your Emacs load-path.
;;   - Add this line to your .emacs file:
;;       (require 'flatbuffers-mode)
;;
;;; Code:

;; Font-locking definitions and helpers
(defconst flatbuffers-mode-keywords
  '("namespace" "root_type" "struct" "table" "enum" "union" "required" "include" "attribute" "rpc_service" "file_extension" "file_identifier"))

(defconst flatbuffers-special-types
  '("double" "bool" "uint" "ulong"))

(defconst flatbuffers-re-ident "[[:word:][:multibyte:]_][[:word:][:multibyte:]_[:digit:]]*")

(defconst flatbuffers-re-generic
  (concat "<[[:space:]]*'" flatbuffers-re-ident "[[:space:]]*>"))

(defun flatbuffers-re-word (inner) "Generate word regex. INNER is the word to enclose." (concat "\\<" inner "\\>"))
(defun flatbuffers-re-grab (inner) "Generate grab regex. INNER is the expression to enclose." (concat "\\(" inner "\\)"))
(defun flatbuffers-re-shy (inner) "Generate shy regex. INNER is the expression to enclose." (concat "\\(?:" inner "\\)"))

(defun flatbuffers-re-item-def (itype)
  "Highlight the keywords. ITYPE is the type of the keyword."
  (concat (flatbuffers-re-word itype)
	  (flatbuffers-re-shy flatbuffers-re-generic) "?"
	  "[[:space:]]+" (flatbuffers-re-grab flatbuffers-re-ident)))

(defvar flatbuffers-mode-font-lock-keywords
  (append
   `(
     ;; Keywords
     (,(regexp-opt flatbuffers-mode-keywords 'symbols) . font-lock-keyword-face)

     ;; Special types
     (,(regexp-opt flatbuffers-special-types 'symbols) . font-lock-type-face)

     (,(concat (flatbuffers-re-grab flatbuffers-re-ident) "[[:space:]]*:[^:]") 1 font-lock-variable-name-face)

     ;; Ensure we highlight `Foo' in a:Foo
     (,(concat ":[[:space:]]*" (flatbuffers-re-grab flatbuffers-re-ident)) 1 font-lock-type-face))

    ;; Ensure we highlight `Foo` in `struct Foo` as a type.
    (mapcar (lambda (x)
                (list (flatbuffers-re-item-def (car x))
                      1 (cdr x)))
            '(("enum" . font-lock-type-face)
              ("struct" . font-lock-type-face)
              ("union" . font-lock-type-face)
              ("root_type" . font-lock-type-face)
              ("table" . font-lock-type-face)))))

;;;###autoload
(define-derived-mode flatbuffers-mode c-mode "Flatbuffers"
  "Major mode for Flatbuffers code.

\\{flatbuffers-mode-map}"
  :group 'flatbuffers-mode

  ;; Fonts
  (setq-local font-lock-defaults '(flatbuffers-mode-font-lock-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fbs\\'" . flatbuffers-mode))

(defun flatbuffers-mode-reload ()
  "Reload the flatbuffers mode in current buffer."
  (interactive)
  (unload-feature 'flatbuffers-mode)
  (require 'flatbuffers-mode)
  (flatbuffers-mode))

(provide 'flatbuffers-mode)

;;; flatbuffers-mode.el ends here
