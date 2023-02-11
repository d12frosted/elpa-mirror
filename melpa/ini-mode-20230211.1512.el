;;; ini-mode.el --- Major mode for Windows-style ini files.

;; Copyright (C) 2014-2017 Anders Lindgren

;; Author: Anders Lindgren
;; Keywords: languages, faces
;; Package-Version: 20230211.1512
;; Package-Commit: 5472abc94e564edc6b469c48d2324519a044a77c
;; Version: 0.0.7
;; Package-Requires: ((emacs "24.1"))
;; Created: 2014-03-19
;; URL: https://github.com/Lindydancer/ini-mode

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for Windows-style ini files.
;;
;; Features:
;;
;; * Syntax highlight support.
;;
;; * Inherits from `prog-mode' (if present).  The effect is that global
;;   minor modes that activates themselves in `prog-mode' buffers
;;   automatically work in `ini-mode'.
;;
;; Example:
;;
;; ![Example](doc/demo.png)

;; Background:
;;
;; There are many implementation of major modes for ini files.  This is
;; my attempt of a modern, simple, implementation.

;; Installation:
;;
;; This package is designed to be installed as a "package".  Once
;; installed, it is automatically used when opening files the .ini
;; extension.
;;
;; Alternatively, you can place the following lines in a suitable
;; initialization file:
;;
;;     (autoload 'ini-mode "ini-mode" nil t)
;;     (add-to-list 'auto-mode-alist '("\\.ini\\'" . ini-mode))

;;; Code:

(defvar ini-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C and C++-style comments.
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    ;; Lisp-style comments.
    (modify-syntax-entry ?\; "< b" table)
    table)
  "Syntax table for `ini-mode'.")

(defvar ini-font-lock-keywords
  '(("^\\[\\(.*\\)\\]"
     (1 font-lock-function-name-face))
    ("^\\s-*\\([^ \t\n=]+\\)\\s-*="
     (1 font-lock-variable-name-face)))
  "Highlight rules for `ini-mode'.")

;;;###autoload
(define-derived-mode ini-mode prog-mode "ini"
  "Major mode for editing Windows-style ini files."
  (setq font-lock-defaults '(ini-font-lock-keywords nil)))

;;;###autoload(add-to-list 'auto-mode-alist '("\\.ini\\'" . ini-mode))

(provide 'ini-mode)

;;; ini-mode.el ends here
