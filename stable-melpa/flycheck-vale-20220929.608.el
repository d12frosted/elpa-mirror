;;; flycheck-vale.el --- flycheck integration for vale -*- lexical-binding: t -*-
;; Copyright (c) 2017 Austin Bingham
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version: 0.1
;; Package-Version: 20220929.608
;; Package-Commit: 7c7ebc3de058a321cb76348a01f45f02dc55d2f0
;; URL: https://github.com/abingham/flycheck-vale
;; Package-Requires: ((emacs "24.4") (flycheck "0.22") (let-alist "1.0.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Description:
;;
;; This provides flycheck integration for vale. It allows flycheck to
;; use vale to provide natural language linting.
;;
;; Basic usage:
;;
;;  (require 'flycheck-vale)
;;  (flycheck-vale-setup)
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
;;; Code:

(require 'cl-lib)
(require 'flycheck)
(require 'let-alist)

(defgroup flycheck-vale nil
  "Variables related to flycheck-vale."
  :prefix "flycheck-vale-"
  :group 'tools)

(defcustom flycheck-vale-program "vale"
  "The vale executable to use."
  :type '(string)
  :group 'flycheck-vale)

(defconst flycheck-vale-modes '(text-mode markdown-mode rst-mode org-mode))

(defcustom flycheck-vale-output-buffer "*flycheck-vale*"
  "Buffer where tool output gets written."
  :type '(string)
  :group 'flycheck-vale)

(defvar-local flycheck-vale-enabled t
  "Buffer-local variable determining if flycheck-vale should be applied.")

(defconst flycheck-vale--level-map
  '(("error" . error)
    ("warning" . warning)
    ("suggestion" . info)))

(defun flycheck-vale--issue-to-error (issue)
  "Parse a single vale issue, ISSUE, into a flycheck error struct.

We only fill in what we can get from the vale issue directly. The
rest (e.g. filename) gets filled in elsewhere."
  (let-alist issue
    (flycheck-error-new
     :line .Line
     :column (elt .Span 0)
     :message .Message
     :id .Check
     :level (assoc-default .Severity flycheck-vale--level-map 'string-equal 'error))))

(defun flycheck-vale--output-to-errors (output)
  "Parse the full JSON output of vale, OUTPUT, into a sequence of flycheck error structs."
  (let* ((full-results (json-read-from-string output))

         ;; Get the list of issues for each file.
         (result-vecs (mapcar 'cdr full-results))

         ;; Chain all of the issues together. The point here, really, is that we
         ;; don't expect results from more than one file, but we should be
         ;; prepared for the theoretical possibility that the issues are somehow
         ;; split across multiple files. This is basically a punt in lieu of
         ;; more information.
         (issues (apply 'append (mapcar 'cdr full-results))))
    (mapcar 'flycheck-vale--issue-to-error issues)))

(defun flycheck-vale--handle-finished (checker callback buf)
  "Parse the contents of the output buffer into flycheck error
structures, attaching CHECKER and BUF to the structures, and
passing the results to CALLBACK."
  (let* ((output (with-current-buffer flycheck-vale-output-buffer (buffer-string)))
         (errors (flycheck-vale--output-to-errors output)))
    ;; Fill in the rest of the error struct database
    (cl-loop for err in errors do
          (setf
           (flycheck-error-buffer err) buf
           (flycheck-error-filename err) (buffer-file-name buf)
           (flycheck-error-checker err) checker))
    (funcall callback 'finished errors)))

(defun flycheck-vale--normal-completion? (event)
  (or  (string-equal event "finished\n")
       (string-match "exited abnormally with code 1.*" event)))

(defun flycheck-vale--start (checker callback)
  "Run vale on the current buffer's contents with CHECKER, passing the results to CALLBACK."

  ;; Clear the output buffer
  (with-current-buffer (get-buffer-create flycheck-vale-output-buffer)
    (read-only-mode 0)
    (erase-buffer))

  (let* ((process-connection-type nil)
         (proc (start-process "flycheck-vale-process"
                              flycheck-vale-output-buffer
                              flycheck-vale-program
                              "--output"
                              "JSON"
                              buffer-file-name)))
    (let ((checker checker)
          (callback callback)
          (buf (current-buffer)))
      (set-process-sentinel
       proc
       #'(lambda (process event)
           (when (flycheck-vale--normal-completion? event)
             (flycheck-vale--handle-finished checker callback buf)))))

    (process-send-region proc (point-min) (point-max))
    (process-send-eof proc)))

;;;###autoload
(defun flycheck-vale-setup ()
  "Convenience function to setup the vale flycheck checker.

This adds the vale checker to the list of flycheck checkers."
  (add-to-list 'flycheck-checkers 'vale))

;;;###autoload
(defun flycheck-vale-toggle-enabled ()
  "Toggle `flycheck-vale-enabled'."
  (interactive)
  (setq flycheck-vale-enabled (not flycheck-vale-enabled)))

(flycheck-define-generic-checker 'vale
  "A flycheck checker using vale natural language linting."
  :start #'flycheck-vale--start
  :predicate (lambda () flycheck-vale-enabled)
  :modes flycheck-vale-modes)

(provide 'flycheck-vale)

;;; flycheck-vale.el ends here
