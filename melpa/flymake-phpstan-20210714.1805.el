;;; flymake-phpstan.el --- Flymake backend for PHP using PHPStan  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 31 Mar 2020
;; Version: 0.6.0
;; Package-Version: 20210714.1805
;; Package-Commit: 0869b152f82a76138daa53e953285936b9d558bd
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/phpstan.el
;; Package-Requires: ((emacs "26.1") (phpstan "0.5.0"))
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

;; Flymake backend for PHP using PHPStan (PHP Static Analysis Tool).
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;     (add-hook 'php-mode-hook #'flymake-phpstan-turn-on)
;;
;; For Lisp maintainers: see [GNU Flymake manual - 2.2.2 An annotated example backend]
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html

;;; Code:
(require 'cl-lib)
(require 'php-project)
(require 'flymake)
(require 'phpstan)
(eval-when-compile
  (require 'pcase))

(defgroup flymake-phpstan nil
  "Flymake backend for PHP using PHPStan."
  :group 'flymake
  :group 'phpstan)

(defcustom flymake-phpstan-disable-c-mode-hooks t
  "When T, disable `flymake-diagnostic-functions' for `c-mode'."
  :type 'boolean
  :group 'flymake-phpstan)

(defvar-local flymake-phpstan--proc nil)

(defun flymake-phpstan-make-process (root command-args report-fn source)
  "Make PHPStan process by ROOT, COMMAND-ARGS, REPORT-FN and SOURCE."
  (let ((default-directory root))
    (make-process
     :name "flymake-phpstan" :noquery t :connection-type 'pipe
     :buffer (generate-new-buffer " *Flymake-PHPStan*")
     :command command-args
     :sentinel
     (lambda (proc _event)
       (pcase (process-status proc)
         (`exit
          (unwind-protect
              (when (with-current-buffer source (eq proc flymake-phpstan--proc))
                (with-current-buffer (process-buffer proc)
                  (goto-char (point-min))
                  (cl-loop
                   while (search-forward-regexp
                          (eval-when-compile
                            (rx line-start (1+ (not (any ":"))) ":"
                                (group-n 1 (one-or-more (not (any ":")))) ":"
                                (group-n 2 (one-or-more not-newline)) line-end))
                          nil t)
                   for msg = (match-string 2)
                   for (beg . end) = (flymake-diag-region
                                      source
                                      (string-to-number (match-string 1)))
                   for type = :warning
                   collect (flymake-make-diagnostic source beg end type msg)
                   into diags
                   finally (funcall report-fn diags)))
                (flymake-log :warning "Canceling obsolete check %s" proc))
            (kill-buffer (process-buffer proc))))
         (code (user-error "PHPStan error (exit status: %s)" code)))))))

(defun flymake-phpstan (report-fn &rest _ignored-args)
  "Flymake backend for PHPStan report using REPORT-FN."
  (let ((command-args (phpstan-get-command-args t)))
    (unless (car command-args)
      (user-error "Cannot find a phpstan executable command"))
    (when (process-live-p flymake-phpstan--proc)
      (kill-process flymake-phpstan--proc))
    (let ((source (current-buffer)))
      (save-restriction
        (widen)
        (setq flymake-phpstan--proc (flymake-phpstan-make-process (php-project-get-root-dir) command-args report-fn source))
        (process-send-region flymake-phpstan--proc (point-min) (point-max))
        (process-send-eof flymake-phpstan--proc)))))

;;;###autoload
(defun flymake-phpstan-turn-on ()
  "Enable `flymake-phpstan' as buffer-local Flymake backend."
  (interactive)
  (let ((enabled (phpstan-enabled)))
    (when enabled
      (flymake-mode 1)
      (when flymake-phpstan-disable-c-mode-hooks
        (remove-hook 'flymake-diagnostic-functions #'flymake-cc t))
      (add-hook 'flymake-diagnostic-functions #'flymake-phpstan nil t))))

(provide 'flymake-phpstan)
;;; flymake-phpstan.el ends here
