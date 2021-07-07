;;; emidje.el --- Test runner and report viewer for Midje -*- lexical-binding: t -*-

;; Copyright © 2018 Nubank

;; Author: Alan Ghelardi <alan.ghelardi@nubank.com.br>
;; Maintainer: Alan Ghelardi <alan.ghelardi@nubank.com.br>
;; Version: 1.2.0-SNAPSHOT
;; Package-Version: 20190209.1726
;; Package-Commit: 7e92f053964d925c97dc8cca8d4d70a3030021db
;; Package-Requires: ((emacs "25") (cider "0.17.0") (seq "2.16") (magit-popup "2.4.0"))
;; Homepage: https://github.com/nubank/emidje
;; Keywords: tools

;; This file is not part of GNU Emacs.

;; Licensed under the Apache License, Version 2.0 (the "License"); you may not use
;; this file except in compliance with the License.  You may obtain a copy of the
;; License at
;; http://www.apache.org/licenses/LICENSE-2.0

;; Unless required by applicable law or agreed to in writing, software distributed
;; under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
;; CONDITIONS OF ANY KIND, either express or implied.  See the License for the
;; specific language governing permissions and limitations under the License.

;;; Commentary:

;; Emidje is a Cider plugin that provides support to run Midje tests within Emacs.

;;; Code:

