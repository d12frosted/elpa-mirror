;;; ob-dart.el --- Evaluate Dart source blocks in org-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Free Software Foundation, Inc.

;; Author: Milan Zimmermann
;; Maintainer: Milan Zimmermann
;; Created: July 7, 2016
;; Modified: Dec 1, 2022
;; Version: 2.0.0
;; Package-Version: 20221201.633
;; Package-Commit: f6d5664d5cc8b15e002f6899f8adedcb10ced5f1
;; Keywords: languages
;; Homepage: http://github.org/mzimmerm/ob-dart
;; Package-Requires: ((emacs "24.4"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;    - See README.org for features, including features added in Version 2.0.0.
;;
;;  Todo:
;;    - Support variable passing from Babel header :var to code.
;;    - Support :results value also when Babel source block contains main().
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
;(use-package 'f)

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
         (vars (nth 1 processed-params))
         (result-params (nth 2 processed-params))
         (result-type (cdr (assoc :result-type params)))
         (full-body (org-babel-expand-body:generic
                     body params))
         ;; ob-dart-evaluate is the core function, which
         ;;   - generates dart code from `body' wrapped in `ob-dart-wrapper'
         ;;   - calls the generated dart code in shell
         ;;   - processes the shell's stdout and stderr
         (result (ob-dart-evaluate
                  session full-body result-type result-params)))

    (org-babel-reassemble-table
     result
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))


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
  RESULT-PARAMS - Symbol likely the `format' type from docs
                  - should be named: results-format."
  (when session (error "Session is not (yet) supported for Dart"))

  ;; Set the name generated-filename='generated-filename=/tmp/dart-RAND.dart'
  (let* ((generated-filename (org-babel-temp-file "dart-")))
    
    ;; Create 'temp-file' named 'generated-filename',
    ;;   and insert into it the Dart code generated from body.

    (ob-dart-write-dart-file-from body generated-filename)

    ;; In this section below, we call 'org-babel-eval'.
    ;; The 'org-babel-eval' runs the first arg 'command' by delegating
    ;;   the run to 'org-babel--shell-command-on-region'.
    ;; The region is in the "current buffer", which is the 'temp-buffer'
    ;;   created as the "current buffer". The 'temp-buffer' is the buffer where
    ;;   everything in the 'org-babel--shell-command-on-region' runs, see below.
    ;; The 'temp-buffer' is populated with the
    ;;   second arg QUERY (we set QUERY to "", so only 'command' runs)
    ;; We do build the 'command' below as a string
    ;;   concat of 'org-babel-dart-command' => dart and the 'generated-filename';
    ;;   this creates a string which, if executed,
    ;;   runs OS process as "dart generated-filename".
    ;; The 'generated-filename=/tmp/dart-RAND.dart' was named above using
    ;;   'org-babel-temp-file'. The 'generated-filename' contains the BEGIN_SRC..END_SRC.
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

    ;; Run org-babel-eval, a shell process that calls dart on the generated-filename.
    (let ((raw (org-babel-eval
                (concat ob-dart-command " " generated-filename " " (symbol-name result-type)) "")))
      ;; result-type: both 'value and 'output formats results as table, unless raw is specified
      (org-babel-result-cond result-params
        raw
        (ob-dart-table-or-string raw)))))

(defun ob-dart-write-dart-file-from (body generated-filename)
  "From BODY, create the Dart code to run, and save it in GENERATED-FILENAME."
  (let*
      ;; Split body into parts, and form the `generated-dart-str'
      ((parts (ob-dart-split-body-depending-on-structure body))
       (wrapper (nth 0 parts))        ;; ob-dart-wrapper or "%s"
       (body-part-top (nth 1 parts))  ;; ob-dart-wrapper-imports or "import dart:async"
       (body-part-main (nth 2 parts)) ;; part of body with main code or full body
       (generated-dart-str (ob-dart-generate-dart-full-code-from
                            body-part-top
                            wrapper
                            body-part-main)))
    ;;(f-write-text
    ;; generated-dart-str
    ;; 'utf-8
    ;; generated-filename)

    (with-temp-file
        generated-filename
      (insert generated-dart-str))))

(defun ob-dart-split-body-depending-on-structure (body)
  "Split the passed BODY into BODY-PART-TOP and BODY-PART-MAIN.

Return a list with WRAPPER, the BODY-PART-TOP and BODY-PART-MAIN
which were split from BODY.

The result of the split depends on the BODY structure (presence of main).

The WRAPPER is either the standard ob-dart wrapper, or `%s'
depending on the BODY structure.

Comments:

1. The parts which are split from BLOCK are:
   - BODY-PART-TOP  = imports, top classes, top functions.
                      Never wrapped.
   - BODY-PART-MAIN = if the main exists, the contents of the main,
                      otherwise BLOCK except imports, top classes,
                      top functions.  Caller wrap it in WRAPPER,
                      or it becomes the WRAPPER.

2. We assume that any supported structure of the Org Babel Dart source block
can be split into 2 parts, then processed with a common wrapper
to generate the Dart source that is executed.

3. The WRAPPER contains format symbols as %s, where block parts are inserted.
Currently only BODY-PART-MAIN is inserted.

4. If main function exists in BODY:
    - the BODY effectively becomes the generated Dart code
      by returning  `%s' in WRAPPER
    - only  `:results output` is supported
   Else main function does not exist in BODY:
    -  WRAPPER is either the standard ob-dart wrapper
    - `:results output' and `:results value' are supported"

  (let* (
         (main-function-line-index (string-match "^ *\\([A-z0-9_<>]*\\) *main *(.*" body)))

    (if main-function-line-index
        ;; If main function exists in body,
        ;;   ob-dart uses this Org Babel souce block unchanged,
        ;;   with imports and all code.
        ;; Only :results output are supported in this branch.
        ;; Dart code is  "import 'dart:async';\n", appended with body.
        ;; The wrapper becomes "%s", effectively becomes the body.

        (list "%s" "import 'dart:async';\n" body)
      ;; main function NOT in body, passed wrapper MUST be ob-dart-wrapper
      (list ob-dart-wrapper ob-dart-wrapper-imports body))))

(defun ob-dart-generate-dart-full-code-from (body-part-top wrapper body-part-main)
  "Create and return full Dart code as string from Org Babel source block.

The created string starts with unchanged string BODY-PART-TOP,
appended with WRAPPER string which contains format symbols as %s, %w, %a.
The WRAPPER is inserted with contents of format-specs at appropriate symbols,
and BODY-PART-MAIN at WRAPPER's symbol %s.

The wrapper can be just `%s' then the BODY-PART-MAIN
becomes the WRAPPER, and is appended after BODY-PART-TOP.

Comments:

This method functions the same irrespective whether the
full source block body contained the Dart `main()' method or not.

Assumes the passed BODY-PART-TOP and BODY-PART-MAIN were extracted
from the Org Babel Dart full source block,

The logic of splitting the  source block body into
BODY-PART-TOP and BODY-PART-MAIN depends on whether the
source block body contained the Dart `main()' method or not
is not part of this method."
  (concat
   body-part-top
   (format-spec
    wrapper
    `((?a . "async ") (?w . "await ") (?s . ,body-part-main))
                                        ; ignore missing symbols %a in wrapper
    nil
                                        ; split to list
    nil)))


(defvar ob-dart-wrapper-imports
  "
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';

import 'dart:io';
import 'dart:isolate';

import 'dart:math';
import 'dart:mirrors';
"
"Documentation: Variable which returns Dart wrapper imports as String.

Created from wrapper-imports.drap.

Used when the Dart snippet in Org source block
does NOT contain a `main' method.  See ob-dart-wrapper."
  )

(defvar ob-dart-wrapper
  "
/// Helper class allows to run Dart code in Org Babel source block.
/// This is a test version which is eventually embedded in elisp ob-dart.el
/// as `ob-dart-wrapper`.
class Gen {
  /// Wrapped code from the org file:
  ///   if org file has NO MAIN, code is from between #+begin_src and #+end_src.
  ///   if org file has MAIN,    code is copied from main.
  /// Either way, async is added if the code block contains await.
  /// That is theory: for files with MAIN, we add async here if the main is async. 
  runBlock(List args) %a {
    //   - Org code block from begin_src .. end_src inserted here by elisp format.
    //   - See `ob-dart-wrapper` and `format-spec` in wrap-body.esh and ob-dart.el
    %s
  }

  /// Run the potentially async block asynchronously, and mark this method async,
  ///   for caller to wait at the point we need the result - just before the [print]
  ///   in the flow.
  ///
  /// See the [runBlockResultsValue] for description how the async propagation
  /// and await-ing result just before print.
  runBlockResultsOutput(List args) %a {
    runBlock(args);
  }

  /// Runs the BEGIN_SRC .. END_SRC source block.
  ///
  /// Uses [ZoneSpecification] to skip the print to stdout,
  /// then return the value of the last expression
  /// of the source block, which MUST have an explicit 'return' such as:
  ///
  ///   `return returnedValue;`
  ///
  /// Should be invoked in the branch of
  ///    'results_collection_type == 'value'',
  /// where a [returnedValue.toString()] is called.
  ///
  /// The [returnedValue.toString] result pops up in elisp code
  /// in the 'ob-dart.el' function
  ///    'org-babel-dart-evaluate'.
  /// This function parses and manipulates the [returnedValue.toString] returned from here.
  ///
  /// The elisp parsing and manipulation of the [returnedValue.toString] in
  /// the 'org-babel-dart-evaluate' depends on the parameters passed in
  ///    `:results [output|value] [raw]`
  /// for example, for:
  ///   - [value raw] there is no parsing or manipulation of the result.
  ///   - [value]     converts the [returnedValue.toString] to table if the string
  ///                 looks like a table (grouped using () or {} or [], delimited by comma),
  ///                 otherwise behaves as [value raw].
  ///   - [output raw] and [output] just return the [returnedValue.toString]
  /// So, most situations, the [returnedValue.toString] shows up in
  /// the org RESULTS block.
  ///
  ///
  /// Note: ASYNC DECLARATION IS NOT REQUIRED TO BE PROPAGATED AND MARKED ON CALLER.
  ///         BUT AWAIT CALL MUST BE MARKED ASYNC ON CALLER.
  ///
  ///       In other words, a call to async method:
  ///           1. 'await-marked     async method call MUST mark caller async'
  ///           2. 'await-non-marked async method call has CHOICE to mark caller async'
  ///
  ///   What does this note mean:
  ///         Calling ASYNC `method` inside `methodCaller`, ONLY requires
  ///       to declare
  ///            `methodCaller async {...}`
  ///        if we use await on method call:
  ///             `await method();`
  ///
  ///        - If caller calls `await method()`, flow waits at this point.
  ///        - Otherwise, caller calls `method():`
  ///             the flow continues TO CALLERS, WHO NEVER AGAIN
  ///             ARE REQUIRED to AWAIT OR DECLARE ASYNC.
  ///             THE DISADVANTAGE OF THE 'Otherwise' IS THE
  ///             FLOW CONTINUES, AND THE 'AWAIT' MAY NOT FINISH UNTIL
  ///             AFTER THE PROGRAM FINISHES. THAT MEANS, WHATEVER
  ///             RESULT WAS EXPECTED FROM THE LOWEST LEVEL ASYNC FUNCTION,
  ///             WILL BE NULL.
  ///
  ///  Continue flow after the call to async `runBlock`,
  ///  without wait to caller(s).
  ///
  ///   The [runBlock] runs async,
  ///  but BEFORE WE PRINT IN CALLER, this thread WAITs, making async to resolve
  ///  the future [runBlock] returnedValue BACK INTO this FLOW (THREAD) before print.
 runBlockResultsValue(List args) %a {
    var returnedValue;
    /// Runs it's [body], the function in the first argument,
    /// in a new [Zone], based on [ZoneSpecification].
    ///
    /// The [ZoneSpecification] is defined such that any [print] statement
    /// in the [body] is ignored.
    runZoned(() {
      // If we used 'await runBlock()', we would also be forced to 'runZoned(() async {'.
      // Even if this code did not propagate the above async up to runBlockResultsValue(),
      // or further, the 'await runBlock()' causes to wait here,
      // but the code flow continue,
      // This means, that the async operation immediately reaches the caller
      //    print('${ Gen().runBlockResultsValue()}');
      // the [returnedValue] is not copied from it's Future,
      // by the time of print, so the print would output [null]
      // rather then the [returnedValue].
      returnedValue = runBlock(args);
    }, zoneSpecification:
        ZoneSpecification(print: (self, parent, zone, message) {
      // Ignore argument message passed to print.
      // This causes any print invocations inside runZoned
      // to do nothing.  This achieves the goals of 'result: value'
      // not printing anything to stdout
    }));

    // Return the returnedValue from 'runBlock()' .
    return returnedValue;
  }
}

 main(List args) %a {
  var results_collection_type = null;
  if (args.length > 0) {
    results_collection_type = args.elementAt(0);
  }

  if (results_collection_type == 'output') {
    // For [:results output rest], [runBlock] runs non-zoned,
    // all [print] methods execute.
    %w Gen().runBlockResultsOutput(args);
  } else if (results_collection_type == 'value') {
    // For [:results value rest] [runBlock] runs in the print-avoid zone.
    // This ignores all [print] in [runBlock].
    // The result is passed to [print] below, which is already out of
    // the zone, and prints [runBlockResultsValue] converted [toString].
    print('${ %w Gen().runBlockResultsValue(args)}');
  } else {
    throw Exception(
        'Invalid collection type in results: ${results_collection_type}. Only one of [output/value] allowed.');
  }
}
"

"Documentation: Variable which returns Dart wrapper code as String.

Created from wrapper.drap

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


(defun org-babel-prep-session:dart (_session _params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "Session is not (yet) supported for Dart"))

(defun ob-dart-initiate-session (&optional _session)
  "If there is not a current inferior-process-buffer in SESSION then create.
Return the initialized session.  Sessions are not supported in Dart."
  nil)

(provide 'ob-dart)

;;; ob-dart.el ends here
