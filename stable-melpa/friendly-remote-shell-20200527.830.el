;;; friendly-remote-shell.el --- Human-friendly remote interactive shells -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Jordan Besly
;;
;; Version: 0.2.2
;; Package-Version: 20200527.830
;; Package-Commit: ad4ac00662829fa18858be02b322753ad091ffe3
;; Keywords: processes, terminals
;; URL: https://github.com/p3r7/friendly-shell
;; Package-Requires: ((emacs "24.1")(cl-lib "0.6.1")(with-shell-interpreter "0.2.3")(friendly-tramp-path "0.1.0")(friendly-shell "0.2.0"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Smarter and more user-friendly interactive remote shell.
;;
;; Provides `friendly-remote-shell', a command that eases the creation of
;; remote shells. It's basically a wrapper around `shell' with saner
;; defaults and additional keyword arguments.
;;
;; It can also be used as a regular function (programmatically).
;;
;; For detailed instructions, please look at the function documentation or
;; the README.md at
;; https://github.com/p3r7/friendly-shell/blob/master/README.md

;;; Code:



;; REQUIRES

(require 'cl-lib)

(require 'tramp)
(require 'tramp-sh)

(require 'friendly-tramp-path)
(require 'with-shell-interpreter)
(require 'friendly-shell)



;; VARS

(defvar friendly-remote-shell-buffer-name-regexp "^\\*\\(.*\\)@\\(.*\\)\\*\\(.*\\)$")



;; PRIVATE MACROS

(defmacro friendly-remote-shell--make-tramp-file-name (vec)
  "Construct Tramp file name from Tramp VEC.
Handles the signature of `tramp-make-tramp-file-name' changing
over time."
  (if (>= emacs-major-version 26)
      `(let ((method (tramp-file-name-method ,vec))
             (user (tramp-file-name-user ,vec))
             (domain (tramp-file-name-domain ,vec))
             (host (tramp-file-name-host ,vec))
             (port (tramp-file-name-port ,vec))
             (localname (tramp-file-name-localname ,vec)))
         (tramp-make-tramp-file-name method
                                     user domain
                                     host port
                                     localname))
    `(let ((method (tramp-file-name-method ,vec))
           (user (tramp-file-name-user ,vec))
           (host (tramp-file-name-host ,vec))
           (localname (tramp-file-name-localname ,vec)))
       (tramp-make-tramp-file-name method
                                   user
                                   host
                                   localname))))



;; INTERACTIVE SHELLS

(cl-defun friendly-remote-shell (&key path
                                      interpreter interpreter-args
                                      command-switch
                                      w32-arg-quote)
  "Open a remote shell to host (extracted from :path).
User-friendly wrapper around `friendly-shell' for remote connections.

If not specified, prompt the user for :path.

:path can be in any format supported by `friendly-tramp-path-dissect':
 - \"/<method>:[<user>[%<domain>]@]<host>[%<port>][:<localname>]\" (regular TRAMP format)
 - \"[<user>[%<domain>]@]<host>[%<port>][:<localname>]\" (permissive format)

For more details about all the keyword arguments, see `with-shell-interpreter'."
  (interactive)
  (let* ((path (or path (read-string "Host: ")))
         (path (with-shell-interpreter--normalize-path path))
         (vec (friendly-tramp-path-dissect path))
         (path (friendly-remote-shell--make-tramp-file-name vec)))
    (friendly-shell :path path
                    :interpreter interpreter
                    :interpreter-args interpreter-args
                    :command-switch command-switch
                    :w32-arg-quote w32-arg-quote)))



;; INIT

(defun friendly-remote-shell-register-display-same-window ()
  "Register remote shell buffers to display in same window.
Assumes `friendly-remote-shell-buffer-name-regexp' and `prf/shell-buffer-remote-name-construction-fn' are kept with their default values."
  (when (>= emacs-major-version 25)
    ;; NB: before Emacs 25, shell-mode buffers would display in same window.
    (add-to-list 'display-buffer-alist `(,friendly-remote-shell-buffer-name-regexp display-buffer-same-window))))




(provide 'friendly-remote-shell)

;;; friendly-remote-shell.el ends here
