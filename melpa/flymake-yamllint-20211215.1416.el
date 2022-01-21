;;; flymake-yamllint.el --- YAML linter with yamllint  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Martin Kjær Jørgensen (shaohme) <mkj@gotu.dk>
;;
;; Author: Martin Kjær Jørgensen <mkj@gotu.dk>
;; Created: 26 November 2021
;; Version: 0.1.1
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/shaohme/flymake-yamllint
;;; Commentary:

;; This package adds YAML syntax checker yamllint.
;; Make sure 'yamllint' binary is on your path.
;; Installation instructions https://github.com/adrienverge/yamllint#installation

;; flymake-yamllint expect `yamllint' to produce stdout like:
;; test.yml:2:4: [error] wrong indentation: expected 2 but found 3 (indentation)

;; Example above should be matched by regex used in code like this:
;; 0: stdin:79:81: [warning] line too long (117 > 80 characters) (line-length)
;; 1: 79
;; 2: 81
;; 3: [warning]
;; 4: line too long (117 > 80 characters) (line-length)

;; SPDX-License-Identifier: GPL-3.0-or-later

;; flymake-yamllint is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; flymake-yamllint is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with flymake-yamllint.  If not, see http://www.gnu.org/licenses.

;;; Code:

(require 'flymake)

(defgroup flymake-yamllint nil
  "Yamllint backend for Flymake."
  :prefix "flymake-yamllint-"
  :group 'tools)

(defcustom flymake-yamllint-path
  (executable-find "yamllint")
  "The path to the `yamllint' executable."
  :type 'string)

(defvar-local flymake-yamllint--proc nil)

(defun flymake-yamllint (report-fn &rest _args)
  "Flymake backend for yamllint report using REPORT-FN."
  (unless (and flymake-yamllint-path
               (file-executable-p flymake-yamllint-path))
    (error "Could not find yamllint executable"))

  (when (process-live-p flymake-yamllint--proc)
    (kill-process flymake-yamllint--proc)
    (setq flymake-yamllint--proc nil))

  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq
       flymake-yamllint--proc
       (make-process
        :name "flymake-yamllint" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *flymake-yamllint*")
        :command (list flymake-yamllint-path "-" "-f" "parsable")
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-yamllint--proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (let ((diags))
                        (while (search-forward-regexp "^.+?:\\([0-9]+\\):\\([0-9]+\\): \\(\\[.*\\]\\) \\(.*\\)$" nil t)
                          (let ((region (flymake-diag-region source (string-to-number (match-string 1)) (string-to-number (match-string 2))))
                                (error-type (match-string 3)))
                            ;; expect `region' to only have 2 values (start . end)
                            (push (flymake-make-diagnostic source
                                                           (car region)
                                                           (cdr region)
                                                           (cond ((equal error-type "[error]") :error)
                                                                 ((equal error-type "[warning]") :warning)
                                                                 ((equal error-type "[info]") :info))
                                                           (match-string 4)) diags)))
                        (funcall report-fn (reverse diags))))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-yamllint--proc (point-min) (point-max))
      (process-send-eof flymake-yamllint--proc))))

;;;###autoload
(defun flymake-yamllint-setup ()
  "Enable yamllint flymake backend."
  (add-hook 'flymake-diagnostic-functions #'flymake-yamllint nil t))

(provide 'flymake-yamllint)
;;; flymake-yamllint.el ends here
