;;; opam-switch-mode.el --- Select OCaml opam switches via a menu -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022  Hendrik Tews
;; Copyright (C) 2022  Erik Martin-Dorel
;;
;; Authors: Hendrik Tews
;; Maintainer: proof-general-maintainers@groupes.renater.fr
;; URL: https://github.com/ProofGeneral/opam-switch-mode
;; Package-Requires: ((emacs "25.1"))
;; Version: 1.0-git
;;
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License in file COPYING in this or one of the parent
;; directories for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with "prooftree". If not, see <http://www.gnu.org/licenses/>.
;;
;;
;;; Commentary:
;;
;; Provide command `opam-switch-set-switch' to change the opam switch
;; of the running Emacs session and minor mode `opam-switch-mode' to
;; select the opam switch via a menu-bar menu.
;;
;; `opam-switch-set-switch' reads the name of the switch in the
;; minibuffer, providing completion with all available switches.  With
;; no input (i.e., leaving the minibuffer empty) the environment is
;; reset to the state before the first call of
;; `opam-switch-set-switch'.
;;
;; The menu is generated each time the minor mode is enabled and
;; contains the switches that are known at that time.  If you create a
;; new switch, re-enable the minor mode to get it added to the menu.
;; The menu contains an additional entry "reset" to reset the
;; environment to the state when Emacs was started.
;;
;; For obvious reasons, `opam-switch-set-switch' does not change the
;; switch of any other shell.
;;
;; See https://opam.ocaml.org for comprehensive documentation on opam.
;;

(require 'seq)

;;; User options and variables

(defgroup opam-switch ()
  "Customization for opam switch support in Emacs."
  :group 'external)

(defcustom opam-switch-program-name "opam"
  "Name or path of the opam binary."
  :group 'opam-switch
  :type 'string)

(defcustom opam-switch-common-options ()
  "Options to be supplied to every opam invocation.
This must be a list of strings, each member string an option
accepted by opam."
  :group 'opam-switch
  :type '(repeat string))

(defcustom opam-switch-common-environment
  '("OPAMUTF8=never"
    "OPAMCOLOR=never"
    "LC_ALL=C")
  "Process environment to be set for every opam invocation.
List of strings compatible with `process-environment', i.e., each
element should have the form of ENVVARNAME=VALUE.

The process environment must ensure that output is plain ascii
without color, non-ascii arrow symbols and that it is in English.
Otherwise parsing the output of opam commands won't work."
  :group 'opam-switch
  :type '(repeat string))

