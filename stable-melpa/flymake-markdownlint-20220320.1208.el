;;; flymake-markdownlint.el --- Markdown linter with markdownlint  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Martin Kjær Jørgensen (shaohme) <mkj@gotu.dk>
;;
;; Author: Martin Kjær Jørgensen <mkj@gotu.dk>
;; Created: 15 December 2021
;; Version: 0.1.3
;; Package-Version: 20220320.1208
;; Package-Commit: 59e3520668d9394c573e07b7980a2d48d9f6086c
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/shaohme/flymake-markdownlint
;;; Commentary:

;; This package adds Markdown syntax checking using
;; 'markdownlint-cli'.  Make sure 'markdownlint' binary is on your
;; path, or configure the program name to something else.

;; Installation instructions
;; https://github.com/igorshubovych/markdownlint-cli

;; SPDX-License-Identifier: GPL-3.0-or-later

;; flymake-markdownlint is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; flymake-markdownlint is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with flymake-markdownlint.  If not, see http://www.gnu.org/licenses.

;;; Code:

(require 'flymake)

(defgroup flymake-markdownlint nil
  "Markdownlint backend for Flymake."
  :prefix "flymake-markdownlint-"
  :group 'tools)

(defcustom flymake-markdownlint-program
  "markdownlint"
  "Name of to the `markdownlint' compatible executable."
  :type 'string)

(defvar-local flymake-markdownlint--proc nil)

(defun flymake-markdownlint (report-fn &rest _args)
  "Flymake backend for markdownlint report using REPORT-FN."
  (if (not flymake-markdownlint-program)
      (error "No markdown linter program name set"))
  (let ((flymake-markdownlint--executable-path (executable-find flymake-markdownlint-program)))
    (if (or (null flymake-markdownlint--executable-path)
            (not (file-executable-p flymake-markdownlint--executable-path)))
        (error "Could not find '%s' executable" flymake-markdownlint-program))
    (when (process-live-p flymake-markdownlint--proc)
      (kill-process flymake-markdownlint--proc)
      (setq flymake-markdownlint--proc nil))
    (let ((source (current-buffer)))
      (save-restriction
        (widen)
        (setq
         flymake-markdownlint--proc
         ;; markdownlint usually outputs JSON to stderr. read from
         ;; both just in case they change that behavior.
         (make-process
          :name "flymake-markdownlint" :noquery t :connection-type 'pipe
          :stderr nil
          :buffer (generate-new-buffer " *flymake-markdownlint*")
          :command (list flymake-markdownlint--executable-path "-s" "-j")
          :sentinel
          (lambda (proc _event)
            (when (eq 'exit (process-status proc))
              (unwind-protect
                  (if (with-current-buffer source (eq proc flymake-markdownlint--proc))
                      (with-current-buffer (process-buffer proc)
                        (goto-char (point-min))
                        (let ((diags)
                              (map-vec (condition-case nil (json-parse-buffer) (error nil))))
                          (when map-vec
                            (if (not (vectorp map-vec))
                                (error "JSON-parser-buffer returned unexpected type.  got %s" (type-of map-vec)))
                            (let ((len (length map-vec))
                                  (i 0))
                              (while (< i len)
                                (let* ((map (aref map-vec i))
                                       (line-number (gethash "lineNumber" map))
                                       (rule-names (gethash "ruleNames" map))
                                       (rule-desc (gethash "ruleDescription" map))
                                       (error-range (gethash "errorRange" map)) ; returns vector
                                       (error-type (if (eq error-range :null) :warning :error))
                                       ;; expect first element of
                                       ;; error-range to be start
                                       ;; column, and second element
                                       ;; to be length of error (not
                                       ;; end column index)
                                       (region (flymake-diag-region source line-number (if (eq error-range :null) nil (elt error-range 0)))))
                                  ;; expect `region' to only have 2 values (start . end).
                                  ;; expect `rule-names' first element to be MDxxx code
                                  (push (flymake-make-diagnostic source
                                                                 (car region)
                                                                 (cdr region)
                                                                 error-type
                                                                 (format "%s: %s" (aref rule-names 0) rule-desc)) diags)
                                  (setq i (+ i 1))))))
                          (funcall report-fn (reverse diags))))
                    (flymake-log :warning "Canceling obsolete check %s"
                                 proc))
                (kill-buffer (process-buffer proc)))))))
        (process-send-region flymake-markdownlint--proc (point-min) (point-max))
        (process-send-eof flymake-markdownlint--proc)))))

;;;###autoload
(defun flymake-markdownlint-setup ()
  "Enable markdownlint flymake backend."
  (add-hook 'flymake-diagnostic-functions #'flymake-markdownlint nil t))

(provide 'flymake-markdownlint)
;;; flymake-markdownlint.el ends here
