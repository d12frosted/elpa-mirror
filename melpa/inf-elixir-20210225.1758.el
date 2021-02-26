;;; inf-elixir.el --- Run an interactive Elixir shell -*- lexical-binding: t -*-

;; Copyright © 2019–2021 Jonathan Arnett <jonathan.arnett@protonmail.com>

;; Author: Jonathan Arnett <jonathan.arnett@protonmail.com>
;; URL: https://github.com/J3RN/inf-elixir
;; Package-Version: 20210225.1758
;; Package-Commit: beb00b31a778654a2cb17e818e5e7472278e6a1f
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


;;; Mode definitions and configuration
(defvar inf-elixir-buffer nil
  "The buffer of the currently-running Elixir REPL subprocess.")

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


;;; Public functions

;;;###autoload
(defun inf-elixir-run-cmd (cmd)
  "Open an IEx buffer (creating one if needed) and run CMD."
  (if (and inf-elixir-buffer (comint-check-proc inf-elixir-buffer))
      (pop-to-buffer inf-elixir-buffer)
    (let* ((name "Elixir")
           (cmdlist (split-string cmd)))
      (set-buffer (apply #'make-comint-in-buffer
                         name
                         (generate-new-buffer-name (format "*%s*" name))
                         (car cmdlist)
                         nil
                         (cdr cmdlist)))
      (inf-elixir-mode)
      (setq inf-elixir-buffer (current-buffer))
      (pop-to-buffer (current-buffer)))))

;;;###autoload
(defun inf-elixir (&optional cmd)
  "Run Elixir shell, using CMD if given."
  (interactive)
  (inf-elixir-run-cmd
   (cond
    (cmd cmd)
    (current-prefix-arg
     (read-from-minibuffer "Command: " inf-elixir-base-command nil nil 'inf-elixir))
    (t inf-elixir-base-command))))

(defun inf-elixir-project (&optional cmd)
  "Run REPL in the context of the current project, using CMD if given."
  (interactive)
  (let ((default-directory (inf-elixir--find-project-root)))
    (inf-elixir-run-cmd
     (cond
      (cmd cmd)
      (current-prefix-arg
       (read-from-minibuffer "Project command: " inf-elixir-project-command nil nil 'inf-elixir-project))
      (t inf-elixir-project-command)))))

(defun inf-elixir-send-line ()
  "Send the region to the REPL buffer and run it."
  (interactive)
  (comint-send-region inf-elixir-buffer (point-at-bol) (point-at-eol))
  (comint-send-string inf-elixir-buffer "\n"))

(defun inf-elixir-send-region ()
  "Send the region to the REPL buffer and run it."
  (interactive)
  (comint-send-region inf-elixir-buffer (point) (mark))
  (comint-send-string inf-elixir-buffer "\n"))

(defun inf-elixir-send-buffer ()
  "Send the buffer to the REPL buffer and run it."
  (interactive)
  (comint-send-region inf-elixir-buffer 1 (point-max))
  (comint-send-string inf-elixir-buffer "\n"))

(provide 'inf-elixir)

;;; inf-elixir.el ends here
