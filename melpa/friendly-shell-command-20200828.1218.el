;;; friendly-shell-command.el --- Better shell-command API -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Jordan Besly
;;
;; Version: 0.2.2
;; Package-Version: 20200828.1218
;; Package-Commit: 1b1ba2033e59e5968380640280bd853701fbbb21
;; Keywords: processes, terminals
;; URL: https://github.com/p3r7/friendly-shell
;; Package-Requires: ((emacs "24.1")(cl-lib "0.6.1")(dash "2.17.0")(with-shell-interpreter "0.2.3"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Smarter and more user-friendly shell command executions.
;;
;; Provides wrappers around shell command functions from simple.el with
;; saner defaults and additional keyword arguments:
;;  - `friendly-shell-command-to-string' for `shell-command-to-string'
;;  - `friendly-shell-command' for `shell-command'
;;  - `friendly-shell-command-async' for `async-shell-command'
;;
;; `friendly-shell-command' and `friendly-shell-command-async' can be used
;; as functions or commands (i.e. called interactively).
;;
;; For detailed instructions, please look at each function documentation
;; or the README.md at
;; https://github.com/p3r7/friendly-shell/blob/master/README.md

;;; Code:



;; REQUIRES

(require 'cl-lib)
(require 'dash)

(require 'tramp)
(require 'tramp-sh)

(require 'with-shell-interpreter)



;; (NON-INTERACTIVE) SHELL COMMANDS

(cl-defun friendly-shell-command-to-string (command &key path interpreter command-switch)
  "Call COMMAND w/ `shell-command-to-string' with shell
interpreter :interpreter and at location :path.  If :path is
remote, the command will be executed with the remote host
interpreter.

For more details about all the keyword arguments, see
`with-shell-interpreter'"
  (with-shell-interpreter
    :form (shell-command-to-string command)
    :path path
    :interpreter interpreter
    :command-switch command-switch))

(cl-defun friendly-shell-command-async (command &key output-buffer error-buffer
                                                path interpreter command-switch
                                                callback
                                                kill-buffer
                                                sentinel)
  "Call COMMAND w/ `async-shell-command' with shell interpreter
:interpreter and at location :path. If :path is remote, the
command will be executed with the remote host interpreter.

Usage:

  (friendly-shell-command-async command
     [:keyword [option]]...
     )

:output-buffer      Buffer to output to.
                    Can be a buffer object or a string (buffer name).
                    Defaults to *Async Shell Command*.
:error-buffer       Buffer to output stderr to.
                    If not specified, errors will appear in :output-buffer.
:kill-buffer        If t, the output buffer will get killed automatically
                    at the end of command execution.
:callback           Function to run at the end of the command execution.
                    Should take no argument.
:sentinel           Process sentinel function to associate to the command
                    process.
                    Takes 2 arguments: process and output.
                    See `set-process-sentinel' for more information.


For more details about the remaining keyword arguments, see `with-shell-interpreter'"
  (with-shell-interpreter
    :form
    (let* ((win (async-shell-command command output-buffer error-buffer))
           (buffer-name (or output-buffer "*Async Shell Command*"))
           (process (get-buffer-process buffer-name)))
      ;; REVIEW: do not kill in case of error ?
      ;; not sure we can grab the errno for async commands
      ;; but can still see if :error-buffer is not empty I guess...
      (when (or sentinel callback kill-buffer)
        (let ((combined-sentinel
               (friendly-shell-command--build-process-sentinel
                process
                :sentinel sentinel
                :callback callback
                :kill-buffer kill-buffer)))
          ;; REVIEW: why not use `set-process-sentinel'
          (setf (process-sentinel process) combined-sentinel)))
      win)
    :path path
    :interpreter interpreter
    :command-switch command-switch))

(cl-defun friendly-shell-command (command &key output-buffer error-buffer
                                          callback kill-buffer
                                          path interpreter command-switch)
  "Call COMMAND w/ `shell-command' with shell interpreter
:interpreter and at location :path. If :path is remote, the
command will be executed with the remote host interpreter.

Usage:

  (friendly-shell-command command
     [:keyword [option]]...
     )

:output-buffer      Buffer to output to.
                    Can be a buffer object or a string (buffer name).
                    Defaults to *Shell Command Output*.
:error-buffer       Buffer to output stderr to.
                    If not specified, errors will appear in :output-buffer.
:kill-buffer        If t, the output buffer will get killed automatically
                    at the end of command execution.
:callback           Function to run at the end of the command execution.
                    Should take no argument.

For more details about the remaining keyword arguments, see `with-shell-interpreter'"
  (with-shell-interpreter
    :form
    (let ((errno (shell-command command output-buffer error-buffer))
          (buffer-name (or output-buffer "*Shell Command Output*")))
      (when callback
        (funcall callback))
      (when kill-buffer
        (kill-buffer buffer-name))
      errno)
    :path path
    :interpreter interpreter
    :command-switch command-switch))



;; HELPERS: PROCESS SENTINELS

(defun friendly-shell-command--kill-buffer-sentinel (process _output)
  "Process sentinel to auto kill associated buffer once PROCESS dies."
  (unless (process-live-p process)
    (kill-buffer (process-buffer process))))

(cl-defun friendly-shell-command--build-process-sentinel (process &key sentinel callback kill-buffer)
  "Build a process sentinel for PROCESS.

The output process sentinel is the merge of:
 - :sentinel, if set
 - :callback, if set
 - `friendly-shell-command--kill-buffer-sentinel' if :kill-buffer is t"
  (let (callback-sentinel kill-buffer-sentinel sentinel-list)
    (when kill-buffer
      (setq kill-buffer-sentinel #'friendly-shell-command--kill-buffer-sentinel))
    (when callback
      (setq callback-sentinel (lambda (_process _output)
                                (unless (process-live-p process)
                                  (funcall callback)))))
    (setq sentinel-list (-remove #'null
                                 (list sentinel callback-sentinel kill-buffer-sentinel)))
    (lambda (process line)
      (--each sentinel-list
        (funcall it process line)))))




(provide 'friendly-shell-command)

;;; friendly-shell-command.el ends here
