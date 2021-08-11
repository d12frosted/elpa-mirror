;;; flymake-proselint.el --- Flymake backend for proselint -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Free Software Foundation, Inc.
;;
;; Author: Manuel Uberti <manuel.uberti@inventati.org>
;; Version: 0.2.1
;; Package-Version: 20210810.1449
;; Package-Commit: 6509e5c8fc15acd85f036f06e235ef96b3afa0e0
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/manuel-uberti/flymake-proselint

;; flymake-proselint is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later version.
;;
;; flymake-proselint is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License
;; along with flymake-proselint.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package adds support for proselint (http://proselint.com/) in Flymake.

;; Once installed, the backend can be enabled with:
;; (add-hook 'markdown-mode-hook #'flymake-proselint-setup)

;;; Code:

(require 'flymake)

(defvar-local flymake-proselint--flymake-proc nil)

(defun flymake-proselint-backend (report-fn &rest _args)
  (unless (executable-find "proselint")
    (user-error "Executable proselint not found on PATH"))

  (when (process-live-p flymake-proselint--flymake-proc)
    (kill-process flymake-proselint--flymake-proc))

  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq
       flymake-proselint--flymake-proc
       (make-process
        :name "proselint-flymake" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *proselint-flymake*")
        :command '("proselint" "-")
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-proselint--flymake-proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (cl-loop
                       while (search-forward-regexp
                              "^.+:\\([[:digit:]]+\\):\\([[:digit:]]+\\): \\(.+\\)$"
                              nil t)
                       for msg = (match-string 3)
                       for (beg . end) = (flymake-diag-region
                                          source
                                          (string-to-number (match-string 1))
                                          (string-to-number (match-string 2)))
                       collect (flymake-make-diagnostic source
                                                        beg
                                                        end
                                                        :warning
                                                        msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-proselint--flymake-proc (point-min) (point-max))
      (process-send-eof flymake-proselint--flymake-proc))))

;;;###autoload
(defun flymake-proselint-setup ()
  "Enable Flymake backend proselint."
  (add-hook 'flymake-diagnostic-functions #'flymake-proselint-backend nil t))

(provide 'flymake-proselint)

;;; flymake-proselint.el ends here
