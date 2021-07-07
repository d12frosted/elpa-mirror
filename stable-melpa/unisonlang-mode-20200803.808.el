;;; unisonlang-mode.el --- Simple major mode for editing Unison -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2020, Dario Oddenino

;; Author: Dario Oddenino
;; Version: 0.2.0
;; Package-Version: 20200803.808
;; Package-Commit: 2b794adbe0b2a4edd40f350173a32b80bd2c5896
;; Package-Requires: ((emacs "25.1"))
;; Created: 24 Apr 2020
;; Keywords: languages
;; URL: https://github.com/dariooddenino/unison-mode-emacs

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A simple major mode to edit Unison files (.u)

;;; Code:

(defconst unisonlang-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; -- Are comments
    (modify-syntax-entry ?- ". 12" table)
    ;; \n is a comment ender
    (modify-syntax-entry ?\n ">" table)
    ;; [: :] for docs
    (modify-syntax-entry ?\[ ". 1" table)
    (modify-syntax-entry ?: ". 23b" table)
    (modify-syntax-entry ?\] ". 4" table)
    table))

(defvar unisonlang-font-lock-keywords)
(setq unisonlang-font-lock-keywords
      (let* (
             ;; Regex for identifiers

             ;; Type identifier
             (type-regexp "[A-Z_][A-Za-z_!'0-9]*")
             ;; A valid identifier
             ;; TODO include unicode characters
             (identifier-regexp "[A-Za-z_][A-Za-z_!'0-9]*")
             ;; namespaced identifier
             (namespaced-regexp (concat "\\(?:\\.\\|" identifier-regexp "\\)+"))

             ;; Handle the unison fold
             (x-fold-regexp "---\\(\n\\|.\\)*")

             ;; define several categories of keywords
             ;; symbol keywords
             (x-symbol-keywords '(":" "->"))
             ;; standard alphabetical keywords
             (x-keywords '("if" "then" "else" "forall" "handle" "unique" "where" "use" "and" "or" "true" "false" "type" "ability" "alias" "let" "namespace" "cases" "match" "with"))

             ;; generate regex strings for each keyword category
             (x-keywords-regexp (regexp-opt x-keywords 'words))
             (x-symbol-keywords-regexp (regexp-opt x-symbol-keywords 1))
             ;; (x-single-quote-exc-regexp (regexp-opt x-single-quote-exc 1))
             (x-keywords-full-regexp (concat x-keywords-regexp "\\|" x-symbol-keywords-regexp))

             (x-request-regexp "Request")

             ;; single quote or exclamation point when it's not part of an identifier
             (x-single-quote-exc-regexp "\\(\s\\)\\(!\\|'\\)")

             ;; Signautres
             (x-sig-regexp (concat "^\s*?\\(" namespaced-regexp "\\).+?[:=]"))

             ;; Namespaces definition
             (x-namespace-def-regexp (concat "namespace\s+\\(" namespaced-regexp "\\)\s+where"))
             ;; Namespaces import
             (x-namespace-import-regexp (concat "use\s+\\(" namespaced-regexp "\\)"))

             ;; Abilities
             (x-ability-def-regexp (concat "ability\s\\(" type-regexp "\\)\s.+"))
             ;;(x-ability-regexp (concat "{\\(?:.*\\|\\(" type-regexp "\\)\\)}"))
             (x-ability-regexp (concat "[{,].*?\\(" type-regexp "\\)"))

             (x-type-def-regexp (concat "type\s\\(" type-regexp "\\)\s.+"))
             (x-type-regexp (concat "[^a-z]\\(" type-regexp "\\)"))

             (x-esc-regexp "!"))


        `(
          (,x-fold-regexp . (0 font-lock-comment-face t))
          (,x-keywords-full-regexp . font-lock-keyword-face)
          (,x-single-quote-exc-regexp . (2 font-lock-keyword-face))
          (,x-request-regexp . font-lock-preprocessor-face)
          (,x-sig-regexp . (1 font-lock-function-name-face))
          (,x-namespace-def-regexp . (1 font-lock-constant-face))
          (,x-namespace-import-regexp . (1 font-lock-constant-face))
          (,x-ability-def-regexp . (1 font-lock-variable-name-face))
          (,x-ability-regexp . (1 font-lock-variable-name-face))
          (,x-type-def-regexp . (1 font-lock-type-face))
          (,x-type-regexp . (1 font-lock-type-face))
          (,x-esc-regexp . font-lock-negation-char-face))))

(defun unisonlang-mode-add-fold ()
  "Add a fold above the current line."
  (interactive)
  (newline)
  (newline)
  (newline)
  (save-excursion
    (forward-line -2)
    (insert "---")))

(defun unisonlang-delete-line ()
  "Delete the current line if empty."
  (let (start end content)
    (setq start (line-beginning-position))
    (setq end (line-end-position))
    (setq content (buffer-substring start end))
    (if (eq start end)
      (delete-region start (+ 1 end))
      (if (string-equal content "---")
        (delete-region start (+ 1 end))
        (forward-line 1)))))

(defun unisonlang-mode-remove-fold ()
  "Remove the fold directly above the current line."
  (interactive)
  (progn
     (goto-char (search-backward "---"))
     (forward-line -1)
     (unisonlang-delete-line)
     (unisonlang-delete-line)
     (unisonlang-delete-line)))

(defvar unisonlang-mode-map
  (let ((km (make-sparse-keymap)))
   (define-key km (kbd "C-c C-f") #'unisonlang-mode-add-fold)
   (define-key km (kbd "C-c C-d") #'unisonlang-mode-remove-fold)
   km)
  "Keymap for `unisonlang-mode'.")

(defun unisonlang-font-lock-extend-region ()
  "Extend the search region to include an entire block of text."
  ;; Avoid compiler warnings about these global variables from font-lock.el.
  ;; See the documentation for variable `font-lock-extend-region-functions'.
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (or (re-search-backward "\n\n" nil t) (point-min))))
      (goto-char font-lock-end)
      (when (re-search-forward "\n\n" nil t)
        (beginning-of-line)
        (setq font-lock-end (point)))
      (setq font-lock-beg found))))

;;;###autoload
(define-derived-mode unisonlang-mode prog-mode "unisonlang-mode"
  "Major mode for editing Unison"

  :syntax-table unisonlang-mode-syntax-table

  (setq font-lock-defaults '(unisonlang-font-lock-keywords))
  (setq font-lock-multiline t)
  (add-hook 'font-lock-extend-region-functions #'unisonlang-font-lock-extend-region)
  (font-lock-ensure)

  (setq-local comment-start "--  ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.u\\'" . unisonlang-mode))

;; add the mode
(provide 'unisonlang-mode)

;;; unisonlang-mode.el ends here
