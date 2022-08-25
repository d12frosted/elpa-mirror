;;; djinni-mode.el --- Major-mode for editing Djinni files. -*- lexical-binding: t -*-

;; Copyright (C) 2019 Daniel Martín (mardani29@yahoo.es)

;; Author: Daniel Martín <mardani29@yahoo.es>
;; URL: https://github.com/danielmartin/djinni-mode
;; Package-Version: 20190303.139
;; Package-Commit: f0da31d8f45c4b1b2341cf88ec7f2d2e7d16267f
;; Version: 1.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: languages

;; This file is not part of GNU Emacs.

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

;; Major mode for editing Djinni files (https://github.com/dropbox/djinni).
;; Automatically loaded when a file with .djinni extension is open in Emacs.

;;; Code:

(require 'compile)

(defgroup djinni nil
  "Editing and compiling Djinni files."
  :group 'languages)

(defcustom djinni-basic-offset 4
  "Indentation width to use in Djinni files."
  :type 'integer
  :group 'djinni)

;;;###autoload
(defcustom djinni-compile-command (purecopy "./run_djinni.sh")
  "Name of the script to compile Djinni files."
  :type 'string
  :group 'djinni)

(defvar djinni-syntax-table
  (let ((st (make-syntax-table)))
    ;; Comments
    (modify-syntax-entry ?\# "<" st)
    (modify-syntax-entry ?\n ">" st)
    ;; Parenthesis
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\} "){" st)
    st)
  "Syntax table in use in `djinni-mode' buffers.")

(defvar djinni-font-lock-keywords
  (let* (;; Define categories of keywords.
         (djinni-keywords '("interface" "record" "enum" "flags" "deriving" "eq" "ord" "const" "static" "none" "all"))
         (djinni-types '("bool" "string" "i8" "i16" "i32" "i64" "f8" "f16" "f32" "f64"
                         "binary" "date" "list" "set" "map" "optional"))

         ;; Generate an optimized regexp for each category.
         (djinni-keywords-regexp (regexp-opt djinni-keywords 'symbols))
         (djinni-types-regexp (regexp-opt djinni-types 'symbols)))
    `(("\\([a-zA-Z0-9_]+\\)\\s-*:\\s-*\\([a-zA-Z0-9_]+\\)" (1 'font-lock-variable-name-face) (2 'font-lock-type-face))
      ("^\\s-*\\([a-zA-Z0-9_]+\\)\\s-*;" . (1 'font-lock-variable-name-face))
      ("+\\(j\\|c\\|o\\)\\b" . font-lock-keyword-face)
      ;; @import is also considered a keyword.
      ("@\\import\\b" . font-lock-keyword-face)
      (")\\s-*:\\s-*\\([a-zA-Z0-9_]+\\)" . (1 'font-lock-type-face))
      ("<\\s-*\\([a-zA-Z0-9_]+\\)\\s-*>" . (1 'font-lock-type-face))
      ("^\\s-*\\(\\sw+\\)\\s-*=" . (1 'font-lock-type-face))
      ("^\\s-*\\(static\\|const\\s-*\\)?\\s-+\\(\\(\\sw\\|\\s_\\)+\\)\\s-*(" . (2 'font-lock-function-name-face))
      (,djinni-types-regexp . font-lock-type-face)
      (,djinni-keywords-regexp . font-lock-keyword-face))))

(defun djinni-font-lock-setup ()
  "Configures font locking in ‘djinni-mode’."
  (setq font-lock-defaults
        '((djinni-font-lock-keywords))))

;; Indentation
(defun djinni-indent-line ()
  "Indent current line in `djinni-mode' buffers."
  (interactive)
  (let ((indent-col 0))
    (save-excursion
      (beginning-of-line)
      (condition-case nil
          (while t
            (backward-up-list 1)
            (when (looking-at "[{]")
              (setq indent-col (+ indent-col djinni-basic-offset))))
        (error nil)))
    (save-excursion
      (back-to-indentation)
      (when (and (looking-at "[}]") (>= indent-col djinni-basic-offset))
        (setq indent-col (- indent-col djinni-basic-offset))))
    (indent-line-to indent-col)))

(defun djinni-compile-configuration ()
  "Configures `compilation-error-regexp-alist-alist' to parse
line and column information from errors in the compilation
buffer."
  (add-to-list 'compilation-error-regexp-alist-alist
                   '(djinni
                     "\\([_[:alnum:]-/]*.djinni\\)\s(\\([[:digit:]]+\\).\\([[:digit:]]+\\)).*$"
                     1 2 3)))

(add-hook 'djinni-mode-hook 'djinni-compile-configuration)

;; Compilation
;;;###autoload
(defun djinni-compile (command)
  "Compiles a Djinni file in current buffer."
  (interactive
   (list
    (let ((command (eval djinni-compile-command)))
     (if (or compilation-read-command current-prefix-arg)
	 (compilation-read-command command)
       command))))
  (let* ((compilation-buffer-name-function (lambda (major-mode-name) "*Djinni compilation*"))
         (buffer (compile command)))
    (with-current-buffer buffer
      (setq-local compilation-error-regexp-alist '(djinni)))))

;; Keybindings
(defvar djinni-mode-map
  (let ((djinni-mode-map (make-sparse-keymap)))
    (define-key djinni-mode-map (kbd "C-c C-c") 'djinni-compile)
    djinni-mode-map)
  "Keymap for `djinni-mode'.")

;;;###autoload
(define-derived-mode djinni-mode prog-mode "Djinni"
  "Major mode for editing Djinni files."
  ;; Syntax table
  (set-syntax-table djinni-syntax-table)
  ;; Comments
  (setq-local comment-start "#")
  ;; Indentation
  (setq indent-tabs-mode nil)
  (setq-local indent-line-function 'djinni-indent-line)
  ;; Font locking
  (djinni-font-lock-setup))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.djinni\\'" . djinni-mode))

(provide 'djinni-mode)
;;; djinni-mode.el ends here
