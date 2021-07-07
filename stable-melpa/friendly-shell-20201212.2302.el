;;; friendly-shell.el --- Better shell-mode API -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Jordan Besly
;;
;; Version: 0.2.4
;; Package-Version: 20201212.2302
;; Package-Commit: ad4ac00662829fa18858be02b322753ad091ffe3
;; Keywords: processes, terminals
;; URL: https://github.com/p3r7/friendly-shell
;; Package-Requires: ((emacs "24.1")(cl-lib "0.6.1")(dash "2.17.0")(with-shell-interpreter "0.2.4"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Smarter and more user-friendly interactive shell.
;;
;; Provides `friendly-shell', a wrapper around `shell' with saner defaults
;; and additional keyword arguments.
;;
;; Can be used as a function or command (i.e. called interactively).
;;
;; For detailed instructions, please look at the function documentation or
;; the README.md at
;; https://github.com/p3r7/friendly-shell/blob/master/README.md

;;; Code:



;; REQUIRES

(require 'cl-lib)
(require 'dash)

(require 'tramp)
(require 'tramp-sh)

(require 'with-shell-interpreter)



;; VARS

(defvar friendly-shell-spawn-in-same-win 't
  "If 't, shell buffers will spawn in the same window.")

(defvar friendly-shell-default-buffer-name "shell"
  "Default buffer name for local shells.")
(defvar friendly-shell-buffer-local-name-construction-fn #'friendly-shell--generate-buffer-name-local
  "Function to generate local shell buffer names.")
(defvar friendly-shell-buffer-remote-name-construction-fn #'friendly-shell--generate-buffer-name-remote
  "Function to generate remote shell buffer names.")

;; NB: only bound on Windows build of Emacs
(unless (boundp 'w32-quote-process-args)
  ;; tame lexical binding warnings
  (defvar w32-quote-process-args))



;; INTERACTIVE SHELLS

(cl-defun friendly-shell (&key path
                               interpreter interpreter-args
                               command-switch
                               w32-arg-quote
                               allow-local-vars
                               buffer-name)
  "Create a shell with shell interpreter :interpreter and at
location :path. If :path is remote, the command will be executed
with the remote host interpreter.

Usage:

  (friendly-shell
     [:keyword [option]]...
     )

For more details about the keyword arguments, see `with-shell-interpreter'"
  (interactive)

  (with-shell-interpreter
    :path path
    :interpreter interpreter
    :interpreter-args interpreter-args
    :command-switch command-switch
    :w32-arg-quote w32-arg-quote
    :allow-local-vars allow-local-vars
    :form

    ;; NB: duplicated code from `with-shell-interpreter', but necessary as not special vars and lexical binding is on
    (cl-destructuring-bind (path
                            is-remote
                            allow-buffer-local-vars
                            allow-cnnx-local-vars cnnx-local-vars
                            interpreter interpreter-name
                            explicit-interpreter-args-var)
        (with-shell-interpreter--generate-props path interpreter allow-local-vars)
      (let* (
             ;; shell buffer name
             (shell-buffer-basename (or buffer-name
                                        (friendly-shell--generate-buffer-name is-remote interpreter default-directory)))
             (shell-buffer-name (generate-new-buffer-name (concat "*" shell-buffer-basename "*")))
             (shell-buffer (get-buffer-create shell-buffer-name))
             ;; special vars
             (current-prefix-arg '(4))
             ;; copies of special vars set by with-shell-interpreter
             (og-explicit-shell-file-name explicit-shell-file-name)
             (og-shell-file-name shell-file-name)
             (og-explicit-interpreter-args (symbol-value explicit-interpreter-args-var))
             (og-shell-command-switch shell-command-switch)
             (og-w32-quote-process-args w32-quote-process-args)
             (og-comint-process-echoes (friendly-shell--stty-echo-p og-explicit-interpreter-args)))

        (when friendly-shell-spawn-in-same-win
          (friendly-shell--maybe-register-buffer-display-same-win shell-buffer-basename))

        (with-current-buffer shell-buffer
          ;; NB: when making those var buffer-local, we seem to be forced to bind them to the buffer beforehand
          ;; otherwise, starting from 2nd launched shell, lexical binding will be ignored
          (set (make-local-variable 'explicit-shell-file-name) og-explicit-shell-file-name)
          (set (make-local-variable 'shell-file-name) og-shell-file-name)
          (set (make-local-variable explicit-interpreter-args-var) og-explicit-interpreter-args)
          ;; NB: necessary when launching `shell-command' and friends from the interactive shell buffer
          (set (make-local-variable 'shell-command-switch) og-shell-command-switch)
          (when (boundp 'w32-quote-process-args)
            (set (make-local-variable 'shell-command-switch) og-w32-quote-process-args))
          (set (make-local-variable 'comint-process-echoes) og-comint-process-echoes))

        (shell shell-buffer)

        (with-current-buffer shell-buffer
          ;; NB: comint / shell undoes some of our bindings, so we need to set them back
          (set (make-local-variable 'explicit-shell-file-name) og-explicit-shell-file-name)
          (set (make-local-variable 'shell-file-name) og-shell-file-name)
          (set (make-local-variable explicit-interpreter-args-var) og-explicit-interpreter-args)
          (set (make-local-variable 'shell-command-switch) og-shell-command-switch)
          (when (boundp 'w32-quote-process-args)
            (set (make-local-variable 'shell-command-switch) og-w32-quote-process-args))
          (set (make-local-variable 'comint-process-echoes) og-comint-process-echoes))

        shell-buffer))))



;; PRIVATE UTILS: BUFFER NAME

(defun friendly-shell--generate-buffer-name (is-remote interpreter path)
  "Generate a buffer name according to INTERPRETER, PATH and whether IS-REMOTE or not."
  (let ((fn (if is-remote
                friendly-shell-buffer-remote-name-construction-fn
              friendly-shell-buffer-local-name-construction-fn)))
    (funcall fn interpreter path)))

(defun friendly-shell--generate-buffer-name-local (&optional interpreter _path)
  "Generate a buffer name for local shell, according to INTERPRETER."
  (if interpreter
      (with-shell-interpreter--interpreter-name interpreter)
    friendly-shell-default-buffer-name))

(defun friendly-shell--generate-buffer-name-remote (&optional _interpreter path)
  "Generate a buffer name for remote shell, according to PATH."
  (let ((vec (tramp-dissect-file-name path)))
    (friendly-shell--generate-buffer-name-remote-from-vec vec)))

(defun friendly-shell--generate-buffer-name-remote-from-vec (vec)
  "Generate a buffer name for remote shell, from VEC (split tramp path)."
  (concat
   (tramp-file-name-user vec) "@" (tramp-file-name-host vec)))



;; PRIVATE UTILS: STTY ECHO?

(defun friendly-shell--stty-echo-p (explicit-interpreter-args)
  "Return t when \"stty echo\" is set through EXPLICIT-INTERPRETER-ARGS."
  ;; NB: we do not handle a edge-case scenario where would first "stty echo" and then "stty -echo"
  (not (-all? #'null
              (--map
               (string-match-p (regexp-quote "stty echo") it)
               explicit-interpreter-args))))



;; PRIVATE UTILS: BUFFER DISPLAY BEHAVIOR

(defun friendly-shell--maybe-register-buffer-display-same-win (basename)
  "If necessary, register buffer buffers containing BASENAME as spawning in the same window."
  (let ((entry `(,(concat "^\\*" basename "\\*\\(.*\\)$") display-buffer-same-window)))
    ;; NB: before Emacs 25, shell-mode buffers would display in same window.
    (when (and (>= emacs-major-version 25)
               (not (member entry display-buffer-alist)))
      (add-to-list 'display-buffer-alist entry))))




(provide 'friendly-shell)

;;; friendly-shell.el ends here