(defgroup emidje nil
  "Test runner, report viewer and formatting tool for Midje."
  :prefix "emidje-"
  :group 'applications
  :link '(url-link :tag "GitHub" "https://github.com/nubank/emidje"))

(require 'ansi-color)
(require 'cider)
(unless (fboundp 'cider--format-region)
  ;; For cider >= 0.18.x
  (require 'cider-format)
  (declare-function cider--format-region "cider-format" (start end formatter)))
(require 'ido)
(require 'pkg-info)
(require 'magit-popup)
(require 'seq)

(defface emidje-failure
  '((t (:inherit error)))
  "Face for failed tests."
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defface emidje-error
  '((t (:inherit error)))"Face for erring tests."
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defface emidje-success
  '((t (:inherit success)))
  "Face for passing tests."
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defface emidje-work-todo
  '((t (:inherit warning)))
  "Face for future facts."
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defcustom emidje-inject-nrepl-middleware-at-jack-in t
  "When nil, do not inject `midje-nrepl' at `cider-jack-in' time."
  :group 'emidje
  :type 'boolean
  :package-version '(emidje . "1.0.0"))

(defcustom emidje-always-show-test-report nil
  "When nil, only show the test report if tests fail."
  :group 'emidje
  :type 'boolean
  :package-version '(emidje . "1.2.0"))

(defcustom emidje-infer-test-ns-function 'emidje-default-infer-test-ns-function
  "Function to infer the test namespace."
  :type 'symbol
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defun emidje-default-infer-test-ns-function (current-ns)
  "Default function for inferring the namespace to be tested.
Apply the Leiningen convention of appending the suffix `-test' to CURRENT-NS."
  (let ((suffix "-test"))
    (if (string-suffix-p suffix current-ns)
        current-ns
      (concat current-ns suffix))))

(defcustom emidje-load-facts-on-eval nil
  "When set to nil, Midje facts won't be loaded on operations that cause the evaluation of Clojure forms like `eval' and `load-file'."
  :type 'boolean
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defcustom emidje-show-full-test-summary t
  "When set to t, show a full test summary on the message buffer.
Set to nil if you prefer to see a shorter version of test summaries."
  :type 'boolean
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defcustom emidje-suppress-nrepl-middleware-warnings nil
  "When set to t, no nREPL middleware warnings are shown on the REPL."
  :type 'boolean
  :group 'emidje
  :package-version '(emidje . "1.0.0"))

(defconst emidje-evaluation-operations `("eval" "load-file")
  "List of nREPL operations that cause the evaluation of Clojure forms.")

(defconst emidje-test-report-buffer "*midje-test-report*"
  "The title of test report buffer.")

(defvar emidje-supported-operations
  '((:version . "midje-nrepl-version")
    (:format-tabular . "midje-format-tabular")
    (:project . "midje-test-all")
    (:ns . "midje-test-ns")
    (:retest . "midje-retest")
    (:test-at-point . "midje-test")
    (:test-namespaces . "test-namespaces")
    (:test-paths . "test-paths")
    (:test-stacktrace . "midje-test-stacktrace")))

(defun emidje-render-stacktrace (causes)
  "Render the Cider error buffer with the given CAUSES."
  (cider-stacktrace-render
   (cider-popup-buffer cider-error-buffer
                       cider-auto-select-error-buffer
                       #'cider-stacktrace-mode)
   causes))

(defun emidje-handle-error-response (response)
  "Handle the error RESPONSE returned by `midje-nrepl'."
  (nrepl-dbind-response response (error-message exception status)
    (cond
     (error-message (user-error error-message))
     (exception (emidje-render-stacktrace exception))
     (t (user-error "Midje-nrepl returned the following status: %st" (mapconcat #'identity status ", "))))))

(defun emidje-handle-nrepl-response (handler-function response)
  "Handle the nREPL RESPONSE by delegating to the specified HANDLER-FUNCTION.
If RESPONSE contains the `error' status, delegate to `emidje-handle-error-response'."
  (nrepl-dbind-response response (status)
    (if (seq-contains status "error")
        (emidje-handle-error-response response)
      (funcall handler-function response))))

(defun emidje-send-request (op-alias &optional args callback)
  "Send a request to nREPL middleware.
All functions that interact with nREPL middleware must rely on
this one, since it treats error responses appropriately.
OP-ALIAS is a keyword representing the nREPL op (see
`emidje-supported-operations').  ARGS is an alist of remaining
parameters to be sent in the request.  Keys can be symbols that
will be transformed into strings before sending the request.
CALLBACK is a function that takes the nREPL response as its only
argument.  When set, the request is sent asynchronously.  If
omitted, the request is sent synchronously and the nREPL response
is returned."
  (cider-ensure-connected)
  (let* ((op (or (cdr (assq op-alias emidje-supported-operations))
                 (error "Unknown op alias `%s'" op-alias)))
         (message (thread-last (or args `())
                    (seq-map (lambda (value)
                               (if (symbolp value)
                                   (symbol-name value)
                                 value)))
                    (append `("op" ,op)))))
    (if callback
        (cider-nrepl-send-request message (apply-partially #'emidje-handle-nrepl-response callback))
      (thread-last (cider-nrepl-send-sync-request message)
        (emidje-handle-nrepl-response #'identity)))))

(defun emidje-version ()
  "Read Emidje's version from the version header."
  (let ((version-regex "^[0-9]+\.[0-9]+\.[0-9]+-?[A-Z0-9]*$")
        (version (lm-version (pkg-info-library-source 'emidje))))
    (if (not (string-match version-regex version))
        (error "Invalid version `%s'" version)
      version)))

(defun emidje-show-warning-on-repl (message &rest args)
  "Show the MESSAGE on the Cider's REPL buffer if applicable.
ARGS are arbitrary values to be interpolated in the MESSAGE."
  (unless emidje-suppress-nrepl-middleware-warnings
    (cider-repl-emit-interactive-stderr
     (apply #'format (concat "WARNING: " message
                             "\nYou can mute this warning by changing the variable emidje-suppress-nrepl-middleware-warnings to t.")
            args))))

(defun emidje-check-nrepl-middleware-version ()
  "Check whether `emidje' and `midje-nrepl' versions are in sync.
Show warning messages on Cider's REPL when applicable."
  (let ((emidje-version (emidje-version))
        (midje-nrepl-version (nrepl-dict-get-in (emidje-send-request :version) `("midje-nrepl" "version-string"))))
    (cond
     ((not midje-nrepl-version)
      (emidje-show-warning-on-repl "midje-nrepl isn't in your classpath; Emidje keybindings won't work!
 You can either start this REPL via cider-jack-in or add midje-nrepl to your profile.clj dependencies."))
     ((not (string-equal emidje-version midje-nrepl-version))
      (emidje-show-warning-on-repl "Emidje and midje-nrepl are out of sync. Things will break!
Their versions are %s and %s, respectively.
Please, consider updating the midje-nrepl version in your profile.clj to %s or start the REPL via cider-jack-in." emidje-version midje-nrepl-version emidje-version)))))

(defun emidje-inject-nrepl-middleware-p (&rest _)
  "Return t if the nREPL middleware should be injected at Cider jack-in.
Currently, this predicate returns the value of
  `emidje-inject-nrepl-middleware-at-jack-in'.  For more details
  about predicate functions called by Cider at jack-in, see
  `cider-jack-in-lein-plugins'."
  emidje-inject-nrepl-middleware-at-jack-in)

(defun emidje-inject-nrepl-middleware ()
  "Inject `midje-nrepl' in the REPL started by `cider-jack-in'."
  (when (boundp 'cider-jack-in-lein-plugins)
    (add-to-list 'cider-jack-in-lein-plugins `("nubank/midje-nrepl" ,(emidje-version)  :predicate emidje-inject-nrepl-middleware-p) t)))

;;;###autoload
(defun emidje-enable-nrepl-middleware ()
  "Enable `midje-nrepl' middleware as a `Cider' dependency.
Call this function in your `init.el' to enable the automatic
injection of the nREPL middleware in the `cider-jack-in'
command.  See also: `emidje-setup'."
  (emidje-inject-nrepl-middleware)
  (add-hook 'cider-connected-hook #'emidje-check-nrepl-middleware-version))

(defmacro emidje-outline-section (heading &rest body)
  "Create an outline region in the current buffer.

First inserts the HEADING, then evaluates BODY.  If the inserted
region has more than two lines (including the heading), hides the
outline.  Otherwise, keeps it visible."
  (declare (indent 1)
           (debug (sexp body)))
  `(let ((begin (point)))
     (cider-insert ,heading 'bold t)
     ,@body
     (when (> (count-lines begin (point)) 2)
       (save-excursion
         (goto-char begin)
         (outline-hide-subtree)))))

(defun emidje-insert-rectangle-with-no-markers (lines)
  "Insert text of RECTANGLE with upper left corner at point.
This function behaves exactly like `insert-rectangle', except
that it doesn't set the mark.  LINES is a list of strings
containing the text to be inserted."
  ;; Borrowed from `insert-rectangle' in rect.el.
  (let ((insertcolumn (current-column))
        (first t))
    (while lines
      (or first
          (progn
            (forward-line 1)
            (or (bolp) (insert ?\n))
            (move-to-column insertcolumn t)))
      (setq first nil)
      (insert-for-yank (car lines))
      (setq lines (cdr lines)))))

(defun emidje-insert-section (content)
  "Insert CONTENT in the current buffer's position.
CONTENT is a string returned by nREPL middleware for the expected, actual and/or checker message sections."
  (let* ((begin (point))
         (lines (if (stringp content)
                    (split-string content "\n")
                  (append content '("\n")))))
    (thread-last lines
      (seq-map                         #'cider-font-lock-as-clojure)
      emidje-insert-rectangle-with-no-markers)
    (ansi-color-apply-on-region begin (point))
    (beginning-of-line)))

(defun emidje-render-one-test-result (result)
  "Render one test RESULT in the current buffer's position."
  (nrepl-dbind-response result (context expected actual error message type)
    (cl-flet ((insert-label (text)
                            (cider-insert (format "%8s: " text) 'font-lock-comment-face)))
      (cider-propertize-region (cider-intern-keys (cdr result))
        (let ((begin (point))
              (type-face (cider-test-type-simple-face type))
              (bg `(:background ,cider-test-items-background-color)))
          (if (equal type "to-do")
              (cider-insert "Work To Do " 'emidje-work-todo nil)
            (cider-insert (capitalize type) type-face nil " in "))
          (dolist (text context)
            (cider-insert text 'font-lock-doc-face t))
          (insert "\n")
          (when expected
            (insert-label "expected")
            (emidje-insert-section expected)
            (insert "\n"))
          (when actual
            (insert-label "actual")
            (emidje-insert-section actual)
            (insert "\n"))
          (unless (seq-empty-p message)
            (insert-label "Checker said about the reason")
            (emidje-insert-section message))
          (when error
            (insert-label "error")
            (insert-text-button error
                                'follow-link t
                                'action '(lambda (_button) (emidje-show-test-stacktrace))
                                'help-echo "View causes and stacktrace")
            (insert "\n\n"))
          (overlay-put (make-overlay begin (point)) 'font-lock-face bg))))))

(defun emidje-count-non-passing-tests (results)
  "Return the number of non-passing test results from the RESULTS list."
  (seq-count (lambda (result)
               (let* ((type (nrepl-dict-get result "type")))
                 (or (equal type "error")
                     (equal type "fail")))) results))

(defun emidje-get-displayable-results (results)
  "Filter RESULTS by returning a new list without passing facts."
  (seq-filter (lambda (result)
                (not (equal (nrepl-dict-get result "type") "pass")))
              results))

(defun emidje-render-test-results-section (results-dict)
  "Iterate over RESULTS-DICT and render all test results."
  (cider-insert "** Results" 'bold t "\n")
  (nrepl-dict-map (lambda (ns results)
                    (let* ((displayable-results (emidje-get-displayable-results results))
                           (problems (emidje-count-non-passing-tests displayable-results)))
                      (when (> problems 0)
                        (insert (format "%s\n%d non-passing tests:\n\n"
                                        (cider-propertize ns 'ns) problems)))
                      (dolist (result displayable-results)
                        (emidje-render-one-test-result result)))
                    ) results-dict))

(defun emidje-render-profile-section (profile)
  "Render the profile section of the report buffer.

PROFILE is a `nrepl-dict' containing the information returned by
the nREPL middleware."
  (cl-flet ((insert-average (data)
                            (nrepl-dbind-response data (average total-time number-of-tests)
                              (insert average " average ")
                              (insert (format "(%s / %d tests)" total-time number-of-tests) ?\n)))
            (insert-slowest-tests (slowest-tests)
                                  (let ((number-of-tests (length (nrepl-dict-get slowest-tests "tests"))))
                                    (if (= number-of-tests 1)
                                        (insert (format "Slowest test (%s, %s of total time):"
                                                        (nrepl-dict-get slowest-tests "total-time") (nrepl-dict-get slowest-tests "percent-of-total-time")))
                                      (insert (format "Top %d slowest tests (%s, %s of total time):"
                                                      number-of-tests (nrepl-dict-get slowest-tests "total-time") (nrepl-dict-get slowest-tests "percent-of-total-time"))))
                                    (insert ?\n)
                                    (dolist (test-data (nrepl-dict-get slowest-tests "tests"))
                                      (cider-propertize-region (cider-intern-keys (cdr test-data))
                                        (dolist (text (nrepl-dict-get test-data "context"))
                                          (cider-insert text 'font-lock-doc-face t))
                                        (when (> number-of-tests 1)
                                          (insert (nrepl-dict-get test-data "total-time") ?\n)))))))
    (emidje-outline-section "** Profile"
      (nrepl-dbind-response profile (top-slowest-tests namespaces)
        (insert-average profile)
        (insert-slowest-tests top-slowest-tests)
        (insert ?\n)
        (cider-insert "*** Namespaces (slowest first)" 'bold t)
        (dolist (ns-data namespaces)
          (cider-propertize-region (cdr ns-data)
            (insert (cider-propertize (nrepl-dict-get ns-data "ns") 'ns) ": ")
            (insert-average ns-data))
          (insert (format "%s of total time"
                          (nrepl-dict-get ns-data "percent-of-total-time")) ?\n))))
    (insert ?\n)))

(defun emidje-render-checked-namespaces-section (results-dict)
  "Render a list of tested namespaces in the current buffer.
Propertize each namespace appropriately in order to allow users
to jump to the file in question.  RESULTS-DICT is a dictionary of
namespaces to test results."
  (cl-flet ((file-path-for (namespace)
                           (thread-first results-dict
                             (nrepl-dict-get namespace)
                             car
                             (nrepl-dict-get "file")))
            (ns-passed-p (ns)
                         (thread-last (nrepl-dict-get results-dict ns)
                           (seq-every-p (lambda (test)
                                          (string-equal (nrepl-dict-get test "type") "pass"))))))
    (let* ((namespaces (seq-sort #'string< (nrepl-dict-keys results-dict)))
           (number-of-namespaces (length namespaces))
           (max-width (seq-max (seq-map #'length namespaces))))
      (when (> number-of-namespaces 0)
        (emidje-outline-section (format "** Checked namespaces (%d)" number-of-namespaces)
          (dolist (namespace namespaces)
            (cider-propertize-region `(file ,(file-path-for namespace))
              (cider-insert (format (concat "%-" (number-to-string max-width) "s ") namespace) 'ns)
              (insert (if (ns-passed-p namespace)
                          (cider-propertize "passed" 'success)
                        (cider-propertize "failed" 'failure)) ?\n))))
        (insert ?\n)))))

(defun emidje-render-test-summary-section (summary)
  "Render the test SUMMARY in the current buffer's position."
  (nrepl-dbind-response summary (check error fact fail finished-in pass to-do)
    (cider-insert "** Test summary" 'bold t)
    (insert (format "Finished in %s\n" finished-in))
    (insert (format "Ran %d checks in %d facts\n" check fact))
    (unless (zerop fail)
      (cider-insert (format "%d failures" fail) 'emidje-failure t))
    (unless (zerop error)
      (cider-insert (format "%d errors" error) 'emidje-error t))
    (unless (zerop to-do)
      (cider-insert (format "%d to do" to-do) 'emidje-work-todo t))
    (when (zerop (+ fail error))
      (cider-insert (format "%d passed" pass) 'emidje-success t))
    (insert "\n")))

(defun emidje-kill-test-report-buffer ()
  "Kill the test report buffer if one exists."
  (when-let ((buffer (get-buffer emidje-test-report-buffer)))
    (kill-buffer buffer)))

(defun emidje-tests-passed-p (summary)
  "Return t if every test passed.
SUMMARY is a dict containing test counters."
  (nrepl-dbind-response summary (fail error)
    (zerop (+ fail error))))

(defun emidje-show-test-report-p (request summary)
  "Return t if the test report should be rendered.

REQUEST is a list containing the parameters sent to the nREPL
middleware.  SUMMARY is a `nrepl-dict' with test counters."
  (or emidje-always-show-test-report
      (seq-contains request 'profile?)
      (not (emidje-tests-passed-p summary))))

(defun emidje-render-test-report (op-alias request response)
  "Render the test report if applicable.

OP-ALIAS is a keyword that represents the current test
operation.  REQUEST is a list containing the parameters sent to
the nREPL middleware and RESPONSE a `nrepl-dict' containing the
information returned by the same."
  (nrepl-dbind-response response (results profile summary)
    (if (not (emidje-show-test-report-p request summary))
        (emidje-kill-test-report-buffer)
      (with-current-buffer (or (get-buffer emidje-test-report-buffer)
                               (cider-popup-buffer emidje-test-report-buffer t))
        (emidje-report-mode)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (cider-insert "Test report" 'bold t "\n")
          (when (seq-contains `(:ns :project) op-alias)
            (emidje-render-checked-namespaces-section results))
          (emidje-render-test-summary-section summary)
          (when profile
            (emidje-render-profile-section profile))
          (when (not (emidje-tests-passed-p summary))
            (emidje-render-test-results-section results))
          (goto-char (point-min)))))))

(defun emidje-summarize-test-results (op-alias namespace summary)
  "Return a string summarizing test results according to user's preferences.
OP-ALIAS is a keyword describing the current test operation.
NAMESPACE is the ns under test (only relevant when OP-ALIAS is `:ns').
SUMMARY is a dict containing test counters."
  (nrepl-dbind-response summary (check fact error fail finished-in pass to-do)
    (let ((possible-test-ns (if (equal op-alias :ns)
                                (format "%s: " namespace)
                              ""))
          (possible-future-facts (if (zerop to-do)
                                     ""
                                   (format ", %d to do" to-do))))
      (cond
       (emidje-show-full-test-summary (format "%sRan %d checks in %d facts (%s). %d failures, %d errors%s." possible-test-ns check fact finished-in fail error possible-future-facts))
       ((zerop (+ error fail)) (format "All checks (%d) succeeded." check))
       (t (format "%d checks failed, but %d succeeded." (+ error fail) pass))))))

(defun emidje-echo-test-summary (op-alias namespace summary)
  "Show a test summary on the echo area.
OP-ALIAS is a keyword describing the current test operation.
NAMESPACE is the ns under test (only relevant when OP-ALIAS is `:ns').
SUMMARY is a dict containing test counters."
  (nrepl-dbind-response summary (check fail error)
    (if (and (zerop check) (zerop error))
        (message (propertize "No facts were checked. Is that what you wanted?"
                             'face 'emidje-error))
      (let ((face (cond
                   ((not (zerop error)) 'emidje-error)
                   ((not (zerop fail)) 'emidje-failure)
                   (t 'emidje-success))))
        (message (propertize
                  (emidje-summarize-test-results op-alias namespace summary) 'face face))))))

(defun emidje-read-test-description-at-point ()
  "Return the fact description at point if one exists."
  (ignore-errors
    (save-excursion (down-list)
                    (forward-sexp 2)
                    (let ((possible-description (sexp-at-point)))
                      (if (stringp possible-description)
                          (format "\"%s\" " possible-description)
                        "")))))

(defun emidje-echo-running-tests (op-alias args)
  "Show a message indicating that a test suite will run.
OP-ALIAS is a keyword describing the current test operation.
ARGS is an alist of parameters that will be sent in the nREPL request."
  (let* ((ns (plist-get args 'ns))
         (test-path (car (plist-get args 'test-paths)))
         (test-description (emidje-read-test-description-at-point)))
    (pcase op-alias
      (:project (message "Running tests in %s..." (if test-path (concat "the " (cider-propertize test-path 'bold) " directory") "all project namespaces")))
      (:ns (message "Running tests in %s..." (cider-propertize ns 'ns)))
      (:test-at-point (message "Running test %sin %s..." (cider-propertize test-description 'bold) (cider-propertize ns 'ns)))
      (      :retest (message "Re-running non-passing tests...")))))

(defun emidje-send-test-request (op-alias &optional request)
  "Send the test request to nREPL middleware.
Show the test report if applicable.  OP-ALIAS is a keyword
describing the desired test operation (see
`emidje-supported-operations').  REQUEST is a list of parameters
to be sent to nREPL middleware."
  (emidje-echo-running-tests op-alias request)
  (emidje-send-request op-alias request
                       (lambda (response)
                         (nrepl-dbind-response response (results summary)
                           (when (and results summary)
                             (emidje-echo-test-summary op-alias (plist-get request 'ns) summary)
                             (emidje-render-test-report op-alias request response))))))

(defun emidje-select-test-path (_ value)
  "Prompt user for selecting a test path.
This function is meant to be used as a reader in Magit popups (for more
details see `magit-define-popup-option').  VALUE is a list
containing the previous selected value or nil if the option
hasn't been set yet."
  (let* ((test-paths (nrepl-dict-get (emidje-send-request :test-paths) "test-paths")))
    (list (ido-completing-read "Select a test path: "
                               test-paths nil t (car value)))))

(defun emidje-read-list-from-popup-option (name value)
  "Read values from minibuffer and return them as a list.
This function is meant to be used as an option reader in Magit
popups.  For more details see `magit-define-popup-option'.

NAME is the option name and VALUE is the value set previously if
any."
  (split-string (read-from-minibuffer name
                                      (when value
                                        (string-join value " ")))
                "\s+"))

(defun emidje-parse-popup-args (args)
  "Parse Magit popup arguments and convert them to a list.
ARGS is a list containing options and/or switches produced by
`magit-define-popup'.  Returns a list of key and values that can
be sent as request parameters to nREPL."
  (cl-flet* ((parse-switch (switch-name)
                           (list switch-name "true" ))
             (parse-value (value)
                          (let ((value (car (read-from-string value))))
                            (cond
                             ((symbolp value) (symbol-name value))
                             ((seqp value) (seq-map #'symbol-name value))
                             (t value))))
             (parse-option (option-name value)
                           (list option-name
                                 (parse-value value)))
             (parse-arg (arg)
                        (let* ((parts (split-string arg "="))
                               (name (intern (car parts))))
                          (if (= (length parts) 1)
                              (parse-switch name)
                            (parse-option name (car (cdr parts)))))))
    (seq-reduce (lambda (results arg)
                  (seq-concatenate 'list results (parse-arg arg)))
                args (list))))

(defun emidje-run-all-tests (&optional args)
  "Run facts defined in all project namespaces.
ARGS is a list containing key and values that will be sent as
additional options to the nREPL middleware in order to customize
the test execution.  Users may call this function interactively
through `emidje-run-all-tests-popup' since it provides a Magit
popup to set supported options in a more convenient way."
  (interactive (list (emidje-parse-popup-args (emidje-run-all-tests-arguments))))
  (emidje-send-test-request :project args))

(magit-define-popup emidje-run-all-tests-popup
  "Popup console for `emidje-run-all-tests' command."
  :switches '((?p "Enable profiling of tests and list slowest ones" "profile?"))
  :options '("Options for filtering tests"
             (?e "Exclude namespaces that match these regexes" "ns-exclusions=" emidje-read-list-from-popup-option)
             (?i "Run only tests in namespaces that match these regexes" "ns-inclusions=" emidje-read-list-from-popup-option)
             (?E "Exclude tests that have these keywords in their meta" "test-exclusions=" emidje-read-list-from-popup-option)
             (?I "Run only tests that have these keywords in their meta" "test-inclusions=" emidje-read-list-from-popup-option)
             (?t "List of directories containing tests" "test-paths="  emidje-select-test-path)
             "Options for profiling tests"
             (?s "Number of slowest tests" "slowest-tests="))
  :actions '((?R "Run tests" emidje-run-all-tests())))

(defun emidje-current-test-ns ()
  "Return the test namespace that corresponds to the current Clojure namespace context."
  (let ((current-ns (cider-current-ns t)))
    (if (string-equal current-ns "user")
        (user-error "No namespace to be tested in the current context")
      (funcall emidje-infer-test-ns-function current-ns))))

(defun emidje-run-tests-in-current-ns ()
  "Run facts in the current namespace context."
  (let ((ns (emidje-current-test-ns)))
    (emidje-send-test-request :ns `(ns ,ns))))

(defun emidje-select-test-ns (callback)
  "Prompt user for selecting a test namespace.
CALLBACK is a function that will be called with the selected
namespace as its sole argument."
  (emidje-send-request :test-namespaces `() (lambda (response)
                                              (nrepl-dbind-response response (test-namespaces)
                                                (when test-namespaces
                                                  (funcall callback (ido-completing-read "Select a namespace: "
                                                                                         test-namespaces nil t)))))))

(defun emidje-run-ns-tests (&optional select-ns)
  "Run all facts in the current Clojure namespace context.
When called interactively with the prefix argument SELECT-NS,
prompts the user for selecting a test namespace."
  (interactive "P")
  (if (not select-ns)
      (emidje-run-tests-in-current-ns)
    (emidje-select-test-ns (lambda (ns)
                             (emidje-send-test-request :ns `(ns ,ns))))))

(defun emidje-run-test-at-point ()
  "Run test at point.
Test means facts, fact, tabular or any Clojure form containing any of those."
  (interactive)
  (let* ((ns (cider-current-ns t))
         (sexp (cider-sexp-at-point))
         (line-number (line-number-at-pos)))
    (emidje-send-test-request :test-at-point `(ns ,ns
                                                  source ,sexp
                                                  line ,line-number))))

(defun emidje-re-run-non-passing-tests ()
  "Re-run facts that didn't pass in the last execution."
  (interactive)
  (emidje-send-test-request :retest))

(defun emidje-show-test-report ()
  "Show the test report buffer, if one exists."
  (interactive)
  (if-let (test-report-buffer (get-buffer emidje-test-report-buffer))
      (switch-to-buffer test-report-buffer)
    (user-error "No test report buffer")))

(defun emidje-send-format-request (sexpr)
  "Send a format request with the specified SEXPR to nREPL middleware.
Return the formatted sexpr."
  (thread-first
      (emidje-send-request :format-tabular `(code ,sexpr))
    (nrepl-dict-get "formatted-code")))

(defun emidje-format-tabular ()
  "Format tabular fact at point."
  (interactive)
  (save-excursion
    (mark-sexp)
    (cider--format-region (region-beginning) (region-end) #'emidje-send-format-request)))

(defun emidje-instrumented-nrepl-send-request (original-function request &rest args)
  "Instrument nrepl functions by appending the parameter load-tests? to request.
ORIGINAL-FUNCTION is either `nrepl-send-request' or
`nrepl-send-sync-request' functions.  REQUEST is the request list
that will be sent to nREPL server.  ARGS are other arguments
taken by aforementioned functions."
  (let* ((op (thread-last request
               (seq-drop-while (lambda (candidate)
                                 (not (equal candidate "op"))))
               cdr
               car))
         (request (if (and emidje-load-facts-on-eval (seq-contains emidje-evaluation-operations op))
                      (append request `("load-tests?" "true"))
                    request)))
    (apply original-function request args)))

;; Adivice functions
(advice-add'nrepl-send-request :around #'emidje-instrumented-nrepl-send-request)
(advice-add 'nrepl-send-sync-request :around #'emidje-instrumented-nrepl-send-request)

(defun emidje-toggle-load-facts-on-eval (&optional globally)
  "Toggle the value of `emidje-load-facts-on-eval'.
When called with the interactive prefix argument GLOBALLY,
toggles the default value of this variable on all buffers."
  (interactive "P")
  (let ((switch (not emidje-load-facts-on-eval)))
    (if globally
        (setq-default emidje-load-facts-on-eval switch)
      (progn (make-local-variable 'emidje-load-facts-on-eval)
             (setq emidje-load-facts-on-eval switch)))
    (message "Turned %s %s %s"
             (if switch "on" "off")
             'emidje-load-facts-on-eval
             (if globally "globally" "locally"))))

(defun emidje-search-test-result-change (position search-function predicate-function)
  "Recursively search the next or previous change of text property `type'.
POSITION is the current point's position.  SEARCH-FUNCTION is
either `next-single-property-change' or
`previous-single-property-change'.  PREDICATE-FUNCTION is a one
argument function that returns t when the value of `type' matches
some criteria."
  (let* ((position (funcall search-function position 'type))
         (test-result-type (when position
                             (get-text-property position 'type))))
    (cond
     ((not test-result-type) nil)
     ((funcall predicate-function test-result-type) position)
     (t (emidje-search-test-result-change position search-function predicate-function)))))

(defun emidje-move-point-to (direction test-result-type &optional friendly-result-name)
  "Move point across results in the test report buffer.
DIRECTION is the symbol 'next or 'previous.  TEST-RESULT-TYPE is
a symbol indicating the type in question (e.g. 'error, 'fail or
'result meaning any of those).  FRIENDLY-RESULT-NAME is an
optional string that will be used in error messages."
  (with-current-buffer (get-buffer emidje-test-report-buffer)
    (let* ((search-function (if (equal direction 'next) #'next-single-property-change #'previous-single-property-change))
           (predicate-function (if (equal test-result-type 'result) (apply-partially 'identity) (apply-partially 'equal (symbol-name test-result-type))))
           (position (emidje-search-test-result-change (point) search-function predicate-function)))
      (if position
          (goto-char position)
        (user-error "No %s %s in the test report" direction (or friendly-result-name test-result-type))))))

(defun emidje-next-result ()
  "Go to next test result in the test report buffer."
  (interactive)
  (emidje-move-point-to 'next 'result))

(defun emidje-previous-result ()
  "Go to previous test result in the test report buffer."
  (interactive)
  (emidje-move-point-to 'previous 'result))

(defun emidje-next-error ()
  "Go to next test error in the test report buffer."
  (interactive)
  (emidje-move-point-to 'next 'error))

(defun emidje-previous-error ()
  "Go to previous test error in the test report buffer."
  (interactive)
  (emidje-move-point-to 'previous 'error))

(defun emidje-next-failure ()
  "Go to next test failure in the test report buffer."
  (interactive)
  (emidje-move-point-to 'next 'fail "failure"))

(defun emidje-previous-failure ()
  "Go to previous test failure in the test report buffer."
  (interactive)
  (emidje-move-point-to 'previous 'fail "failure"))

(defun emidje-jump-to-definition (&optional other-window)
  "Jump to definition of namespace or test result at point.
If called interactively with the prefix argument `OTHER-WINDOW', visit the file in question in a new window."
  (interactive "p")
  (let* ((file (or (get-text-property (point) 'file)
                   (user-error "Nothing to be visited here")))
         (line (or (get-text-property (point) 'line) 1))
         (buffer (cider--find-buffer-for-file file)))
    (if buffer
        (cider-jump-to buffer (cons line 1) other-window)
      (error "No source location"))))

(defun emidje-show-test-stacktrace-at (ns index)
  "Show the stacktrace for the error whose location within the report map is given by the NS and INDEX."
  (let ((causes (list)))
    (emidje-send-request :test-stacktrace `(ns ,ns
                                               index ,index
                                               print-fn "clojure.lang/println")
                         (lambda (response)
                           (nrepl-dbind-response response (class status)
                             (cond (class  (setq causes (cons response causes)))
                                   (status (when causes
                                             (emidje-render-stacktrace (reverse causes))))))))))

(defun emidje-show-test-stacktrace ()
  "Show the stacktrace for the erring test at point."
  (interactive)
  (let ((ns    (get-text-property (point) 'ns))
        (index (get-text-property (point) 'index))
        (error (get-text-property (point) 'error)))
    (if (and error ns index)
        (emidje-show-test-stacktrace-at ns index)
      (user-error "No test error at point"))))

(defvar emidje-report-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "e") #'emidje-show-test-stacktrace)
    (define-key map (kbd "RET") #'emidje-jump-to-definition)
    (define-key map (kbd "M-.") #'emidje-jump-to-definition)
    (define-key map (kbd "TAB") #'org-cycle)
    (define-key map (kbd "<backtab>") #'org-shifttab)
    (define-key map (kbd "n r") #'emidje-next-result)
    (define-key map (kbd "p r") #'emidje-previous-result)
    (define-key map (kbd "n e") #'emidje-next-error)
    (define-key map (kbd "p e") #'emidje-previous-error)
    (define-key map (kbd "n f") #'emidje-next-failure)
    (define-key map (kbd "p f") #'emidje-previous-failure)
    (define-key map (kbd "n h") #'outline-next-heading)
    (define-key map (kbd "p h") #'outline-previous-heading)
    map))

(defvar emidje-commands-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-j f") #'emidje-format-tabular)
    (define-key map (kbd "C-c C-j p") #'emidje-run-all-tests)
    (define-key map (kbd "C-c C-j P") #'emidje-run-all-tests-popup)
    (define-key map (kbd "C-c C-j n") #'emidje-run-ns-tests)
    (define-key map (kbd "C-c C-j t") #'emidje-run-test-at-point)
    (define-key map (kbd "C-c C-j r") #'emidje-re-run-non-passing-tests)
    (define-key map (kbd "C-c C-j s") #'emidje-show-test-report)
    map))

(define-derived-mode emidje-report-mode special-mode "Test Report"
  "Major mode for presenting Midje test results.

\\{emidje-report-mode-map}"
  (when cider-special-mode-truncate-lines
    (setq-local truncate-lines t))
  (setq-local electric-indent-chars nil))

;;;###autoload
(define-minor-mode emidje-mode
  "Provide a set of keybindings for interacting with Midje tests.

With a prefix argument ARG, enable emidje-mode if ARG
is positive, and disable it otherwise.  If called from Lisp,
enable the mode if ARG is omitted or nil.

\\{emidje-commands-map}"
  :lighter " emidje"
  :keymap emidje-commands-map)

;;;###autoload
(defun emidje-setup ()
  "Setup `emidje-mode' and enable the `midje-nrepl' middleware conveniently."
  (emidje-enable-nrepl-middleware)
  (add-hook 'clojure-mode-hook #'emidje-mode t)
  (add-hook 'cider-repl-mode-hook #'emidje-mode t))

(provide 'emidje)

;;; emidje.el ends here
