;;; flymake-ktlint.el --- Flymake extension for Ktlint. -*- lexical-binding: t -*-

;; Copyright (C) 2018 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flymake-ktlint
;; Package-Version: 20180831.346
;; Package-Commit: bea8bf350802c06756efd4e6dfba65f31dc41d78
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages ktlint

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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
;; Flymake extension for Ktlint.
;;
;; (with-eval-after-load 'flymake
;;   (flymake-ktlint-setup))

;;; Code:

(require 'flymake)
(require 'cl-lib)
(eval-when-compile (require 'subr-x))

;;; Flymake

(defcustom flymake-ktlint-executable "ktlint"
  "Executable for ktlint."
  :type 'string
  :group 'flymake-ktlint)

(defcustom flymake-ktlint-args nil
  "Args to pass to ktlint."
  :type 'list
  :group 'flymake-ktlint)

(defvar-local flymake-ktlint--lint-process nil
  "Buffer-local process started for linting the buffer.")

;;;###autoload
(defun flymake-ktlint-setup ()
  "Set up Flymake for Ktlint."
  (interactive)
  (add-hook 'kotlin-mode-hook #'flymake-ktlint-add-hook))

;;;###autoload
(defun flymake-ktlint-add-hook ()
  "Add `flymake-ktlint-lint' to `flymake-diagnostic-functions'."
  (add-hook 'flymake-diagnostic-functions 'flymake-ktlint-lint nil t))

(defun flymake-ktlint-lint (report-fn &rest _args)
  "A Flymake backend for ktlint check.

REPORT-FN will be called when ktlint process finishes."
  (when (and flymake-ktlint--lint-process
             (process-live-p flymake-ktlint--lint-process))
    (kill-process flymake-ktlint--lint-process))
  (let ((source-buffer (current-buffer))
        (output-buffer (generate-new-buffer " *flymake-ktlint-lint*")))
    (setq flymake-ktlint--lint-process
          (make-process
           :name "flymake-ktlint-lint"
           :buffer output-buffer
           :command `(,flymake-ktlint-executable
                      ,@flymake-ktlint-args
                      ,buffer-file-name)
           :connection-type 'pipe
           :sentinel
           (lambda (proc _event)
             (when (eq (process-status proc) 'exit)
               (unwind-protect
                   (cond
                    ((not (and (buffer-live-p source-buffer)
                               (eq proc (with-current-buffer source-buffer
                                          flymake-ktlint--lint-process))))
                     (flymake-log :warning
                                  "byte-compile process %s obsolete" proc))
                    ((zerop (process-exit-status proc))
                     ;; No ktlint errors/warnings..
                     (funcall report-fn nil))
                    ((= 1 (process-exit-status proc))
                     (flymake-ktlint--lint-done report-fn
                                                source-buffer
                                                output-buffer))
                    (:error
                     (funcall report-fn
                              :panic
                              :explanation
                              (format "ktlint process %s errored." proc))))
                 (kill-buffer output-buffer))))))))

;; Helpers
(defun flymake-ktlint--lint-done (report-fn
                                  source-buffer
                                  output-buffer)
  "Process ktlint result and call REPORT-FN.

SOURCE-BUFFER is the buffer to apply flymake to.
OUTPUT-BUFFER is the result of running ktlint on SOURCE-BUFFER."
  (with-current-buffer
      source-buffer
    (save-excursion
      (save-restriction
        (widen)
        (funcall
         report-fn
         (with-current-buffer output-buffer
           (mapcar (lambda (line)
                     ;; ex: /Users/user/kotlin/File.kt:32:30: Unnecessary space(s)
                     (let* ((split (split-string line ":" t))
                            (_ (nth 0 split)) ; filename
                            (line (string-to-number (nth 1 split)))
                            (column (string-to-number (nth 2 split)))
                            (message (string-trim (nth 3 split)))
                            (point (flymake-ktlint--find-point source-buffer line column)))
                       (flymake-make-diagnostic
                        source-buffer
                        (1- point)
                        point
                        :warning
                        message)))
                   (split-string (buffer-string) "\n" t))))))))

(defun flymake-ktlint--find-point (source-buffer line column)
  "Return point given LINE and COLUMN in SOURCE-BUFFER."
  (with-current-buffer source-buffer
    (save-excursion
      (goto-char (point-min))
      (forward-line (1- line))
      (move-to-column column)
      (point))))

(provide 'flymake-ktlint)
;;; flymake-ktlint.el ends here
