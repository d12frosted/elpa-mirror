;;; with-shell-interpreter.el --- Helper for shell command APIs -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Jordan Besly
;;
;; Version: 0.2.4
;; Package-Version: 20200828.1217
;; Package-Commit: 45b7d6ad63165c82a95966b291abbfe305d3ada2
;; Keywords: processes, terminals
;; URL: https://github.com/p3r7/with-shell-interpreter
;; Package-Requires: ((emacs "25.1")(cl-lib "0.6.1"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Helper macro for Emacs shell command APIs, making implicit argument as explicit keyword arguments.
;; Provides macro `with-shell-interpreter'.
;;
;; For detailed instructions, please look at the README.md at https://github.com/p3r7/with-shell-interpreter/blob/master/README.md

;;; Code:



;; REQUIRES

(require 'cl-lib)

(require 'files-x)
(require 'shell)



;; VARS

(defvar with-shell-interpreter-connection-local-vars-implem
  'custom
  "Implementation of connection-local vars to use.
Possible values:
 - 'custom: with-shell-interpreter's implementation
 - 'native: native Emacs (>= 26.1) implementation

When 'custom, configure var
`with-shell-interpreter-connection-local-vars'.

When 'native, configure vars `connection-local-profile-alist' and
`connection-local-criteria-alist' with helper functions
`connection-local-set-profile-variables' and
`connection-local-set-profiles'.")

(defvar with-shell-interpreter-connection-local-vars
  '((".*" . ((explicit-shell-file-name . "/bin/bash")
             (explicit-bash-args . ("-c" "export EMACS=; export TERM=dumb; stty echo; bash"))
             (shell-command-switch . "-c"))))
  "Alist mapping connection path regexp to variable lists.
It aims at providing a more flexible implementation of
connection-local variables.

Order of entries matter, only first matched variables are used.
Use `add-to-list' to add entries.

It only get interpreted for remote connections.
For local connections, customize defautl values of vars:
 - `explicit-shell-file-name' / `shell-file-name'
 - `explicit-INTEPRETER-args'
 - `shell-command-switch'

To read more about the standard connection-local variables see
`with-shell-interpreter-connection-local-vars-implem'.")



;; COMPATIBILITY

;; NB: connection-local variables are only available since version 26.1
(eval-when-compile
  (if (fboundp 'hack-connection-local-variables)
      (defalias 'with-shell-interpreter--hack-connection-local-variables #'hack-connection-local-variables)
    (defalias 'with-shell-interpreter--hack-connection-local-variables (lambda (_c) nil))))

(if (fboundp 'hack-connection-local-variables)
    (defalias 'with-shell-interpreter--hack-connection-local-variables #'hack-connection-local-variables)
  (defalias 'with-shell-interpreter--hack-connection-local-variables (lambda (_c) nil)))

;; NB: only bound on Windows build of Emacs
(unless (boundp 'w32-quote-process-args)
  ;; tame lexical binding warnings
  (defvar w32-quote-process-args))



;; MAIN HELPER

(defmacro with-shell-interpreter (&rest args)
  "Eval :form at location described by :path with :interpreter binary.

ARGS are in fact keywords, `with-shell-interpreter' being a macro wrapper around
`with-shell-interpreter-eval'.  Usage:

  (with-shell-interpreter
     [:keyword [option]]...
     :form
     ;; actual code
     )

:form               Code to execute.
:path               Location from which form is executed.
                    Can be local or remote (TRAMP format).
                    Let-binds `default-directory'.
:interpreter        Name or absolute path of shell interpreter executable.
                    If only providing a name, ensure that the executable
                    is present in the PATH.
                    Let-binds `explicit-shell-file-name' and
                    `shell-file-name'.
:interpreter-args   Login args to call interpreter with for login.
                    Let-binds `explicit-INTEPRETER-args'.
                    Useful only for interactive shells.
:command-switch     Command switch arg for asking interpreter to run a
                    shell command (e.g. \"-c\" in Bourne shell and most
                    derivatives).
                    Let-binds `shell-command-switch'.
                    Useful only for single shell commands.
:w32-arg-quote      Only affecting Microsoft Windows build of Emacs.
                    Character to use for quoting arguments.
                    Let-binds `w32-quote-process-args'.
:allow-local-vars   Allow local values to have precedence over global ones
                    for:
                     - `explicit-shell-file-name'
                     - `explicit-INTEPRETER-args'
                     - `shell-command-switch'
                     - `w32-quote-process-args'
                    Value can be:
                      - 'buffer: allow buffer-local vars values
                      - 'connection: allow connection-local values
                      - 'both: allow both types of local values
                      - 'none: ignore all local values
                    Default is 'connection.

For more detailed instructions, have a look at https://github.com/p3r7/with-shell-interpreter/blob/master/README.md"
  (declare (indent 1) (debug t))
  `(with-shell-interpreter-eval
    :form (lambda () ,(cons 'progn (with-shell-interpreter--plist-get args :form)))
    :path ,(plist-get args :path)
    :interpreter ,(plist-get args :interpreter)
    :interpreter-args ,(plist-get args :interpreter-args)
    :command-switch ,(plist-get args :command-switch)
    :w32-arg-quote ,(plist-get args :w32-arg-quote)
    :allow-local-vars ,(plist-get args :allow-local-vars)))

(put 'with-shell-interpreter 'lisp-indent-function 'defun)

(cl-defun with-shell-interpreter-eval (&key form path
                                            interpreter interpreter-args command-switch
                                            w32-arg-quote
                                            allow-local-vars)
  "Same as `with-shell-interpreter' except :form has to be a quoted sexp."
  (cl-destructuring-bind (path
                          is-remote
                          allow-buffer-local-vars
                          allow-cnnx-local-vars cnnx-local-vars
                          interpreter interpreter-name
                          explicit-interpreter-args-var)
      (with-shell-interpreter--generate-props path interpreter allow-local-vars)
    (let* ((func
            (if (functionp form) form
              ;; Try to use the "current" lexical/dynamic mode for `form'.
              (eval `(lambda () ,form) lexical-binding)))
           (interpreter-args (with-shell-interpreter--interpreter-args-value is-remote explicit-interpreter-args-var
                                                                             interpreter
                                                                             allow-buffer-local-vars
                                                                             allow-cnnx-local-vars cnnx-local-vars
                                                                             interpreter-args))
           (command-switch (with-shell-interpreter--command-switch is-remote interpreter
                                                                   allow-buffer-local-vars
                                                                   allow-cnnx-local-vars cnnx-local-vars
                                                                   command-switch))
           ;; bellow are vars acting as implicit options to shell functions
           (default-directory path)
           (shell-file-name interpreter)
           (explicit-shell-file-name interpreter)
           (shell-command-switch command-switch)
           (enable-connection-local-variables nil) ; disable lookup of connection-local vars in :form
           ;; NB: w32-only feature
           (w32-quote-process-args (with-shell-interpreter--w32-quote-process-args is-remote interpreter
                                                                                   allow-buffer-local-vars
                                                                                   allow-cnnx-local-vars cnnx-local-vars
                                                                                   w32-arg-quote)))
      (cl-progv
          (list explicit-interpreter-args-var)
          (list interpreter-args)
        (funcall func)))))



;; HELPERS: STRING NORMALIZATION

(defun with-shell-interpreter--normalize-path (path)
  "Normalize PATH, converting \\ into /."
  ;; REVIEW: shouldn't we just use instead `convert-standard-filename'
  ;; or even `executable-find'?
  (subst-char-in-string ?\\ ?/ path))


(defun with-shell-interpreter--interpreter-name (interpreter)
  "Extracts INTERPRETER name, keeping extension."
  (file-name-nondirectory interpreter))



;; HELPERS: STRUCTURES

(defun with-shell-interpreter--plist-get (plist prop)
  "Extract value of property PROP from property list PLIST.
Like `plist-get' except allows value to be multiple elements."
  (when plist
    (cl-loop with passed = nil
             for e in plist
             until (and passed
                        (keywordp e)
                        (not (eq e prop)))
             if (and passed
                     (not (keywordp e)))
             collect e
             else if (and (not passed)
                          (keywordp e)
                          (eq e prop))
             do (setq passed 't))))

(defun with-shell-interpreter--some (fn list)
  "Return (FN x) for the first LIST item where (FN x) is non-nil."
  (let (res)
    (while (not res)
      (setq res (funcall fn (car list))
            list (cdr list)))
    res))



;; HELPERS: VARIABLES SCOPE

(defun with-shell-interpreter--symbol-value (sym &optional allow-buffer-local)
  "Return the value of SYM in current buffer.
If ALLOW-BUFFER-LOCAL is nil, always return global value (never buffer-local one)."
  (if (not allow-buffer-local)
      ;; NB: if local-only `default-value' throws an error
      (ignore-errors
        (default-value sym))
    (symbol-value sym)))


(defun with-shell-interpreter--boundp-buffer-local (symbol)
  "Return t if SYMBOL has a buffer-local value.
Even works if it's value is nil."
  (assoc symbol (buffer-local-variables)))



;; HELPERS: CONNECTION-LOCAL VARS

(defun with-shell-interpreter--cnnx-local-vars (path)
  "Get connection-local vars for PATH."
  (if (eq with-shell-interpreter-connection-local-vars-implem 'custom)
      (with-shell-interpreter--cnnx-local-vars-custom path)
    (with-shell-interpreter--cnnx-local-vars-native path)))

(defun with-shell-interpreter--cnnx-local-vars-custom (path)
  "Get connection-local vars for PATH (custom)."
  (when (file-remote-p path)
    (with-shell-interpreter--some
     (lambda (e)
       (let ((regexp (car e))
             (vars (cdr e)))
         (when (string-match regexp path)
           vars)))
     with-shell-interpreter-connection-local-vars)))

(defun with-shell-interpreter--cnnx-local-vars-native (path)
  "Get connection-local vars for PATH (native)."
  (when (file-remote-p path)
    (let (output)
      (with-temp-buffer
        (with-shell-interpreter--hack-connection-local-variables
         `(
           ;; REVIEW: only those props in criteria?
           ;; this is what `shell' uses, but maybe can we do better?
           :application tramp
           :protocol ,(file-remote-p path 'method)
           :user ,(file-remote-p path 'user)
           :machine ,(file-remote-p path 'host)))
        (setq output connection-local-variables-alist))
      output)))



;; HELPERS: STANDARD SHELL VARS

(defun with-shell-interpreter--interpreter-value (is-remote
                                                  &optional allow-buffer-local-vars
                                                  allow-cnnx-local-vars cnnx-local-vars
                                                  input-value)
  "Determine value of shell interpreter.
Use INPUT-VALUE if not empty, else fallback to default values, depending on
CNNX-LOCAL-VARS and whether:
 - IS-REMOTE or not
 - ALLOW-BUFFER-LOCAL-VARS or not
 - ALLOW-CNNX-LOCAL-VARS or not

The order of precedence is like so:
 - input value
 - buffer-local value (if ALLOW-BUFFER-LOCAL-VARS is t)
 - connection-local value (if ALLOW-CNNX-LOCAL-VARS is t)
 - default remote value
 - global value"
  (with-shell-interpreter--normalize-path
   (or input-value
       ;; buffer-local value
       (when (and allow-buffer-local-vars
                  (with-shell-interpreter--boundp-buffer-local 'explicit-shell-file-name))
         (with-shell-interpreter--symbol-value 'explicit-shell-file-name t))
       (when (and allow-buffer-local-vars
                  (with-shell-interpreter--boundp-buffer-local 'shell-file-name))
         (with-shell-interpreter--symbol-value 'shell-file-name t))
       ;; connection-local value
       (when (and is-remote
                  allow-cnnx-local-vars)
         (or (alist-get 'explicit-shell-file-name cnnx-local-vars)
             (alist-get 'shell-file-name cnnx-local-vars)))
       ;; global value
       (ignore-errors
         (with-shell-interpreter--symbol-value 'explicit-shell-file-name nil))
       (ignore-errors
         (with-shell-interpreter--symbol-value 'shell-file-name nil))
       ;; universal fallback value
       "/usr/bin/sh")))


(defun with-shell-interpreter--interpreter-args-value (is-remote args-var-name interpreter
                                                                 &optional allow-buffer-local-vars
                                                                 allow-cnnx-local-vars cnnx-local-vars
                                                                 input-value)
  "Determine value of shell interpreter.
Use INPUT-VALUE if not empty, else fallback to default values, depending on
 ARGS-VAR-NAME, INTERPRETER, CNNX-LOCAL-VARS and whether:
 - IS-REMOTE or not
 - ALLOW-BUFFER-LOCAL-VARS or not
 - ALLOW-CNNX-LOCAL-VARS or not

The order of precedence is like so:
 - input value
 - buffer-local value (if ALLOW-BUFFER-LOCAL-VARS is t)
 - connection-local value (if ALLOW-CNNX-LOCAL-VARS is t)
 - default remote value (if INTERPRETER is default remote interpreter)
 - global value
 - universal fallback value"
  (or input-value
      ;; buffer-local value
      (when (and allow-buffer-local-vars
                 (with-shell-interpreter--boundp-buffer-local args-var-name))
        (with-shell-interpreter--symbol-value args-var-name t))
      ;; connection-local value
      (when (and is-remote
                 allow-cnnx-local-vars
                 (or
                  (string= interpreter (alist-get 'explicit-shell-file-name cnnx-local-vars))
                  (string= interpreter (alist-get 'shell-file-name cnnx-local-vars))))
        (alist-get args-var-name cnnx-local-vars))
      ;; global value
      (ignore-errors
        (with-shell-interpreter--symbol-value args-var-name nil))
      ;; universal fallback value
      '("-i")))


(defun with-shell-interpreter--command-switch (is-remote interpreter
                                                         &optional allow-buffer-local-vars
                                                         allow-cnnx-local-vars cnnx-local-vars
                                                         input-value)
  "Determine value of shell command switch.
Use INPUT-VALUE if not empty, else fallback to default values, depending on
 INTERPRETER, CNNX-LOCAL-VARS and whether:
 - IS-REMOTE or not
 - ALLOW-BUFFER-LOCAL-VARS or not
 - ALLOW-CNNX-LOCAL-VARS or not

The order of precedence is like so:
 - input value
 - buffer-local value (if ALLOW-BUFFER-LOCAL-VARS is t)
 - connection-local value (if ALLOW-CNNX-LOCAL-VARS is t)
 - default remote value (if INTERPRETER is default remote interpreter)
 - global value
 - universal fallback value"
  (or input-value
      ;; buffer-local value
      (when (and allow-buffer-local-vars
                 (with-shell-interpreter--boundp-buffer-local 'shell-command-switch))
        (with-shell-interpreter--symbol-value 'shell-command-switch t))
      ;; connection-local value
      (when (and is-remote
                 allow-cnnx-local-vars
                 (or
                  (string= interpreter (alist-get 'explicit-shell-file-name cnnx-local-vars))
                  (string= interpreter (alist-get 'shell-file-name cnnx-local-vars))))
        (alist-get 'shell-command-switch cnnx-local-vars))
      ;; global value
      (ignore-errors
        (with-shell-interpreter--symbol-value 'shell-command-switch nil))
      ;; universal fallback value
      "-c"))


(defun with-shell-interpreter--w32-quote-process-args (is-remote interpreter
                                                                 &optional allow-buffer-local-vars
                                                                 allow-cnnx-local-vars cnnx-local-vars
                                                                 input-value)
  "Determine value of shell command switch.
Use INPUT-VALUE if not empty, else fallback to default values, depending on
 INTERPRETER, CNNX-LOCAL-VARS and whether:
 - IS-REMOTE or not
 - ALLOW-BUFFER-LOCAL-VARS or not
 - ALLOW-CNNX-LOCAL-VARS or not

The order of precedence is like so:
 - input value
 - buffer-local value (if ALLOW-BUFFER-LOCAL-VARS is t)
 - connection-local value (if ALLOW-CNNX-LOCAL-VARS is t)
 - global value"
  (or input-value
      ;; buffer-local value
      (when (and allow-buffer-local-vars
                 (with-shell-interpreter--boundp-buffer-local 'w32-quote-process-args))
        (with-shell-interpreter--symbol-value 'w32-quote-process-args t))
      ;; connection-local value
      (when (and is-remote
                 allow-cnnx-local-vars
                 (or
                  (string= interpreter (alist-get 'explicit-shell-file-name cnnx-local-vars))
                  (string= interpreter (alist-get 'shell-file-name cnnx-local-vars))))
        (alist-get 'shell-command-switch cnnx-local-vars))
      ;; global value
      (ignore-errors
        (with-shell-interpreter--symbol-value 'w32-quote-process-args nil))))



;; HELPER: COMPUTED VARS

(defun with-shell-interpreter--generate-props (path interpreter allow-local-vars)
  "Generate several usefull variable values from PATH, INTERPRETER and ALLOW-LOCAL-VARS.
This function exists to be reused by package `friendly-shell'."
  (unless path
    (setq path default-directory))
  (unless (file-exists-p path)
    (error "Path %s doesn't seem to exist" path))

  (let* ((is-remote (file-remote-p path))
         (allow-local-vars (or allow-local-vars 'connection))
         (allow-buffer-local-vars  (member allow-local-vars '(buffer both)))
         (allow-cnnx-local-vars (member allow-local-vars '(connection both)))
         (cnnx-local-vars (with-shell-interpreter--cnnx-local-vars path))
         (interpreter (with-shell-interpreter--interpreter-value is-remote
                                                                 allow-buffer-local-vars
                                                                 allow-cnnx-local-vars cnnx-local-vars
                                                                 interpreter))
         (interpreter-name (with-shell-interpreter--interpreter-name interpreter))
         (explicit-interpreter-args-var (intern (concat "explicit-" interpreter-name "-args"))))
    (list path is-remote
          allow-buffer-local-vars
          allow-cnnx-local-vars cnnx-local-vars
          interpreter interpreter-name
          explicit-interpreter-args-var)))




(provide 'with-shell-interpreter)

;;; with-shell-interpreter.el ends here
