;;; yaxception.el --- Provide framework about exception like Java for Elisp

;; Copyright (C) 2013  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: exception error signal
;; Package-Version: 20150105.1540
;; Package-Commit: 4e94cf3e0b9b5631b0e90eb4b7de597ee7185875
;; URL: https://github.com/aki2o/yaxception
;; Version: 0.3.3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; This extension provides framework about exception for elisp.
;; The framework features are the following.
;; - try/catch/finally coding style like Java
;; - custom error object
;; - stacktrace like Java

;;; Dependency:
;; 
;; Nothing.

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your elisp file.
;; 
;; (require 'yaxception)

;;; Configuration:
;; 
;; Nothing

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'macro :prefix "yaxception:" :docstring t)
;; `yaxception:$'
;; Start handling error.
;; `yaxception:$~'
;; Wrapper of `yaxception:$' to keep performance.
;; `yaxception:try'
;; Execute BODY.
;; `yaxception:catch'
;; Execute BODY if the error happened that has ERRSYMBOL in `error-conditions'.
;; `yaxception:finally'
;; Execute BODY.
;; `yaxception:throw'
;; Raise error directly or create and raise error from given value.
;; 
;;  *** END auto-documentation
;; 
;; [EVAL] (autodoc-update-all)
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "yaxception:" :docstring t)
;; `yaxception:deferror'
;; Define custom error.
;; `yaxception:get-text'
;; Get message of error.
;; `yaxception:get-prop'
;; Get property of symbol of error.
;; `yaxception:get-stack-trace-string'
;; Get string like printStackTrace of Java abaut error.
;; 
;;  *** END auto-documentation
;; 
;; [EVAL] (autodoc-update-all)
;; 
;; For detail, see <https://github.com/aki2o/yaxception/blob/master/README.md>
;; 
;; [Note] Other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 23.3.1 (i386-mingw-nt5.1.2600) of 2011-08-15 on GNUPACK


;; Enjoy!!!


