;;; flymake-hadolint.el --- Flymake backend for hadolint, a Dockerfile linter  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Taiki Sugawara

;; Author: Taiki Sugawara <buzz.taiki@gmail.com>
;; Keywords: convenience, processes, docker, flymake
;; URL: https://github.com/buzztaiki/flymake-hadolint
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1"))

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

;; This package provides flymake backend for hadolint, a Dockerfile linter.
;; To use it with dockerfile-mode, add the following to your init file:
;;
;;   (add-hook 'dockerfile-mode-hook #'flymake-hadolint-setup)


;;; Code:

(require 'flymake)

(defvar-local flymake-hadolint--proc nil)

(defgroup flymake-hadolint nil
  "Flymake backend for hadolint."
  :prefix "flymake-hadolint-"
  :group 'flymake)


(defcustom flymake-hadolint-program "hadolint"
  "A hadolint program name."
  :type 'string
  :group 'flymake-hadolint)

(defun flymake-hadolint (report-fn &rest _args)
  "Flymake backend for hadolint.

REPORT-FN is Flymake's callback function."
  (unless (executable-find flymake-hadolint-program)
    (error "Cannot find a suitable hadolint"))
  (when (process-live-p flymake-hadolint--proc)
    (kill-process flymake-hadolint--proc))
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq flymake-hadolint--proc
            (make-process
             :name "flymake-hadolint" :noquery t :connection-type 'pipe
             :buffer (generate-new-buffer " *flymake-hadolint*")
             :command (list flymake-hadolint-program "--no-color" "/dev/stdin")
             :sentinel
             (lambda (proc event) (flymake-hadolint--process-sentinel proc event source report-fn))))
      (process-send-region flymake-hadolint--proc (point-min) (point-max))
      (process-send-eof flymake-hadolint--proc))))

(defun flymake-hadolint--process-sentinel (proc _event source report-fn)
  "Sentinel of the `flymake-hadolint' process PROC for buffer SOURCE.

REPORT-FN is Flymake's callback function."
  (when (eq 'exit (process-status proc))
    (unwind-protect
        (if (with-current-buffer source (eq proc flymake-hadolint--proc))
            (with-current-buffer (process-buffer proc)
              (goto-char (point-min))
              (funcall report-fn (flymake-hadolint--collect-diagnostics source)))
          (flymake-log :warning "Canceling obsolete check %s" proc))
      (kill-buffer (process-buffer proc)))))

(defun flymake-hadolint--collect-diagnostics (source)
  "Collect diagnostics for buffer SOURCE from hadolint output in current buffer."
  (let (diags)
    (while (not (eobp))
      (cond
       ;; Dockerfile:1 DL3006 warning: Always tag the version of an image explicitly
       ((looking-at "^.+?:\\([0-9]+\\) \\([A-Z0-9]+\\) \\([a-z]+\\): \\(.*\\)$")
        (pcase-let ((`(,beg . ,end) (flymake-diag-region source (string-to-number (match-string 1)))))
          (push (flymake-make-diagnostic source beg end
                                         (pcase (match-string 3) ("error" :error) ("warning" :warning) ("info" :info))
                                         (concat (match-string 2 ) " " (match-string 4)))
                diags)))
       ;; Dockerfile:1:5 missing whitespace
       ((looking-at "^.+?:\\([0-9]+\\):\\([0-9]+\\) \\(.*\\)$")
        (pcase-let ((`(,beg . ,end) (flymake-diag-region source
                                                         (string-to-number (match-string 1))
                                                         (string-to-number (match-string 2)))))
          (push (flymake-make-diagnostic source beg end :error (match-string 3))
                diags))))
      (forward-line 1))
    diags))

;;;###autoload
(defun flymake-hadolint-setup ()
  "Setup Flymake to use `flymake-hadolint' buffer locally."
  (add-hook 'flymake-diagnostic-functions #'flymake-hadolint nil t))


(provide 'flymake-hadolint)
;;; flymake-hadolint.el ends here
