;;; run-command.el --- Run an external command from a context-dependent list -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021 Massimiliano Mirra

;; Author: Massimiliano Mirra <hyperstruct@gmail.com>
;; URL: https://github.com/bard/emacs-run-command
;; Package-Version: 20210201.810
;; Package-Commit: ca86ae94eed33ca09c4202523cffaf05f70bbc69
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
;; Leave Emacs less.  Relocate those frequent shell commands to configurable,
;; dynamic, context-sensitive lists, and run them at a fraction of the
;; keystrokes with autocompletion.

;;; Code:

(declare-function helm "ext:helm")
(declare-function helm-make-source "ext:helm")
(defvar helm-current-prefix-arg)

(declare-function ivy-read "ext:ivy")
(defvar ivy-current-prefix-arg)

;;; Customization

(defgroup run-command nil
  "Run an external command from a context-dependent list."
  :group 'convenience
  :prefix "run-command-"
  :link '(url-link "https://github.com/bard/emacs-run-command"))

(defcustom run-command-completion-method
  'auto
  "Completion framework to use to select a command."
  :type '(choice (const :tag "autodetect" auto)
                 (const :tag "helm" helm)
                 (const :tag "ivy" ivy)
                 (const :tag "completing-read" completing-read)))

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
  :type '(repeat symbol)
  :group 'run-command)

;;; User interface

;;;###autoload
(defun run-command ()
  "Pick a command from a context-dependent list, and run it.

The command is run with `compile'.

The command list is produced by the functions configured in
`run-command-recipes' (see that for the format expected from
said functions)."
  (interactive)
  (if run-command-recipes
      (pcase run-command-completion-method
        ('auto
         (cond ((and (boundp 'helm-mode) helm-mode)
                (run-command--helm))
               ((and (boundp 'ivy-mode) ivy-mode)
                (run-command--ivy))
               (t (run-command--completing-read))))
        ('helm (run-command--helm))
        ('ivy (run-command--ivy))
        ('completing-read (run-command--completing-read))
        (_ (error "Unrecognized completion method: %s"
                  run-command-completion-method)))
    (error "Please customize `run-command-recipes' in order to use `run-command'")))

;;; Utilities

(defvar run-command--experiment-allow-static-recipes nil
  "For internal use only.")

(defun run-command--generate-command-specs (command-recipe)
  "Execute `COMMAND-RECIPE' to generate command specs."
  (let ((command-specs
         (cond
          ((fboundp command-recipe)
           (funcall command-recipe))
          ((and run-command--experiment-allow-static-recipes
                (boundp command-recipe))
           (symbol-value command-recipe))
          (t (error "Invalid command recipe: %s" command-recipe)))))
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

(defun run-command--run (command-spec)
  "Run `COMMAND-SPEC'.  Back end for helm and ivy actions."
  (cl-destructuring-bind
      (&key command-name command-line scope-name working-dir &allow-other-keys)
      command-spec
    (setq-local run-command-command-spec command-spec)
    (let* ((buffer-base-name (format "%s[%s]" command-name scope-name))
           (default-directory working-dir))
      (pcase run-command-run-method
        ('compile (run-command--run-compile command-line buffer-base-name))
        ('term (run-command--run-term command-line buffer-base-name))))))

;;; Run method `compile'

(defun run-command--run-compile (command-line buffer-base-name)
  "Command execution backend for when run method is `compile'.

Executes COMMAND-LINE in buffer BUFFER-BASE-NAME."
  (let ((compilation-buffer-name-function
         (lambda (_name-of-mode) buffer-base-name)))
    (compile command-line)))

;;; Run method `term'

(defun run-command--run-term (command-line buffer-base-name)
  "Command execution backend for when run method is `term'.

Executes COMMAND-LINE in buffer BUFFER-BASE-NAME."
  (let ((buffer-name (concat "*" buffer-base-name "*")))
    (when (get-buffer buffer-name)
      (let ((proc (get-buffer-process buffer-name)))
        (when (and proc
                   (yes-or-no-p "A process is running; kill it?"))
          (condition-case ()
              (progn
                (interrupt-process proc)
                (sit-for 1)
                (delete-process proc))
            (error nil))))
      (with-current-buffer (get-buffer buffer-name)
        (erase-buffer)))
    (with-current-buffer
        (make-term buffer-base-name shell-file-name nil "-c" command-line)
      (compilation-minor-mode)
      (run-command-term-minor-mode)
      (display-buffer (current-buffer)))))

(define-minor-mode run-command-term-minor-mode
  "Minor mode to re-run `run-command' commands started in term buffers."
  :keymap '(("g" .  run-command-term-recompile)))

(defvar-local run-command-command-spec nil
  "Holds command spec for command run via `run-command'.")

(defun run-command-term-recompile ()
  "Provide `recompile' in term buffers with command run via `run-command'."
  (interactive)
  (run-command--run run-command-command-spec))

;;; Completion via helm

(defun run-command--helm ()
  "Complete command with helm and run it."
  (helm :buffer "*run-command*"
        :prompt "Command Name: "
        :sources (run-command--helm-sources)))

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
    (helm-make-source (run-command--shorter-recipe-name-maybe command-recipe)
        'helm-source-sync
      :action 'run-command--helm-action
      :candidates candidates)))

(defun run-command--helm-action (command-spec)
  "Execute `COMMAND-SPEC' from Helm."
  (let* ((command-line (plist-get command-spec :command-line))
         (final-command-line (if helm-current-prefix-arg
                                 (read-string "> " (concat command-line " "))
                               command-line)))
    (run-command--run (plist-put command-spec
                                 :command-line
                                 final-command-line))))

;;; Completion via ivy

(defvar run-command--ivy-history nil
  "History for `run-command--ivy'.")

(defun run-command--ivy ()
  "Complete command with ivy and run it."
  (unless (window-minibuffer-p)
    (ivy-read "Command Name: "
              (run-command--ivy-targets)
              :caller 'run-command--ivy
              :history 'run-command--ivy-history
              :action 'run-command--ivy-action)))

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
                               (plist-get command-spec :display))
                              command-spec))
                      command-specs)))
          run-command-recipes))

(defun run-command--ivy-action (selection)
  "Execute `SELECTION' from Ivy."
  (let* ((command-spec (cdr selection))
         (command-line (plist-get command-spec :command-line))
         (final-command-line (if ivy-current-prefix-arg
                                 (read-string "> " (concat command-line " "))
                               command-line)))
    (run-command--run (plist-put command-spec
                                 :command-line final-command-line))))

(defun run-command--ivy-edit-action (selection)
  "Edit `SELECTION' then execute from Ivy."
  (let ((ivy-current-prefix-arg t))
    (run-command--ivy-action selection)))

;;; Completion via completing-read

(defun run-command--completing-read ()
  "Complete command with `completing-read' and run it."
  (let* ((targets (run-command--ivy-targets))
         (choice (completing-read "Command Name: " targets)))
    (when choice
      (let ((command-spec (cdr (assoc choice targets))))
        (run-command--run command-spec)))))

(provide 'run-command)

;;; Experiments

(defun run-command--enable-experiments (requested-experiments)
  "Opt in to a set of experiments defined by REQUESTED-EXPERIMENTS."
  ;; Static recipes
  (setq run-command--experiment-allow-static-recipes
        (member 'static-recipes requested-experiments))
  ;; Example deprecated experiment
  (when (member 'foo requested-experiments)
    (message "Experiment `foo' is deprecated, please update your config."))
  ;; Example retired experiment
  (when (member 'bar requested-experiments)
    (error "Experiment `bar' is no longer available, please update your config")))

;;; run-command.el ends here
