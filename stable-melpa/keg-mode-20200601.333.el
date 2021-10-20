;;; keg-mode.el --- Major mode for editing Keg files  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Keywords: convenience
;; Package-Version: 20200601.333
;; Package-Commit: d98113b8c32ad0164b05f92bec447d64268e311e
;; URL: https://github.com/conao3/keg.el
;; Package-Requires: ((emacs "24.4"))
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for editing Keg files.

;;; Code:

(require 'lisp-mode)

(defvar keg-lisp-mode-symbol-regexp "\\(?:\\sw\\|\\s_\\|\\\\.\\)+"
  "Lisp symbol regexp.
This variable defined as backward compatibility.
Original variable is `lisp-mode-symbol-regexp'.")

(defvar keg-mode-font-lock-keywords
  `((,(regexp-opt
       '("source" "package" "dev-dependency" "disable-lint")
       'symbols)
     . font-lock-keyword-face)
    (,(regexp-opt
       '("gnu" "melpa-stable" "melpa" "org")
       'symbols)
     . font-lock-variable-name-face)
    ;; Constant values.
    (,(concat "\\_<:" keg-lisp-mode-symbol-regexp "\\_>")
     (0 font-lock-builtin-face))))

;;;###autoload
(define-derived-mode keg-mode prog-mode "Keg"
  "Major mode for editing Keg files."
  (lisp-mode-variables t nil t)
  (setq font-lock-defaults '(keg-mode-font-lock-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("/Keg\\'" . keg-mode))

(provide 'keg-mode)
;;; keg-mode.el ends here
