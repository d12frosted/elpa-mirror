;;; caddyfile-mode.el --- Major mode for Caddy configuration files -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Thomas Jost

;; Author: Thomas Jost <schnouki@schnouki.net>
;; Maintainer: Thomas Jost <schnouki@schnouki.net>
;; Created: November 18, 2018
;; Version: 0.2
;; Package-Version: 20181120.1616
;; Package-Commit: b0371063adc18d3cbd6dd673ea4fe39d27825d1b
;; Package-Requires: ((emacs "24.3"))
;; Keywords: languages
;; URL: https://github.com/Schnouki/caddyfile-mode/

;; This file is not part of GNU Emacs.

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

;; See the README.md file for details.


;;; Code:

(require 'font-lock)
(require 'rx)


;;; Customizable variables ====================================================

(defgroup caddyfile nil
  "Major mode for editing Caddy configuration files."
  :prefix "caddyfile-"
  :group 'data
  :link '(url-link "https://github.com/Schnouki/caddyfile-mode"))


;;; Regular expressions =======================================================

(defconst caddyfile--regexp-block-start
  (rx bol (* blank) (1+ (not blank)) (* nonl) "{" (* blank) eol)
  "Regular expression for a block start line.
Used to compute the block level, not for font locking.")

(defconst caddyfile--regexp-block-end
  (rx bol (* blank) "}" (* blank) eol)
  "Regular expression for a block end line.
Used to compute the block level, not for font locking.")

(defconst caddyfile--regexp-label
  (rx (+ (or (not (any space "{}(),\n"))
	     (seq "{" (* (not (any space "{}(),\n"))) "}")
	     (seq "(" (* (not (any space "{}(),\n"))) ")"))))
  "Regular expression for a single Caddyfile label.")

(defconst caddyfile--regexp-directive
  (rx bol
      (* (any space))
      (group
       (not (any space "}"))
       (* (not (any space "\n")))))
  "Regular expression for a Caddyfile directive or subdirective.")

(defconst caddyfile--regexp-variable
  (rx "{" (+ (not (any space "}\n"))) "}")
  "Regular expression for a Caddyfile variable.")


;;; Font Lock =================================================================

(defgroup caddyfile-faces nil
  "Faces used in Caddyfile mode."
  :group 'caddyfile
  :group 'faces)

(defface caddyfile-comment-face
  '((t (:inherit font-lock-comment-face)))
  "Face for Caddyfile comments."
  :group 'caddyfile-faces)

(defface caddyfile-label-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for Caddyfile labels."
  :group 'caddyfile-faces)

(defface caddyfile-directive-face
  '((t (:inherit font-lock-function-name-face)))
  "Face for Caddyfile directives."
 :group 'caddyfile-faces)

(defface caddyfile-subdirective-face
  '((t (:inherit font-lock-type-face)))
  "Face for Caddyfile subdirectives."
  :group 'caddyfile-faces)

(defface caddyfile-variable-face
  '((t (:inherit font-lock-variable-name-face)))
  "Font face for Caddyfile variables."
  :group 'caddyfile-faces)

(defun caddyfile--match-at-block-level (level regexp last)
  "Match REGEXP at nesting level LEVEL.
LAST is a buffer position that bounds the search."
  (let (res)
    (while (and (setq res (re-search-forward regexp last t))
		(not (= (car (syntax-ppss)) level))))
    res))

(defun caddyfile--match-label (last)
  "Match a Caddyfile label.
LAST is a buffer position that bounds the search."
  (caddyfile--match-at-block-level 0 caddyfile--regexp-label last))

(defun caddyfile--match-directive (last)
  "Match a Caddyfile directive.
LAST is a buffer position that bounds the search."
  (caddyfile--match-at-block-level 1 caddyfile--regexp-directive last))

(defun caddyfile--match-subdirective (last)
  "Match a Caddyfile subdirective.
LAST is a buffer position that bounds the search."
  (caddyfile--match-at-block-level 2 caddyfile--regexp-directive last))

(defun caddyfile--match-variable (last)
  "Match a Caddyfile variable.
LAST is a buffer position that bounds the search."
  (let (res)
    (while (and (setq res (re-search-forward caddyfile--regexp-variable last t))
		(nth 4 (syntax-ppss))))
    res))

(defconst caddyfile-mode-font-lock-keywords
  `((caddyfile--match-label . ((0 'caddyfile-label-face)))
    (caddyfile--match-directive . (( 1 'caddyfile-directive-face)))
    (caddyfile--match-subdirective . (( 1 'caddyfile-subdirective-face)))
    (caddyfile--match-variable . ((0 'caddyfile-variable-face t))))
  "Syntax highlighting for Caddyfiles.")


;;; Syntax table ==============================================================

(defvar caddyfile-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    ;; Opening/closing braces
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    table)
  "Syntax table for Caddyfiles.")


;;; Indentation ===============================================================

(defun caddyfile--indent-line ()
  "Indent the current line."
  (save-excursion
    (let* ((level (min (car (syntax-ppss (line-beginning-position)))
		       (car (syntax-ppss (line-end-position)))))
	   (indent (* level tab-width)))
      (beginning-of-line)
      (delete-horizontal-space)
      (indent-to-column indent)))
  (when (< (current-column) (current-indentation))
    (back-to-indentation)))


;;; Major mode ================================================================

;;;###autoload
(define-derived-mode caddyfile-mode prog-mode "Caddyfile"
  "Major mode for editing Caddy configuration files."
  ;; Comments
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#[ \t]*")
  (setq-local comment-column 0)
  (setq-local comment-use-syntax t)
  ;; Font lock
  (setq-local font-lock-defaults '(caddyfile-mode-font-lock-keywords))
  ;; Indentation
  (setq-local tab-width 8)
  (setq-local indent-tabs-mode t)
  (setq-local indent-line-function 'caddyfile--indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("Caddyfile\\'" . caddyfile-mode))

(provide 'caddyfile-mode)

;;; caddyfile-mode.el ends here
