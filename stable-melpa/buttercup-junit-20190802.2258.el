;;; buttercup-junit.el --- JUnit reporting for Buttercup -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2019  Ola Nilsson

;; Author: Ola Nilsson <ola.nilsson@gmail.com>
;; Maintainer: Ola Nilsson <ola.nilsson@gmail.com>
;; Created: Oct 2, 2016
;; Keywords: tools test unittest buttercup ci
;; Package-Version: 20190802.2258
;; Package-Commit: 3ae4f84813c9e04e03a6e703990ca998b62b6deb
;; Version: 1.1.1
;; Package-Requires: ((emacs "24.3") (buttercup "1.15"))
;; URL: https://bitbucket.org/olanilsson/buttercup-junit

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

;; Print buttercup test results to JUnit XML report files, while also
;; producing normal buttercup output on stdout.
;;
;; `emacs -batch -L . -f package-initialize -f buttercup-junit-run-discover [buttercup-options]'
;;
;; buttercup-junit-run-discover can be configured with the following
;; command line options:
;;
;;  --xmlfile FILE    Write JUnit report to FILE
;;  --junit-stdout    Write JUnit report to stdout.
;;                    The report file will also be written to stdout,
;;                    after the normal buttercup report.
;;  --outer-suite     Add a wrapping testsuite around the outer suites.
;;
;; buttercup tests are grouped into descriptions, and descriptions can
;; be contained in other descriptions creating a tree structure where
;; the tests are leafs.  buttercup-junit will output a testsuite for
;; each buttercup description and a testcase for each `it' testcase.
;; Pending tests will be marked as skipped in the report.

;;; Code:

