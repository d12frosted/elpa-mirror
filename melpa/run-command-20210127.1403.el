;;; run-command.el --- Run an external command from a context-dependent list -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021 Massimiliano Mirra

;; Author: Massimiliano Mirra <hyperstruct@gmail.com>
;; URL: https://github.com/bard/emacs-run-command
;; Package-Version: 20210127.1403
;; Package-Commit: 11a1323d672474dca98fbf887901d596393a0686
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: processes

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Leave Emacs less. Relocate those frequent shell commands to configurable,
;; dynamic, context-sensitive lists, and run them at a fraction of the
;; keystrokes via Helm or Ivy.

;;; Code:

(declare-function helm "ext:helm")
(declare-function helm-build-sync-source "ext:helm")
(declare-function ivy-read "ext:ivy")
(defvar helm-current-prefix-arg)

;; Customization

(defgroup run-command nil
  "Run an external command from a context-dependent list."
  :group 'convenience
  :prefix "run-command-"
  :link '(url-link "https://github.com/bard/emacs-run-command"))

(defcustom run-command-completion-method
  (if (featurep 'ivy) 'ivy 'helm)
  "Completion framework to use to select a command."
  :type '(choice (const :tag "Helm" helm)
                 (const :tag "Ivy" ivy)))

(defcustom run-command-run-method
  'compile
  "Run strategy.

Terminal Mode: use a buffer in `term-mode'.
    - Supports full ANSI including colors and cursor movements.
    - Lower performance.

Compilation Mode: use a buffer in `compilation-mode'."
  :type '(choice (const :tag "Terminal Mode" term)
                 (const :tag "Compilation Mode" compile)))

(defcustom run-command-recipes nil
  "List of functions that will produce runnable commands.

Each function will be called without arguments and is expected
to return a list-of-plists, where each plist represents a
runnable command and has the following format:

  :command-name

    (string, required) A name for the command, used internally as well as (if
:display is not provided) shown to the user.

  :command-line

    (string, required) The command line that will be executed.  It will be
passed to `compile'.

  :display

    (string, optional) A descriptive name for the command that will be shown
in place of :command-name.

  :working-dir

    (string, optional) Directory path to run the command in.  If not given,
command will be run in `default-directory'."
  :type '(repeat function)
  :group'run-command)

;; Entry point

(defun run-command ()
  "Pick a command from a context-dependent list, and run it.

The command is run with `compile'.

The command list is produced by the functions configured in
`run-command-recipes' (see that for the format expected from
said functions)."
  (interactive)
  (pcase run-command-completion-method
    ('helm
     (helm :buffer "*run-command*"
           :prompt "Command Name: "
           :sources (run-command--helm-sources)))
    ('ivy (unless (window-minibuffer-p)
            (ivy-read "Command Name: "
                      (run-command--ivy-targets)
                      :action 'run-command--ivy-action)))))

;; Utilities

(defun run-command--generate-command-specs (command-recipe)
  "Execute `COMMAND-RECIPE' to generate command specs."
  (let ((command-specs (funcall command-recipe)))
    (mapcar #'run-command--normalize-command-spec
            (delq nil command-specs))))

(defun run-command--normalize-command-spec (command-spec)
  "Sanity-check and fill in defaults for user-provided `COMMAND-SPEC'."
  (unless (plist-get command-spec :command-name)
    (error "[run-command] `:command-name' item missing from command spec: %S"
           command-spec))
  (unless (plist-get command-spec :command-line)
    (error "[run-command] `:command-line' item missing from command spec: %S"
           command-spec))
  (append command-spec
          (unless (plist-get command-spec :display)
            (list :display (plist-get command-spec :command-name)))
          (unless  (plist-get command-spec :working-dir)
            (list :working-dir default-directory))
          (unless  (plist-get command-spec :scope-name)
            (list :scope-name (abbreviate-file-name
                               (or (plist-get command-spec :working-dir)
                                   default-directory ))))))

(defun run-command--shorter-recipe-name-maybe (command-recipe)
  "Shorten `COMMAND-RECIPE' name when it begins with conventional prefix."
  (let ((recipe-name (symbol-name command-recipe)))
    (if (string-match "^run-command-recipe-\\(.+\\)$" recipe-name)
        (match-string 1 recipe-name)
      recipe-name)))

(defvar-local run-command-command-spec nil
  "Holds command spec for command run via `run-command'.")

(define-minor-mode run-command-term-minor-mode
  "Minor mode to re-run `run-command' commands started in term buffers."
  :keymap '(("g" .  run-command-term-recompile)))

(defun run-command-term-recompile ()
  "Provide `recompile' in term buffers with command run via `run-command'."
  (interactive)
  (run-command--run run-command-command-spec))

(defun run-command--run (command-spec)
  "Run `COMMAND-SPEC'.  Back end for helm and ivy actions."
  (cl-destructuring-bind
      (&key command-name command-line scope-name working-dir &allow-other-keys)
      command-spec
    (let* ((buffer-name-base (format "%s[%s]" command-name scope-name))
           (buffer-name (format "*%s*" buffer-name-base))
           (default-directory working-dir))
      (pcase run-command-run-method
        ('compile
         (let ((compilation-buffer-name-function (lambda (_name-of-mode) buffer-name)))
           (compile command-line)))
        ('term
         (when (get-buffer buffer-name)
           (let ((proc (get-buffer-process buffer-name)))
             (when (and proc
                        (yes-or-no-p "A process is running; kill it?"))
               (condition-case ()
                   (progn
                     (interrupt-process proc)
                     (sit-for 1)
                     (delete-process proc))
                 (error nil)))))
         (with-current-buffer
             (make-term buffer-name-base shell-file-name nil "-c" command-line)
           (erase-buffer)
           (compilation-minor-mode)
           (run-command-term-minor-mode)
           (setq-local run-command-command-spec command-spec)
           (display-buffer (current-buffer))))))))

;; Helm integration

(defun run-command--helm-sources ()
  "Create Helm sources from all active recipes."
  (mapcar #'run-command--helm-source-from-recipe
          run-command-recipes))

(defun run-command--helm-source-from-recipe (command-recipe)
  "Create a Helm source from `COMMAND-RECIPE'."
  (let* ((command-specs (run-command--generate-command-specs command-recipe))
         (candidates (mapcar (lambda (command-spec)
                               (cons (plist-get command-spec :display) command-spec))
                             command-specs)))
    (helm-build-sync-source (run-command--shorter-recipe-name-maybe command-recipe)
      :action 'run-command--helm-action
      :candidates candidates
      :filtered-candidate-transformer '(helm-adaptive-sort))))

(defun run-command--helm-action (command-spec)
  "Execute `COMMAND-SPEC' from Helm."
  (let* ((command-line (plist-get command-spec :command-line))
         (final-command-line (if helm-current-prefix-arg
                                 (read-string "> " (concat command-line " "))
                               command-line)))
    (run-command--run (plist-put command-spec
                                 :command-line
                                 final-command-line))))

;; Ivy integration

(defun run-command--ivy-targets ()
  "Create Ivy targets from all recipes."
  (mapcan (lambda (command-recipe)
            (let ((command-specs
                   (run-command--generate-command-specs command-recipe))
                  (recipe-name
                   (run-command--shorter-recipe-name-maybe command-recipe)))
              (mapcar (lambda (command-spec)
                        (cons (concat
                               (propertize (concat recipe-name "/")
                                           'face 'shadow)
                               (plist-get command-spec :display)) command-spec))
                      command-specs)))
          run-command-recipes))

(defun run-command--ivy-action (selection)
  "Execute `SELECTION' from Ivy."
  (let ((command-spec (cdr selection)))
    (run-command--run command-spec)))

(provide 'run-command)

;;; run-command.el ends here
