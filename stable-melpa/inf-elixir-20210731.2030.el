;;; inf-elixir.el --- Run an interactive Elixir shell -*- lexical-binding: t -*-

;; Copyright © 2019–2021 Jonathan Arnett <jonathan.arnett@protonmail.com>

;; Author: Jonathan Arnett <jonathan.arnett@protonmail.com>
;; URL: https://github.com/J3RN/inf-elixir
;; Package-Version: 20210731.2030
;; Package-Commit: 404f88530975e3540f357f6a4f96c864bd19065b
;; Keywords: languages, processes, tools
;; Version: 2.0.0
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this package. If not, see https://www.gnu.org/licenses.

;;; Commentary:

;; Provides access to an IEx shell buffer, optionally running a
;; specific command (e.g. iex -S mix, iex -S mix phx.server, etc)

;;; Code:

(require 'comint)
(require 'subr-x)


;;; Customization
(defgroup inf-elixir nil
  "Ability to interact with an Elixir REPL."
  :prefix "inf-elixir-"
  :group 'languages)

(defcustom inf-elixir-prefer-umbrella t
  "Whether or not to prefer running the REPL from the umbrella, if it exists.

If there is no umbrella project, the value of this variable is irrelevant."
  :type 'boolean
  :group 'inf-elixir)

(defcustom inf-elixir-base-command "iex"
  "The command that forms the base of all REPL commands.

Should be able to be run without any arguments."
  :type 'string
  :group 'inf-elixir)

(defcustom inf-elixir-project-command "iex -S mix"
  "The command used to start a REPL in the context of the current project."
  :type 'string
  :group 'inf-elixir)

(defcustom inf-elixir-open-command "emacsclient --no-wait +__LINE__ __FILE__"
  "Value to be populated into the `ELIXIR_EDITOR' environment variable.

The `ELIXIR_EDITOR' is used by the IEx `open/1' helper to open files from the
REPL.  Run `h(open)' in an IEx shell for more information about `ELIXIR_EDITOR'.

NOTE: Changing this variable will not affect running REPLs."
  :type 'string
  :group 'inf-elixir)


;;; Mode definitions and configuration
(defvar inf-elixir-project-buffers (make-hash-table :test 'equal)
  "A mapping of projects to buffers with running Elixir REPL subprocesses.")

;;;###autoload
(define-minor-mode inf-elixir-minor-mode
  "Minor mode for Elixir buffers that allows interacting with the REPL.")

;;;###autoload
(define-derived-mode inf-elixir-mode comint-mode "Inf-Elixir"
  "Major mode for interacting with an Elixir REPL.")


;;; Private functions

(defun inf-elixir--up-directory (dir)
  "Return the directory above DIR."
  (file-name-directory (directory-file-name dir)))

(defun inf-elixir--find-umbrella-root (start-dir)
  "Traverse upwards from START-DIR until highest mix.exs file is discovered."
  (when-let ((project-dir (locate-dominating-file start-dir "mix.exs")))
    (or (inf-elixir--find-umbrella-root (inf-elixir--up-directory project-dir))
        project-dir)))

(defun inf-elixir--find-project-root ()
  "Find the root of the current Elixir project."
  (if inf-elixir-prefer-umbrella
      (inf-elixir--find-umbrella-root default-directory)
    (locate-dominating-file default-directory "mix.exs")))

(defun inf-elixir--get-project-buffer (dir)
  "Find the REPL buffer for project DIR."
  (gethash dir inf-elixir-project-buffers))

(defun inf-elixir--set-project-buffer (dir buf)
  "Set BUF to be the REPL buffer for project DIR."
  (puthash dir buf inf-elixir-project-buffers))

(defun inf-elixir--get-project-process (dir)
  "Find the process for project DIR."
  (get-buffer-process (inf-elixir--get-project-buffer dir)))

(defun inf-elixir--project-name (dir)
  "Determine a human-readable name for DIR."
  (if dir
      (file-name-nondirectory (directory-file-name dir))
    ""))

(defun inf-elixir--buffer-name (dir)
  "Generate a REPL buffer name for DIR."
  (if dir
      (concat "Inf-Elixir - " (inf-elixir--project-name dir))
    "Inf-Elixir"))

(defun inf-elixir--maybe-kill-repl (dir)
  "If a REPL is already running in DIR, ask user if they want to kill it."
  (let ((proc (inf-elixir--get-project-process dir))
        (name (inf-elixir--project-name dir)))
    (when (and
           proc
           (yes-or-no-p
                (concat "An Elixir REPL is already running in " name ". Kill it? ")))
      (delete-process proc))))

(defun inf-elixir--maybe-clear-repl (dir)
  "Clear the REPL buffer for project DIR if the process is dead."
  (when-let ((buf (inf-elixir--get-project-buffer dir)))
    (if (and
         (buffer-live-p buf)
         (not (process-live-p (get-buffer-process buf))))
        (with-current-buffer buf (erase-buffer)))))

(defun inf-elixir--maybe-start-repl (dir cmd)
  "If no REPL is running in DIR, start one with CMD.

Always returns a REPL buffer for DIR."
  (let ((buf-name (inf-elixir--buffer-name dir)))
    (if (process-live-p (inf-elixir--get-project-process dir))
        (inf-elixir--get-project-buffer dir)
      (setenv "ELIXIR_EDITOR" inf-elixir-open-command)
      (with-current-buffer
          (apply #'make-comint-in-buffer buf-name nil (car cmd) nil (cdr cmd))
        (inf-elixir-mode)
        (when dir (inf-elixir--set-project-buffer dir (current-buffer)))
        (current-buffer)))))

(defun inf-elixir--send (command)
  "Send COMMAND to the REPL process in BUF."
  (let* ((proj-dir (inf-elixir--find-project-root))
         (proj-buf (inf-elixir--get-project-buffer proj-dir)))
    (if (process-live-p (get-buffer-process proj-buf))
        (with-current-buffer proj-buf
          (comint-add-to-input-history command)
          (comint-send-string proj-buf (concat command "\n")))
      (message (concat "No REPL running in " (inf-elixir--project-name proj-dir))))))


;;; Public functions

;;;###autoload
(defun inf-elixir-run-cmd (dir cmd)
  "Create a new IEx buffer and run CMD in project DIR.

DIR should be an absolute path to the root level of a Mix project (where the
mix.exs file is).  A value of nil for DIR indicates that the REPL should not
belong to any project."
  (inf-elixir--maybe-kill-repl dir)
  (inf-elixir--maybe-clear-repl dir)
  (pop-to-buffer (inf-elixir--maybe-start-repl dir (split-string cmd))))

;;;###autoload
(defun inf-elixir (&optional cmd)
  "Create an Elixir REPL, using CMD if given.

When called from ELisp, an argument (CMD) can be passed which will be the
command run to start the REPL.  The default is provided by
`inf-elixir-base-command'.

When called interactively with a prefix argument, the user will
be prompted for the REPL command.  The default is provided by
`inf-elixir-base-command'."
  (interactive)
  (let ((cmd (cond
              (cmd cmd)
              (current-prefix-arg (read-from-minibuffer "Command: " inf-elixir-base-command nil nil 'inf-elixir))
              (t inf-elixir-base-command))))
    (inf-elixir-run-cmd nil cmd)))

;;;###autoload
(defun inf-elixir-project (&optional cmd)
  "Create a REPL in the context of the current project, using CMD if given.

If an existing REPL already exists for the current project, the user will be
asked whether they want to keep the running REPL or replace it.

When called from ELisp, an argument (CMD) can be passed which will be the
command run to start the REPL.  The default is provided by
`inf-elixir-project-command'.

When called interactively with a prefix argument, the user will
be prompted for the REPL command.  The default is provided by
`inf-elixir-project-command'."
  (interactive)
  (let ((default-directory (inf-elixir--find-project-root))
        (cmd (cond
              (cmd cmd)
              (current-prefix-arg (read-from-minibuffer "Project command: " inf-elixir-project-command nil nil 'inf-elixir-project))
              (t inf-elixir-project-command))))
    (inf-elixir-run-cmd default-directory cmd)))

(defun inf-elixir-send-line ()
  "Send the region to the REPL buffer and run it."
  (interactive)
  (inf-elixir--send (buffer-substring (point-at-bol) (point-at-eol))))

(defun inf-elixir-send-region ()
  "Send the region to the REPL buffer and run it."
  (interactive)
  (inf-elixir--send (buffer-substring (point) (mark))))

(defun inf-elixir-send-buffer ()
  "Send the buffer to the REPL buffer and run it."
  (interactive)
  (inf-elixir--send (buffer-string)))

(provide 'inf-elixir)

;;; inf-elixir.el ends here
