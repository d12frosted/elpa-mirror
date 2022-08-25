;;; ob-dart.el --- org-babel functions for Dart evaluation

;; Copyright (C) 2016 Free Software Foundation, Inc.

;; Author: Milan Zimmermann
;; Keywords: literate programming, reproducible research, emacs, org, babel, dart
;; Package-Version: 20170106.1624
;; Package-Commit: 2e463d83a3fe1c9c86f2040e0d22c06dfa49ecbf
;; Homepage: http://github.org/mzimmerm/ob-dart

;; This is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For the GNU General Public License, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;    - Currently only supports execution of Dart code that can be wrapped
;;      in Dart main() method body.
;;  Todo:
;;    - Support any valid Dart code, including class definitions and
;;      the main() method
;;    - Session support

;;; Requirements:
;; - Dart language installed - An implementation can be downloaded from
;;                             https://www.dartlang.org/downloads/
;; - The dart executable is on the PATH 
;; - (Optional) Dart major mode -  Can be installed from MELPA

;; Notes:
;;   - Code follows / inspired by these previously supported org-languages,
;;     roughly in this order:
;;     - ob-io.el
;;     - ob-scala.el
;;     - ob-groovy.el
;;     - ob-R.el
;;     - ob-python.el

;;; Code:

(require 'ob)
(eval-when-compile (require 'cl))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("dart" . "dart"))
(defvar org-babel-default-header-args:dart '())
(defvar org-babel-dart-command "dart"
  "Name of the command to use for executing Dart code. todo - Windows")

(defun org-babel-execute:dart (body params)
  "
Execute a block of Dart code with org-babel.  This function is
called by `org-babel-execute-src-block'

Args:
  BODY   - String - Dart code from org file, between #+begin_src and #+end_src
                  - should be named: dart-src
  PARAMS - List   - Org parameters after #+begin_src and #+end_src
                  - todo - document better, is this correct?
"
  (message "executing Dart source code block")
  (let* ((processed-params (org-babel-process-params params))
         (session (org-babel-dart-initiate-session (nth 0 processed-params)))
         (vars (nth 1 processed-params))
         (result-params (nth 2 processed-params))
         (result-type (cdr (assoc :result-type params)))
         (full-body (org-babel-expand-body:generic
                     body params))
         (result (org-babel-dart-evaluate
                  session full-body result-type result-params)))

    (org-babel-reassemble-table
     result
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))


(defun org-babel-dart-table-or-string (results)
  "
Convert RESULTS into an appropriate elisp value.

The default core implementation org-babel-script-escape behaves as follows:
  - If RESULTS look like a table (grouped using () or {} or [] and delimited by comme), 
     then convert them into an Emacs-lisp table (list of lists), 
  - otherwise return the results unchanged as a string.

Args:
  RESULTS - String - String resulting from Dart invocation, and printed to stdio
                     by stdout.write() or print()
"
  (org-babel-script-escape results))

;; Variable which returns Dart code in String.
;;
;; The Dart code wraps Dart source between the org document's  #+begin_src and #+end_src,
;;   in a Dart main() method. There are some added runZoned() tricks to either use
;;   the printed strings or returned value as results of the #+begin_src and #+end_src
;;   code.
;; 
;; The above behaviour is controlled by an argument passed from elisp
;;   to the during 'org-babel-eval dart-code argument'.
;;
;; In particular, if the passed argument (named results_collection_type in code) is:
;;   - "output":
;;     - Strings from Dart print() is send to the standart output,
;;       and becomes the result 
;;   - "value":
;;     - Value of the last statement converted to String  is send to the standart output,
;;       and becomes the result.

(defvar org-babel-dart-wrapper-method

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
  
}
"
  )


(defun org-babel-dart-evaluate
    (session body &optional result-type result-params)
  "
Evaluate BODY in external Dart process.
If RESULT-TYPE equals 'output then return standard output as a string.
If RESULT-TYPE equals 'value then return the value of the last statement
in BODY as elisp.

Args:
  SESSION       - TODO DOCUMENT
  BODY          - String from org file, between #+begin_src and #+end_src
                  - should be named: dart-src
  RESULT-TYPE   - Symbol with value (output|value) that follows #+begin_src :results TODO DOCUMENT 
                  - should be named: results-collection - Symbol - (output|value) -
  RESULT-PARAMS - Symbol TODO DOCUMENT likely the 'format' type from docs
                  - should be named: results-format
"
  (when session (error "Session is not (yet) supported for Dart."))
  
  (let* ((src-file (org-babel-temp-file "dart-"))
         (wrapper (format org-babel-dart-wrapper-method body)))
    
    (with-temp-file src-file (insert wrapper))
    (let ((raw (org-babel-eval
                (concat org-babel-dart-command " " src-file " " (symbol-name result-type)) "")))
      ;; result-type: both 'value and 'output formats results as table, unless raw is specified
      (org-babel-result-cond result-params
        raw
        (org-babel-dart-table-or-string raw)))))

(defun org-babel-prep-session:dart (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "Session is not (yet) supported for Dart."))

(defun org-babel-dart-initiate-session (&optional session)
  "
If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session.  Sessions are not
supported in Dart.
"
  nil)

(provide 'ob-dart)

;;; ob-dart.el ends here
