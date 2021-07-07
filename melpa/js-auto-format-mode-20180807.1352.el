;;; js-auto-format-mode.el --- Minor mode for auto-formatting JavaScript code  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Masafumi Koba <ybiquitous@gmail.com>

;; Author: Masafumi Koba <ybiquitous@gmail.com>
;; Version: 1.1.1
;; Package-Version: 20180807.1352
;; Package-Commit: 516abed166d687aa8b197973315bd6ea0900fb62
;; Package-Requires: ((emacs "24"))
;; Keywords: languages
;; URL: https://github.com/ybiquitous/js-auto-format-mode
;; Created: Apr 2016
;; License: GNU General Public License v3.0
;; Distribution: This file is not part of Emacs

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

;; Usage:
;;
;;   (add-hook 'js-mode-hook #'js-auto-format-mode)
;;
;; To customize:
;;
;;   M-x customize-group RET js-auto-format RET
;;
;; For details, please see `https://github.com/ybiquitous/js-auto-format-mode'.

;;; Code:

(defgroup js-auto-format nil
  "Minor mode for auto-formatting JavaScript code."
  :group 'languages
  :prefix "js-auto-format-"
  :link '(url-link :tag "Repository" "https://github.com/ybiquitous/js-auto-format-mode"))

(defcustom js-auto-format-command "eslint"
  "Executable command."
  :group 'js-auto-format
  :type 'string
  :safe #'stringp)

(defcustom js-auto-format-command-args "--fix --format=unix"
  "Argument(s) of command."
  :group 'js-auto-format
  :type 'string
  :safe #'stringp)

(defcustom js-auto-format-disabled nil
  "Disable this mode."
  :group 'js-auto-format
  :type 'boolean
  :safe #'booleanp)

(defun js-auto-format-full-command ()
  "Return full command with all arguments."
  (format "%s %s %s"
    (shell-quote-argument (executable-find js-auto-format-command))
    js-auto-format-command-args
    (shell-quote-argument (expand-file-name buffer-file-name))))

(defun js-auto-format-buffer-name (_arg)
  "Return this mode's buffer name."
  "*JS Auto Format*")

;;;###autoload
(defun js-auto-format-enabled-p ()
  "Test whether js-auto-format-mode is enabled."
  (and
    (not buffer-read-only)
    (not js-auto-format-disabled)
    (buffer-file-name)
    (not (string-match-p "/node_modules/" buffer-file-name))))

;;;###autoload
(defun js-auto-format-execute ()
  "Format JavaScript source code."
  (interactive)
  (when (js-auto-format-enabled-p)
    (let* ((saved-current-buffer (current-buffer))
            (compile-buffer (compilation-start (js-auto-format-full-command) nil #'js-auto-format-buffer-name)))
      (with-current-buffer compile-buffer
        (add-hook 'compilation-finish-functions
          (lambda (buffer _message)
            ;; `compilation-num-errors-found' is private API
            (if (= compilation-num-errors-found 0)
              (quit-window t (get-buffer-window buffer t))
              (shrink-window-if-larger-than-buffer (get-buffer-window buffer t)))
            (with-current-buffer saved-current-buffer
              (revert-buffer t t t)
              (if (fboundp 'flycheck-buffer) (flycheck-buffer))))
          t t))
      )))

;;;###autoload
(define-minor-mode js-auto-format-mode
  "Minor mode for auto-formatting JavaScript code"
  :group 'js-auto-format
  :lighter " AutoFmt"
  (if js-auto-format-mode
    (add-hook 'after-save-hook 'js-auto-format-execute t t)
    (remove-hook 'after-save-hook 'js-auto-format-execute t)))

(provide 'js-auto-format-mode)
;;; js-auto-format-mode.el ends here