;;; Code:
(require 'cl)


(defvar yaxception-debug-enable nil)
(defvar yaxception-debug-buffer-name "*YAX Debug*")

(defmacro yaxception-debug (msg &rest args)
  `(when yaxception-debug-enable
     (condition-case e
         (with-current-buffer (get-buffer-create yaxception-debug-buffer-name)
           (goto-char (point-max))
           (insert (format ,msg ,@args) "\n"))
       (error (message "[yaxception-debug] %s" (error-message-string e))))))

(defun yaxception:toggle-debug-enable ()
  "Toggle debug is enabled/disabled."
  (interactive)
  (message "Yaxception Debug: %s" (setq yaxception-debug-enable (not yaxception-debug-enable))))

(defun yaxception:clear-debug-log ()
  "Clear debug log."
  (interactive)
  (with-current-buffer (get-buffer-create yaxception-debug-buffer-name)
    (erase-buffer)))


(defstruct yaxception name msgtmpl parent tmplkeys)


(defvar yaxception-custom-err-hash (make-hash-table :test 'equal))
(defvar yaxception-err (gensym))
(defvar yaxception-errsymbol (gensym))
(defvar yaxception-errcatched (gensym))
(defvar yaxception-active-p nil)
(defvar yaxception-return-value (gensym))
(defvar yaxception-signal-hook-function 'yaxception-build-stacktrace)


(defun* yaxception:deferror (errsymbol parent errmsgtmpl &rest tmplkeys)
  "Define custom error.

ERRSYMBOL is symbol for custom error. It's OK that not yet defined symbol.
PARENT is symbol of parent error. If nil, means 'error.
ERRMSGTMPL is string as a template used by `error-message-string'.
 This is like argument of `format'. '%s' in this value are replaced with TMPLKEYS.
TMPLKEYS is symbol for replacing '%s' in ERRMSGTMPL with the given value when `yaxception:throw'."
  (condition-case e
      (when (symbolp errsymbol)
        (let* ((errnm (symbol-name errsymbol)))
          (when (not parent)
            (setq parent 'error))
          (put errsymbol 'error-conditions (list errsymbol parent))
          (put errsymbol 'error-message errmsgtmpl)
          (puthash errnm
                   (make-yaxception :name errnm :parent parent :msgtmpl errmsgtmpl :tmplkeys tmplkeys)
                   yaxception-custom-err-hash)))
    (error (message "[yaxception:deferror] %s" (error-message-string e))
           nil)))

(defmacro* yaxception:$ (try &rest catch_or_finally)
  "Start handling error.

TRY is a `yaxception:try' sexp.
CATCH_OR_FINALLY is a `yaxception:catch' or `yaxception:finally' sexp.

If error is happened while execute `yaxception:try', go to `yaxception:catch' that match it first.
If not exist `yaxception:catch' matched it, raise its error.
If has `yaxception:finally', execute it at last without relation to if error was happened.

Return value is the following.
- If error was not happened, it's a TRY returned value.
- If error was happened and a matched `yaxception:catch' exist, it's the `yaxception:catch' returned value.

If you mind the decrease of performance by this function, see `yaxception:$~'."
  (declare (indent 0))
  (lexical-let* (catches finally)
    (condition-case e
        (loop for e in catch_or_finally
              for s = (when (listp e) (car e))
              for symbolnm = (when s (format "%s" s))
              do (cond ((string= symbolnm "yaxception:catch")   (cond (catches
                                                                       (setq catches (append catches (list e))))
                                                                      (t
                                                                       (setq catches (list e)))))
                       ((string= symbolnm "yaxception:finally") (setq finally e))))
      (error (message "[yaxception:$] %s" (error-message-string e))))
    `(let* ((,yaxception-err)
            (signal-hook-function yaxception-signal-hook-function)
            (yaxception-active-p t))
       (unwind-protect
           (condition-case ,yaxception-err
               ,try
             (error (let* ((,yaxception-errsymbol (car ,yaxception-err))
                           (,yaxception-errcatched)
                           (,yaxception-return-value))
                      ,@catches
                      (when (not ,yaxception-errcatched)
                        (signal ,yaxception-errsymbol (cdr ,yaxception-err)))
                      ,yaxception-return-value)))
         ,finally))))

(defmacro* yaxception:$~ (try &rest catch_or_finally)
  "Wrapper of `yaxception:$' to keep performance.

This function has the following restriction in exchange for performance.
 - can't use `yaxception:get-stack-trace-string'."
  (declare (indent 0))
  `(let ((yaxception-signal-hook-function nil))
     (yaxception:$ ,try ,@catch_or_finally)))

(defmacro* yaxception:try (&rest body)
  "Execute BODY.

BODY is sexp.

This can be used only in `yaxception:$'.
Return value is a last sexp returned value."
  (declare (indent 0))
  `(progn ,@body))

(defmacro* yaxception:catch (errsymbol errvar &rest body)
  "Execute BODY if the error happened that has ERRSYMBOL in `error-conditions'.

ERRSYMBOL is symbol of a error or parent error that want to catch.
ERRVAR is variable that using as error object in BODY. It's OK that not yet defined.
BODY is sexp that executed if the error happened that has ERRSYMBOL in `error-conditions'.

This can be used only in `yaxception:$'.
Return value is a last sexp returned value in BODY."
  (declare (indent 2))
  `(when (and (not ,yaxception-errcatched)
              (memq ,errsymbol (get ,yaxception-errsymbol 'error-conditions)))
     (setq ,yaxception-return-value
           (let* ((,errvar ,yaxception-err))
             (setq ,yaxception-errcatched t)
             ,@body))))

(defmacro* yaxception:finally (&rest body)
  "Execute BODY.

BODY is sexp.

This can be used only in `yaxception:$'.
Return value is a last sexp returned value. But it's not used in `yaxception:$'."
  (declare (indent 0))
  `(progn ,@body))

(defmacro* yaxception:throw (err_or_errsymbol &rest args &allow-other-keys)
  "Raise error directly or create and raise error from given value.

ERR_OR_ERRSYMBOL is variable or symbol. Accept the following value.
 - If raise error directly, this is a variable of it.
 - If create error and raise it, this is a symbol of it.
ARGS is anything.
 This is used if create error.
 This format is keyward arguments.
 If given this, get this by `yaxception:get-prop' in `yaxception:catch'."
  (declare (indent 0))
  `(progn
     (yaxception-debug "start throw\n  err: %s\n  args: %s\n  car: %s\n  cdr: %s"
                       ',err_or_errsymbol
                       ',args
                       (ignore-errors (car ,err_or_errsymbol))
                       (ignore-errors (cdr ,err_or_errsymbol)))
     (cond ((ignore-errors (boundp ',err_or_errsymbol))
            ;; re-throw err
            (signal (car ,err_or_errsymbol) (cdr ,err_or_errsymbol)))
           ((symbolp ,err_or_errsymbol)
            ;; throw create error
            (when (not (yaxception-err-symbol-p ,err_or_errsymbol))
              (yaxception:deferror ,err_or_errsymbol nil (get 'error 'error-message)))
            (yaxception-throw-custom-err ,err_or_errsymbol (yaxception-get-err-info-hash ,@args)))
           (t
            (message "[yaxception:throw] Illegal argument : %s" ,err_or_errsymbol)
            (error (format "%s" ,err_or_errsymbol))))))

(defun yaxception:get-text (err)
  "Get message of error.

ERR is variable of error.

Return value is a `error-message-string' return value."
  (condition-case e
      (error-message-string err)
    (error (message "[yaxception:get-text] %s" (error-message-string e))
           "")))

(defun yaxception:get-prop (err propsymbol)
  "Get property of symbol of error.

ERR is variable of error.
PROPSYMBOL is symbol of property. Give this like the following.
 If give `yaxception:throw' :hoge, this is 'hoge."
  (condition-case e
      (let* ((errsymbol (when (listp err)
                          (intern-soft (car err))))
             (keysymbol (when (symbolp propsymbol)
                          (intern-soft (concat ":" (symbol-name propsymbol))))))
        (when (and (yaxception-err-symbol-p errsymbol)
                   (symbolp keysymbol))
          (get errsymbol keysymbol)))
    (error (message "[yaxception:get-prop] %s" (error-message-string e))
           nil)))

(defun yaxception:get-stack-trace-string (err)
  "Get string like printStackTrace of Java abaut error.

ERR is variable of error.

This can be used only in `yaxception:catch'.
List called function and its arguments until error was happened."
  (condition-case e
      (let* ((errsymbol (when (listp err)
                          (intern-soft (car err))))
             (callstack (when (yaxception-err-symbol-p errsymbol)
                          (get errsymbol 'yaxception-call-stack)))
             (calllist (when callstack
                         (plist-get callstack :stack)))
             (getliner (lambda (c)
                         (concat "  at " (plist-get c :name) "(" (plist-get c :argstr) ")")))
             (ctxtype (plist-get callstack :type))
             (endline (cond
                        ((member ctxtype '("try" "catch" "finally"))
                         (concat "  in yaxception:" ctxtype))
                        (t
                         (concat "  in unknown-statment: " ctxtype)))))
        (if (not callstack)
            ""
          (concat "Exception is '" (symbol-name errsymbol) "'. " (error-message-string err) "\n"
                  (mapconcat getliner calllist "\n") "\n"
                  endline)))
    (error (message "[yaxception:get-stack-trace-string] %s" (error-message-string e))
           "")))


(defun* yaxception-throw-custom-err (errsymbol errinfoh)
  (yaxception-debug "start throw custom err : %s" errsymbol)
  (let* ((parents (yaxception-get-err-parents errsymbol))
         (errmsg (yaxception-get-err-msg errsymbol errinfoh)))
    (condition-case e
        (progn
          (put errsymbol 'error-conditions parents)
          (put errsymbol 'error-message errmsg)
          (loop for k being the hash-keys in errinfoh using (hash-values v)
                if (and (symbolp k)
                        (string-match "^:" (symbol-name k)))
                do (put errsymbol k v)))
      (error (message "[yaxception-throw-custom-err] %s" (error-message-string e))))
    (signal errsymbol (gethash " " errinfoh))))

(defun* yaxception-get-err-info-hash (&rest args &allow-other-keys)
  (condition-case e
      (loop with s
            with h = (make-hash-table :test 'equal)
            for e in args
            do (cond ((and (symbolp e)
                           (string-match "^:" (symbol-name e)))
                      (puthash (setq s e) t h))
                     (s
                      (puthash s e h)
                      (setq s nil))
                     (t
                      (puthash " " e h)))
            finally return h)
    (error (message "[yaxception-get-err-info-hash] %s" (error-message-string e))
           (make-hash-table :test 'equal))))

(defun yaxception-get-err-parents (errsymbol)
  (condition-case e
      (let* ((e (or (gethash (symbol-name errsymbol) yaxception-custom-err-hash)
                    errsymbol))
             (ret))
        (while (yaxception-p e)
          (setq ret (append ret (list (intern-soft (yaxception-name e)))))
          (setq e (or (gethash (symbol-name (yaxception-parent e)) yaxception-custom-err-hash)
                      (yaxception-parent e))))
        (append ret (get e 'error-conditions)))
    (error (message "[yaxception-get-err-parents] %s" (error-message-string e))
           '(error))))

(defun yaxception-get-err-msg (errsymbol errinfoh)
  (condition-case e
      (let* ((e (gethash (symbol-name errsymbol) yaxception-custom-err-hash))
             (tmplkeys (when (yaxception-p e)
                         (yaxception-tmplkeys e)))
             (msgtmpl (cond ((yaxception-p e) (yaxception-msgtmpl e))
                            (t                (get errsymbol 'error-message))))
             (msgtmpl (if (functionp msgtmpl) (funcall msgtmpl) msgtmpl))
             (msgargs (loop for k in tmplkeys
                            for s = (intern (concat ":" (symbol-name k)))
                            collect (gethash s errinfoh))))
        (apply 'format msgtmpl msgargs))
    (error (message "[yaxception-get-err-msg] %s" (error-message-string e))
           "")))

(defun yaxception-get-err-symbols ()
  (loop for s in (apropos-internal "^[a-z\\-:/]+$")
        when (yaxception-err-symbol-p s)
        collect s))

(defun yaxception-err-symbol-p (s)
  (ignore-errors (and (memq 'error-conditions (symbol-plist s))
                      (memq 'error-message (symbol-plist s))
                      t)))

(defvar yaxception-regexp-function-in-backtrace (rx-to-string `(and bos (+ space)
                                                                    (group (+ (not (any space "("))))
                                                                    "(" (group (* not-newline)) ")" (* space) eos)))
(defvar yaxception-regexp-macro-in-backtrace (rx-to-string `(and bos (+ space) "("
                                                                 (group (+ (not (any space)))) (+ space)
                                                                 (group (* not-newline)) ")" (* space) eos)))
(defvar yaxception-regexp-yaxception-in-backtrace (rx-to-string `(and bos (+ space) "("
                                                                      (group (or "yaxception:try"
                                                                                 "yaxception:catch"
                                                                                 "yaxception:finally"))
                                                                      (+ space))))
(defun yaxception-build-stacktrace (error-symbol data)
  (ignore-errors
    (when yaxception-active-p
      (with-temp-buffer
        (let ((standard-output (current-buffer))
              (print-escape-newlines t)
              (print-level 50)
              (print-length 50))
          (backtrace))
        (goto-char (point-min))
        (if (not (re-search-forward "^\\s-+yaxception-build-stacktrace(" nil t))
            (message "[yaxception] failed get backtrace : not found called signal-hook-function")
          (forward-line 1)
          (beginning-of-line)
          (let* ((ctxtype)
                 (calllist (loop for line = (replace-regexp-in-string "[\0\r\n]" "" (thing-at-point 'line))
                                 until (or (string-match yaxception-regexp-yaxception-in-backtrace line)
                                           (eobp))
                                 for c = (cond ((string-match yaxception-regexp-function-in-backtrace line)
                                                (let* ((funcnm (match-string-no-properties 1 line))
                                                       (argtext (match-string-no-properties 2 line))
                                                       (callinfo `(:name ,funcnm :argstr ,argtext)))
                                                  (when (not (string= funcnm "yaxception-throw-custom-err"))
                                                    callinfo)))
                                               ((string-match yaxception-regexp-macro-in-backtrace line)
                                                (let* ((macnm (match-string-no-properties 1 line))
                                                       (argtext (match-string-no-properties 2 line))
                                                       (macsym (intern-soft macnm))
                                                       (callinfo `(:name ,macnm :argstr ,argtext)))
                                                  (when (and macsym
                                                             (fboundp macsym))
                                                    (when (string= macnm "yaxception:throw")
                                                      callinfo)))))
                                 if c collect c
                                 do (forward-line 1)
                                 finally (let* ((lastf (or (match-string-no-properties 1 line)
                                                           "")))
                                           (setq ctxtype (cond ((string= lastf "yaxception:try")     "try")
                                                               ((string= lastf "yaxception:catch")   "catch")
                                                               ((string= lastf "yaxception:finally") "finally")
                                                               (t                                    lastf)))))))
            (put error-symbol 'yaxception-call-stack `(:type ,ctxtype :stack ,calllist)))
          nil)))))


(provide 'yaxception)
;;; yaxception.el ends here
