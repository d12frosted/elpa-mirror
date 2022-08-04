;;; flymake-go-staticcheck.el --- Go staticcheck linter for flymake  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Sergey Kostyaev

;; Author: Sergey Kostyaev <feo.me@ya.ru>
;; Version: 0.1.0
;; Package-Version: 20220803.1929
;; Package-Commit: d29b158acc2c131cdbb5c62f54cb0fc024339575
;; Keywords: languages, tools
;;
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

;;; URL: https://github.com/s-kostyaev/flymake-go-staticcheck

;;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; A Flymake backend for Go using staticcheck.

;;; Code:

(defgroup flymake-go-staticcheck nil
  "Flymake backend for Go using staticcheck"
  :group 'programming
  :prefix "flymake-go-staticcheck-")

(defcustom flymake-go-staticcheck-executable "staticcheck"
  "Name or path to executable for staticcheck linter."
  :type 'string
  :group 'flymake-go-staticcheck)

(defcustom flymake-go-staticcheck-executable-args nil
  "Extra arguments to pass to staticcheck."
  :type '(choice
          string
          (repeat string))
  :group 'flymake-go-staticcheck)

(defvar flymake-go-staticcheck--message-regex "^\\([^:]*\\):\\([0-9]+\\):\\([0-9]*\\):[[:space:]]*\\(.*\\)"
  "Internal variable.
Regular expression definition to match staticcheck messages.")

(defvar-local flymake-go-staticcheck--process nil
  "Internal variable.
Handle to the linter process for the current buffer.")

(defun flymake-go-staticcheck--ensure-binary-exists ()
  "Internal function.
Throw an error and tell REPORT-FN to disable itself if `flymake-go-staticcheck-executable' can't be found."
  (unless (executable-find flymake-go-staticcheck-executable)
    (error "Can't find '%s' in exec-path - try M-x customize-variable flymake-go-staticcheck-executable maybe?"
           flymake-go-staticcheck-executable)))

(defun flymake-go-staticcheck--report (checker-output-buf source-buf)
  "Generate report from CHECKER-OUTPUT-BUF to be reported against SOURCE-BUF.
Return a list of results."
  (with-current-buffer checker-output-buf
    (goto-char (point-min))
    (let (results)
      (while (not (eobp))
        (when (looking-at flymake-go-staticcheck--message-regex)
          (let* ((filename (match-string 1))
                 (lineno (string-to-number (match-string 2)))
                 (column (string-to-number (match-string 3)))
                 (msg (match-string 4))
                 (src-pos (flymake-diag-region source-buf lineno column)))
            (if (string= (buffer-file-name source-buf)
                         (expand-file-name filename))
                (push (flymake-make-diagnostic source-buf
                                               (car src-pos)
                                               (min (buffer-size source-buf) (cdr src-pos))
                                               :error
                                               msg)
                      results))))
        (forward-line 1))
      results)))

(defun flymake-go-staticcheck--create-process (source-buffer callback)
  "Internal function.
Create linter process for SOURCE-BUFFER which invokes CALLBACK
once linter is finished.  CALLBACK is passed one argument, which
is a buffer containing stdout from linter."
  (when (process-live-p flymake-go-staticcheck--process)
    (kill-process flymake-go-staticcheck--process))
  (let ((args (pcase flymake-go-staticcheck-executable-args
                ("" nil)
                ((and (pred listp) x) x)
                (x (list x)))))
    (setq flymake-go-staticcheck--process
          (make-process
           :name "flymake-go-staticcheck"
           :connection-type 'pipe
           :noquery t
           :buffer (generate-new-buffer " *flymake-go-staticcheck*")
           :command `(,flymake-go-staticcheck-executable
                      ,@args
                      ,(buffer-file-name source-buffer))
           :sentinel (lambda (proc &rest ignored)
                       (when (and (eq 'exit (process-status proc))
                                  (with-current-buffer source-buffer (eq proc flymake-go-staticcheck--process)))
                         (let ((proc-buffer (process-buffer proc)))
                           (funcall callback proc-buffer)
                           (kill-buffer proc-buffer))))))))

(defun flymake-go-staticcheck--check-and-report (source-buffer flymake-report-fn)
  "Internal function.
Run go-staticcheck against SOURCE-BUFFER and use FLYMAKE-REPORT-FN to report results."
  (flymake-go-staticcheck--create-process
   source-buffer
   (lambda (go-staticcheck-stdout)
     (funcall flymake-report-fn (flymake-go-staticcheck--report go-staticcheck-stdout source-buffer)
              ;; If the buffer hasn't changed since last
              ;; call to the report function, flymake won't
              ;; delete old diagnostics.  Using :region
              ;; keyword forces flymake to delete
              ;; them (github#159).
              ;;
              ;; thanks to eglot for workaround.
              :region (with-current-buffer source-buffer (cons (point-min) (point-max)))))))

;;;###autoload
(defun flymake-go-staticcheck-checker (flymake-report-fn &rest ignored)
  "Run go-staticcheck on the current buffer.
Report results using FLYMAKE-REPORT-FN.  All other parameters are currently IGNORED."
  (flymake-go-staticcheck--check-and-report (current-buffer) flymake-report-fn))

;;;###autoload
(defun flymake-go-staticcheck-enable ()
  "Add flymake-go-staticcheck as a buffer-local Flymake backend."
  (interactive)
  (flymake-go-staticcheck--ensure-binary-exists)
  (add-hook 'flymake-diagnostic-functions #'flymake-go-staticcheck-checker nil t))

;;;###autoload
(defun flymake-go-staticcheck-disable ()
  "Remove flymake-go-staticcheck from Flymake backends."
  (interactive)
  (remove-hook 'flymake-diagnostic-functions #'flymake-go-staticcheck-checker t))

(provide 'flymake-go-staticcheck)
;;; flymake-go-staticcheck.el ends here
