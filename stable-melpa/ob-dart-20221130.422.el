;;; ob-dart.el --- Evaluate Dart source blocks in org-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Free Software Foundation, Inc.

;; Author: Milan Zimmermann
;; Maintainer: Milan Zimmermann
;; Created: July 7, 2016
;; Modified: May 19, 2022
;; Version: 1.0.1
;; Package-Version: 20221130.422
;; Package-Commit: 5bf2d175aae90bb2844ef8a5c2708b7938eccad4
;; Keywords: languages
;; Homepage: http://github.org/mzimmerm/ob-dart
;; Package-Requires: ((emacs "24.4"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;    - Currently only supports execution of Dart code that can be wrapped
;;      in Dart main() method body.
;;  Todo:
;;    - Support any valid Dart code, including class definitions and
;;      the main() method
;;    - Session support
;;
;;; Requirements:
;; - Dart language installed - An implementation can be downloaded from
;;                             https://www.dartlang.org/downloads/
;; - The dart executable is on the PATH
;; - (Optional) Dart major mode from MELPA
;;
;; Notes:
;;   - Code follows / inspired by these previously supported org-languages,
;;     roughly in this order:
;;     - ob-io.el
;;     - ob-scala.el
;;     - ob-groovy.el
;;     - ob-R.el
;;     - ob-python.el
;;
;;; Code:

(require 'ob)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("dart" . "dart"))
(defvar org-babel-default-header-args:dart '())
(defvar ob-dart-command "dart"
  "Name of the command to use for executing Dart code.
Windows support is pending.")

(defun org-babel-execute:dart (body params)
  "Execute a block of Dart code with org-babel.
This function is called by `org-babel-execute-src-block'.

Args:
  BODY   - String - Dart code from org file, between #+begin_src and #+end_src
  PARAMS - List   - Org Babel code block args after #+begin_src, converted
                    to plist.  Some plist values may be multi-valued,
                    for example for the key `:var', (varname varvalue)
                    from Babel args `:var varname=varvalue`,
                    or for the key `:results', (value raw)
                    from Babel args `:results value raw'."
  (message "executing Dart source code block")
  ;; (processed-params = org-babel-process-params RETURNS assoc list with slightly
  ;;     reformatted list of :param values from all elements after #+begin_src
  ;;   For example, from ':results output raw', the function creates two assoc elements,
  ;;     one is (:result-type . output), second is (:result-params . raw)
  ;;   Variables are converted to PROPERTY LIST in the result.
  ;;   Other less frequent parameters like  (:colname-names . (list names)) are cons cells.
  (let* ((processed-params (org-babel-process-params params))
         (session (ob-dart-initiate-session (nth 0 processed-params)))
         ;; (vars (nth 1 processed-params))  UNUSED?
         (result-params (nth 2 processed-params))
         (result-type (cdr (assoc :result-type params)))
         (full-body (org-babel-expand-body:generic
                     body params))
         (result (ob-dart-evaluate
                  session full-body result-type result-params)))

    (org-babel-reassemble-table
     result
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))


(defun ob-dart-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.

The default core implementation `org-babel-script-escape' behaves as follows:

If RESULTS look like a table (grouped using () or {} or [] and
delimited by commas), then convert them into an Emacs-lisp
table (list of lists),

Otherwise, return the results unchanged as a string.

Args:
  RESULTS - String - String resulting from Dart invocation, and printed to stdio
                     by stdout.write() or print()"
  (org-babel-script-escape results))


(defvar ob-dart-wrapper
  "
//import 'dart:analysis_server';
//import 'dart:analyzer';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
//import 'dart:developer';
//import 'dart:html';
//import 'dart:indexed_db';
//import 'dart:internal';
import 'dart:io';
import 'dart:isolate';
//import 'dart:js';
import 'dart:math';
import 'dart:mirrors';
//import 'dart:profiler';
//import 'dart:svg';
//import 'dart:typed_data';
//import 'dart:web_audio';
//import 'dart:web_gl';
//import 'dart:web_sql';


//// Helper class allows to run Dart code wrapped in emacs org mode
//// Also see:
////   https://gist.github.com/0e1dd60ca06369f7990d0ecfda8ed6a7
////   https://dartpad.dartlang.org/0e1dd60ca06369f7990d0ecfda8ed6a7
class Gen {

  // Wrapped code from the org file, between #+begin_src and #+end_src

  runSrc() {
    // print(\"from print - for :results output\");
    // return \"returning - for :result value\";
    // Code from begin_src .. end_src inserted here by elisp format.
    //   See (format org-babel-dart-wrapper-method body)
    %s
  }

  // run, allow print to stdout, and  ignore return value
  runSrcResultsOutput() {
    runSrc();
  }

  // run, ignore print to stdout, and use return value  (which will be printed to stdout)
  runSrcResultsValue() {
    // ignore prints to stdout
    var retval;
	  runZoned(() {
  	  retval = runSrc();
  	}, zoneSpecification: new ZoneSpecification(
    	print: (self, parent, zone, message) {
      	// Ignore argument message passed to print.
    	}));

    return retval;
  }
}

void main(List args) {

  // new Gen().runSrcResultsOutput();
  // print(\"${new Gen().runSrcResultsValue()}\");

  var results_collection_type = null;
  if (args != null && args.length > 0) {
    results_collection_type = args.elementAt(0);
  }

  if (results_collection_type == \"output\") {
  	// generate this for :results output
  	new Gen().runSrcResultsOutput();
  } else if (results_collection_type == \"value\") {
  	// generate this for :results value  (use return value and print it)
  	// this works because in Dart print inside print still goes to stdout
  	stdout.write(\"${new Gen().runSrcResultsValue()}\"); // print with no newline. Needed for
  } else {
    throw new Exception(\"Invalid collection type in results: ${results_collection_type}. Only one of [output/value] allowed.\");
  }

}"

"Documentation: Variable which returns Dart wrapper code as String.

Used when the Dart snippet in Org source block
does NOT contain a `main' method.  The returned Dart code wraps Dart
source between #+begin_src and #+end_src, into a Dart main() method.

If the passed argument to

  `org-babel-eval dart-code argument'

is:
  - `output':
    - The stdout from Dart print() in the snippet is send
      to the standart output, and becomes the #+RESULT.
  - `value':
    - The stdout from Dart print() is blocked by the `runZoned'
      method, and the `toString()' of the last `return lasExpression'
      becomes the  #+RESULT."
)

;; todo-last
;; (defvar ob-dart-with-main-snippet-wrapper
;; "todo return this"
;; "Documentation: wraps a ob-dart snippet containing main.
;; For `:results output', in does not wrap, but replaces it's contents with the
;; ob-dart snippet.
;; For `:results value' it wraps the content of main() into runZoned()."
;; )

(defun ob-dart-evaluate (session body &optional result-type result-params)
  "Evaluate BODY in external Dart process.
If RESULT-TYPE equals `output' then return standard output as a string.
If RESULT-TYPE equals `value' then return the value of the last statement
in BODY as elisp.

Args:
  SESSION       - `val' from Org source block header arg `:session val'.
                  Not supported yet.
  BODY          - String from org file, between #+begin_src and #+end_src
                  - should be named: dart-src
  RESULT-TYPE   - `val' from Org source block header argument `:results vals'.
                  `val' is one of (output|value).
                  It defaults to `value' if neither is found among `vals'.
                  - should be named: results-collection
  RESULT-PARAMS - Symbol TODO DOCUMENT likely the `format' type from docs
                  - should be named: results-format."
  (when session (error "Session is not (yet) supported for Dart"))

  ;; Set the name src-file='src-file=/tmp/dart-RAND.dart'
  (let* ((src-file (org-babel-temp-file "dart-"))
         (wrapper (format ob-dart-wrapper body)))
    
    ;; Create 'temp-file' named 'src-file',
    ;;   and insert into it the Dart code from the source block
    ;;   between BEGIN_SRC..END_SRC, wrapped in Dart code which:
    ;;      1. runs the source block
    ;;      2. 'dart:print's the source block
    ;;        'results: output' or 'results: value' to 'stdout'.
    (with-temp-file src-file (insert wrapper))

    ;; In this section below, we call 'org-babel-eval'.
    ;; The 'org-babel-eval' runs the first arg 'command' by delegating
    ;;   the run to 'org-babel--shell-command-on-region'.
    ;; The region is in the "current buffer", which is the 'temp-buffer'
    ;;   created as the "current buffer". The 'temp-buffer' is the buffer where
    ;;   everything in the 'org-babel--shell-command-on-region' runs, see below.
    ;; The 'temp-buffer' is populated with the
    ;;   second arg QUERY (we set QUERY to "", so only 'command' runs)
    ;; We do build the 'command' below as a string
    ;;   concat of 'org-babel-dart-command' => dart and the 'src-file';
    ;;   this creates a string which, if executed,
    ;;   runs OS process as "dart src-file".
    ;; The 'src-file=/tmp/dart-RAND.dart' was named above using
    ;;   'org-babel-temp-file'. The 'src-file' contains the BEGIN_SRC..END_SRC.
    ;;
    ;; In detail, the 'org-babel-eval', works like this:
    ;; 1. Lets - 'error-buffer' = " *Org-Babel Error*", creates or erases it.
    ;; 2. Creates a 'temp-buffer' ('with-temp-buffer' rest of work done here)
    ;;      where it inserts the QUERY (empty)
    ;; 3. As if cursor was put in the temp-buffer, it delegates to
    ;;        'org-babel--shell-command-on-region' 'command' 'error-buffer'
    ;;    where
    ;;        'command'='dart /tmp/dart-RAND.dart "output|value"'
    ;; 4. On success of the
    ;;      'org-babel--shell-command-on-region' 'command' 'error-buffer '
    ;;      its stdout is placed in the 'temp-buffer'
    ;;      in which context steps 3-6 run
    ;;      (temp-buffer is 'scratch' in testing).
    ;;    On error, error text is placed in the 'error-buffer'.
    ;; 5. Where are we: After step 4,
    ;;      the 'temp-buffer' contains the stdout from Dart code 'println',
    ;;      which may be:
    ;;        - either output from internal 'print' (if results: 'output')
    ;;        - or toString() on the 'return lastStatement' (results: 'value')
    ;;    See the 'org-babel-dart-wrapper-method' for Dart code that runs the .
    ;; 6. The contents of the temp-buffer is returned to caller as
    ;;      'buffer-string' ; string of the temp-buffer, stdout from Dart.
    ;;  
    ;; Note: Test this step 3. in 'scratch' as if the temp-buffer was scratch:
    ;;         - Place pointer to 'scratch' and do
    ;;         - Alt-: (org-babel--shell-command-on-region "echo Hello" "")
    ;;           this runs "echo Hello" is shell, and places
    ;;           the string Hello in 'scratch' - the 'temp-buffer'!
    ;;
    ;;
    ;;
    ;; Details of 'org-babel--shell-command-on-region' 'command' 'error-buffer'
    ;; 1. Assumes it is run when pointer is in the 'temp-buffer' created
    ;;      by caller 'org-babel-eval' - 'temp-buffer' is 'scratch' in our testing.
    ;; 2. Lets variables
    ;;      - input-file       named 'ob-input-TEMP-RAND'
    ;;      - error-file       named 'ob-error--TEMP-RAND'
    ;;      - shell-file-name  /bin/sh
    ;; 3. Copies the temp-buffer where the pointer is, to 'input-file';
    ;;      at the time this is called, the 'temp-buffer' contains the QUERY,
    ;;      which is a zero-lenght string "" in our case.
    ;; 3. Calls 'process-file' (this is like 'call-process' with args:
    ;;      (process-file
    ;;         program = shell-file-name       ; has /bin/sh
    ;;         infile  = input-file            ; has QUERY
    ;;         buffer  = has cons (t . error-file) ; see call-process
    ;;         display = nil                   ; has nil
    ;;         args1   = sh-switch             ; has probably empty
    ;;         args2   = command ; 'dart /tmp/dart-RAND.dart "output|value"'
    ;;    which calls apply on:
    ;;      call-process ; runs program synchronously in separate process
    ;;        program    = program    ; has /bin/sh
    ;;        infile     = input-file ; has QUERY - would be stdin of command
    ;;        destination=            ; has cons(t . error-file)
    ;;                                ;   how to handle program output
    ;;                                ;   t = "use current buffer for stdout"
    ;;                                ;   error-file is where strerr goes
    ;;        display                 ; has nil, means no action
    ;;        args1     = sh-switch   ; has probably empty
    ;;        args2     = command ; 'dart /tmp/dart-RAND.dart "output|value"'
    ;;         
    ;; 4. The above step 3 means:
    ;;     - Exec 'dart /tmp/dart-RAND.dart "output|value"'
    ;;     - Place stdout to current buffer (t), which is the with-temp-buff
    ;;       created by 'org-babel-eval'
    ;;     - Places stderr in the error-file viewed by the error-buffer
    ;; 
    
    (let ((raw (org-babel-eval
                (concat ob-dart-command " " src-file " " (symbol-name result-type)) "")))
      ;; result-type: both 'value and 'output formats results as table, unless raw is specified
      (org-babel-result-cond result-params
        raw
        (ob-dart-table-or-string raw)))))

(defun org-babel-prep-session:dart (_session _params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "Session is not (yet) supported for Dart"))

(defun ob-dart-initiate-session (&optional _session)
  "If there is not a current inferior-process-buffer in SESSION then create.
Return the initialized session.  Sessions are not supported in Dart."
  nil)

(provide 'ob-dart)

;;; ob-dart.el ends here
