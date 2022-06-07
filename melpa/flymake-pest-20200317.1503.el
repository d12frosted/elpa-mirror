;;; flymake-pest.el --- A flymake handler for Pest files  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020  ksqsf, Naoya Yamashita

;; Author: ksqsf <i@ksqsf.moe>
;;         Naoya Yamashita <conao3@gmail.com>
;; URL: https://github.com/ksqsf/pest-mode
;; Package-Version: 20200317.1503
;; Package-Commit: af677327f185113442e95b00986097b30cab650c
;; Keywords: languages flymake
;; Version: 0.1
;; Package-Requires: ((emacs "26.3") (pest-mode "0.1"))

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

;; A flymake handler for Pest files.

;; To use this pacakge, simply add below code your init.el

;;   (with-eval-after-load 'pest-mode
;;     (require 'flymake-pest)
;;     (add-hook 'pest-mode-hook #'flymake-pest-setup)
;;     (add-hook 'pest-input-mode-hook #'flymake-pest-input-setup))

;;; Code:

(require 'flymake)
(require 'pest-mode)

(defvar flymake-pest--diagnosis-regexp (rx bol
                                           "nil "
                                           "(" (group (+ (char digit))) "," (group (+ (char digit))) ") "
                                           (group (* nonl))
                                           eol))
(defvar pest--grammar-buffer)
(defvar-local flymake-pest--lang-flymake-proc nil)
(defvar-local flymake-pest--meta-flymake-proc nil)

(defun flymake-pest (report-fn &rest _args)
  "The `flymake-diagnostic-functions' backend for `pest-mode'.

REPORT-FN will be called whenever diagnoses are available."
  (unless pest-pesta-executable
    (error "Cannot find a suitable `pesta' executable"))
  (when (process-live-p flymake-pest--meta-flymake-proc)
    (kill-process flymake-pest--meta-flymake-proc))
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq flymake-pest--meta-flymake-proc
            (make-process
             :name "pest-meta-flymake"
             :noquery t
             :connection-type 'pipe
             :buffer (generate-new-buffer " *pest-meta-flymake*")
             :command `(,pest-pesta-executable "meta_check")
             :sentinel
             (lambda (proc _event)
               (when (eq 'exit (process-status proc))
                 (unwind-protect
                     (if (with-current-buffer source (eq proc flymake-pest--meta-flymake-proc))
                         (with-current-buffer (process-buffer proc)
                           (goto-char (point-min))
                           (cl-loop
                            while (search-forward-regexp flymake-pest--diagnosis-regexp
                                                         nil t)
                            for msg = (match-string 3)
                            for beg = (string-to-number (match-string 1))
                            for end = (string-to-number (match-string 2))
                            for type = :error
                            collect (flymake-make-diagnostic source
                                                             beg
                                                             end
                                                             type
                                                             msg)
                            into diags
                            finally (funcall report-fn diags)))
                       (flymake-log :warning "Canceling obsolete check %s"
                                    proc))
                   (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-pest--meta-flymake-proc (point-min) (point-max))
      (process-send-eof flymake-pest--meta-flymake-proc))))

(defun flymake-pest-input (report-fn &rest _args)
  "Check and give diagnostic messages about the input.

REPORT-FN will be called whenever diagnoses are available."
  (unless pest-pesta-executable
    (error "Cannot find a suitable `pesta' executable"))
  (when (process-live-p flymake-pest--lang-flymake-proc)
    (kill-process flymake-pest--lang-flymake-proc))
  (if (null pest--selected-rule)
      (message "You haven't selected a rule to start; do so with `pest-select-rule'.")
    (let ((source (current-buffer)))
      (save-restriction
        (widen)
        (setq flymake-pest--lang-flymake-proc
              (make-process
               :name "flymake-pest-input"
               :noquery t
               :connection-type 'pipe
               :buffer (generate-new-buffer " *pest-input-flymake*")
               :command `(,pest-pesta-executable "lang_check" ,pest--selected-rule)
               :sentinel
               (lambda (proc _event)
                 (when (eq 'exit (process-status proc))
                   (unwind-protect
                       (if (with-current-buffer source (eq proc flymake-pest--lang-flymake-proc))
                           (with-current-buffer (process-buffer proc)
                             (goto-char (point-min))
                             (cl-loop
                              while (search-forward-regexp flymake-pest--diagnosis-regexp
                                                           nil t)
                              for beg = (string-to-number (match-string 1))
                              for end = (string-to-number (match-string 2))
                              for msg = (match-string 3)
                              for type = :error
                              collect (flymake-make-diagnostic source
                                                               beg
                                                               end
                                                               type
                                                               msg)
                              into diags
                              finally (funcall report-fn diags)))
                         (flymake-log :warning "Canceling obsolete check %s"
                                      proc))
                     (kill-buffer (process-buffer proc)))))))
        (let* ((grammar (with-current-buffer pest--grammar-buffer
                          (save-restriction
                            (widen)
                            (buffer-string))))
               (input (buffer-string))
               (send-data (json-encode-list (list grammar input))))
          (process-send-string flymake-pest--lang-flymake-proc send-data)
          (process-send-eof flymake-pest--lang-flymake-proc))))))

;;;###autoload
(defun flymake-pest-setup ()
  "Setup flymake-pest."
  (add-hook 'flymake-diagnostic-functions #'flymake-pest nil t))

;;;###autoload
(defun flymake-pest-input-setup ()
  "Setup `pest-input-mode'."
  (add-hook 'flymake-diagnostic-functions #'flymake-pest-input nil t))

(provide 'flymake-pest)
;;; flymake-pest.el ends here
