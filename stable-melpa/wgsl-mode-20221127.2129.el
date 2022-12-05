;;; wgsl-mode.el --- Syntax highlighting for the WebGPU Shading Language -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Anthony Cowley
;; Author: Anthony Cowley
;; URL: https://github.com/acowley/wgsl-mode
;; Package-Version: 20221127.2129
;; Package-Commit: e7856d6755d93e40ed74598a68ef5f607322618b
;; Package-Requires: ((emacs "24"))
;; Keywords: wgsl, c
;; Version: 1.0

;; This program is free software: you can redistribute it and/or modify
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

;; Syntax highlighting for the WebGPU Shading Language (WGSL).

;;; Code:

(require 'cc-fonts)

(defconst wgsl-keywords-regexp
  (rx (seq (group (or "struct" "fn" "var" "let" "ptr" "type")) (or space "<"))))

(defconst wgsl-keywords-regexp2
  (rx (seq (group (or "if" "else" "elseif"
                      "switch" "case" "default" "break" "fallthrough"
                      "loop" "continuing"  "continue"
                      "return" "for"))
           (or space "<" "(" ";" "{"))))

(defconst wgsl-attributes-regexp
  (rx (seq
       (or "[[" "," space)
       (group (or "builtin" "block" "location" "group" "binding" "stage" "workgroup_size" "access"
                  "stride"))
       (or "]]" "("))))

(defconst wgsl-storage-classes-regexp
  (rx (seq "<"
           (* (not ?>))
           (group (or "in" "out" "function" "private" "workgroup" "uniform"
                      "storage" "handle"))
           (or ">" ","))))

(defconst wgsl-builtins-regexp
  (rx (seq
       symbol-start
       (group (or "vertex_index"
                  "instance_index"
                  "position"
                  "frag_coord"
                  "front_facing"
                  "frag_depth"
                  "local_invocation_id"
                  "local_invocation_index"
                  "global_invocation_id"
                  "workgroup_id"
                  "workgroup_size"
                  "sample_index"
                  "sample_mask_in"
                  "sample_mask_out"))
       symbol-end)))

(defconst wgsl-constants-regexp
  (rx (seq symbol-start
           (group (or "compute" "vertex" "fragment" "read" "write" "read_write"))
           symbol-end)))

(defconst wgsl-scalar-types-regexp
  (rx (or "f32" "u32" "i32" "bool" "void")))

(defconst wgsl-types-regexp
  (rx symbol-start
      (or (regexp wgsl-scalar-types-regexp)
          (seq "vec" (or "2" "3" "4"))
          (seq "mat" (or "2" "3" "4") "x" (or "2" "3" "4"))
          (seq "array")
          (seq "texture"
               (or "" "_storage" "_depth")
               (opt "_multisampled")
               (or "_1d" "_2d" "_3d" "_cube")
               (opt "_array")))
      symbol-end))

(defconst wgsl-variable-name-regexp
  (rx (seq (group (regexp "[a-zA-Z][0-9a-zA-Z_]*")) (* space) (or ":" "="))))

(defconst wgsl-function-name-regexp
  (rx (seq "fn" (+ space) (group (regexp "[a-zA-Z][0-9a-zA-Z_]*")) (* space) "(")))

(defconst wgsl-font-lock-keywords
  `((,wgsl-builtins-regexp 1 font-lock-builtin-face)
    (,wgsl-constants-regexp 1 font-lock-constant-face)
    (,wgsl-storage-classes-regexp 1 font-lock-constant-face)
    (,wgsl-types-regexp . font-lock-type-face)
    (,wgsl-attributes-regexp 1 font-lock-builtin-face)
    (,wgsl-keywords-regexp 1 font-lock-keyword-face)
    (,wgsl-keywords-regexp2 1 font-lock-keyword-face)
    (,wgsl-variable-name-regexp 1 font-lock-variable-name-face)
    (,wgsl-function-name-regexp 1 font-lock-function-name-face)))

;;;###autoload
(define-derived-mode wgsl-mode c++-mode "WGSL"
  "Major mode for WGSL source."
  (add-to-list 'c-offsets-alist '(access-label . 0))
  (font-lock-remove-keywords 'wgsl-mode c++-font-lock-keywords-3)
  (font-lock-add-keywords nil wgsl-font-lock-keywords))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wgsl\\'" . wgsl-mode))

(provide 'wgsl-mode)
;;; wgsl-mode.el ends here
