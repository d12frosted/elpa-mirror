;;; undo-fu.el --- Undo helper with redo -*- lexical-binding: t -*-

;; Copyright (C) 2019  Campbell Barton, 2020 Free Software Foundation, Inc.

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-undo-fu
;; Version: 0.4
;; Package-Requires: ((emacs "25.1"))

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

;; Undo/redo convenience wrappers to Emacs default undo commands.
;;
;; The redo operation can be accessed from a key binding
;; and stops redoing once the initial undo action is reached.
;;
;; If you want to cross the initial undo boundary to access
;; the full history, running [keyboard-quit] (typically C-g).
;; lets you continue redoing for functionality not typically
;; accessible with regular undo/redo.
;;
;; If you prefer [keyboard-quit] not interfere with undo behavior
;; You may optionally set `undo-fu-ignore-keyboard-quit' & explicitly
;; call `undo-fu-disable-checkpoint'.
;;

;;; Usage:

;; ;; Bind the keys
;; (global-unset-key (kbd "C-z"))
;; (global-set-key (kbd "C-z")   'undo-fu-only-undo)
;; (global-set-key (kbd "C-S-z") 'undo-fu-only-redo)

;;; Code:

;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup undo-fu nil "Configure default behavior for undo-fu wrapper." :group 'undo)

(defcustom undo-fu-allow-undo-in-region nil
  "When non-nil, use `undo-in-region' when a selection is present.
Otherwise `undo-in-region' is never used, since it doesn't support `undo-only',
causing undo-fu to work with reduced functionality when a selection exists."
  :type 'boolean)

(defcustom undo-fu-ignore-keyboard-quit nil
  "When non-nil, don't use `keyboard-quit' to disable linear undo/redo behavior.

Instead, explicitly call `undo-fu-disable-checkpoint'."
  :type 'boolean)

;; ---------------------------------------------------------------------------
;; Internal Variables

;; Apply undo/redo constraints to stop redo from undoing or
;; passing the initial undo checkpoint.
(defvar-local undo-fu--respect t)
;; Initiated an undo-in region (don't use `undo-only').
;; Only use when `undo-fu-allow-undo-in-region' is true.
(defvar-local undo-fu--in-region nil)
;; Track the last undo/redo direction.
;; Use in conjunction with `undo-fu--was-undo-or-redo' to ensure the value isn't stale.
(defvar-local undo-fu--was-redo nil)
;; List of interactive commands.
(defconst undo-fu--commands
  '(undo-fu-only-undo undo-fu-only-redo-all undo-fu-only-redo undo-fu-disable-checkpoint))

;; ---------------------------------------------------------------------------
;; Back Port `undo-redo'
;; Emacs 28's `undo-redo back-ported into undo-fu

(defun undo-fu--backport-undo--last-change-was-undo-p (undo-list)
  "Return the last changed undo step in UNDO-LIST."
  (while (and (consp undo-list) (eq (car undo-list) nil))
    (setq undo-list (cdr undo-list)))
  (gethash undo-list undo-equiv-table))

(defun undo-fu--backport-undo-redo (&optional arg)
  "Undo the last ARG undos."
  (interactive "*p")
  (cond
    ((not (undo-fu--backport-undo--last-change-was-undo-p buffer-undo-list))
      (user-error "No undo to undo"))
    (t
      (let*
        (
          (ul buffer-undo-list)
          (new-ul
            (let ((undo-in-progress t))
              (while (and (consp ul) (eq (car ul) nil))
                (setq ul (cdr ul)))
              (primitive-undo arg ul)))
          (new-pul (undo-fu--backport-undo--last-change-was-undo-p new-ul)))
        (message
          "Redo%s"
          (if undo-in-region
            " in region"
            ""))
        (setq this-command 'undo)
        (setq pending-undo-list new-pul)
        (setq buffer-undo-list new-ul)))))

;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

(defun undo-fu--checkpoint-disable ()
  "Disable using the checkpoint.

This allows the initial boundary to be crossed when redoing."
  (setq undo-fu--respect nil)
  (setq undo-fu--in-region nil))

(defmacro undo-fu--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with advice added.

WHERE using FN-ADVICE temporarily added to FN-ORIG."
  `
  (let ((fn-advice-var ,fn-advice))
    (unwind-protect
      (progn
        (advice-add ,fn-orig ,where fn-advice-var)
        ,@body)
      (advice-remove ,fn-orig fn-advice-var))))

(defmacro undo-fu--with-message-suffix (suffix &rest body)
  "Add text after the message output.
Argument SUFFIX is the text to add at the start of the message.
Optional argument BODY runs with the message suffix."
  (declare (indent 1))
  `
  (undo-fu--with-advice 'message
    :around
    (lambda (fn-orig arg &rest args)
      (apply fn-orig (append (list (concat arg "%s")) args (list ,suffix))))
    ,@body))

(defmacro undo-fu--with-messages-as-non-repeating-list (message-list &rest body)
  "Run BODY adding any message call to the MESSAGE-LIST list."
  (declare (indent 1))
  `
  (let ((temp-message-list (list)))
    (undo-fu--with-advice 'message
      :around
      (lambda (_ &rest args)
        (when message-log-max
          (let ((message-text (apply 'format-message args)))
            (unless (equal message-text (car temp-message-list))
              (push message-text temp-message-list)))))
      (unwind-protect
        (progn
          ,@body)
        ;; Protected.
        (setq ,message-list (append ,message-list (reverse temp-message-list)))))))

(defun undo-fu--undo-enabled-or-error ()
  "Raise a user error when undo is disabled."
  (when (eq t buffer-undo-list)
    (user-error "Undo has been disabled!")))

(defun undo-fu--was-undo-or-redo ()
  "Return t when the last destructive action was undo or redo."
  (not (null (undo-fu--backport-undo--last-change-was-undo-p buffer-undo-list))))

;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun undo-fu-disable-checkpoint ()
  "Remove the undo-fu checkpoint, making all future actions unconstrained.

This command is needed when `undo-fu-ignore-keyboard-quit' is t,
since in this case `keyboard-quit' cannot be used
to perform unconstrained undo/redo actions."
  (interactive)
  ;; Display an appropriate message.
  (if (undo-fu--was-undo-or-redo)
    (if (and undo-fu--respect)
      (message "Undo checkpoint cleared!")
      (message "Undo checkpoint already cleared!"))
    (message "Undo checkpoint disabled for next undo action!"))

  (undo-fu--checkpoint-disable))

;;;###autoload
(defun undo-fu-only-redo-all ()
  "Redo all actions until the initial undo step.

wraps the `undo' function."
  (interactive "*")
  ;; Raise error since we can't do anything useful in this case.
  (undo-fu--undo-enabled-or-error)
  (let ((message-list (list)))
    (undo-fu--with-messages-as-non-repeating-list message-list
      (while (undo-fu--was-undo-or-redo)
        (undo-fu--backport-undo-redo 1)))
    (dolist (message-text message-list)
      (message "%s All" message-text)))
  (setq this-command 'undo-fu-only-redo)
  (setq undo-fu--was-redo t))

;;;###autoload
(defun undo-fu-only-redo (&optional arg)
  "Redo an action until the initial undo action.

wraps the `undo' function.

Optional argument ARG The number of steps to redo."
  (interactive "*p")
  ;; Raise error since we can't do anything useful in this case.
  (undo-fu--undo-enabled-or-error)

  (let*
    ( ;; Assign for convenience.
      (was-undo-or-redo (undo-fu--was-undo-or-redo))
      (was-redo (and was-undo-or-redo undo-fu--was-redo))
      (was-undo (and was-undo-or-redo (null was-redo)))
      (undo-fu-quit-command
        (if undo-fu-ignore-keyboard-quit
          'undo-fu-disable-checkpoint
          'keyboard-quit)))

    ;; Reset the option to not respect the checkpoint
    ;; after running non-undo related commands.
    (unless undo-fu--respect
      (unless was-undo-or-redo
        (when undo-fu-allow-undo-in-region
          (setq undo-fu--in-region nil))
        (setq undo-fu--respect t)))

    (when (region-active-p)
      (cond
        (undo-fu-allow-undo-in-region
          (message "Undo in region in use. Undo checkpoint ignored!")
          (undo-fu--checkpoint-disable)
          (setq undo-fu--in-region t))
        ;; Default behavior, just remove selection.
        (t
          (deactivate-mark))))

    ;; Allow crossing the boundary, if we press [keyboard-quit].
    ;; This allows explicitly over-stepping the boundary,
    ;; in cases when users want to bypass this constraint.
    (when undo-fu--respect
      (when (member last-command (list undo-fu-quit-command 'undo-fu-disable-checkpoint))
        (undo-fu--checkpoint-disable)
        (message "Redo checkpoint stepped over!")))

    (when undo-fu--respect
      (when (null was-undo-or-redo)
        (user-error
          "Redo without undo step (%s to ignore)"
          (substitute-command-keys (format "\\[%s]" (symbol-name undo-fu-quit-command))))))

    (let*
      (
        ;; It's important to clamp the number of steps before assigning
        ;; 'last-command' since it's used when checking the available steps.
        (steps
          (if (numberp arg)
            arg
            1))
        (last-command
          (cond
            (was-undo
              ;; Break undo chain, avoid having to press [keyboard-quit].
              'ignore)
            (was-redo
              ;; Checked by the undo function.
              'undo)
            ((string-equal last-command 'keyboard-quit)
              ;; This case needs to be explicitly detected.
              ;; If we undo until there is no undo information left,
              ;; then press `keyboard-quit' and redo, it fails without this case.
              'ignore)
            (t
              ;; No change.
              last-command)))
        (success
          (condition-case err
            (progn
              (undo-fu--with-message-suffix
                (if undo-fu--respect
                  ""
                  " (unconstrained)")
                (if undo-fu--respect
                  (undo-fu--backport-undo-redo steps)
                  (undo steps)))
              t)
            (error
              (progn
                (message "%s" (error-message-string err))
                nil)))))

      (when success
        (setq undo-fu--was-redo t))

      (setq this-command 'undo-fu-only-redo)
      success)))

;;;###autoload
(defun undo-fu-only-undo (&optional arg)
  "Undo the last action.

wraps the `undo-only' function.

Optional argument ARG the number of steps to undo."
  (interactive "*p")
  ;; Raise error since we can't do anything useful in this case.
  (undo-fu--undo-enabled-or-error)

  (let*
    ( ;; Assign for convenience.
      (was-undo-or-redo (undo-fu--was-undo-or-redo))
      (was-redo (and was-undo-or-redo undo-fu--was-redo))
      (undo-fu-quit-command
        (if undo-fu-ignore-keyboard-quit
          'undo-fu-disable-checkpoint
          'keyboard-quit)))

    ;; Reset the option to not respect the checkpoint
    ;; after running non-undo related commands.
    (unless undo-fu--respect
      (unless was-undo-or-redo
        (when undo-fu-allow-undo-in-region
          (setq undo-fu--in-region nil))
        (setq undo-fu--respect t)))

    (when (region-active-p)
      (cond
        (undo-fu-allow-undo-in-region
          (message "Undo in region in use. Undo checkpoint ignored!")
          (undo-fu--checkpoint-disable)
          (setq undo-fu--in-region t))
        ;; Default behavior, just remove selection.
        (t
          (deactivate-mark))))

    ;; Allow crossing the boundary, if we press [keyboard-quit].
    ;; This allows explicitly over-stepping the boundary,
    ;; in cases when users want to bypass this constraint.
    (when undo-fu--respect
      (when (member last-command (list undo-fu-quit-command 'undo-fu-disable-checkpoint))
        (undo-fu--checkpoint-disable)
        (message "Undo checkpoint ignored!")))

    (let*
      ;; Swap in 'undo' for our own function name.
      ;; Without this undo won't stop once the first undo step is reached.
      (
        (steps (or arg 1))
        (last-command
          (cond
            ;; Special case, to avoid being locked out of the undo-redo chain.
            ;; Without this, continuously redoing will end up in a state where undo & redo fails.
            ;;
            ;; Detect this case and break the chain. Only do this when previously redoing
            ;; otherwise undo will reverse immediately once it reaches the beginning,
            ;; which we don't want even when unconstrained,
            ;; as we don't want to present the undo chain as infinite in either direction.
            ((and was-redo (null undo-fu--respect) (eq t pending-undo-list))
              'ignore)
            (was-undo-or-redo
              ;; Checked by the undo function.
              'undo)
            (t
              ;; No change.
              last-command)))
        (success
          (condition-case err
            (progn
              (undo-fu--with-message-suffix
                (if undo-fu--respect
                  ""
                  " (unconstrained)")
                (if (or (not undo-fu--respect) undo-fu--in-region)
                  (undo steps)
                  (undo-only steps)))
              t)
            (error
              (progn
                (message "%s" (error-message-string err))
                nil)))))

      (when success
        (setq undo-fu--was-redo nil))

      (setq this-command 'undo-fu-only-undo)
      success)))

;; Evil Mode (setup if in use)
;;
;; Don't let these commands repeat.
;;
;; Notes:
;; - Use `with-eval-after-load' once Emacs version 24.4 is the minimum supported version.
;; - Package lint complains about using this command,
;;   however it's needed to avoid issues with `evil-mode'.
(declare-function evil-declare-not-repeat "ext:evil-common")
(eval-after-load 'evil '(mapc #'evil-declare-not-repeat undo-fu--commands))

;; `aggressive-indent-mode’ (setup if in use).
(defvar aggressive-indent-protected-commands)
(eval-after-load
  'aggressive-indent
  '(nconc aggressive-indent-protected-commands undo-fu--commands))

(provide 'undo-fu)
;;; undo-fu.el ends here
