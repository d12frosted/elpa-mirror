;;; buffer-env.el --- Buffer-local process environments -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Augusto Stoffel

;; Author: Augusto Stoffel <arstoffel@gmail.com>
;; URL: https://github.com/astoff/buffer-env
;; Package-Version: 20210520.1616
;; Package-Commit: 32c1cfdf06dfa7bdbd79aba8066064212672e755
;; Keywords: processes, tools
;; Package-Requires: ((emacs "27.1"))
;; Version: 0.1

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

;; This package adjusts the `process-environment' and `exec-path'
;; variables buffer locally according to the output of a shell script.
;; The idea is that the same scripts used elsewhere to set up a
;; project environment can influence external processes started from
;; buffers editing the project files.  This is important for the
;; correct operation of tools such as linters, language servers and
;; the `compile' command, for instance.

;; The default settings of the package are compatible with the popular
;; direnv program.  However, this package is entirely independent of
;; direnv and it's not possible to use direnv-specific features in the
;; .envrc scripts.  On the plus side, it's possible to configure the
;; package to support other environment setup methods, such as .env
;; files or Python virtualenvs.  The package Readme includes some
;; examples.

;; The usual way to activate this package is by including the
;; following in your init file:
;;
;;     (add-hook 'hack-local-variables-hook 'buffer-env-update)
;;
;; This way, any buffer potentially affected by directory-local
;; variables can also be affected by buffer-env.  It is nonetheless
;; possible to call `buffer-env-update' interactively or add it only
;; to specific major-mode hooks.

;; Note that it is quite common for process-executing Emacs libraries
;; not to heed to the fact that `process-environment' and `exec-path'
;; may have a buffer-local value.  This unfortunate state of affairs
;; can be remedied by the `inheritenv' package, which see.

;;; Code:

(require 'seq)
(eval-when-compile (require 'subr-x))

(defgroup buffer-env nil
  "Buffer-local process environments."
  :group 'processes)

(defcustom buffer-env-script-name ".envrc"
  "Base name of the script to produce environment variables."
  :type 'string)

(defcustom buffer-env-command ">&2 . \"$0\" && env -0"
  "Command to produce environment variables.
This string is executed as a command in a shell, in the directory
of the environment script, with its absolute file name as
argument.  The command should print a null-separated list of
environment variables, and nothing else, to the standard
output."
  :type 'string)

(defcustom buffer-env-safe-files nil
  "List of scripts marked as safe to execute.
Entries are conses consisting of the file name and a hash of its
content."
  :type 'alist)

(defcustom buffer-env-ignored-variables
  '("_=" "PS1=" "SHLVL=" "DISPLAY=" "PWD=")
  "List of environment variables to ignore."
  :type '(string))

(defcustom buffer-env-extra-variables
  '("TERM=dumb")
  "List of additional environment variables."
  :type '(string))

(defun buffer-env--authorize (file)
  "Check if FILE is safe to execute, or ask for permission.
Files marked as safe to execute are permanently stored in
`buffer-env-safe-files' via the Custom mechanism."
  (let ((hash (with-temp-buffer
                (insert-file-contents-literally file)
                (secure-hash 'sha256 (current-buffer)))))
    (or (member (cons file hash) buffer-env-safe-files)
        (when (y-or-n-p (format-message "Mark current version of `%s' as safe to execute? "
                                        file))
          (customize-save-variable 'buffer-env-safe-files
                                   (push (cons file hash)
                                         buffer-env-safe-files))))))

(defun buffer-env--locate-script ()
  "Locate a dominating file named `buffer-env-script-name'."
  (when-let* ((dir (and (stringp buffer-env-script-name)
                        (not (file-remote-p default-directory))
                        (locate-dominating-file default-directory
                                                buffer-env-script-name))))
    (expand-file-name buffer-env-script-name dir)))

;;;###autoload
(defun buffer-env-update (&optional file)
  "Update the process environment buffer locally.
This function executes FILE in a shell, collects the exported
variables (see `buffer-env-command' for details), and then sets
the buffer-local values of the variables `exec-path' and
`process-environment' accordingly.

If FILE omitted, a file with base name `buffer-env-script-name'
is looked up in the current directory and its parents; nothing
happens if no such file is found.  This makes this function
suitable for use in a normal hook.

When called interactively, ask for a FILE."
  (interactive (list (let ((file (buffer-env--locate-script)))
                       (read-file-name "Environment script: "
                                       file file t))))
  (when-let* ((file (if file
                        (expand-file-name file)
                     (buffer-env--locate-script)))
              ((buffer-env--authorize file))
              (vars (with-temp-buffer
                      (let* ((default-directory (file-name-directory file))
                             (status (call-process shell-file-name nil t nil
                                                   shell-command-switch
                                                   buffer-env-command
                                                   file)))
                        (if (eq 0 status)
                            (split-string (buffer-substring (point-min) (point-max))
                                          "\0" t)
                          (prog1 nil
                            (message "[buffer-env] Error in `%s', exit status %s"
                                     file status)))))))
    (setq-local process-environment
                (nconc (seq-remove (lambda (var)
                                     (seq-contains-p buffer-env-ignored-variables var
                                                     'string-prefix-p))
                                   vars)
                       buffer-env-extra-variables))
    (when-let* ((path (getenv "PATH")))
      (setq-local exec-path (nconc (split-string path path-separator)
                                   (list exec-directory))))
    (unless (string-prefix-p " " (buffer-name (current-buffer)))
      (message "[buffer-env] Environment of `%s' set from `%s'"
               (current-buffer)
               file))))

;;;###autoload
(defun buffer-env-reset ()
  "Reset this buffer's process environment to the global values."
  (interactive)
  (kill-local-variable 'process-environment)
  (kill-local-variable 'exec-path))

(provide 'buffer-env)
;;; buffer-env.el ends here
