;;; test-simple.el --- Simple Unit Test Framework for Emacs Lisp
;; Rewritten from Phil Hagelberg's behave.el by rocky

;; Copyright (C) 2010, 2012-2013, 2014 Rocky Bernstein

;; Author: Rocky Bernstein
;; URL: http://github.com/rocky/emacs-test-simple
;; Package-Version: 20141216.2125
;; Package-Commit: 75eea25bae04d8e5e3e835a2770f02f0ff4602c4
;; Keywords: unit-test
;; Version: 1.0

;; This file is NOT part of GNU Emacs.

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
;; * Simple. No need for
;;   - context macros,
;;   - enclosing specifications,
;;   - required test tags.
;;
;;   But if you want, you still can enclose tests in a local scope,
;;   add customized assert failure messages, or add summary messages
;;   before a group of tests.
;;
;; * Accomodates both interactive and non-interactive use.
;;    - For interactive use, one can use `eval-last-sexp', `eval-region',
;;      and `eval-buffer'. One can `edebug' the code.
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
;; Edit (with Emacs of course) test-gcd.el and run M-x eval-current-buffer
;;
;; You should see in buffer *test-simple*:
;;
;;    test-gcd.el
;;    ......
;;    0 failures in 6 assertions (0.002646 seconds)
;;
;; Now let us try from a command line:
;;
;;    $ emacs --batch --no-site-file --no-splash --load test-gcd.el
;;    Loading /src/external-vcs/emacs-test-simple/example/gcd.el (source)...
;;    *scratch*
;;    ......
;;    0 failures in 6 assertions (0.000723 seconds)

;;; To do:

;; Main issues: more expect predicates

(require 'time-date)

;;; Code:

(eval-when-compile
  (byte-compile-disable-warning 'cl-functions)
  ;; Somehow disabling cl-functions causes the erroneous message:
  ;;   Warning: the function `reduce' might not be defined at runtime.
  ;; FIXME: isolate, fix and/or report back to Emacs developers a bug
  ;; (byte-compile-disable-warning 'unresolved)
  (require 'cl)
  )
(require 'cl)

(defvar test-simple-debug-on-error nil
  "If non-nil raise an error on the first failure.")

(defvar test-simple-verbosity 0
  "The greater the number the more verbose output.")

(defstruct test-info
  description                 ;; description of last group of tests
  (assert-count 0)            ;; total number of assertions run
  (failure-count 0)           ;; total number of failures seen
  (start-time (current-time)) ;; Time run started
  )

(defvar test-simple-info (make-test-info)
  "Variable to store testing information for a buffer.")

(defun note (description &optional test-info)
  "Adds a name to a group of tests."
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
  "Initializes and resets everything to run tests. You should run
this before running any assertions. Running more than once clears
out information from the previous run."

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

(defmacro assert-raises (error-condition body &optional fail-message test-info)
  (let ((fail-message (or fail-message
			  (format "assert-raises did not get expected %s"
				  error-condition))))
    (list 'condition-case nil
	  (list 'progn body
		(list 'assert-t nil fail-message test-info))
	  (list error-condition '(assert-t t)))))

(defun assert-op (op expected actual &optional fail-message test-info)
  "expectation is that ACTUAL should be equal to EXPECTED."
  (unless test-info (setq test-info test-simple-info))
  (incf (test-info-assert-count test-info))
  (if (not (funcall op actual expected))
      (let* ((fail-message
	      (if fail-message
		  (format "Message: %s" fail-message)
		""))
	     (expect-message
	      (format "\n  Expected: %s\n  Got: %s" expected actual))
	     (test-info-mess
	      (if (boundp 'test-info)
		  (test-info-description test-info)
		"unset")))
	(add-failure (format "assert-%s" op) test-info-mess
		     (concat fail-message expect-message)))
    (ok-msg fail-message)))

(defun assert-equal (expected actual &optional fail-message test-info)
  "expectation is that ACTUAL should be equal to EXPECTED."
  (assert-op 'equal expected actual fail-message test-info))

(defun assert-eq (expected actual &optional fail-message test-info)
  "expectation is that ACTUAL should be EQ to EXPECTED."
  (assert-op 'eql expected actual fail-message test-info))

(defun assert-eql (expected actual &optional fail-message test-info)
  "expectation is that ACTUAL should be EQL to EXPECTED."
  (assert-op 'eql expected actual fail-message test-info))

(defun assert-matches (expected-regexp actual &optional fail-message test-info)
  "expectation is that ACTUAL should match EXPECTED-REGEXP."
  (unless test-info (setq test-info test-simple-info))
  (incf (test-info-assert-count test-info))
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
	(add-failure "assert-equal" test-info-mess
		     (concat expect-message fail-message)))
    (progn (test-simple-msg ".") t)))

(defun assert-t (actual &optional fail-message test-info)
  "expectation is that ACTUAL is not nil."
  (assert-nil (not actual) fail-message test-info "assert-t"))

(defun assert-nil (actual &optional fail-message test-info assert-type)
  "expectation is that ACTUAL is nil. FAIL-MESSAGE is an optional
additional message to be displayed. Since several assertions
funnel down to this one, ASSERT-TYPE is an optional type."
  (unless test-info (setq test-info test-simple-info))
  (incf (test-info-assert-count test-info))
  (if actual
      (let* ((fail-message
	      (if fail-message
		  (format "\n\tMessage: %s" fail-message)
		""))
	     (test-info-mess
	      (if (boundp 'test-simple-info)
		  (test-info-description test-simple-info)
		"unset")))
	(add-failure "assert-nil" test-info-mess fail-message test-info))
    (ok-msg fail-message)))

(defun add-failure(type test-info-msg fail-msg &optional test-info)
  (unless test-info (setq test-info test-simple-info))
  (incf (test-info-failure-count test-info))
  (let ((failure-msg
	 (format "\nDescription: %s, type %s\n%s" test-info-msg type fail-msg))
	(old-read-only inhibit-read-only)
	)
    (save-excursion
      (not-ok-msg fail-msg)
      (test-simple-msg failure-msg 't)
      (unless noninteractive
	(if test-simple-debug-on-error
	    (signal 'test-simple-assert-failed failure-msg)
	  ;;(message failure-msg)
	  )))))

(defun end-tests (&optional test-info)
  "Give a tally of the tests run"
  (interactive)
  (unless test-info (setq test-info test-simple-info))
  (test-simple-describe-failures test-info)
  (if noninteractive
      (progn
	(switch-to-buffer "*test-simple*")
	(message "%s" (buffer-substring (point-min) (point-max)))
	)
    (switch-to-buffer-other-window "*test-simple*")
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reporting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun test-simple-msg(msg &optional newline)
  (switch-to-buffer "*test-simple*")
  (let ((old-read-only inhibit-read-only))
    (setq inhibit-read-only 't)
    (insert msg)
    (if newline (insert "\n"))
    (setq inhibit-read-only old-read-only)
    (switch-to-buffer nil)
  ))

(defun ok-msg(fail-message &optional test-info)
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

(defun not-ok-msg(fail-message &optional test-info)
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

(provide 'test-simple)
;;; test-simple.el ends here
