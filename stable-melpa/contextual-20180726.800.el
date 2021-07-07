;;; contextual.el --- Contextual profile management system	-*- lexical-binding: t; -*-

;; Copyright (C) 2016 LShift Services GmbH, 2018 Alexander Kahl

;; Author: Alexander Kahl <ak@sodosopa.io>
;; Version: 1.0.0
;; Package-Version: 20180726.800
;; Package-Commit: e3c0de4a2e06757a0e8407c3c6e75930026191e3
;; Package-Requires: ((emacs "24") (dash "2.12.1") (cl-lib "0.5"))
;; Keywords: convenience, tools
;; URL: https://github.com/lshift-de/contextual

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Contextual provides profiles support for Emacs.  Switching between contexts
;; sets global variables and runs hooks to reflect switching the user's identity
;; or the working environment.

;;; Code:

(require 'cl-lib)
(require 'dash)

;;; Types and customization

(defgroup contextual nil
  "Contextual global minor mode"
  :group 'convenience
  :prefix "contextual-")

(defcustom contextual-keymap-prefix (kbd "s-c")
  "Contextual keymap prefix."
  :group 'contextual
  :type 'string)

(defcustom contextual-enabled-hook nil
  "Called after Contextual is turned on."
  :group 'contextual
  :type 'hook)

(defcustom contextual-disabled-hook nil
  "Called after Contextual is turned off."
  :group 'contextual
  :type 'hook)

;;; Implementation

(defun contextual--define-context (context initial)
  "Initialize CONTEXT.

Set INITIAL profile."
  (put context 'initial-profile initial)
  (put context 'active-profile nil)
  (put context 'profiles nil))

(cl-defmacro defcontext (context &optional initial)
  "Declare CONTEXT to be a context.

Optionally, set the INITIAL profile."
  `(contextual--define-context ',context ,initial))

(defcontext contextual-default-context)

(defun contextual-mode-line ()
  "Contextual mode line formatter."
  (format " contextual[%s]" (or (get 'contextual-default-context 'active-profile) "(none)")))

(defun contextual-activate-profile (context profile)
  "Activate PROFILE in CONTEXT."
  (let ((active (get context 'active-profile))
        (initial (get context 'initial-profile))
        (profiles (get context 'profiles)))
    (unless (string= active profile)
      (-let (((&alist active (old-theme)
                      profile (theme hook)) profiles))
        ; (disable-theme old-theme) horrible idea; makes whole screen flash
        (enable-theme theme)
        (funcall hook)
        (put context 'active-profile profile)
        (message "Loaded profile %s" profile)))))

(defun contextual-context-loader (context)
  "Create interactive profile loader for CONTEXT.

Use this with `contextual-define-context-loader' to create custom context loaders."
  #'(lambda ()
      (interactive)
      (let ((profiles (get context 'profiles))
            (active (get context 'active-profile)))
        (contextual-activate-profile context (completing-read "Profile: " (cl-remove active profiles :key #'car :test #'equal) nil t)))))

(defun contextual--add-profile (context name profile)
  "Add new PROFILE with NAME to CONTEXT."
  (setf (get context 'profiles)
        (cons (cons name profile) (get context 'profiles))))

(cl-defmacro contextual-add-profile (profile (&optional (context 'contextual-default-context)) (&rest vars) &rest body)
  "Add a new Contextual PROFILE to an existing context.

Use this function to define a new context.
If CONTEXT is not set, it will add to the main context that is
activated with Contextual's minor mode.

PROFILE will also be registered as a custom theme with VARS passed to
`custom-theme-set-variables'. Therefore, every argument in VARS should be a list of the form
 
  (SYMBOL EXP [NOW [REQUEST [COMMENT]])]

as documented in `custom-theme-set-variables'.

BODY is run unconditionally each time the profile is activated."
  (let ((theme (intern (concat (symbol-name context) "-" profile))))
    `(progn
       (deftheme ,theme)
       (apply #'custom-theme-set-variables ',theme ',vars)
       (contextual--add-profile ',context ,profile
         '(,theme
           (lambda () ,@body))))))

(defun contextual-set-initial-profile (profile)
  "Set Contextual's initial PROFILE.

If set while `contextual-mode' is active, the specified profile will
be activated right away."
  (put 'contextual-default-context 'initial-profile profile)
  (when (and contextual-mode
             (not (get 'contextual-default-context 'active-profile)))
    (contextual-activate-profile 'contextual-default-context profile)))

(defvar contextual-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") 'contextual-load-profile)
    map)
  "Keymap used for Contextual commands after `contextual-keymap-prefix'.")
(fset 'contextual-command-map contextual-command-map)

(defvar contextual-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map contextual-keymap-prefix 'contextual-command-map)
    map)
  "Keymap for Contextual mode.")

(cl-defmacro contextual-define-context-loader (name context &optional key)
  "Define Contextual profile loader `name'

Pass a context created with `contextual-define-context' for `context'.
A `key' may be passed to be added to Contextual's keymap for quick
profile switching."
  `(progn
     (defalias ',name (contextual-context-loader ',context))
     ,(when key
        `(define-key contextual-command-map ,key ',name))))

;; Profile cycling
(defun contextual-cycle-profile (context x)
  "Cycle through `X' profiles in `CONTEXT', wrapping over if necessary."
  (let* ((profiles (mapcar #'car (get context 'profiles)))
         (n (length profiles)))
    (nth (mod (+ x (position (get 'contextual-default-context 'active-profile) profiles :test #'equal) n) n)
         profiles)))

(defun contextual-next-profile (context)
  "The next profile defined for `CONTEXT', wrapping over if necessary."
  (contextual-cycle-profile context 1))

(defun contextual-previous-profile (context)
  "The previous profile defined for `CONTEXT', wrapping over if necessary."
  (contextual-cycle-profile context -1))

(defun contextual-activate-next-profile (context)
  "Activate the next profile defined for `CONTEXT'."
  (interactive (list (if (boundp 'context) context 'contextual-default-context)))
  (contextual-activate-profile context (contextual-next-profile context)))

(defun contextual-activate-previous-profile (context)
  "Activate the previous profile defined for `CONTEXT'."
  (interactive (list (if (boundp 'context) context 'contextual-default-context)))
  (contextual-activate-profile context (contextual-previous-profile context)))

(global-set-key (kbd "<M-s-right>") #'contextual-activate-next-profile)
(global-set-key (kbd "<M-s-left>") #'contextual-activate-previous-profile)

;; Define the default context loader
(contextual-define-context-loader contextual-load-profile
  contextual-default-context (kbd "c"))

;;;###autoload
(define-minor-mode contextual-mode
  "Contextual is an Emacs global minor mode that enables customization
  variables to be changed and hooks to be run whenever a user changes
  her profile."
  nil (:eval (contextual-mode-line))
  :group 'contextual
  :keymap contextual-keymap
  (if contextual-mode
      (let ((initial (get 'contextual-default-context 'initial-profile))
            (active (get 'contextual-default-context 'active-profile)))
        (run-hooks 'contextual-enabled-hook)
        (when (and (not active) initial)
          (contextual-activate-profile 'contextual-default-context initial)))
    (run-hooks 'contextual-disabled-hook)))

;;;###autoload
(define-globalized-minor-mode contextual-global-mode contextual-mode contextual-mode)

;; This beast exists for the simple purpose of coloring and indenting
;; some functions.
(dolist (v '(defcontext contextual-add-profile contextual-define-context-loader))
  (put v 'lisp-indent-function 'defun)
  (dolist (mode '(emacs-lisp-mode lisp-interaction-mode))
    (font-lock-add-keywords mode `((,(concat
                                      "(\\<\\(" (symbol-name v) "\\)\\_>"
                                      "[ \t'\(]*"
                                      "\\(\\(?:\\sw\\|\\s_\\)+\\)?")
                                    (1 font-lock-keyword-face)
                                    (2 font-lock-variable-name-face nil t))))))

(provide 'contextual)
;;; contextual.el ends here
