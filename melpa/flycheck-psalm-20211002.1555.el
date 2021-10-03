;;; flycheck-psalm.el --- Flycheck integration for Psalm  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 10 May 2020
;; Version: 0.6.0
;; Package-Version: 20211002.1555
;; Package-Commit: 28d546a79cb865a78b94cd7e929d66d720505faa
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/psalm.el
;; Package-Requires: ((emacs "24.3") (flycheck "26") (psalm "0.6.0"))
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

;; Flycheck integration for Psalm.
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;     (defun my-php-mode-setup ()
;;       "My PHP-mode hook."
;;       (require 'flycheck-psalm)
;;       (flycheck-mode t))
;;
;;     (add-hook 'php-mode-hook 'my-php-mode-setup)
;;

;;; Code:
(require 'flycheck)
(require 'psalm)

;; Usually it is defined dynamically by flycheck
(defvar flycheck-psalm-executable)

(defun flycheck-psalm--enabled-and-set-variable ()
  "Return path to psalm configure file, and set buffer execute in side effect."
  (let ((enabled (psalm-enabled)))
    (prog1 enabled
      (when (and psalm-flycheck-auto-set-executable
                 (not (and (boundp 'flycheck-psalm-executable)
                           (symbol-value 'flycheck-psalm-executable)))
                 (or (eq 'docker psalm-executable)
                     (and (consp psalm-executable)
                          (stringp (car psalm-executable))
                          (listp (cdr psalm-executable)))))
        (set (make-local-variable 'flycheck-psalm-executable)
             (if (eq 'docker psalm-executable)
                 psalm-docker-executable
               (car psalm-executable)))))))

(flycheck-define-checker psalm
  "PHP static analyzer based on Psalm."
  :command ("php" (eval (psalm-get-command-args))
            (eval (psalm-normalize-path
                   (flycheck-save-buffer-to-temp #'flycheck-temp-file-inplace)
                   (buffer-file-name))))
  :working-directory (lambda (_) (psalm-get-working-dir))
  :enabled (lambda () (flycheck-psalm--enabled-and-set-variable))
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":warning - " (message) line-end)
   (error line-start (file-name) ":" line ":" column ":error - " (message) line-end))
  :modes (php-mode phps-mode))

(add-to-list 'flycheck-checkers 'psalm t)
(flycheck-add-next-checker 'php 'psalm)

(provide 'flycheck-psalm)
;;; flycheck-psalm.el ends here
