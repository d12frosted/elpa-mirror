;;; pronto.el --- Compilation mode for pronto stylechecks -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Julian Rubisch

;; Author: Julian Rubisch <julian@julianrubisch.at>
;; Version: 1.0
;; Package-Version: 20200218.1633
;; Package-Commit: c0cd13d8219879610b7fe284b182a9db4d3d40b3
;; Keywords: processes, tools
;; URL: https://github.com/julianrubisch/pronto.el
;; Package-Requires: ((emacs "24"))

;;; Commentary:
;; Run pronto (https://github.com/prontolabs/pronto) in a compilation mode and
;; present errors in an Emacs compilation buffer.

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

;;; Code:
(require 'compile)
(require 'ansi-color)

(defvar pronto-last-commit nil
  "Last commit pronto was run against.")

(defvar pronto-last-args nil
  "Last arguments pronto was run with.")

(defun pronto-run (commit)
  "Run pronto against COMMIT."
  (interactive (list (read-string "Commit: " pronto-last-commit)))
  (pronto-compile commit))

(define-compilation-mode pronto-compilation-mode "Pronto Compilation"
  "Compilation mode for pronto output."
  (add-hook 'compilation-filter-hook #'pronto-colorize-compilation-buffer nil t))

(defun pronto-colorize-compilation-buffer()
  "Colorize the compilation buffer."
  (ansi-color-apply-on-region compilation-filter-start (point)))

(defun pronto-compile (commit)
  "Start a compilation against COMMIT."
  (setq pronto-last-commit commit)
  (compile (format "bundle exec pronto run -c=%s" (shell-quote-argument commit)) #'pronto-compilation-mode))

(defvar pronto-compilation-error-regexp-alist-alist
  '((pronto "^\\([0-9A-Za-z@_./:-]+\\.rb\\):\\([0-9]+\\)" 1 2 nil 2 1)))

(defvar pronto-compilation-error-regexp-alist
  (mapcar #'car pronto-compilation-error-regexp-alist-alist))

(provide 'pronto)
;;; pronto.el ends here