(require 'pcase)
(require 'cl-lib)
(require 'xml)
(require 'buttercup)

(defgroup buttercup-junit nil
  "buttercup-junit customizations."
  :group 'buttercup)

(defcustom buttercup-junit-result-file "results.xml"
  "Default result file for buttercup-junit."
  :group 'buttercup-junit
  :type 'string)

(defvar buttercup-junit-inner-reporter #'buttercup-reporter-adaptive
  "Second reporter that will also receive all events.
Used to also print the normal output to stdout.
Set to nil to have no output.")

(defvar buttercup-junit--to-stdout nil
  "Whether to print the xml file to stdout as well.")

(defvar buttercup-junit-master-suite nil
  "Name of wrapping test suite.
An extra outer testsuite with this name is added to the report if
`buttercup-junit-master-suite' is set to a non-empty string.")

(defsubst buttercup-junit--nonempty-string-p (object)
  "Return non-nil if OBJECT is a non-empty string."
  (and (stringp object) (not (string= object ""))))

(defun buttercup-junit--extract-argument-option (option)
  "Return the item following OPTION in `command-line-args-left'.
OPTION is tyically a string `--option' that should be followed by
a mandatory option argument.  All pairs of `OPTION argument' will
be removed from `command-line-args-left', and the argument of the
last pari will be returned.  Throws an error If OPTION is found
as the last item in `command-line-args-left'."
  (let ((option-elt (member option command-line-args-left))
		argument)
	(while option-elt
	  (unless (cdr option-elt)
		(error "Option %s requires an argument" option))
	  (setq argument (cadr option-elt))
	  (setcdr option-elt (cddr option-elt))
	  (setq command-line-args-left
			(cl-remove option command-line-args-left :test #'string= :count 1))
	  (setq option-elt (member option command-line-args-left)))
	argument))

(defun buttercup-junit--option-set (option)
  "Check `command-line-args-left' for OPTION.  Remove any found."
  (prog1 (member option command-line-args-left)
	(setq command-line-args-left (remove option command-line-args-left))))

(defmacro buttercup-junit--with-reporter (&rest body)
  "Execute BODY with necessary variables bound.
This macro is used to wrap calls to buttercup with relevant
variables set."
  (declare (debug t) (indent defun))
  `(let ((buttercup-junit-result-file
          (or (buttercup-junit--extract-argument-option "--xmlfile")
              buttercup-junit-result-file))
         (buttercup-junit--to-stdout
          (or (buttercup-junit--option-set "--junit-stdout")
              buttercup-junit--to-stdout))
         (buttercup-junit-master-suite
          (or (buttercup-junit--extract-argument-option "--outer-suite")
              buttercup-junit-master-suite))
         (buttercup-reporter #'buttercup-junit-reporter))
     ,@body))

;;;###autoload
(defun buttercup-junit-at-point (&optional outer)
  "Execute `buttercup-run-at-point' with `buttercup-junit-reporter' set.
The JUnit report will be written to thte file specified by
`buttercup-junit-result-file'.  If OUTER or
`buttercup-junit-master-suite' is a non-empty string, a wrapper
testsuite of that name will be added."
  (interactive "souter: ")
  (let ((command-line-args-left (list "--xmlfile" buttercup-junit-result-file)))
	(when outer
	  (setq command-line-args-left (append command-line-args-left
										   (list "--outer-suite" outer))))
    (buttercup-junit--with-reporter
      (buttercup-run-at-point))))

;;;###autoload
(defun buttercup-junit-run-discover ()
  "Execute `buttercup-run-discover' with `buttercup-junit-reporter' set.
The JUnit report will be written to the file specified by
`buttercup-junit-result-file', and to stdout if
`buttercup-junit-to-stdout' is non-nil.  If
`buttercup-junit-master-suite' is set a wrapper testsuite of that
name will be added.  These variables can be overriden by the
options `--xmlfile XMLFILE', `--junit-stdout', and `--outer-suite
SUITE' in `commandline-args-left'."
  (buttercup-junit--with-reporter
    (buttercup-run-discover)))

;;;###autoload
(defun buttercup-junit-run-markdown-buffer (&rest markdown-buffers)
  "Execute `buttercup-run-markdown-buffer' with `buttercup-junit-reporter'.
MARKDOWN-BUFFERS is passed to `buttercup-run-markdown-buffer'.
The JUnit report will be written to the file specified by
`buttercup-junit-result-file', and to stdout if
`buttercup-junit-to-stdout' is non-nil.  If
`buttercup-junit-master-suite' is set a wrapper testsuite of that
name will be added.  These variables can be overriden by the
options `--xmlfile XMLFILE', `--junit-stdout', and `--outer-suite
SUITE' in `commandline-args-left'."
  (interactive)
  (buttercup-junit--with-reporter
    (apply #'buttercup-run-markdown-buffer markdown-buffers)))

;;;###autoload
(defun buttercup-junit-run-markdown ()
  "Execute `buttercyp-run-markdown' with `buttercup-junit-reporter'."
  (buttercup-junit--with-reporter
    (buttercup-run-markdown)))

;;;###autoload
(defun buttercup-junit-run-markdown-file (file)
  "Pass FILE to `buttercup-run-markdown-file' using `buttercup-junit-reporter'."
  (interactive "fMarkdown file: ")
  (buttercup-junit--with-reporter
    (buttercup-run-markdown-file file)))

;;;###autoload
(defun buttercup-junit-run ()
  "Execute `buttercup-run' with `buttercup-junit-reporter'."
  (interactive)
  (buttercup-junit--with-reporter
    (buttercup-run)))

(defsubst buttercup-junit--insert-at (marker &rest insert-args)
  "Go to MARKER, disable MARKER, and `insert' INSERT-ARGS."
  (goto-char marker)
  (setq marker nil)
  (apply #'insert insert-args))

(defun buttercup-junit--escape-string (string)
  "Convert STRING into a string containing valid XML character data.
Convert all non-printable characters in string to a `^A'
sequence, then pass the result to `xml-escape-string'."
  (xml-escape-string
   (with-temp-buffer
	 (insert string)
	 (goto-char 1)
	 (while (not (eobp))
	   (if (aref printable-chars (char-after))
		   (forward-char)
		 (insert (format "^%c" (+ (char-after) ?A -1)))
		 (delete-char 1)))
	 (buffer-string))))

(defun buttercup-junit--error-p (spec)
  "Return t if SPEC has thrown an error."
  (and (eq 'failed (buttercup-spec-status spec))
       (let ((desc (buttercup-spec-failure-description spec)))
         (and (consp desc)
              (eq 'error (car desc))))))

(defun buttercup-junit--errors (suite)
  "Return the total number (recursively) of erroring testcases in SUITE."
  (cl-loop for spec in (buttercup--specs (list suite))
           count (buttercup-junit--error-p spec)))

(defun buttercup-junit--failures (suite)
  "Return the total number (recursively) of failed testcases in SUITE."
  (- (buttercup-suites-total-specs-failed (list suite))
     (buttercup-junit--errors suite)))

(defun buttercup-junit--testcase (spec indent)
  "Print a `testcase' xml element for SPEC to the current buffer.
The testcase tags will be indented with INDENT spaces."
  (insert (make-string indent ?\s)
          "<testcase name=\""
          (buttercup-junit--escape-string (buttercup-spec-description spec))
          "\" classname=\"buttercup\" time=\""
          (format "%f" (float-time (buttercup-elapsed-time spec)))
          "\">")
  (pcase (buttercup-spec-status spec)
    (`failed
     (let ((desc (buttercup-spec-failure-description spec))
           (stack (buttercup-spec-failure-stack spec))
           tag message type)
       (cond ((stringp desc) (setq tag "failed"
                                   message desc
                                   ;; TODO: find a proper value for type
                                   type "type"))
             ((eq (car desc) 'error)
              (setq tag "error"
                    message (pp-to-string (cadr desc))
                    type (symbol-name (car desc))))
             (t (setq tag "failed"
                      message (pp-to-string desc)
                      type "unknown")))
       (insert "\n" (make-string (1+ indent) ?\s)
               "<" tag " message=\""
               (buttercup-junit--escape-string message) "\""
               " type=\"" (buttercup-junit--escape-string type) "\">"
               "Traceback (most recent call last):\n")
       (dolist (frame stack)
         (insert (buttercup-junit--escape-string (format "  %S" (cdr frame)))
                 "\n"))
       (insert "</" tag ">\n")))
    (`pending
     (insert "\n" (make-string (1+ indent) ?\s)
             "<skipped/>\n")))
  (insert (if (bolp) (make-string indent ?\s) "")
          "</testcase>\n"))

(defun buttercup-junit--testsuite (suite indent)
  "Print a `testsuite' xml element for SUITE to the current buffer.
Recursively print any contained suite or spec.
Each testsuite element will be preceeded by INDENT space characters."
  (insert
   (make-string indent ?\s)
   (format "<testsuite name=\"%s\""
           (buttercup-junit--escape-string (buttercup-suite-description suite)))
   (format-time-string " timestamp=\"%Y-%m-%d %T%z\""
                       (buttercup-suite-time-started suite))
   (format " hostname=\"%s\"" (buttercup-junit--escape-string (system-name)))
   (format " tests=\"%d\"" (buttercup-suites-total-specs-defined (list suite)))
   (format " failures=\"%d\"" (buttercup-junit--failures suite))
   (format " errors=\"%d\"" (buttercup-junit--errors suite))
   (format " time=\"%f\"" (float-time (buttercup-elapsed-time suite)))
   (format " skipped=\"%d\">\n" (buttercup-suites-total-specs-pending (list suite))))
  (dolist (child (buttercup-suite-children suite))
    (if (buttercup-spec-p child)
        (buttercup-junit--testcase child (1+ indent))
      (buttercup-junit--testsuite child (1+ indent))))
  (insert (make-string indent ?\s)
          "</testsuite>\n"))

(defun buttercup-junit--make-outer (description suites)
  "Create an outer suite DESCRIPTION with SUITES as children.
The start time will be the same as the first suite, and the end
time the same as the last suite."
  (make-buttercup-suite
   :description description
   :children suites
   :time-started (buttercup-suite-or-spec-time-started (car suites))
   :time-ended (buttercup-suite-or-spec-time-ended (car (last suites)))))

;;;###autoload
(defun buttercup-junit-reporter (event arg)
  "Insert JUnit tags into the `*junit*' buffer according to EVENT and ARG.
See `buttercup-reporter' for documentation on the values of EVENT
and ARG.  A new output buffer is created on the
`buttercup-started' event, and its contents are written to
`buttercup-junit-result-file' and possibly stdout on the
`buttercup-done' event."
  (when buttercup-junit-inner-reporter
    (funcall buttercup-junit-inner-reporter event arg))
  (when (eq event 'buttercup-done)
    (when (buttercup-junit--nonempty-string-p buttercup-junit-master-suite)
      (setq arg (list (buttercup-junit--make-outer buttercup-junit-master-suite
                                                   arg))))
    (with-temp-buffer
      (set-buffer-file-coding-system 'utf-8)
      (insert "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
              "<testsuites>\n")
      (dolist (suite arg)
        (buttercup-junit--testsuite suite 1))
      (insert "</testsuites>\n")
      ;; Output XML data
      (when buttercup-junit--to-stdout
        (send-string-to-terminal (buffer-string)))
      (when buttercup-junit-result-file
        (write-file buttercup-junit-result-file)))))

(provide 'buttercup-junit)
;;; buttercup-junit.el ends here
;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; tab-width: 4
;; indent-tabs-mode: nil
;; End:
