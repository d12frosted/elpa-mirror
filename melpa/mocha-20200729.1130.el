;;; mocha.el --- Run Mocha or Jasmine tests

;; Copyright (C) 2016 Al Scott <github.com/scottaj>
;; Author: Al Scott
;; URL: http://github.com/scottaj/mocha.el
;; Package-Version: 20200729.1130
;; Package-Commit: 6a72fa20e7be6e55c09b1bc9887ee09c5df28e45
;; Created: 2016
;; Version: 1.1
;; Keywords: javascript mocha jasmine
;; Package-Requires: ((js2-mode "20150909") (f "0.18"))

;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; This mode provides the ability to run Mocha or Jasmine tests from within Emacs

;;; Code:
(require 'compile)
(require 'js2-mode)
(require 'f)

(defgroup mocha nil
  "Tools for running mocha tests."
  :group 'tools)

(defcustom mocha-which-node "node"
  "The path to the node executable to run."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defcustom mocha-command "node_modules/.bin/mocha"
  "The path to the mocha command to run."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defcustom mocha-environment-variables "FORCE_COLOR=1"
  "Environment variables to run mocha with."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defcustom mocha-options "--recursive"
  "Command line options to pass to mocha."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defcustom mocha-reporter "dot"
  "Name of reporter to use."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defcustom mocha-debugger 'realgud
  "Which debugger to use."
  :type '(choice (const :tag "realgud" realgud)
                 (const :tag "indium" indium))
  :group 'mocha
  :safe #'mocha-debugger-name-p)

(defvar mocha-debuggers
  '((realgud :must-bind realgud:nodejs :attach-fn mocha-realgud:nodejs-attach)
    (indium :must-bind indium-connect-to-nodejs :attach-fn mocha-attach-indium))
  "List of debuggers which can be attached with `mocha-debug'.
Each entry is a list of (name . props), where NAME is a symbol
that `mocha-debugger' can take on, and PROPS is a plist with two keys:

:MUST-BIND is the name of a function that is bound when the
debugger is loaded.  Before running mocha in debug mode, the
symbol is tested with `fboundp' and the debug run is aborted if
the result is nil.

:ATTACH-FN is a function to `funcall' after the debug run has
been started.  The function will be passed the following arguments:
NODE - the value of `mocha-which-node' used for the debug run.
BUF - the name of the buffer with the debug run command output.
PORT - the value of `mocha-debug-port' when the debug run was started.
MOCHA-FILENAME - the filename that `mocha-debug' was called on, if any.
TEST - the name of the test that `mocha-debug' was called on, if any.")

(defun mocha-debugger-name-p (val)
  "Return nil if VAL is an invalid debugger name."
  (assq val mocha-debuggers))

(defcustom mocha-debug-port "5858"
  "The port number to debug mocha tests at."
  :type 'string
  :group 'mocha
  :safe #'stringp)

(defun mocha-list-of-strings-p (object)
  "Return t if OBJECT is a list of strings and nil otherwise."
  (and (listp object)
       (not (memq nil (mapcar #'stringp object)))))

(defcustom mocha-test-definition-nodes '("describe" "it")
  "The names of functions used to define mocha tests or test suites."
  :type '(repeat 'string)
  :group 'mocha
  :safe #'mocha-list-of-strings-p)

(defcustom mocha-imenu-functions '("describe" "it" "beforeAll" "beforeEach" "afterAll" "afterEach")
  "Functions that create a new imenu entry at every call site."
  :type '(repeat 'string)
  :group 'mocha
  :safe #'mocha-list-of-strings-p)

(defvar mocha-project-test-directory nil)
(put 'mocha-project-test-directory 'safe-local-variable #'stringp)

(defvar node-error-regexp
  "^[  ]+at \\(?:[^\(\n]+ \(\\)?\\(\\(?:[a-zA-Z]:\\)?[a-zA-Z\.0-9_/\\-]+\\):\\([0-9]+\\):\\([0-9]+\\)\)?"
  "Regular expression to match NodeJS errors.
From http://benhollis.net/blog/2015/12/20/nodejs-stack-traces-in-emacs-compilation-mode/")

(defvar node-error-regexp-alist
  `((,node-error-regexp 1 2 3 nil 1)))

(defun mocha-compilation-filter ()
  "Filter function for compilation output."
  (ansi-color-apply-on-region compilation-filter-start (point-max))
  (save-excursion
    (while (re-search-forward "^[\\[[0-9]+[a-z]" nil t)
      (replace-match ""))))

(define-compilation-mode mocha-compilation-mode "Mocha"
  "Mocha compilation mode."
  (progn
    (set (make-local-variable 'compilation-error-regexp-alist) node-error-regexp-alist)
    (add-hook 'compilation-filter-hook 'mocha-compilation-filter nil t)
    ))

(defun mocha-find-project-root ()
  "Find the root of the project."
  (let ((root-dir (f--traverse-upwards (f-exists? (f-expand "package.json" it)))))
    (when root-dir (f-slash root-dir))))

(defun mocha-opts-file (path)
  "Return path to mocha.opts file for PATH."
  (or path (setq path default-directory))
  (let ((opts-dir
         (f--traverse-upwards
          (f-exists? (f-expand "mocha.opts" it))
          (if (f-dir? path)
              path
            (f-parent path)))))
    (when opts-dir
      (f-join opts-dir "mocha.opts"))))

(defun mocha-generate-command (debug &optional mocha-file test)
  "The test command to run.

If DEBUG is true, then make this a debug command.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (let* ((path (or mocha-file mocha-project-test-directory))
         (target (if test (concat "--fgrep '" test "' ") ""))
         (node-command (concat mocha-which-node (if debug (concat " --debug=" mocha-debug-port) "")))
         (options (concat mocha-options (if debug " -t 21600000")))
         (options (concat options (concat " --reporter " mocha-reporter)))
         (opts-file (mocha-opts-file path)))
    (when opts-file
      (setq options (concat options (if opts-file (concat " --opts " opts-file)))))
    (concat mocha-environment-variables " "
            node-command " "
            mocha-command " "
            options " "
            target
            path)))

(defun mocha-debugger-get (debugger-name prop)
  "Return the value of debugger DEBUGGER-NAME's prop PROP."
  (let ((props (assq debugger-name mocha-debuggers)))
    (unless props (error "Unknown debugger %s" debugger-name))
    (plist-get (cdr props) prop)))

(defun mocha-check-debugger ()
  "Ensure that the selected debugger is loaded."
  (let ((cmd (mocha-debugger-get mocha-debugger :must-bind)))
    (unless (and cmd (fboundp cmd))
      (user-error "%s is required to debug mocha" cmd))))

(defun mocha-debug (&optional mocha-file test)
  "Run mocha and attach a debugger.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (mocha-check-debugger)
  (save-some-buffers (not compilation-ask-about-save)
                     (when (boundp 'compilation-save-buffers-predicate)
                       compilation-save-buffers-predicate))

  (when (get-buffer "*mocha tests: debug*")
    (kill-buffer "*mocha tests: debug*"))
  (let ((test-command-to-run (mocha-generate-command t mocha-file test))
        (root-dir (mocha-find-project-root)))
    (with-current-buffer (get-buffer-create "*mocha tests: debug*")
      (setq default-directory root-dir)
      (compilation-start test-command-to-run 'mocha-compilation-mode (lambda (m) (buffer-name)))
      (funcall (mocha-debugger-get mocha-debugger :attach-fn)
               mocha-which-node (buffer-name) mocha-debug-port mocha-file test))))

(defun mocha-realgud:nodejs-attach (node buf port file test)
  "Attach `realgud:nodejs' to a running node process.
NODE, BUF, PORT, FILE, and TEST are described in
`mocha-debuggers' under :attach-fn."
  (ignore buf file test)
  (realgud:nodejs (concat node " debug localhost:" port)))

(defun mocha-attach-indium (node buf port file test)
  "Create a new `indium' connection to a running process.
NODE, BUF, PORT, FILE, and TEST are described in
`mocha-debuggers' under :attach-fn."
  (ignore node port file test)
  (with-current-buffer buf
    (sit-for 1 t)
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward (rx "Debugger listening on ws://" (group (* (not (any ":")))) ":"
                                 (group (* digit)) "/" (group (repeat 8 hex)
                                                              (repeat 4 (: "-" (repeat 4 hex)))
                                                              (repeat 8 hex))))
          (indium-connect-to-nodejs (match-string 1) (match-string 2) (match-string 3))
        (error "Did not find debugger connection details for Indium")))))

(defun mocha-run (&optional mocha-file test)
  "Run mocha in a compilation buffer.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (let ((test-command-to-run (mocha-generate-command nil mocha-file test))
        (default-directory (mocha-find-project-root))
        (compilation-buffer-name-function (lambda (_) "" "*mocha tests*")))
    (compile test-command-to-run 'mocha-compilation-mode)))

(defun mocha-walk-up-to-it (node)
  "Recursively walk up the ast from the js2-node NODE.

Stops when we find a call node named 'describe' or 'it' or reach the root.

If we find the name node we are looking for, return the first argument of the
 call node.

If we reach the root without finding what we are looking for return nil."
  (if (and (js2-node-p node) (not (js2-ast-root-p node)))
      (if (and
           ;; If the node is an expression or statement
           (js2-expr-stmt-node-p node)
           ;; And the expression is a function calL
           (js2-call-node-p (js2-expr-stmt-node-expr node))
           ;; And the call target is a name node
           (js2-name-node-p (js2-call-node-target (js2-expr-stmt-node-expr node)))
           ;; And the name of the name node is what we are looking for
           (member (js2-name-node-name (js2-call-node-target (js2-expr-stmt-node-expr node)))
                   mocha-test-definition-nodes))
          ;; Get the first argument, check it is a string and return its value
          (let ((first-arg (car (js2-call-node-args (js2-expr-stmt-node-expr node)))))
            (if (js2-string-node-p first-arg)
                (js2-string-node-value first-arg)
              nil))
        (mocha-walk-up-to-it (js2-node-parent-stmt node)))
    nil))

(defun mocha-find-current-test ()
  "Try to find the innermost 'describe' or 'it' using js2-mode.

When a 'describe' or 'it' is found, return the first argument of that call.
If js2-mode is not enabled in the buffer, returns nil.
If there is no wrapping 'describe' or 'it' found, return nil."
  (let ((node (js2-node-at-point nil t)))
    (mocha-walk-up-to-it node)))

;;;###autoload
(defun mocha-test-project ()
  "Test the current project."
  (interactive)
  (mocha-run))

;;;###autoload
(defun mocha-debug-project ()
  "Debug the current project."
  (interactive)
  (mocha-debug))

;;;###autoload
(defun mocha-test-file ()
  "Test the current file."
  (interactive)
  (mocha-run (buffer-file-name)))

;;;###autoload
(defun mocha-debug-file ()
  "Debug the current file."
  (interactive)
  (mocha-debug (buffer-file-name)))

;;;###autoload
(defun mocha-test-at-point ()
  "Test the current innermost 'it' or 'describe' or the file if none is found."
  (interactive)
  (let ((file (buffer-file-name)) (test-at-point (mocha-find-current-test)))
    (mocha-run file test-at-point)))

;;;###autoload
(defun mocha-debug-at-point ()
  "Debug the current innermost 'it' or 'describe' or the file if none is found."
  (interactive)
  (let ((file (buffer-file-name)) (test-at-point (mocha-find-current-test)))
    (mocha-debug file test-at-point)))

(defun mocha--get-callsite-name (node)
  "Return the name of a `describe' or `it' NODE."
  (let* ((first-arg (car (js2-call-node-args node)))
         (start (js2-node-abs-pos first-arg)))
    (concat
     (js2-name-node-name (js2-call-node-target node))
     " "
     (if (js2-string-node-p first-arg)
        (js2-string-node-value first-arg)
      (if first-arg
          (buffer-substring start (+ start (js2-node-len first-arg)))
        "~empty~")))))

(defun mocha-make-imenu-alist ()
  "Generate an imenu alist mirroring the mocha test suite structure."
  (when js2-mode-ast
      (let ((children-stack (list '())) callee callee-name)
        (js2-visit-ast
         js2-mode-ast
         (lambda (node end-p)
           (if (and (js2-call-node-p node)
                    (js2-name-node-p (setq callee (js2-call-node-target node)))
                    (member (setq callee-name (js2-name-node-name callee)) mocha-imenu-functions))
               (cond
                ((string= callee-name "describe")
                 (if end-p
                     (let ((my-children (nreverse (pop children-stack))))
                       (push (cons (mocha--get-callsite-name node) my-children) (car children-stack)))
                   (push (list (cons "*declaration*" (js2-node-abs-pos node))) children-stack)
                   t))
                (end-p nil)             ; We only want to visit the others once
                ((member callee-name mocha-test-definition-nodes)
                 (push (cons (mocha--get-callsite-name node) (js2-node-abs-pos node))
                       (car children-stack)))
                (t (push (cons callee-name (js2-node-abs-pos node)) (car children-stack))))
             t)))
        (nreverse (pop children-stack)))))

(defvar mocha--other-js2-imenu-function nil "Used to store the prior js2 imenu function.")

;;;###autoload
(defun mocha-toggle-imenu-function ()
  "Toggle the use mocha-specific imenu function."
  (interactive)
  (if mocha--other-js2-imenu-function
      (progn
        (setq-local imenu-create-index-function mocha--other-js2-imenu-function)
        (setq-local mocha--other-js2-imenu-function nil))
    (setq-local mocha--other-js2-imenu-function imenu-create-index-function)
    (setq-local imenu-create-index-function 'mocha-make-imenu-alist))
  ;; Flush the imenu cache
  (setq imenu--index-alist nil))

(provide 'mocha)
;;; mocha.el ends here
