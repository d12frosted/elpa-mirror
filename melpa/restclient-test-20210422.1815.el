;;; restclient-test.el --- Run tests with restclient.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2021 Simen Heggestøyl

;; Author: Simen Heggestøyl <simenheg@runbox.com>
;; Created: 14 May 2016
;; Version: 0.3
;; Package-Version: 20210422.1815
;; Package-Commit: 3c6661d087526510a04ea9de421c5869a1a1d061
;; Package-Requires: ((emacs "26.1") (restclient "0"))
;; Homepage: https://github.com/simenheg/restclient-test.el

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; Turn your restclient.el documents into interactive test suites!

;; See README.org for more information.

;;; Code:

(require 'restclient)
(require 'subr-x)

(defun restclient-test--goto-entry (entry)
  "Move point to ENTRY and save it in the match data.
The whole entry is saved in the match data at index 0, while its
value is saved at index 1."
  (re-search-backward
   (concat "# " entry ":\\(.*\\)")
   (save-excursion (backward-sentence)) t))

(defun restclient-test--update-entry (entry value)
  "Update or create ENTRY with value VALUE."
  (let ((entry-header (concat "# " entry ":")))
    (save-excursion
      (when (restclient-test--goto-entry entry)
        (delete-region (point) (line-end-position))
        (backward-delete-char 1)))
    (insert entry-header " " value "\n")))

;;;###autoload
(defun restclient-test-current ()
  "Test query at point.
When the test contains an \"Expect\" entry, return `pass' if the
test passed and `fail' if the test failed.  Else return nil.'"
  (interactive)
  (save-window-excursion
    (save-excursion
      (goto-char (restclient-current-min))
      (if (not (looking-at-p restclient-method-url-regexp))
          (when (called-interactively-p 'interactive)
            (message "This doesn't look like a query"))
        (let ((buf (current-buffer)))
          (restclient-http-send-current t t)
          (while restclient-within-call
            (sit-for 0.05))
          (switch-to-buffer "*HTTP Response*")
          (let ((response (buffer-substring-no-properties
                           (point-min) (line-end-position))))
            (switch-to-buffer buf)
            (restclient-test--update-entry "Response" response)
            (let ((expect
                   (save-excursion
                     (restclient-test--goto-entry "Expect")
                     (match-string-no-properties 1))))
              (when expect
                (let ((passed
                       (string-match-p (string-trim expect) response)))
                  (restclient-test--update-entry
                   "Result" (if passed "Passed" "Failed"))
                  (if passed 'pass 'fail))))))))))

(defun restclient-test-flymake (report-fn &rest _args)
  (let ((diags '()))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward-regexp
              "^# Expect: \\(.*\\)\n# Response: \\(.*\\)\n# Result: Failed$"
              nil t)
        (push
         (flymake-make-diagnostic
          (current-buffer)
          (line-beginning-position)
          (line-end-position)
          :error
          (format-message "Expected: `%s', got: `%s'"
                          (match-string-no-properties 1)
                          (match-string-no-properties 2)))
         diags)))
    (funcall report-fn diags)))

(defun restclient-test-setup-flymake-backend ()
  (add-hook
   'flymake-diagnostic-functions #'restclient-test-flymake nil t))

;;;###autoload
(defun restclient-test-buffer ()
  "Test every query in the current buffer."
  (interactive)
  (let ((restclient-log-request nil)
        (num-pass 0)
        (num-fail 0))
    (save-excursion
      ;; Attempt to find the first query in the buffer
      (goto-char (point-min))
      (restclient-jump-next)
      (restclient-jump-prev)
      (while (let ((res (restclient-test-current)))
               (cond
                ((eq res 'pass) (setq num-pass (+ num-pass 1)))
                ((eq res 'fail) (setq num-fail (+ num-fail 1))))
               (goto-char (restclient-current-min))
               (let ((prev (point)))
                 (restclient-jump-next)
                 (goto-char (restclient-current-min))
                 (/= prev (point))))))
    (message "Test results: %d passed, %d failed" num-pass num-fail)))

(defun restclient-test-next-error (arg)
  "Jump to the first failed test found after point.
The numeric argument ARG decides how many failed tests to jump
forward, or backward with a negative argument."
  (declare (obsolete flymake-goto-next-error "0.3"))
  (interactive "p")
  (let ((orig-pos (point)))
    (if (< arg 0)
        (beginning-of-line)
      (end-of-line))
    (let ((found-failure (search-forward "Result: Failed" nil t arg)))
      (beginning-of-line)
      (unless found-failure
        (goto-char orig-pos)
        (message "No more failed tests %s point"
                 (if (< arg 0) "before" "after"))))))

(defun restclient-test-previous-error (arg)
  "Jump to the first failed test found before point."
  (declare (obsolete flymake-goto-prev-error "0.3"))
  (interactive "p")
  (restclient-test-next-error (* arg -1)))

;;;###autoload
(define-minor-mode restclient-test-mode
  "Minor mode with key-bindings for restclient-test commands.
With a prefix argument ARG, enable the mode if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil."
  :lighter " REST Test"
  :keymap `((,(kbd "C-c C-b") . restclient-test-buffer)
            (,(kbd "C-c C-t") . restclient-test-current))
  (restclient-test-setup-flymake-backend))

(provide 'restclient-test)
;;; restclient-test.el ends here
