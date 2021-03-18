;;; kaocha-runner.el --- A package for running Kaocha tests via CIDER. -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Magnar Sveen

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 0.3.0
;; Package-Version: 20190904.1950
;; Package-Commit: 755b0dfb3bd676c769c4b4aeb81c2cd5828bd207
;; Package-Requires: ((emacs "26") (s "1.4.0") (cider "0.21.0") (parseedn "0.1.0"))
;; URL: https://github.com/magnars/kaocha-runner.el

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

;; A minor-mode for running Kaocha tests with CIDER

;;; Code:

(require 'cider)
(require 'parseedn)
(require 's)

(defgroup kaocha-runner nil
  "Run Kaocha tests via CIDER."
  :group 'tools)

(defcustom kaocha-runner-repl-invocation-template
  "(do (require 'kaocha.repl) %s)"
  "The invocation sent to the REPL to run kaocha tests, with the actual run replaced by %s."
  :group 'kaocha-runner
  :type 'string)

(defcustom kaocha-runner-extra-configuration
  "{:kaocha/fail-fast? true}"
  "Extra configuration options passed to kaocha, a string containing an edn map."
  :group 'kaocha-runner
  :type 'string)

(defcustom kaocha-runner-long-running-seconds
  3
  "After a test run has taken this many seconds, pop up the output window to see what is going on."
  :group 'kaocha-runner
  :type 'integer
  :package-version '(kaocha-runner . "0.3.0"))

(defcustom kaocha-runner-ongoing-tests-win-min-height
  12
  "The minimum height in lines of the output window when tests are taking long to run.
This is to show the ongoing progress from kaocha."
  :group 'kaocha-runner
  :type 'integer
  :package-version '(kaocha-runner . "0.2.0"))

(defcustom kaocha-runner-failure-win-min-height
  4
  "The minimum height in lines of the output window when there are failing tests."
  :group 'kaocha-runner
  :type 'integer
  :package-version '(kaocha-runner . "0.2.0"))

(defcustom kaocha-runner-output-win-max-height
  16
  "The maximum height in lines of the output window."
  :group 'kaocha-runner
  :type 'integer
  :package-version '(kaocha-runner . "0.2.0"))

(defface kaocha-runner-success-face
  '((t (:foreground "green")))
  "Face used to highlight success messages."
  :group 'kaocha-runner)

(defface kaocha-runner-error-face
  '((t (:foreground "red")))
  "Face used to highlight error messages."
  :group 'kaocha-runner)

(defface kaocha-runner-warning-face
  '((t (:foreground "yellow")))
  "Face used to highlight warning messages."
  :group 'kaocha-runner)

(defun kaocha-runner--eval-clojure-code (code callback)
  "Send CODE to be evaled and run to CIDER, calling CALLBACK with updates."
  (cider-nrepl-request:eval
   code
   callback
   nil nil nil nil
   (cider-current-repl 'clj 'ensure)))

(defvar kaocha-runner--out-buffer "*kaocha-output*")
(defvar kaocha-runner--err-buffer "*kaocha-error*")

(defun kaocha-runner--clear-buffer (buffer)
  "Ensure that BUFFER exists and is empty."
  (get-buffer-create buffer)
  (with-current-buffer buffer
    (delete-region (point-min) (point-max))))

(defun kaocha-runner--colorize ()
  "Turn ANSI codes in the current buffer into Emacs colors."
  (save-excursion
    (goto-char (point-min))
    (insert "[m")
    (ansi-color-apply-on-region (point-min) (point-max))))

(defun kaocha-runner--insert (buffer s)
  "Insert S into BUFFER, then turn ANSI codes into color."
  (with-current-buffer buffer
    (insert s)
    (kaocha-runner--colorize)))

(defmacro kaocha-runner--with-window (buffer original-buffer &rest body)
  "Open a dedicated window showing BUFFER, perform BODY, then switch back to ORIGINAL-BUFFER."
  (declare (debug (form body))
           (indent 2))
  `(let ((window (get-buffer-window ,buffer)))
     (if window
         (select-window window)
       (let ((window (split-window-vertically -4)))
         (select-window window)
         (switch-to-buffer ,buffer)
         (set-window-dedicated-p window t)))
     ,@body
     (switch-to-buffer-other-window ,original-buffer)))

(defun kaocha-runner--fit-window-snuggly (min-height max-height)
  "Resize current window to fit its contents, within MIN-HEIGHT and MAX-HEIGHT."
  (window-resize nil (- (max min-height
                             (min max-height
                                  (- (line-number-at-pos (point-max))
                                     (line-number-at-pos (point)))))
                        (window-height))))

(defun kaocha-runner--recenter-top ()
  "Change the scroll position so that the cursor is at the top of the window."
  (recenter (min (max 0 scroll-margin)
                 (truncate (/ (window-body-height) 4.0)))))

(defun kaocha-runner--num-warnings ()
  "Count the number of warnings in the error buffer."
  (s-count-matches "WARNING:"
                   (with-current-buffer kaocha-runner--err-buffer
                     (buffer-substring-no-properties (point-min) (point-max)))))

(defun kaocha-runner--show-report (value testable-sym)
  "Show a message detailing the test run restult in VALUE, prefixed by TESTABLE-SYM"
  (when-let* ((result (parseedn-read-str (s-chop-prefix "#:kaocha.result" value))))
    (let* ((tests (gethash :count result))
           (pass (gethash :pass result))
           (fail (gethash :fail result))
           (err (gethash :error result))
           (warnings (kaocha-runner--num-warnings))
           (happy? (and (= 0 fail) (= 0 err)))
           (report (format "%s%s"
                           (if testable-sym
                               (concat "[" testable-sym "] ")
                             "")
                           (propertize (format "%s tests, %s assertions%s, %s failures."
                                               tests
                                               (+ pass fail err)
                                               (if (< 0 err)
                                                   (format ", %s errors" err)
                                                 "")
                                               fail)
                                       'face (if happy?
                                                 'kaocha-runner-success-face
                                               'kaocha-runner-error-face)))))
      (when (< 0 warnings)
        (let ((warnings-str (format "(%s warnings)" warnings)))
          (setq report (concat report (s-repeat (max 3 (- (frame-width) (length report) (length warnings-str))) " ")
                               (propertize warnings-str 'face 'kaocha-runner-warning-face)))))
      (message "%s" report))))

(defvar kaocha-runner--fail-re "\\(FAIL\\|ERROR\\)")

(defun kaocha-runner--show-details-window (original-buffer min-height)
  "Show details from the test run with a MIN-HEIGHT, but switch back to ORIGINAL-BUFFER afterwards."
  (kaocha-runner--with-window kaocha-runner--out-buffer original-buffer
    (visual-line-mode 1)
    (goto-char (point-min))
    (let ((case-fold-search nil))
      (re-search-forward kaocha-runner--fail-re nil t))
    (end-of-line)
    (kaocha-runner--fit-window-snuggly min-height kaocha-runner-output-win-max-height)
    (kaocha-runner--recenter-top)))

(defun kaocha-runner--testable-sym (ns test-name cljs?)
  (concat "'"
          (if cljs? "cljs:" "")
          ns
          (when test-name (concat "/" test-name))))

(defun kaocha-runner--hide-window (buffer-name)
  (when-let (buffer (get-buffer buffer-name))
    (when-let (window (get-buffer-window buffer))
      (delete-window window))))

(defun kaocha-runner--run-tests (testable-sym &optional run-all? background? original-buffer)
  "Run kaocha tests.

If RUN-ALL? is t, all tests are run, otherwise attempt a run with the provided
TESTABLEY-SYM. In practice TESTABLEY-SYM can be a test id, an ns or an ns/test-fn.

If BACKGROUND? is t, we don't message when the tests start running.

Given an ORIGINAL-BUFFER, use that instead of (current-buffer) when switching back."
  (interactive)
  (kaocha-runner--clear-buffer kaocha-runner--out-buffer)
  (kaocha-runner--clear-buffer kaocha-runner--err-buffer)
  (kaocha-runner--eval-clojure-code
   (format kaocha-runner-repl-invocation-template
           (if run-all?
               (format "(kaocha.repl/run-all %s)" kaocha-runner-extra-configuration)
             (format
              "(kaocha.repl/run %s %s)"
              testable-sym
              kaocha-runner-extra-configuration)))
   (let ((original-buffer (or original-buffer (current-buffer)))
         (done? nil)
         (any-errors? nil)
         (shown-details? nil)
         (the-value nil)
         (start-time (float-time)))
     (unless background?
       (if run-all?
           (message "Running all tests ...")
         (message "[%s] Running tests ..." testable-sym)))
     (lambda (response)
       (nrepl-dbind-response response (value out err status)
         (when out
           (kaocha-runner--insert kaocha-runner--out-buffer out)
           (when (let ((case-fold-search nil))
                   (string-match-p kaocha-runner--fail-re out))
             (setq any-errors? t))
           (when (and (< kaocha-runner-long-running-seconds
                         (- (float-time) start-time))
                      (not shown-details?))
             (setq shown-details? t)
             (kaocha-runner--show-details-window original-buffer kaocha-runner-ongoing-tests-win-min-height)))
         (when err
           (kaocha-runner--insert kaocha-runner--err-buffer err))
         (when value
           (setq the-value value))
         (when (and status (member "done" status))
           (setq done? t))
         (when done?
           (if the-value
               (kaocha-runner--show-report the-value (unless run-all? testable-sym))
             (unless (get-buffer-window kaocha-runner--err-buffer 'visible)
               (message "Kaocha run failed. See error window for details.")
               (switch-to-buffer-other-window kaocha-runner--err-buffer))))
         (when done?
           (if any-errors?
               (kaocha-runner--show-details-window original-buffer kaocha-runner-failure-win-min-height)
             (kaocha-runner--hide-window kaocha-runner--out-buffer))))))))

;;;###autoload
(defun kaocha-runner-hide-windows ()
  "Hide all windows that kaocha has opened."
  (interactive)
  (kaocha-runner--hide-window kaocha-runner--out-buffer)
  (kaocha-runner--hide-window kaocha-runner--err-buffer))

;;;###autoload
(defun kaocha-runner-run-tests (&optional test-id?)
  "Run tests in the current namespace.
If prefix argument TEST-ID? is present ask user for a test-id to run."
  (interactive "P")
  (kaocha-runner-hide-windows)
  (let ((test-id (when test-id? (read-from-minibuffer "test id: "))))
    (kaocha-runner--run-tests
     (if test-id
         test-id
       (kaocha-runner--testable-sym (cider-current-ns) nil (eq major-mode 'clojurescript-mode))))))

;;;###autoload
(defun kaocha-runner-run-test-at-point ()
  "Run the test at point in the current namespace."
  (interactive)
  (kaocha-runner-hide-windows)
  (kaocha-runner--run-tests
   (kaocha-runner--testable-sym (cider-current-ns) (cadr (clojure-find-def)) (eq major-mode 'clojurescript-mode))))

;;;###autoload
(defun kaocha-runner-run-all-tests ()
  "Run all tests."
  (interactive)
  (kaocha-runner-hide-windows)
  (kaocha-runner--run-tests nil t))

;;;###autoload
(defun kaocha-runner-show-warnings (&optional switch-to-buffer?)
  "Display warnings from the last kaocha test run.
Prefix argument SWITCH-TO-BUFFER? opens a separate window."
  (interactive "P")
  (if switch-to-buffer?
      (switch-to-buffer-other-window kaocha-runner--err-buffer)
    (message "%s"
             (s-trim
              (with-current-buffer kaocha-runner--err-buffer
                (buffer-substring (point-min) (point-max)))))))

(provide 'kaocha-runner)
;;; kaocha-runner.el ends here
