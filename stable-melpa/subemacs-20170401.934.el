;;; subemacs.el --- Evaluating expressions in a fresh Emacs subprocess  -*- mode: emacs-lisp; lexical-binding: t; coding: utf-8-unix; byte-compile-dynamic: t; -*-

;; Copyright (C) 2015  Klaus-Dieter Bauer

;; Author: Klaus-Dieter Bauer <bauer.klaus.dieter@gmail.com>
;; Keywords: extensions, lisp, multiprocessing
;; Package-Version: 20170401.934
;; Package-Commit: 18d53939fec8968c08dfc5aff7240ca07efb1aac
;; Version: 1.0.0
;; Requires: ((emacs "24"))
;; URL: https://github.com/kbauer/subemacs

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

;; Using the function `subemacs-eval', a form can be synchronously
;; evaluated in a freshly started Emacs process, which inherits only
;; the `load-path' from the current process. 
;; 
;; Other values must be passed explicitly by making them part of the
;; form, e.g. by writing 
;; 
;;     (let ((my-int 10))
;;       (subemacs-eval `(+ 5 ',my-int)))
;;         
;;         => 15
;; 
;; `subemacs-eval' also supports errors raised by Emacs' `signal' and
;; related functions, and displays messages emitted in the subprocess. 
;; 
;; 
;; 
;; ## Clean compilation
;; 
;; The original motivation for writing this package was Emacs Lisp
;; byte-compilation.  When byte-compiling a file from within a running
;; Emacs process, missing `require' calls for dependencies and typos
;; may be hidden from the byte compiler due to the environment already
;; containing them. 
;; 
;; Such issues may not become apparent until the code is executed by a
;; user, who does not load the same files during startup.  While they
;; can be diagnosed by testing code with `emacs -Q`, this solution is
;; inconvenient. 
;; 
;; Instead, compiling Emacs Lisp files in a clean process by default
;; turns the byte-compiler into a powerful ad-hoc tool to identify
;; issues from byte-compiler warnings. 
;; 
;; Functions `subemacs-byte-compile-file' and
;; `subemacs-byte-recompile-directory' are therefore provided and also
;; serve as a demonstration of the use of `subemacs-eval'.
;; 
;; 
;; 
;; ## Why not subemacs-funcall?
;; 
;; Originally I had planned to implement `subemacs-funcall', as
;; passing functions to the subprocess would allow compile-time
;; checking of the passed expressions for issues.
;; 
;; Passing a `lambda' form to a hypothetical `subemacs-funcall' in an
;; environment where `lexical-binding' is enabled, will capture the
;; lexical environment into the resulting `closure' form and make it
;; available to the subprocess.  This behaviour however is not
;; documented and may break in the future.  As a consequence an
;; implementation of `subemacs-funcall' would either require enforcing
;; unexpected limitations (e.g. not allowing closures) or risk the
;; creation of code that depends on an undocumented feature of current
;; Emacs versions.
;; 
;; Passing a quoted `lambda' form would avoid these problems, but
;; would also sacrifice compile-time checks, and thus the only
;; advantage.
;;
;;
;;
;; ## Comparison to async.el
;; 
;; [async.el](https://github.com/jwiegley/emacs-async) implements a
;; superset of the functionality of `subemacs.el', with
;; `async-sandbox' having essentially the functionality of
;; `subemacs-eval'. However, a few complementary properties allow
;; `subemacs.el' to remain useful.
;; 
;;   - `subemacs-eval' forwards the STDOUT and STDERR of the
;;     subprocess and allows access to the contents as a string.
;;     `async-sandbox' does not.
;;   
;;   - With `subemacs-byte-compile-file', the module contains a 
;;     useful development tool, that is optimized for quickly 
;;     checking against compiler warnings.
;; 
;;   - On Windows at least, `async-sandbox' has more overhead.
;;   
;;         (async-sandbox '(lambda ())) ; ≈ 0.75 seconds
;;         (subemacs-eval '(progn))     ; ≈ 0.35 seconds
;;   
;;   - On Windows, I sometimes experience `async-sandbox' hanging,
;;     while I never had such a problem with `subemacs-eval'.
;; 
;; 
;; <!--
;; TODO Another possible usecase: Chaining external commands and elisp.
;; TODO     Currently emacs has no good method to execute multiple
;; TODO     external commands in an asynchronous shell buffer, 
;; TODO     executing emacs lisp in between.
;; -->
;; 
;; ## Changelog
;; 
;; ### v1.1
;; 
;; - Rewrote `subemacs-byte-compile-file'. 
;; - Adjusted README text to describe usecases compared to `async.el'.
;; 
;; ### v1.0
;; 
;; Original release. Supports exclusively synchronous execution. 



;;; Code:

;; -*- mode:emacs-lisp;coding:utf-8-unix;lexical-binding:t;byte-compile-dynamic:t; -*-

(require 'cl-macs)

;;;; AUXILIARY FUNCTIONS 


(defun subemacs--binary-path ()
  "Path to Emacs executable of this Emacs process if known."
  (concat 
   (or invocation-directory
       (error "Cannot determine path to emacs executable"))
   (or invocation-name
       (error "Cannot determine path to emacs executable"))))


(defconst subemacs-output-buffer-name " *subemacs-eval*"
  "Name of the buffer used by `subemacs-eval' for capturing output of the Emacs subprocess.")


(defun subemacs-output-buffer ()
  "Return and possibly create the output buffers used by `subemacs-eval'."
  (get-buffer-create " *subemacs-eval*"))


(defun subemacs--reraise-error (err)
  "ERR: An error as catched by `condition-case'."
  (signal (car err) (cdr err)))


(defun subemacs--1-call-direct (form)
  "Execute FORM in Emacs subprocess, passing FORM as exec argument."
  (call-process (subemacs--binary-path) nil (subemacs-output-buffer) nil 
                "--batch" "--eval" (format "%S" form)))


(defun subemacs--2-call-with-tempfile (form)
  "Execute FORM in Emacs subprocess, passing FORM through a temporary file.

This is needed due to length restrictions on exec argument
strings, which is especially likely to interfere with normal
operation on Windows."
  (let ((temp-file (make-temp-file "subemacs-input-file-" nil ".el.tmp")))
    (unwind-protect
        (progn 
          (with-temp-file temp-file
            (print form (current-buffer)))
          (call-process (subemacs--binary-path) nil (subemacs-output-buffer) nil
                        "--batch" "--load" temp-file))
      (delete-file temp-file))))


(defun subemacs--append-to-buffer (buffer &rest strings)
  (with-current-buffer buffer
    (let ((inhibit-read-only t))
      (goto-char (point-max))
      (apply #'insert strings))))


(defun subemacs--make-form (form)
  "Internal.

Create the full form passed to the subprocess for `subemacs-eval'
from the use-supplied form FORM.

Passes values to parent process as alist."
  `(let ((load-path ',load-path)) 
     (unwind-protect 
         (progn 
           (condition-case err
               (prin1 (list (cons 'value ,form)))
             (error (prin1 (list (cons 'error err)))))
           (kill-emacs))
       (prin1 (list (cons 'error '(error "Invalid error signal in subemacs process")))))))


(put 'subemacs-error 'error-conditions '(subemacs-error error))


(defun subemacs--readable-form-p (form)
  "Is FORM a sexp, that can be `read' from its `print' representation?"
  (condition-case nil
      (prog1 t
        (equal form
               (with-temp-buffer 
                 (print form (current-buffer))
                 (goto-char (point-min))
                 (read (current-buffer)))))
    (invalid-read-syntax nil)))


(defun subemacs--read--expression (prompt &optional initial-contents)
  "Internal.
Copied from `read--expression' in `simple.el'.
I didn't want to depend on an undocumented, possibly changing function.
PROMPT, INITIAL-CONTENTS should be self-explanatory."   
  (let ((minibuffer-completing-symbol t))
    (minibuffer-with-setup-hook
        (lambda ()
          (add-hook 'completion-at-point-functions
                    #'elisp-completion-at-point nil t)
          (run-hooks 'eval-expression-minibuffer-setup-hook))
      (read-from-minibuffer prompt initial-contents
                            read-expression-map t
                            'read-expression-history))))


(eval-and-compile
  (defun subemacs--assert (value predicate)
    (unless (funcall predicate value)
      (error "Assertion failed: %S, %S" value predicate))))


(defmacro subemacs--function-let (bindings &rest body)
  "Rebind global functions according to BINDINGS while executing BODY.

Bindings uses as syntax

   BINDINGS = (BINDFORM ...)
   BINDFORM = (SYMBOL FUNCTION)

where SYMBOL identifies the function to be rebound and FUNCTION
its replacement (which may be a symbol).

Beware: Dangerous. Used on fundamental functions like `car' may
break the Emacs session."
  (declare (indent 1))
  (cl-loop for (symbol function) in bindings 
           do (subemacs--assert symbol #'symbolp)
           do (subemacs--assert (eval function)
                                     (lambda (e) 
                                       (or (symbolp e) (functionp e)))))
  `(subemacs--function-let-1 
    (list ,@(cl-loop for (symbol function) in bindings 
                    collect `(cons #',symbol ,function)))
    (lambda () ,@body)))


(defun subemacs--function-let-1 (binding-alist body-func)
  "See `subemacs--function-let'."
  (let ((original-bindings-alist 
         (cl-loop for (symbol . _) in binding-alist 
                  collect (cons symbol (symbol-function symbol)))))
    (unwind-protect 
        (cl-loop for (symbol . newfunc) in binding-alist
                 do (fset symbol newfunc)
                 finally return (funcall body-func))
      (cl-loop for (symbol . oldfunc) in original-bindings-alist
               do (fset symbol oldfunc)))))


;;;; PUBLIC FUNCTIONS AND COMMANDS 


(defvar subemacs-last-stdout nil
  "After `subemacs-eval', holds the stdout/stderr.")


(cl-defun subemacs-eval (form &key discard-messages)
  "Evaluate FORM in an Emacs subprocess.

FORM will be passed as a string to a new Emacs session and
evaluated there. The result will be returned to the current
session as return value of the `subemacs-eval' function call.

When the form results in an error, that error is collected and
`signal'ed in the current session.

The `print' representation of FORM must be `read'able, which is
veryfied before starting a subprocess. 

The subprocess session is started with the --batch argument and
thus doesn't process the `.emacs' file. 

It automatically inherits the `load-path' of the current session.
It does not however inherit any other variable values or function
definitions. These have to be supplied by either `require'ing the
needed libraries (which is why the `load-path' is supplied by
default) or by explicitly constructing FORM to set them, e.g.

    \`(let ((remote-value ',local-value))
        (do-it remote-value))

The stdout/stderr of the subprocess that is NOT part of the final
value is forwarded to the `*Messages*' buffer, unless
DISCARD-MESSAGES is nil. It is always available however through
the `subemacs-last-stdout' variable.


Additional Remarks 
------------------

Do NOT try something like `(funcall (function ,(lambda () ...))).
Currently this construct would pass a closure to the subprocess
which carries along its lexical environment, but this may break
in future implementations of lexical closures.

When FORM is very long, limitations of the system level ‘exec’
interface may prevent passing FORM as an argument to the
subprocess. In this case a temporary file is used. Even on
Windows however, that limit should be in the range of tens of
thousands of characters."
  (cl-check-type form subemacs--readable-form-p)
  ;; The use of a fixed buffer is for debugging primarily. 
  ;; It may be changed to a temporary buffer at any time. 
  (with-current-buffer (subemacs-output-buffer)
    (erase-buffer)
    (condition-case nil
        (subemacs--1-call-direct (subemacs--make-form form))
      (file-error 
       (subemacs--2-call-with-tempfile (subemacs--make-form form))))
    (let ((returned-form 
           (progn (goto-char (point-max))
                  (backward-sexp)
                  (read (current-buffer))))
          (message-contents
           (progn (goto-char (point-max))
                  (backward-sexp)
                  (buffer-substring-no-properties (point-min) (point)))))
      (unless discard-messages
        (subemacs--append-to-buffer (messages-buffer) message-contents))
      (setq subemacs-last-stdout message-contents)
      
      (cond ((assq 'error returned-form)
             (subemacs--reraise-error (cdr (assq 'error returned-form))))
            ((assq 'value returned-form)
             (cdr (assq 'value returned-form)))
            (t (signal 'error
                       (list "Invalid form returned from subemacs-eval"
                             returned-form)))))))


;;;###autoload
(defun subemacs-eval-expression (exp &optional insert-value)
  "Like `eval-expression' but using `subemacs-eval'. 

Shares the history with `eval-expression'."
  (interactive 
   (list (subemacs--read--expression "Subemacs-eval: ")
         current-prefix-arg))
  (let ((debug-on-error t))
    (eval-expression (list 'quote (subemacs-eval exp)) 
                     insert-value)))


;;;###autoload
(cl-defun subemacs-byte-compile-file (file-name &optional load-1 &key 
                                       load log-buffer erase nodisplay discard)
  "Compile FILE-NAME through `subemacs-eval'. 

I.e. the file is compiled in a clean Emacs session and has to
`require' all `features' it depends on itself.

This makes identifying missing `require's easier, as they will
raise compilation warnings, while in the main emacs sessions
dependencies loaded previously by other files will mask the
error.

Returns the return value of `byte-compile-file' in the
subprocess, i.e. non-nil on success, nil on error.

LOAD-1 are provided for backwards compatibility and should
normally be nil.

If LOAD is non-nil, load the compiled file after compiling
successfully. If LOAD is 'source, load FILE-NAME instead.

LOG-BUFFER determines where the compilation log from the
subprocess goes after completion. Useful values include
`nil' (discard the output), and `byte-compile-log-buffer'. Note
that the compiler output always goes to `messages-buffer' too, as
it is part of the emacs subprocess' stdout/stderr streams.

If NODISPLAY is nil, LOG-BUFFER if any will be displayed. 

If ERASE is non-nil, LOG-BUFFER is any will be erased before
inserting anything.

If DISCARD is non-nil, delete the bytecode file after
compilation. This is useful for compiling e.g. the `.emacs' file
to check for errors, without creating a confusion over whether to
load `.emacs' or a likely outdated `.emacs.elc'.

INTERACTIVELY, FILE-NAME is `buffer-file-name', LOAD is
determined by `current-prefix-arg', LOG-BUFFER is
`messages-buffer', ERASE is t, and DISCARD is t if
`buffer-file-name' doesn't match `emacs-lisp-file-regexp'.
"
  ;; Interactive form copied from `byte-compile-file'
  (interactive
    (progn 
      (save-buffer)
      (list (buffer-file-name) nil
        :load current-prefix-arg
        :erase t
        :log-buffer (messages-buffer)
        :discard (not (string-match-p emacs-lisp-file-regexp (buffer-file-name))))))
      
  (setq load (or load-1 load))
  (let*((delim (if (eq (messages-buffer) log-buffer)
                         "------------------------------------------------------------\n"
                       ""))
        (file-to-load 
          (if (or discard (eq 'source load))
              file-name
            (byte-compile-dest-file file-name))))
    (let*((return
            (subemacs-eval
              `(progn
                 (require 'bytecomp)
                 (list 
                   (byte-compile-file ',file-name nil)
                   (with-current-buffer (get-buffer-create byte-compile-log-buffer)
                     (buffer-string))))))
          (compile-successful (nth 0 return))
          (compile-log-contents (nth 1 return)))

      (when (and discard compile-successful)
        (delete-file (byte-compile-dest-file file-name)))

      (when log-buffer 
        (with-current-buffer log-buffer
          (when erase 
            (let ((inhibit-read-only t)) (erase-buffer)))
          (unless (eq major-mode 'compilation-mode)
            (compilation-mode)))
        (subemacs--append-to-buffer log-buffer
          delim
          (format "(%s) %s\n" (format-time-string "%T" (current-time)) file-name)
          compile-log-contents
          delim)
        (unless nodisplay (display-buffer log-buffer)))

      (when (and load compile-successful)
        (load-file file-to-load)
        (when log-buffer
          (subemacs--append-to-buffer log-buffer delim)))

      (when (eq (messages-buffer) log-buffer)
        (message nil))
            
      compile-successful)))


;;;###autoload
(defun subemacs-byte-recompile-directory (directory &optional arg force)
  "Like `byte-recompile-directory' but using
`subemacs-byte-compile-file' insteaf of `byte-compile-file'."
  (interactive "DByte recompile directory: \nP")
  (subemacs--function-let 
      ((byte-compile-file #'subemacs-byte-compile-file))
    (byte-recompile-directory directory arg force)))


;;;; REMOVED FORMS 
;;;
;;; These forms may break without warning, as closures carrying along
;;; their lexical environment even to a subprocess is not documented
;;; and may depend on the current implementation in a not future-proof
;;; manner, so I removed them but left them in for reference. 
;;
;; (defun subemacs-function (function)
;;   "Removed. Closures may allow 
;;   (subemacs-eval `(funcall #',function)))
;; 
;; 
;; (defmacro subemacs-progn (&rest body)
;;   "doc"
;;   (declare (indent 0))
;;   `(subemacs-function 
;;     (lambda () "Generated by `subemacs-progn'" 
;;       ,@body)))
  

(provide 'subemacs)
;;; subemacs.el ends here
