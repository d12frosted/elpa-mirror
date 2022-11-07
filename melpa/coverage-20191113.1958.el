;;; coverage.el --- Code coverage line highlighting

;; Copyright (C) 2016 Powershop NZ Ltd.

;; Author: Kieran Trezona-le Comte <trezona.lecomte@gmail.com>
;; Version: 0.5
;; Package-Version: 20191113.1958
;; Package-Commit: 6e3c6f2dcb759a76086adeeb1fdfe83e4f082482
;; Package-Requires: ((ov "1.0") (cl-lib "0.5"))
;; Created: 2016-01-21
;; Keywords: coverage metrics simplecov ruby rspec
;; URL: https://github.com/trezona-lecomte/coverage

;; This file is NOT part of GNU Emacs.

;;; License:

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;; This package provides a minor mode to highlight code coverage in
;; source code files.
;;
;; At present it only knows how to parse coverage data in the format
;; provided by the Simplecov gem.
;;
;; Coverage highlighting will be automatically updated whenever the
;; coverage results change after running specs.  You can individually
;; toggle Coverage on/off in as many buffers as you like.

;;; Code:

(require 'json)
(require 'ov)
(require 'cl-lib)
(require 'timer)
(autoload 'vc-git-root "vc-git")

(defgroup coverage nil
  "Code coverage line highlighting."
  :group 'programming)

(defvar coverage-resultset-filename ".resultset.json")

(defvar coverage-timer nil
  "Timer used by Coverage.")

(defcustom coverage-interval 1
  "Time, in seconds, between Coverage result file checks.
The value may be an integer or floating point number.

If a timer is already active, there are two ways to make sure
that the new value will take effect immediately.  You can set
this variable through Custom or you can call the command
`coverage-set-timer' after setting the variable.  Otherwise,
the new value will take effect the first time Coverage
calls `coverage-set-timer' for internal reasons or in your
next editing session."
  :group 'coverage
  :type 'number
  :set (lambda (variable value)
         (set-default variable value)
         (and (boundp 'coverage-timer)
              coverage-timer
              (coverage-set-timer))))

(defvar coverage-buffer-list ()
  "List of buffers with `coverage-mode' enabled.")

(defcustom coverage-dir nil
  "The coverage directory for `coverage'.

For example: \"~/dir/to/my/project/coverage/\".

If set, look in this directory for a .resultset.json file to
obtain coverage results.

If nil, look for a /coverage directory immediately under the Git
root directory."
  :type '(choice (const :tag "Default (vc-git-root/coverage)" nil)
                 (string :tag "Path to coverage diretory"))
  :group 'coverage)

(defcustom coverage-highlight-eol nil
  "When t, highlight the rest of the line (past its end) too."
  :type 'boolean
  :group 'coverage)

(defun coverage--line-end-position ()
  "Return point for the end of the overlay according to `coverage-highlight-eol'."
  (+ (line-end-position) (if coverage-highlight-eol 1 0)))

(defun coverage-clear-highlighting-for-current-buffer ()
  "Clear all coverage highlighting for the current buffer."
  (when coverage-timer
    (cancel-timer coverage-timer))
  (ov-clear 'coverage 'any))

(defun coverage-draw-highlighting-for-current-buffer ()
  "Draw line highlighting for the current buffer."
  (save-excursion
    (goto-char (point-min))
    (dolist (element (coverage-get-results-for-current-buffer))
      (ov-clear 'coverage 'any (line-beginning-position) (coverage--line-end-position))
      (cond ((null element)
             t)
            ((= element 0)
             (ov (line-beginning-position) (coverage--line-end-position) 'coverage t 'face 'coverage-uncovered-face))
            ((> element 0)
             (ov (line-beginning-position) (coverage--line-end-position) 'coverage t 'face 'coverage-covered-face)))
      (forward-line))))

(defun coverage-result-path-for-file (filename)
  "Return the fully-qualified filepath of the resultset for FILENAME."
  (concat (coverage-dir-for-file filename) coverage-resultset-filename))

(defun coverage-dir-for-file (filename)
  "Guess the coverage directory of the given FILENAME.

Use `coverage-dir' if set, or fall back to /coverage under Git
root."
  (or coverage-dir
      (concat (vc-git-root filename) "coverage/")))

(defun coverage-get-json-from-file (filepath)
  "Return alist of the json resultset at FILEPATH."
  (json-read-from-string (with-temp-buffer
                           (insert-file-contents filepath)
                           (buffer-string))))

(defun coverage-get-results-for-file (target-path result-path)
  "Return coverage for the file at TARGET-PATH from RESULT-PATH."
  (cl-coerce (cdr
              (car
               (cl-remove-if-not 'identity
                                 (mapcar (lambda (l)
                                           (assoc-string target-path
                                                         (assoc 'coverage l)))
                                         (coverage-get-json-from-file result-path)))))
             'list))

(defun coverage-get-results-for-current-buffer ()
  "Return a list of coverage results for the current buffer."
  (coverage-get-results-for-file (buffer-file-name)
                                 (coverage-result-path-for-file buffer-file-name)))

(defun coverage-get-timestamp-for-results (filepath)
  "Return the time that results at FILEPATH were last updated."
  (with-temp-buffer
    (insert-file-contents filepath)
    (goto-char (point-max))
    (re-search-backward "\"timestamp\": *[0-9]+")
    (re-search-forward ": *")
    (current-word)))

(defun coverage-get-timestamp-for-current-buffer ()
  "Return result timestamp for the current buffer."
  (coverage-get-timestamp-for-results
   (coverage-result-path-for-file buffer-file-name)))

(defun coverage-set-timer ()
  "Restart or cancel the timer used by Coverage.

If the timer is active, cancel it.  Start a new timer if Coverage
is enable in any buffers.  Restarting the timer ensures that
Coverage will use an up-to-date value of `coverage-interval'"
  (if (timerp coverage-timer)
      (cancel-timer coverage-timer))
  (setq coverage-timer
        (run-with-timer coverage-interval
                        coverage-interval
                        'coverage-redraw-buffers)))

;;; Mode definition

;;;###autoload
(define-minor-mode coverage-mode
  "Toggle Coverage mode for the current buffer."
  :lighter " COV"
  (when coverage-mode
    (let ((timestamp-and-buffer (cons (coverage-get-timestamp-for-current-buffer)
                                      (current-buffer))))
      (add-to-list 'coverage-buffer-list timestamp-and-buffer)
      (coverage-set-timer)))
  (when (null coverage-buffer-list)
    (cancel-timer coverage-timer))
  (coverage-redraw-buffers))

(defun coverage-redraw-buffers ()
  "Redraw highlighting in all buffers with Coverage enabled.

Use the `coverage-redraw-current-buffer' function for each
enabled buffer to make sure we don't redraw buffers unless the
timestamp in their results has changed.

If Coverage is no longer enabled in any of the buffers, remove
that buffer from `coverage-buffer-list'."
  (let ((existing-buffers coverage-buffer-list)
        enabled-buffers)
    (dolist (timestamp-and-buffer existing-buffers)
      (let ((buffer (cdr timestamp-and-buffer))
            (existing-timestamp (car timestamp-and-buffer)))
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (if coverage-mode
                (let ((new-timestamp (coverage-get-timestamp-for-current-buffer)))
                  (progn
                    (coverage-redraw-current-buffer new-timestamp existing-timestamp)
                    (push (cons new-timestamp buffer) enabled-buffers)))
              (coverage-clear-highlighting-for-current-buffer))))))
    (setq coverage-buffer-list enabled-buffers)))

(defun coverage-redraw-current-buffer (new-timestamp existing-timestamp)
  "Redraw current buffer unless NEW-TIMESTAMP equals EXISTING-TIMESTAMP."
  (unless (eq new-timestamp existing-timestamp)
    (coverage-draw-highlighting-for-current-buffer)))

;;; Faces

(defface coverage-covered-face
  '((((class color) (background light))
     :background "#ddffdd")
    (((class color) (background dark))
     :background "#335533"))
  "Face for covered lines of code."
  :group 'coverage)

(defface coverage-uncovered-face
  '((((class color) (background light))
     :background "#ffdddd")
    (((class color) (background dark))
     :background "#553333"))
  "Face for uncovered lines of code."
  :group 'coverage)

(provide 'coverage)

;;; coverage.el ends here
