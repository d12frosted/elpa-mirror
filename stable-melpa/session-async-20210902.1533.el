;;; session-async.el --- Asynchronous processing in a forked process session  -*- lexical-binding: t; -*-

;; Copyright © 2021  Felipe Lema

;; Author: Felipe Lema <felipelema@mortemale.org>
;; Created: 2021-07-14
;; Version: 0.0.2
;; Package-Version: 20210902.1533
;; Package-Commit: 32a36841fbb3c864776a3a1ac08bb94d44ca10b3
;; Package-Requires: ((emacs "27.1") (jsonrpc "1.0.9"))
;; URL: https://codeberg.org/FelipeLema/session-async.el

;; Keywords: async, comm, data, files, internal, maint, processes, tools
;; X-URL: https://codeberg.org/FelipeLema/session-async.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Based on `async' package, adds the ability to call asynchronous functions and process with ease.
;; See the documentation for `session-async-start', `session-async-future' and `session-async-new'.

;;; Code:

;;;; Requires
(require 'generator)
(require 'jsonrpc)
(require 'simple)
(require 'subr-x)

;;;; Customs
(defgroup session-async nil
  "Asynchronous processing in separate Emacs session."
  :group 'emacs)

;;;; remote process
;;;;; variables
(defvar session-async--keep-loop-running nil
  "This var controls whether the loop should continue.")

(defvar session-async--request-timeout 60
  "Time in seconds before timing out an async request.")

;;;;; functions
(defun session-async--sexp-to-string (sexp)
  "Ensure that SEXP is correctly written and that is JSON-friendly."
  (let (print-level
        print-length
        print-quoted
        (print-escape-control-characters t)
        (print-escape-nonascii t)
        (print-circle t))
    (prin1-to-string sexp)))

(defun session-async--evaluate (sexp-as-string)
  "`read-from-string' SEXP-AS-STRING and return result.

Will catch any error from `eval'-ing, so it's always safe to call this function
Returns:
\(ok RESULT).
\(error ERROR-MESSAGE-STRING)."
  (let (result error-message)
    (condition-case err
        (thread-last sexp-as-string
          (format "(funcall %s)")
          (read-from-string)
          (car)
          (eval)
          (setq result))
      (error
       (setq
        error-message
        (error-message-string err))))
    (if (null error-message)
        `(ok . ,result)
      `(error . ,error-message))))

(defun session-async--error (&rest args)
  "Forwards ARGS to `error' prepending \"session-async\" to format."
  (let ((e-format (car args)))
    (apply #'error
           (list
            (concat
             "session-async: "
             e-format))
           (cdr args))))

(defun session-async--deserialize-evaluation (eval-result-as-string then)
  "De-serialize EVAL-RESULT-AS-STRING and call THEN on result.

EVAL-RESULT-AS-STRING may wrap an error.  If so, will `error' on wrapped message

See `session-async--evaluate'"
  (pcase (car (read-from-string eval-result-as-string))
    (`(ok . ,result)
     (funcall then result))
    (`(error . ,error-message)
     (session-async--error error-message))))

(defun session-async-handle-request (method &rest params)
  "Handle request from user-facing Emacs process.

Accepted METHOD: 'eval
All other methods will be ignored.

Returned sexp from calling `session-async--evaluate' with PARAMS will be
immediately `session-async--sexp-to-string'-ed before returning from this
function.

This way it can be safely sent back through communication socket."
  (pcase method
    (`eval
     (let ((eval-result
            (session-async--evaluate
             (car params))))
       (session-async--sexp-to-string eval-result)))))


(defun session-async-eval-loop ()
  "Loop to run in separate Emacs session.

Do not run this in user-facing session.  It will hang Emacs until exit."
  (setq session-async--keep-loop-running t)
  (let* ((port (thread-last command-line-args-left
                 (car)
                 (string-to-number)))
         (connection-to-main-emacs
          (make-instance
           'jsonrpc-process-connection
           :name "User-facing Emacs connection"
           :process (open-network-stream
                     "User-facing Emacs connection"
                     nil
                     "localhost"
                     port)
           :request-dispatcher
           (lambda (_main-emacs-connection method params)
             (apply #'session-async-handle-request
                    method
                    (append params nil)))
           :on-shutdown (lambda (_conn)
                          (setq session-async--keep-loop-running nil)))))
    (let ((comm-process (jsonrpc--process connection-to-main-emacs)))
      (while session-async--keep-loop-running
        (accept-process-output comm-process 2.0))
      ;; done looping, my purpose has been fulfilled
      ;; but don't kill right away! let bytes flush first
      (run-at-time
       "2 seconds"
       nil
       (lambda ()
         ;; cleanup
         (when (process-live-p comm-process)
           (delete-process comm-process))
         (kill-emacs 0))))))

;;;; API

(defclass session-async-connection (jsonrpc-process-connection)
  ((-emacs-process
    :initarg :emacs-process
    :accessor session-async-connection--emacs-process
    :documentation "Process for the running Emacs instance (we do not
communicate directly to this process).")
   (-listener-process
    :initarg :listener-process
    :accessor session-async-connection--listener-process
    :documentation "Server listening for (single) connection (form Emacs
sessiona instance)"))
  :documentation
  "Connection to a separate Emacs process running")

(defun session-async--create-unique-session-name ()
  "Create a unique name for a (disposable) Emacs session."
  (format "* Emacs session @ %s..%d"
          (format-time-string "%s")
          (random)))

(cl-defmethod jsonrpc-shutdown ((conn session-async-connection)
                                &optional cleanup)
  "Make sure tcp server and Emacs session are killed.
Argument CONN a object/variable `session-async-connection'
Optional argument CLEANUP whether processes should be cleaned."
  (cl-call-next-method)
  (dolist (p (list
              (session-async-connection--emacs-process conn)
              (session-async-connection--listener-process conn)))
    (when (process-live-p p)
      (delete-process p))
    (when (and cleanup
               (process-buffer p))
      (kill-buffer (process-buffer p)))))

;;;###autoload
(cl-defun session-async-new (&optional
                             (session-name (session-async--create-unique-session-name)))
  "Create a new Emacs process ready to communicate through TCP.

Returned session is named as SESSION-NAME

Creates a server on random port, creates separate Emacs session who will connect
here (user-facing Emacs porcess)."
  ;; 1. create server and listen for connections
  ;; 2. launch Emacs session and tell it to connect to server
  ;; 3. server receives connection, creates `session-async-connection' object
  (let* (session-listener-process
         emacs-session-process
         session)
    (setq session-listener-process
          (let ((listener-name
                 (format "%s (listener)"
                         session-name)))
            (make-network-process
             :name listener-name
             :buffer (generate-new-buffer listener-name)
             :server t :host "localhost"
             :noquery t
             :service 0
             :log
             (lambda (listening-server client _message)
               (if session
                   ;; session has already been set
                   ;; this is a second unexpected connection
                   ;; so we ditch it
                   (delete-process client)
                 (push
                  (setq session
                        (session-async-connection
                         :name (format "%s connection" session-name)
                         :emacs-process emacs-session-process
                         :listener-process session-listener-process
                         :process client))
                  (process-get listening-server 'handlers))
                 ;; will associate to current buffer, even when set @ nil
                 (set-process-buffer client
                                     (generate-new-buffer
                                      (format "%s (client)"
                                              session-name)))
                 ;; set :no-query
                 (set-process-query-on-exit-flag client nil))
               session))))
    (setq
     emacs-session-process
     (let* ((default-directory user-emacs-directory)
            (emacs-command (file-truename
                            (expand-file-name invocation-name
                                              invocation-directory)))
            (instance-process-name
             (format "%s (Emacs Session instance)" session-name))
            (command-and-args
             (list
              emacs-command
              "-l"
	      (locate-library "session-async") ;; installed as package
              "-batch"
              "-f" "session-async-eval-loop"
              (format "%d"
                      (process-contact session-listener-process
                                       :service)))))
       (make-process
        :name instance-process-name
        :buffer (generate-new-buffer
                 (format "*%s IO*" instance-process-name))
        :command command-and-args
        :connection-type 'pipe
        :coding 'utf-8-emacs-unix
        :noquery t
        :stderr (generate-new-buffer
                 (format "*%s stderr*" instance-process-name)))))
    (cl-flet ((session-ready? ()
                              (and session
                                   (process-live-p session-listener-process)
                                   (process-live-p emacs-session-process))))
      ;; wait until session is ready
      (let ((i 0))
        (while (and
                (< i 3)
                (not (session-ready?)))
          (accept-process-output
           nil
           0.1)))
      (if (session-ready?) ;; maybe it timed out in `while' loop above
          session
        (session-async--error "Not connected, timed out")))))

(defalias 'session-async-shutdown #'jsonrpc-shutdown)

(defmacro session-async--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with advice added WHERE using FN-ADVICE temporarily on FN-ORIG.

Taken from `undo-fu--with-advice'"
  `
  (let ((fn-advice-var ,fn-advice))
    (unwind-protect
        (progn
          (advice-add ,fn-orig ,where fn-advice-var)
          ,@body)
      (advice-remove ,fn-orig fn-advice-var))))

(defun session-async--jsonrpc-process-sentinel (proc change)
  "Wrap `jsonrpc--process-sentinel' so that `jsonrpc--message' will be silenced.

PROC and CHANGE are forwarded to `jsonrpc--process-sentinel'."
  (session-async--with-advice
   'jsonrpc--message
   :around 'ignore
   (jsonrpc--process-sentinel proc change)))

(cl-defmethod initialize-instance ((conn session-async-connection) _slots)
  "Prevent jsonrpc from printing debug message on process ending.

Argument CONN a object/variable `session-async-connection'."
  (cl-call-next-method)
  (let* ((proc (jsonrpc--process conn)))
    (set-process-sentinel proc #'session-async--jsonrpc-process-sentinel))
  conn)

;;;###autoload
(cl-defun session-async-start (&optional
                               (remote-sexp `(lambda ()))
                               (receive-function 'ignore)
                               running-session)
  "Like `async-start', execute REMOTE-SEXP in separate process.

The result will be passed to RECEIVE-FUNCTION, which defaults to `ignore'

If RUNNING-SESSION is not provided, will create a new one-shot session.

Returns nil."
  (let* ((kill-session-after-done (null running-session))
         (this-session (or running-session
                           (session-async-new)))
         (remote-sexp-as-string
          (session-async--sexp-to-string
           remote-sexp)))
    (jsonrpc-async-request this-session
                           :eval (vector remote-sexp-as-string)
                           :timeout session-async--request-timeout
                           :success-fn
                           (lambda (result-string)
                             (when kill-session-after-done
                               (run-at-time
                                "1 seconds"
                                nil
                                (lambda ()
                                  (session-async-shutdown this-session t))))
                             ;; de-serialize
                             (session-async--deserialize-evaluation
                              result-string
                              receive-function)))
    nil))

;;;###autoload
(cl-defun session-async-future (&optional
                                (remote-sexp `(lambda ()))
                                running-session)
  "Return an iterator for future value for running REMOTE-SEXP in separate proc.

Underneath calls `session-async-start' and returns an iterator that can be
`iter-next'-ed for its value, for which Emacs will block until value is
available.

If RUNNING-SESSION is not provided, will create a new one-shot session."

  (let* (received-status-and-result ;; either nil or `(ok . RESULT)'
         (kill-session-after-done (null running-session))
         (this-session
          (or running-session
              (session-async-new)))
         (iter-l
          (iter-lambda ()
            (let ((session-process
                   (jsonrpc--process this-session)))
              (while (and
                      (null received-status-and-result)
                      (process-live-p session-process))
                (accept-process-output
                 session-process
                 0.1)))
            ;; exited the loop, we can get rid of one-shot session
            (when kill-session-after-done
              (run-at-time
               "1 seconds"
               nil
               (lambda ()
                 (session-async-shutdown this-session t))))
            (if received-status-and-result
                (iter-yield
                 (cdr received-status-and-result))
              (session-async--error "Could not get result for %s"
                                    remote-sexp)))))
    (session-async-start
     remote-sexp
     (lambda (r)
       (setq received-status-and-result
             `(ok . ,r)))
     this-session)
    ;; create iterator and return it
    (funcall iter-l)))

(provide 'session-async)
;;; session-async.el ends here
