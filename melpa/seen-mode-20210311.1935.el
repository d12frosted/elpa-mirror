;;; seen-mode.el --- A syntax highlighting package for text/kepago -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Filipe da Silva Santos

;; Author: Filipe da Silva Santos <contact@shiori.com.br>
;; Created: 25 Feb 2021
;; Version: 0.3.0
;; Package-Version: 20210311.1935
;; Package-Commit: 57c960d76ad3dc551ac5a57ebe8682ef9fdc6d31
;; Keywords: languages
;; Homepage: https://git.sr.ht/~shiorid/seen.el
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a major mode for editing text/kepago files.
;; I hope it helps future VN translators and developers.

;;; Code:
(require 'cl-lib)

(defcustom seen-mode-hook 'turn-on-visual-line-mode
  "Basic hook for wrapping lines when on `seen-mode'."
  :type 'hook
  :options '(turn-on-visual-line-mode)
  :group 'seen-mode)

(defconst seen-regex-preprocessor
  "^\\(#.*\\)$"
  "Regular expression for matching preprocessor instructions.
Used by 'font-lock-defaults'.")

(defconst seen-regex-function
  "\\(@[^ \t\n:;]+\\)"
  "Regular expression for matching function names e.g. objBgClear.
Used by 'font-lock-defaults'.")

(defconst seen-regex-intx
  "\\(int[A-Z]\\[[0-9]+\\]\\)"
  "Regular expression for matching `int` declarations e.g. intF[3].
Used by 'font-lock-defaults'.")

(defconst seen-regex-strx
  "\\(str[A-Z]\\[[0-9]+\\]\\)"
  "Regular expression for matching `string` declarations e.g. strF[1000].
Used by 'font-lock-defaults'.")

(defconst seen-regex-string
  "'\\(.*\\)'"
  "Regular expression for mathing `string` blocks.
Used by 'font-lock-defaults'.")

(defconst seen-controlflow
  '("farcall" "farcall_with" "gosub" "gosub_case" "gosub_if" "gosub_on"
    "gosub_unless" "goto" "goto_case" "goto_if" "goto_on" "goto_unless" "jump"
    "pause" "ret" "ret_with" "rtl" "rtl_with")
  "Reserved words for control flow.
Used by 'font-lock-defaults'.")

(defconst seen-datatypes
  '("bit" "bit2" "bit4" "byte" "int" "str")
  "Reserved words for datatypes.
Used by 'font-lock-defaults'.")

(defconst seen-functions
  '("bgmLoop" "grpBuffer" "grpMulti" "objBgClear" "objBgMove" "objBgOfFile"
    "op" "recOpenBg" "title")
  "Reserved words for functions.
Used by 'font-lock-defaults'.")

(defconst seen-keywords
  '("case" "ecase" "else" "for" "if" "of" "other" "repeat" "till" "while")
  "Reserved keywords.
Used by 'font-lock-defaults'.")

(defvar seen-font-lock
  `((,seen-regex-preprocessor . font-lock-string-face)
    (,seen-regex-function . font-lock-function-name-face)
    (,seen-regex-intx . font-lock-variable-name-face)
    (,seen-regex-strx . font-lock-variable-name-face)
    (,seen-regex-string . font-lock-string-face)
    
    (,(regexp-opt seen-controlflow)  . font-lock-builtin-face)
    (,(regexp-opt seen-datatypes) . font-lock-keyword-face)
    (,(regexp-opt seen-functions) . font-lock-function-name-face)
    (,(regexp-opt seen-keywords)  . font-lock-keyword-face)))

;;;###autoload
(define-derived-mode seen-mode prog-mode "seen-mode"
  "Major mode for editing text/kepago scripts"
  (setq font-lock-defaults '(seen-font-lock))
  (visual-line-mode 1)
  (run-hooks 'seen-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ke\\'" . seen-mode))

(provide 'seen-mode)

;;; seen-mode.el ends here
