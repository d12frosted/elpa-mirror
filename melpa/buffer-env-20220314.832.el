;;; buffer-env.el --- Buffer-local process environments -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Augusto Stoffel <arstoffel@gmail.com>
;; URL: https://github.com/astoff/buffer-env
;; Package-Version: 20220314.832
;; Package-Commit: 5d0a3d67c9ae196bd44c9d41edc60cb59550eb21
;; Keywords: processes, tools
;; Package-Requires: ((emacs "27.1"))
;; Version: 0.2

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

;; The purpose of this package is to adjust the `process-environment'
;; and `exec-path' variables buffer locally according to the output of
;; a shell script.  This allows the correct operation of tools such as
;; linters, compilers and language servers when working on projects
;; with special requirements which are not installed globally on the
;; system.

;; The default settings of this package are compatible with the
;; popular direnv program.  However, the package is entirely
;; independent of direnv and it's not possible to use direnv-specific
;; features in the .envrc scripts.  On the plus side, it's possible to
;; configure the package to support other environment setup methods,
;; such as .env files or Python virtualenvs.  The README file includes
;; some examples.

;; The usual way to activate this package is by including the
;; following in your init file:
;;
;;     (add-hook 'hack-local-variables-hook 'buffer-env-update)
;;
;; This way, any buffer potentially affected by directory-local
;; variables will also be affected by buffer-env.  It is nonetheless
;; possible to call `buffer-env-update' interactively or add it only
;; to specific major-mode hooks.

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
  :type '(repeat string))

(defcustom buffer-env-extra-variables
  '("TERM=dumb")
  "List of additional environment variables."
  :type '(repeat string))

(defcustom buffer-env-verbose nil
  "Whether to display a message every time `buffer-env-update' runs successfully."
  :type 'boolean)

(defcustom buffer-env-mode-line " Env"
  "Mode line indicator for buffers affected by buffer-env."
  :type '(choice string (const :tag "No indicator" nil)))

(defvar-local buffer-env-active nil
  "Non-nil if a buffer-local process environment has been set.
In this case, this is the name of the script used to generate it.")

(setf (alist-get 'buffer-env-active minor-mode-alist)
      '((:propertize
         buffer-env-mode-line
         help-echo "\
Process environment is buffer local\n\
mouse-1: Inspect process environment\n\
mouse-2: Reset to default process environment"
         mouse-face mode-line-highlight
         local-map (keymap (mode-line keymap
                                      (mouse-1 . buffer-env-inspect)
                                      (mouse-2 . buffer-env-reset))))))

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
              (command buffer-env-command)
              ((buffer-env--authorize file))
              (vars (with-temp-buffer
                      (let* ((default-directory (file-name-directory file))
                             (status (call-process shell-file-name nil t nil
                                                   shell-command-switch
                                                   command file)))
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
    (when buffer-env-verbose
      (message "[buffer-env] Environment of `%s' set from `%s'"
               (current-buffer) file))
    (setq buffer-env-active file)))

;;;###autoload
(defun buffer-env-reset ()
  "Reset the process environment of this buffer to the default values."
  (interactive)
  (kill-local-variable 'buffer-env-active)
  (kill-local-variable 'process-environment)
  (kill-local-variable 'exec-path)
  (force-mode-line-update))

(defun buffer-env--sorted (vars)
  "Sort and remove duplicates in the list of environment VARS."
  (let ((testfn (lambda (x y)
                  (string= (progn (string-match "[^=]*" x)
                                  (match-string 0 x))
                           (progn (string-match "[^=]*" y)
                                  (match-string 0 y))))))
    (sort (seq-uniq vars testfn) 'string<)))

(defun buffer-env-inspect ()
  "Compare buffer-local and global process environments."
  (interactive)
  (if (not (local-variable-p 'process-environment))
      (message "Buffer has the default process environment")
    (let ((name (buffer-name (current-buffer)))
          (script buffer-env-active)
          (local (buffer-env--sorted process-environment))
          (global (buffer-env--sorted (default-toplevel-value 'process-environment)))
          (buffer (get-buffer-create "*buffer-env*"))
          (inhibit-read-only t))
      (with-current-buffer buffer
        (special-mode)
        (erase-buffer)
        (insert "The process environment of buffer ‘" name
                "’ was generated by the script ‘" (or script "??") "’.")
        (fill-paragraph)
        (insert "\n\nOnly in the local process environment:\n\n")
        (add-face-text-property (line-beginning-position -2) (point) 'bold)
        (if-let ((vars (seq-difference local global)))
            (dolist (var vars) (insert var ?\n))
          (insert "(None)"))
        (insert "\nOnly in the global process environment:\n\n")
        (add-face-text-property (line-beginning-position -2) (point) 'bold)
        (if-let ((vars (seq-difference global local)))
            (dolist (var vars) (insert var ?\n))
          (insert "(None)"))
        (insert "\nComplete process environment of the buffer:\n\n")
        (add-face-text-property (line-beginning-position -2) (point) 'bold)
        (dolist (var local) (insert var ?\n))
        (goto-char (point-min)))
      (display-buffer buffer))))

(provide 'buffer-env)
;;; buffer-env.el ends here
