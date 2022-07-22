;;; inf-elixir.el --- Run an interactive Elixir shell -*- lexical-binding: t -*-

;; Copyright © 2019–2021 Jonathan Arnett <jonathan.arnett@protonmail.com>

;; Author: Jonathan Arnett <jonathan.arnett@protonmail.com>
;; URL: https://github.com/J3RN/inf-elixir
;; Package-Version: 20220721.1939
;; Package-Commit: 5b45f5bd346446d87c629794b3c3e586c3eefd9c
;; Keywords: languages, processes, tools
;; Version: 2.1.2
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
(require 'map)


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

(defcustom inf-elixir-repl-buffer nil
  "Override for what REPL buffer code snippets should be sent to.

If this variable is set and the corresponding REPL buffer exists
and has a living process, all `inf-elixir-send-*' commands will
send to it.  If this variable is unset (the default) or the
indicated buffer is dead or has a dead process, a warning will be
printed instead."
  :type 'buffer
  :group 'inf-elixir)


;;; Mode definitions and configuration
(defvar inf-elixir-project-buffers (make-hash-table :test 'equal)
  "A mapping of projects to buffers with running Elixir REPL subprocesses.")

(defvar inf-elixir-unaffiliated-buffers '()
  "A list of Elixir REPL buffers unaffiliated with any project.")

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
        (if dir
            (inf-elixir--set-project-buffer dir (current-buffer))
          (add-to-list 'inf-elixir-unaffiliated-buffers (current-buffer)))
        (current-buffer)))))

(defun inf-elixir--send (cmd)
  "Determine where to send CMD and send it."
  (when-let ((buf (inf-elixir--determine-repl-buf)))
    (with-current-buffer buf
      (comint-add-to-input-history cmd)
      (comint-send-string buf (concat cmd "\n")))
    (pop-to-buffer buf)))

(defun inf-elixir--determine-repl-buf ()
  "Determines where to send a cmd when `inf-elixir-send-*' are used."
  (if inf-elixir-repl-buffer
      (if (process-live-p (get-buffer-process inf-elixir-repl-buffer))
          inf-elixir-repl-buffer
        (inf-elixir--prompt-repl-buffers "`inf-elixir-repl-buffer' is dead, please choose another REPL buffer: "))
    (if-let ((proj-dir (inf-elixir--find-project-root)))
        (inf-elixir--determine-project-repl-buf proj-dir)
      (inf-elixir--prompt-repl-buffers))))

(defun inf-elixir--determine-project-repl-buf (proj-dir)
  "Determines where to send a cmd when `inf-elixir-send-*' are used inside the PROJ-DIR Mix project."
  (if-let ((proj-buf (inf-elixir--get-project-buffer proj-dir)))
      (if (process-live-p (get-buffer-process proj-buf))
          proj-buf
        (if (y-or-n-p "A project REPL buffer exists, but the process is dead.  Start a new one? ")
            (inf-elixir-project)
          (inf-elixir--prompt-repl-buffers)))
    (if (y-or-n-p "No REPL exists for this project yet.  Start one? ")
        (inf-elixir-project)
      (inf-elixir--prompt-repl-buffers))))

(defun inf-elixir--prompt-repl-buffers (&optional prompt)
  "Prompt the user to select an inf-elixir REPL buffers or create an new one.

Returns the select buffer (as a buffer object).

If PROMPT is supplied, it is used as the prompt for a REPL buffer.

When the user selects a REPL, it is set as `inf-elixir-repl-buffer' locally in
the buffer so that the choice is remembered for that buffer."
  ;; Cleanup
  (setq inf-elixir-unaffiliated-buffers (seq-filter 'buffer-live-p inf-elixir-unaffiliated-buffers))
  (setq inf-elixir-project-buffers
        (map-into
         (map-filter (lambda (_dir buf) (buffer-live-p buf)) inf-elixir-project-buffers)
         '(hash-table :test equal)))
  ;; Actual functionality
  (let* ((repl-buffers (append
                       '("Create new")
                       (mapcar (lambda (buf) `(,(buffer-name buf) . buf)) inf-elixir-unaffiliated-buffers)
                       (mapcar (lambda (buf) `(,(buffer-name buf) . buf)) (hash-table-values inf-elixir-project-buffers))))
         (prompt (or prompt "Which REPL?"))
         (selected-buf (completing-read prompt repl-buffers (lambda (_) t) t)))
    (setq-local inf-elixir-repl-buffer (if (equal selected-buf "Create new")
                                           (inf-elixir)
                                         selected-buf))))


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
  (if-let ((default-directory (inf-elixir--find-project-root)))
      (let ((cmd (cond
                  (cmd cmd)
                  (current-prefix-arg (read-from-minibuffer "Project command: " inf-elixir-project-command nil nil 'inf-elixir-project))
                  (t inf-elixir-project-command))))
        (inf-elixir-run-cmd default-directory cmd))
    (message "Could not find project root! Try `inf-elixir' instead.")))

(defun inf-elixir-set-repl ()
  "Select which REPL to use for this buffer."
  (interactive)
  (inf-elixir--prompt-repl-buffers))

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
