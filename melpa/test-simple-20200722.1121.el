;;; test-simple.el --- Simple Unit Test Framework for Emacs Lisp -*- lexical-binding: t -*-
;; Rewritten from Phil Hagelberg's behave.el by rocky

;; Copyright (C) 2015, 2016, 2017, 2020 Free Software Foundation, Inc

;; Author: Rocky Bernstein <rocky@gnu.org>
;; URL: https://github.com/rocky/emacs-test-simple
;; Package-Version: 20200722.1121
;; Package-Commit: ce6de04636e8d19ec84a475c03c0142b20a63de0
;; Keywords: unit-test
;; Package-Requires: ((cl-lib "0"))
;; Version: 1.3.0

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; test-simple.el is:
;;
;; * Simple.  No need for
;;   - context macros,
;;   - enclosing specifications,
;;   - required test tags.
;;
;;   But if you want, you still can enclose tests in a local scope,
;;   add customized assert failure messages, or add summary messages
;;   before a group of tests.
;;
;; * Accommodates both interactive and non-interactive use.
;;    - For interactive use, one can use `eval-last-sexp', `eval-region',
;;      and `eval-buffer'.  One can `edebug' the code.
;;    -  For non-interactive use, run:
;;        emacs --batch --no-site-file --no-splash --load <test-lisp-code.el>
;;
;; Here is an example using gcd.el found in the examples directory.
;;
;;   (require 'test-simple)
;;   (test-simple-start) ;; Zero counters and start the stop watch.
;;
;;   ;; Use (load-file) below because we want to always to read the source.
;;   ;; Also, we don't want no stinking compiled source.
;;   (assert-t (load-file "./gcd.el")
;; 	      "Can't load gcd.el - are you in the right directory?" )
;;
;;   (note "degenerate cases")
;;
;;   (assert-nil (gcd 5 -1) "using positive numbers")
;;   (assert-nil (gcd -4 1) "using positive numbers, switched order")
;;   (assert-raises error (gcd "a" 32)
;;                  "Passing a string value should raise an error")
;;
;;   (note "GCD computations")
;;   (assert-equal 1 (gcd 3 5) "gcd(3,5)")
;;   (assert-equal 8 (gcd 8 32) "gcd(8,32)")
;;   (end-tests) ;; Stop the clock and print a summary
;;
;; Edit (with Emacs of course) gcd-tests.el and run M-x eval-current-buffer
;;
;; You should see in buffer *test-simple*:
;;
;;    gcd-tests.el
;;    ......
;;    0 failures in 6 assertions (0.002646 seconds)
;;
;; Now let us try from a command line:
;;
;;    $ emacs --batch --no-site-file --no-splash --load gcd-tests.el
;;    Loading /src/external-vcs/emacs-test-simple/example/gcd.el (source)...
;;    *scratch*
;;    ......
;;    0 failures in 6 assertions (0.000723 seconds)

;;; To do:

;; FIXME: Namespace is all messed up!
;; Main issues: more expect predicates

(require 'time-date)

;;; Code:

(require 'cl-lib)

(defgroup test-simple nil
  "Simple Unit Test Framework for Emacs Lisp"
  :group 'lisp)

(defcustom test-simple-runner-interface (if (fboundp 'bpr-spawn)
                                            'bpr-spawn
                                          'compile)
  "Function with one string argument when running tests non-interactively.
Command line started with `emacs --batch' is passed as the argument.

`bpr-spawn', which is in bpr package, is preferable because of no window popup.
If bpr is not installed, fall back to `compile'."
  :type 'function
  :group 'test-simple)

(defcustom test-simple-runner-key "C-x C-z"
  "Key to run non-interactive test after defining command line by `test-simple-run'."
  :type 'string
  :group 'test-simple)

(defvar test-simple-debug-on-error nil
  "If non-nil raise an error on the first failure.")

(defvar test-simple-verbosity 0
  "The greater the number the more verbose output.")

(cl-defstruct test-info
  description                 ;; description of last group of tests
  (assert-count 0)            ;; total number of assertions run
  (failure-count 0)           ;; total number of failures seen
  (start-time (current-time)) ;; Time run started
  )

(defvar test-simple-info (make-test-info)
  "Variable to store testing information for a buffer.")

(defun note (description &optional test-info)
  "Add a name to a group of tests."
  (if (getenv "USE_TAP")
    (test-simple-msg (format "# %s" description) 't)
    (if (> test-simple-verbosity 0)
	(test-simple-msg (concat "\n" description) 't))
    (unless test-info
      (setq test-info test-simple-info))
    (setf (test-info-description test-info) description)
    ))

;;;###autoload
(defmacro test-simple-start (&optional test-start-msg)
  `(test-simple-clear nil
		      (or ,test-start-msg
			  (if (and (functionp '__FILE__) (__FILE__))
			      (file-name-nondirectory (__FILE__))
			    (buffer-name)))
		      ))

;;;###autoload
(defun test-simple-clear (&optional test-info test-start-msg)
  "Initialize and reset everything to run tests.
You should run this before running any assertions.  Running more than once
clears out information from the previous run."

  (interactive)

  (unless test-info
    (unless test-simple-info
      (make-variable-buffer-local (defvar test-simple-info (make-test-info))))
    (setq test-info test-simple-info))

  (setf (test-info-description test-info) "none set")
  (setf (test-info-start-time test-info) (current-time))
  (setf (test-info-assert-count test-info) 0)
  (setf (test-info-failure-count test-info) 0)

  (with-current-buffer (get-buffer-create "*test-simple*")
    (let ((old-read-only inhibit-read-only))
      (setq inhibit-read-only 't)
      (delete-region (point-min) (point-max))
      (if test-start-msg (insert (format "%s\n" test-start-msg)))
      (setq inhibit-read-only old-read-only)))
  (unless noninteractive
    (message "Test-Simple: test information cleared")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Assertion tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro assert-raises (error-condition body &optional fail-message)
  (let ((fail-message (or fail-message
			  (format "assert-raises did not get expected %s"
				  error-condition))))
    (list 'condition-case nil
	  (list 'progn body
		(list 'assert-t nil fail-message))
	  (list error-condition '(assert-t t)))))

(defun assert-op (op expected actual &optional fail-message test-info)
  "Expectation is that ACTUAL should be equal to EXPECTED."
  (unless test-info (setq test-info test-simple-info))
  (cl-incf (test-info-assert-count test-info))
  (if (not (funcall op actual expected))
      (let* ((fail-message
	      (if fail-message
		  (format "Message: %s" fail-message)
		""))
	     (expect-message
	      (format "\n  Expected: %S\n  Got: %S" expected actual))
	     (test-info-mess
	      (if (boundp 'test-info)
		  (test-info-description test-info)
		"unset")))
	(test-simple--add-failure (format "assert-%s" op) test-info-mess
                                  (concat fail-message expect-message)))
    (test-simple--ok-msg fail-message)))

(defun assert-equal (expected actual &optional fail-message test-info)
  "Expectation is that ACTUAL should be equal to EXPECTED."
  (assert-op 'equal expected actual fail-message test-info))

(defun assert-eq (expected actual &optional fail-message test-info)
  "Expectation is that ACTUAL should be EQ to EXPECTED."
  (assert-op 'eql expected actual fail-message test-info))

(defun assert-eql (expected actual &optional fail-message test-info)
  "Expectation is that ACTUAL should be EQL to EXPECTED."
  (assert-op 'eql expected actual fail-message test-info))

(defun assert-matches (expected-regexp actual &optional fail-message test-info)
  "Expectation is that ACTUAL should match EXPECTED-REGEXP."
  (unless test-info (setq test-info test-simple-info))
  (cl-incf (test-info-assert-count test-info))
  (if (not (string-match expected-regexp actual))
      (let* ((fail-message
	      (if fail-message
		  (format "\n\tMessage: %s" fail-message)
		""))
	     (expect-message
	      (format "\tExpected Regexp: %s\n\tGot:      %s"
		      expected-regexp actual))
	     (test-info-mess
	      (if (boundp 'test-info)
		  (test-info-description test-info)
		"unset")))
	(test-simple--add-failure "assert-equal" test-info-mess
                                  (concat expect-message fail-message)))
    (progn (test-simple-msg ".") t)))

(defun assert-t (actual &optional fail-message test-info)
  "expectation is that ACTUAL is not nil."
  (assert-nil (not actual) fail-message test-info))

(defun assert-nil (actual &optional fail-message test-info)
  "expectation is that ACTUAL is nil. FAIL-MESSAGE is an optional
additional message to be displayed."
  (unless test-info (setq test-info test-simple-info))
  (cl-incf (test-info-assert-count test-info))
  (if actual
      (let* ((fail-message
	      (if fail-message
		  (format "\n\tMessage: %s" fail-message)
		""))
	     (test-info-mess
	      (if (boundp 'test-simple-info)
		  (test-info-description test-simple-info)
		"unset")))
	(test-simple--add-failure "assert-nil" test-info-mess
                                  fail-message test-info))
    (test-simple--ok-msg fail-message)))

(defun test-simple--add-failure (type test-info-msg fail-msg
                                      &optional test-info)
  (unless test-info (setq test-info test-simple-info))
  (cl-incf (test-info-failure-count test-info))
  (let ((failure-msg
	 (format "\nDescription: %s, type %s\n%s" test-info-msg type fail-msg))
	)
    (save-excursion
      (test-simple--not-ok-msg fail-msg)
      (test-simple-msg failure-msg 't)
      (unless noninteractive
	(if test-simple-debug-on-error
	    (signal 'test-simple-assert-failed failure-msg)
	  ;;(message failure-msg)
	  )))))

(defun end-tests (&optional test-info)
  "Give a tally of the tests run."
  (interactive)
  (unless test-info (setq test-info test-simple-info))
  (test-simple-describe-failures test-info)
  (cond (noninteractive
         (set-buffer "*test-simple*")
         (cond ((getenv "USE_TAP")
                (princ (format "%s\n" (buffer-string)))
                )
               (t ;; non-TAP goes to stderr (backwards compatibility)
              	(message "%s" (buffer-substring (point-min) (point-max)))
                )))
        (t ;; interactive
         (switch-to-buffer-other-window "*test-simple*")
         )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reporting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun test-simple-msg(msg &optional newline)
  (switch-to-buffer "*test-simple*")
  (let ((inhibit-read-only t))
    (insert msg)
    (if newline (insert "\n"))
    (switch-to-buffer nil)
  ))

(defun test-simple--ok-msg (fail-message &optional test-info)
  (unless test-info (setq test-info test-simple-info))
  (let ((msg (if (getenv "USE_TAP")
		 (if (equal fail-message "")
		     (format "ok %d\n" (test-info-assert-count test-info))
		   (format "ok %d - %s\n"
			   (test-info-assert-count test-info)
			   fail-message))
	       ".")))
      (test-simple-msg msg))
  't)

(defun test-simple--not-ok-msg (_fail-message &optional test-info)
  (unless test-info (setq test-info test-simple-info))
  (let ((msg (if (getenv "USE_TAP")
		 (format "not ok %d\n" (test-info-assert-count test-info))
	       "F")))
      (test-simple-msg msg))
  nil)

(defun test-simple-summary-line(info)
  (let*
      ((failures (test-info-failure-count info))
       (asserts (test-info-assert-count info))
       (problems (concat (number-to-string failures) " failure"
			 (unless (= 1 failures) "s")))
       (tests (concat (number-to-string asserts) " assertion"
		      (unless (= 1 asserts) "s")))
       (elapsed-time (time-since (test-info-start-time info)))
       )
    (if (getenv "USE_TAP")
	(format "1..%d" asserts)
      (format "\n%s in %s (%g seconds)" problems tests
	      (float-time elapsed-time))
  )))

(defun test-simple-describe-failures(&optional test-info)
  (unless test-info (setq test-info test-simple-info))
  (goto-char (point-max))
  (test-simple-msg (test-simple-summary-line test-info)))

;;;###autoload
(defun test-simple-run (&rest command-line-formats)
  "Register command line to run tests non-interactively and bind key to run test.
After calling this function, you can run test by key specified by `test-simple-runner-key'.

It is preferable to write at the first line of test files as a comment, e.g,
;;;; (test-simple-run \"emacs -batch -L %s -l %s\" (file-name-directory (locate-library \"test-simple.elc\")) buffer-file-name)

Calling this function interactively, COMMAND-LINE-FORMATS is set above."
  (interactive)
  (setq command-line-formats
        (or command-line-formats
            (list "emacs -batch -L %s -l %s"
                  (file-name-directory (locate-library "test-simple.elc"))
                  buffer-file-name)))
  (let ((func (lambda ()
                (interactive)
                (funcall test-simple-runner-interface
                         (apply 'format command-line-formats)))))
    (global-set-key (kbd test-simple-runner-key) func)
    (funcall func)))

(defun test-simple-noninteractive-kill-emacs-hook ()
  "Emacs exits abnormally when noninteractive test fails."
  (when (and noninteractive test-simple-info
             (<= 1 (test-info-failure-count test-simple-info)))
    (let (kill-emacs-hook)
     (kill-emacs 1))))
(when noninteractive
  (add-hook 'kill-emacs-hook 'test-simple-noninteractive-kill-emacs-hook))


(provide 'test-simple)
;;; test-simple.el ends here
