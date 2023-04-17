;;; flycheck-phpstan.el --- Flycheck integration for PHPStan  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 15 Mar 2018
;; Version: 0.7.2
;; Package-Version: 20230417.1142
;; Package-Commit: 2dc25cb2f3d83484ea0eb063c9ffca8148828a2b
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/phpstan.el
;; Package-Requires: ((emacs "24.3") (flycheck "26") (phpstan "0.7.2"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Flycheck integration for PHPStan.
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;     (defun my-php-mode-setup ()
;;       "My PHP-mode hook."
;;       (require 'flycheck-phpstan)
;;       (flycheck-mode t))
;;
;;     (add-hook 'php-mode-hook 'my-php-mode-setup)
;;

;;; Code:
(require 'flycheck)
(require 'phpstan)

;; Usually it is defined dynamically by flycheck
(defvar flycheck-phpstan-executable)
(defvar flycheck-phpstan--temp-buffer-name "*Flycheck PHPStan*")

(defun flycheck-phpstan--enabled-and-set-variable ()
  "Return path to phpstan configure file, and set buffer execute in side effect."
  (let ((enabled (phpstan-enabled)))
    (prog1 enabled
      (when (and enabled
                 phpstan-flycheck-auto-set-executable
                 (null (bound-and-true-p flycheck-phpstan-executable))
                 (or (stringp phpstan-executable)
                     (eq 'docker phpstan-executable)
                     (and (eq 'root (car-safe phpstan-executable))
                          (stringp (cdr-safe phpstan-executable)))
                     (and (stringp (car-safe phpstan-executable))
                          (listp (cdr-safe phpstan-executable)))
                     (null phpstan-executable)))
        (setq-local flycheck-phpstan-executable (car (phpstan-get-executable-and-args)))))))

(defun flycheck-phpstan-parse-output (output &optional _checker _buffer)
  "Parse PHPStan errors from OUTPUT."
  (with-current-buffer (flycheck-phpstan--temp-buffer)
    (erase-buffer)
    (insert output))
  (flycheck-phpstan-parse-json (flycheck-phpstan--temp-buffer)))

(defun flycheck-phpstan--temp-buffer ()
  "Return a temporary buffer for decode JSON."
  (get-buffer-create flycheck-phpstan--temp-buffer-name))

(defun flycheck-phpstan-parse-json (json-buffer)
  "Parse PHPStan errors from JSON-BUFFER."
  (let ((data (phpstan--parse-json json-buffer)))
    (cl-loop for (file . entry) in (flycheck-phpstan--plist-to-alist (plist-get data :files))
             append (cl-loop for messages in (plist-get entry :messages)
                             for text = (let ((msg (plist-get messages :message))
                                              (tip (plist-get messages :tip)))
                                          (if tip
                                              (concat msg "\n" phpstan-tip-message-prefix tip)
                                            msg))
                             collect (flycheck-error-new-at (plist-get messages :line)
                                                            nil 'error text
                                                            :filename file)))))

(defun flycheck-phpstan--plist-to-alist (plist)
  "Convert PLIST to association list."
  (let (alist)
    (while plist
      (push (cons (substring-no-properties (symbol-name (pop plist)) 1) (pop plist)) alist))
    (nreverse alist)))

(flycheck-define-checker phpstan
  "PHP static analyzer based on PHPStan."
  :command ("php" (eval (phpstan-get-command-args :format "json"))
            (eval (if (or (buffer-modified-p) (not buffer-file-name))
                      (phpstan-normalize-path
                       (flycheck-save-buffer-to-temp #'flycheck-temp-file-inplace))
                    buffer-file-name)))
  :working-directory (lambda (_) (phpstan-get-working-dir))
  :enabled (lambda () (flycheck-phpstan--enabled-and-set-variable))
  :error-parser flycheck-phpstan-parse-output
  :modes (php-mode phps-mode))

(add-to-list 'flycheck-checkers 'phpstan t)
(flycheck-add-next-checker 'php 'phpstan)

(provide 'flycheck-phpstan)
;;; flycheck-phpstan.el ends here
