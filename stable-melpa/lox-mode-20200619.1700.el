;;; lox-mode.el --- Major mode for the Lox programming language -*- lexical-binding: t -*-

;; Copyright (C) 2020 Timmy Jose<zoltan.jose@gmail.com>

;; Author: Timmy Jose <zoltan.jose@gmail.com>
;; Maintainer: Timmy Jose <zoltan.jose@gmail.com>
;; Version: 1.0
;; Package-Version: 20200619.1700
;; Package-Commit: b6935b3f5b131d2c1c7685cf6464274f7cd64943
;; Keywords: languages, lox
;; Package-Requires: ((emacs "24.3"))

;; Homepage: https://github.com/timmyjose-projects/lox-mode

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
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;  A major mode for the Lox programming language (http://craftinginterpreters.com/the-lox-language.html).

;;; Code:

(defvar lox-mode-hook nil)

(defgroup lox-mode-group nil
  "Lox mode configuration group."
  :link '(url-link "https://www.craftinginterpreters.com/the-lox-language.html")
  :group 'languages)

(defcustom lox-bin "clox"
  "Path to the Lox executable."
  :type 'string
  :safe #'stringp
  :group 'lox-mode-group)

;; Lox-specific

(defconst lox-keywords
  '("class" "fun" "var" "for" "if" "else" "while" "return" "and" "or" "super" "this"))

(defconst lox-builtins
  '("print"))

(defconst lox-constants
  '("true" "false" "nil"))

(defvar lox-font-lock-definitions
  (append
   `((,(regexp-opt lox-keywords) . font-lock-keyword-face)
     (,(regexp-opt lox-builtins) . font-lock-builtin-face)
     (,(regexp-opt lox-constants) . font-lock-constant-face))))

;; supported commands

;;;###autoload
(defun lox-run ()
  "Run the currently loaded script."
  (interactive)
  (compile (concat lox-bin " " (buffer-file-name))))

(defvar lox-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-r") 'lox-run)
    map)
  "Keymap for Lox mode.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lox\\'" . lox-mode))

;; Derive the mode from c-mode for automatic syntax highlighting and
;; indentation. Once (if) a custom formatter is written for this mode, this
;; can probably derive from prog-mode instead.

;;;###autoload
(define-derived-mode lox-mode c-mode "Lox"
  "A major mode for the Lox programming language.

  \\{lox-mode-map}"
  :group 'lox-mode-group
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq font-lock-defaults '(lox-font-lock-definitions)))

(provide 'lox-mode)

;;; lox-mode.el ends here
