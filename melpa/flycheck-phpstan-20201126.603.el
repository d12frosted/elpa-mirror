;;; flycheck-phpstan.el --- Flycheck integration for PHPStan  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 15 Mar 2018
;; Version: 0.5.0
;; Package-Version: 20201126.603
;; Package-Commit: 6863a5278fc656cddb604b0c6e165f05d0171d0a
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/phpstan.el
;; Package-Requires: ((emacs "24.3") (flycheck "26") (phpstan "0.5.0"))
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

(defun flycheck-phpstan--enabled-and-set-variable ()
  "Return path to phpstan configure file, and set buffer execute in side effect."
  (let ((enabled (phpstan-enabled)))
    (prog1 enabled
      (when (and phpstan-flycheck-auto-set-executable
                 (not (and (boundp 'flycheck-phpstan-executable)
                           (symbol-value 'flycheck-phpstan-executable)))
                 (or (stringp phpstan-executable)
                     (eq 'docker phpstan-executable)
                     (and (eq 'root (car-safe phpstan-executable))
                          (stringp (cdr-safe phpstan-executable)))
                     (and (stringp (car-safe phpstan-executable))
                          (listp (cdr-safe phpstan-executable)))
                     (null phpstan-executable)))
        (set (make-local-variable 'flycheck-phpstan-executable)
             (cond
              ((eq 'docker phpstan-executable) phpstan-docker-executable)
              ((stringp phpstan-executable) phpstan-executable)
              (t (car phpstan-executable))))))))

(flycheck-define-checker phpstan
  "PHP static analyzer based on PHPStan."
  :command ("php" (eval (phpstan-get-command-args))
            (eval (phpstan-normalize-path
                   (flycheck-save-buffer-to-temp #'flycheck-temp-file-inplace)
                   (flycheck-save-buffer-to-temp #'flycheck-temp-file-system))))
  :working-directory (lambda (_) (phpstan-get-working-dir))
  :enabled (lambda () (flycheck-phpstan--enabled-and-set-variable))
  :error-patterns
  ((error line-start (1+ (not (any ":"))) ":" line ":" (message) line-end))
  :modes (php-mode phps-mode))

(add-to-list 'flycheck-checkers 'phpstan t)
(flycheck-add-next-checker 'php 'phpstan)

(provide 'flycheck-phpstan)
;;; flycheck-phpstan.el ends here