(defcustom opam-switch-change-opam-switch-hook nil
  "Hook run when the opam switch changes.
This is used, for instance, to let Proof General kill the coq
background process when the opam switch changes."
  :group 'opam-switch
  :type '(repeat function))

;;; Code:

(defun opam-switch--run-command-without-stderr (sub-cmd
                                        &optional switch sexp
                                        &rest args)
  "Run opam SUB-CMD, without capturing error output.
Run opam SUB-CMD with additional arguments and insert the output
in the current buffer at point.  Error output (stderr) is
discarded.  If SWITCH is not nil, an option \"--swith=SWITCH\" is
added. If SEXP is t, option --sexp is added. All remaining
arguments ARGS are added as arguments.

Return exit status of the opam invocation.

Internally this function uses `process-file' internally and will
therfore respect file-name handlers specified via
`default-directory'."
  (let ((process-environment
         (append opam-switch-common-environment process-environment))
        (options (append args opam-switch-common-options)))
    (when switch
      (push (format "--switch=%s" switch) options))
    (when sexp
      (push "--sexp" options))
    ;; (message "run %s %s %s" opam-switch-program-name sub-cmd options)
    (apply #'process-file opam-switch-program-name
               nil '(t nil) nil sub-cmd options)))

(defun opam-switch--command-as-string (sub-cmd &optional switch sexp &rest args)
  "Run opam SUB-CMD, with additional arguments, without capturing stderr.
Return nil if the opam command fails.
Return all output as string otherwise.

If SWITCH is not nil, an option \"--swith=SWITCH\" is added.
If SEXP is t, option --sexp is added.
All remaining arguments ARGS are added as arguments.

This function  `opam-switch--run-command-without-stderr'."
  (with-temp-buffer
    (let ((status
           (apply #'opam-switch--run-command-without-stderr sub-cmd switch sexp args)))
      (if (eq status 0)
          (buffer-string)
        nil))))

(defun opam-switch--get-root ()
  "Get the opam root directory.
This function gets the opam variable 'root'.
This function should not be called directly; see `opam-switch--root'."
  (let ((root (opam-switch--command-as-string "var" nil nil "root")))
    (unless root
      (error "Command 'opam var root' failed"))
    (when (eq (aref root (1- (length root))) ?\n)
      (setq root (substring root 0 -1)))
    root))

(defvar opam-switch--root nil
  "The opam root directory.")

(defun opam-switch--root ()
  "Set variable `opam-switch--root' once, if possible, and return it."
  (or opam-switch--root
      (let ((result
             (condition-case _sig
                 (opam-switch--get-root)
               (file-missing (error "Cannot run opam") nil))))
        (when result
          (setq opam-switch--root result)))))

;; Example output of opam switch. The warning is output on stderr.
;;
;; OPAMUTF8=never OPAMCOLOR=never LC_ALL=C opam switch
;; #   switch        compiler                       description
;; ->  4112-coq-812  ocaml-variants.4.11.2+flambda  4112-coq-812
;;     44            ocaml-base-compiler.4.04.0
;;     450-coq-8.9   ocaml-base-compiler.4.05.0     450-coq-8.9
;;     471-no-coq    ocaml-base-compiler.4.07.1     471-no-coq
;;     system        ocaml-system.4.01.0
;;
;; #   switch   compiler      description
;; ->  default  ocaml.4.13.1  default
;;
;; [WARNING] The environment is not in sync with the current switch.
;;           You should run: eval $(opam env)

(defun opam-switch--get-switches ()
  "Return all opam switches as list of strings."
  (let (opam-switches)
    (with-temp-buffer
      (unless (eq (opam-switch--run-command-without-stderr "switch") 0)
        ;; opam exit status different from 0 -- some error occured
        (error "Command 'opam switch' failed"))
      (goto-char (point-min))
      (forward-line)
      (while (re-search-forward "^.. *\\([^ ]*\\).*$" nil t)
        (push (match-string 1) opam-switches))
      opam-switches)))

(defvar opam-switch--switch-history nil
  "Minibuffer history list for `opam-switch--set-switch'.")

(defvar opam-switch--saved-env nil
  "Saved environment variables, overwritten by an opam switch.
This is a list of saved environment variables.  Each saved
variable is a list of two strings, the variable and the value.
Set when the first chosen opam switch overwrites the
environment.")

(defvar opam-switch--saved-exec-path nil
  "Saved value of variable `exec-path'.
Set when the first chosen opam switch overwrites variable `exec-path'.")

(defun opam-switch--save-current-env (opam-env)
  "Save the current environment values relevant to opam.
Argument OPAM-ENV, coming from calling `opam env', is only used
to find the environment variables to save.
The variable `exec-path' is saved in addition to environment variables."
  (setq opam-switch--saved-env
	(mapcar (lambda (x) (list (car x) (getenv (car x)))) opam-env))
  (setq opam-switch--saved-exec-path exec-path))

(defun opam-switch--set-env (opam-env)
  "Set a new opam environment.
Environment variables in OPAM-ENV are put into the environment of
the current Emacs session.  The variable `exec-path' is changed to
match the environment PATH.

It is unclear which value in variable `exec-path' corresponds to a
previously set opam switch and also which entry in the PATH
environment variable in OPAM-ENV corresponds to the new switch.
Therefore this function uses the following heuristic.  First all
entries in variable `exec-path' that match `(opam-switch--root)' are deleted.
Then, the first entry for PATH that maches `(opam-switch--root)' is added at the
front of variable `exec-path'."
  (let ((new-bin-dir
         (seq-find
          (lambda (dir) (string-prefix-p (opam-switch--root) dir))
          (parse-colon-path (cadr (assoc "PATH" opam-env))))))
    (unless new-bin-dir
      (error "No opam-root directory in PATH"))
    (mapc (lambda (x) (setenv (car x) (cadr x))) opam-env)
    (setq exec-path
          (seq-remove (lambda (dir) (string-prefix-p (opam-switch--root) dir)) exec-path))
    (push new-bin-dir exec-path)))

(defun opam-switch--reset-env ()
  "Reset process environment to the state before setting the first opam switch.
Reset variable `exec-path' and all environment variables to the values
they had in this Emacs session before the first chosen opam
switch overwrote them."
  (mapc (lambda (x) (setenv (car x) (cadr x))) opam-switch--saved-env)
  (setq exec-path opam-switch--saved-exec-path)
  (setq opam-switch--saved-env nil)
  (setq opam-switch--saved-exec-path nil))

(defun opam-switch--get-current-switch ()
  "Return name of current switch or \"<none>\"."
  (let ((current-switch (getenv "OPAM_SWITCH_PREFIX")))
    (if current-switch
         (file-name-nondirectory current-switch)
      "<none>")))

(defun opam-switch--set-switch (switch-name)
  "Choose and set an opam switch.
Set opam switch SWITCH-NAME, which must be a valid opam switch
name.  When called interactively, the switch name must be entered
in the minibuffer, which forces completion to a valid switch name
or the empty string.

Setting the opam switch for the first time inside Emacs will save
the current environment.  Using the empty string for SWITCH-NAME
will reset the environment to the saved values.

The switch is set such that all process invocations from
Emacs respect the newly set opam switch.  In addition to setting
environment variables such as PATH and CAML_LD_LIBRARY_PATH, this
also sets variable `exec-path', which controls Emacs'
subprocesses (`call-process', `make-process' and similar
functions).

When the switch is changed, `opam-switch-change-opam-switch-hook'
runs.  This a can be used to inform other modes that may run
background processes that depend on the currently active opam
switch.

For obvious reasons, `opam-switch--set-switch' will only affect Emacs and
not any other shells outside Emacs."
  (interactive
   (let* ((switches (opam-switch--get-switches))
          (current-switch (opam-switch--get-current-switch)))
     (list
      (completing-read
       (format "current switch %s; switch to (empty to reset): " current-switch)
       switches nil t "" 'opam-switch--switch-history nil))))
  (when (and (equal switch-name "") (not opam-switch--saved-env))
    (error "No saved opam environment, cannot reset"))
  (if (equal switch-name "")
      (opam-switch--reset-env)
    (let ((output-string (opam-switch--command-as-string "env" switch-name t))
          opam-env)
      (unless output-string
        (error
         "Command 'opam env %s' failed - probably because of invalid opam switch \"%s\""
         switch-name switch-name))
      (setq opam-env (car (read-from-string output-string)))
      (unless opam-switch--saved-env
        (opam-switch--save-current-env opam-env))
      (opam-switch--set-env opam-env)))
  (run-hooks 'opam-switch-change-opam-switch-hook))

;;;###autoload
(defalias 'opam-switch-set-switch #'opam-switch--set-switch)

;;; minor mode, keymap and menu

(defvar opam-switch--mode-keymap (make-sparse-keymap)
  "Keymap for `opam-switch-mode'.")

(defun opam-switch--menu-items ()
  "Create list of opam switches as menu items for `easy-menu'."
  (append
   ;; first the current switch as info with a separator
   '(["current switch: " nil
      :active t
      :suffix (opam-switch--get-current-switch)
      :help "Shows the currently selected opam switch"]
     "-------")
   ;; then the list with all the real opam switches
   (mapcar
    (lambda (switch)
      (vconcat
       `(,switch
         (opam-switch--set-switch ,switch)
         :active t
         :help ,(concat "select opam switch \"" switch "\""))))
    (opam-switch--get-switches))
   ;; now reset as last element
   '(
     ["reset" (opam-switch--set-switch "")
      :active opam-switch--saved-env
      :help "reset to state when emacs was started"])))

(defun opam-switch--setup-opam-switch-mode ()
  "Re-define menu for `opam-switch-mode'.
This function runs when `opam-switch-mode' is enabled to setup
`opam-switch-mode'. Currently it only redefines the menu.

Note that the code for setting up the keymap and running the hook
is automatically created by `define-minor-mode'."
  (easy-menu-define
    opam-switch--mode-menu
    opam-switch--mode-keymap
    "opam mode menu"
    (cons "opam-switch"
          (opam-switch--menu-items))))

;;;###autoload
(define-minor-mode opam-switch-mode
  "Toggle opam-switch mode.
The mode can be enabled only if opam is found and 'opam var root' succeeds."
  :init-value nil
  :lighter " OPSW"
  :keymap opam-switch--mode-keymap
  :group 'opam-switch
  (when opam-switch-mode
    (condition-case sig
        (progn
          (opam-switch--root)
          (opam-switch--setup-opam-switch-mode))
      (t (setq opam-switch-mode nil)
         (message "Opam-Switch mode disabled %s" (pp-to-string sig))))))

(provide 'opam-switch-mode)

;;; opam-switch-mode.el ends here
