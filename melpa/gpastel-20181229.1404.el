;;; gpastel.el --- Integrates GPaste with the kill-ring  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Free Software Foundation, Inc.

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://gitlab.petton.fr/DamienCassou/desktop-environment
;; Package-Version: 20181229.1404
;; Package-Commit: d5fc55bc825203f998537c5834718e665bb87c29
;; Package-requires: ((emacs "25.1"))
;; Version: 0.5.0
;; Keywords: tools

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

;; GPaste is a clipboard management system.  The Emacs package gpastel
;; makes sure that every copied text in GPaste is also in the Emacs
;; kill-ring.

;; Emacs has built-in support for synchronizing the system clipboard
;; with the `kill-ring' (see, `interprogram-paste-function', and
;; `save-interprogram-paste-before-kill').  This support is not
;; optimal because it makes the `kill-ring' only contain the last text
;; of consecutive copied texts.  In other words, a user cannot copy
;; multiple pieces of text from an external application without going
;; back to Emacs in between.
;;
;; On the contrary, gpastel supports this scenario by hooking into the
;; GPaste clipboard manager.  This means that the `kill-ring' will
;; always contain everything the user copies in external applications,
;; not just the last piece of text.

;; Additionally, when using EXWM (the Emacs X Window Manager), gpastel
;; makes it possible for the user to use the `kill-ring' from external
;; applications.

;;; Code:

(require 'dbus)

(defgroup gpastel nil
  "Configure GPaste integration."
  :group 'environment)

(defcustom gpastel-gpaste-client-command "gpaste-client"
  "GPaste client name or path."
  :type 'string)

(defcustom gpastel-update-hook nil
  "Hook which runs after gpastel added an element to `kill-ring'.

Hook functions can retrieve the latest entry by accessing the
`car' of `kill-ring'."
  :type 'hook)

(defvar gpastel--dbus-object nil
  "D-Bus object remembering the return value of `dbus-register-signal'.
This can be used to unregister from the signal.")

(defvar gpastel--save-interprogram-paste-before-kill-orig nil
  "Value of `save-interprogram-paste-before-kill' before starting gpastel.")

(defconst gpastel--dbus-arguments
  '(:session
    "org.gnome.GPaste"
    "/org/gnome/GPaste"
    "org.gnome.GPaste1")
  "List of arguments referencing GPaste for the D-Bus API.")

(defun gpastel--handle-event-p (action _target index)
  "Return non-nil if gpastel should do anything about an event.

The event is represented by the D-Bus parameters of the Update
signal (i.e., ACTION, TARGET and INDEX).  See
`gpastel--update-handler'."
  (and (string= action "REPLACE") (= index 0)))

(defun gpastel--update-handler (action target index)
  "Update `kill-ring' when GPaste's clipboard is changing.

The function parameters are the one defined in the \"Update\"
signal sent by GPaste:

  - ACTION is a string representing how things have changed;

  - TARGET is a clipboard name

  - INDEX is a number indicating which element in the clipboard
    changed (usually 0)

This handler is executed each time GPaste changes the clipboard's
content.  The handler makes sure that the `kill-ring' contains
all text in the GPaste clipboard."
  (when (gpastel--handle-event-p action target index)
    ;; Setting `interprogram-cut-function' to nil make sure we don't
    ;; send the new kill back to system clipboard as that would start
    ;; infinite recursion:
    (let ((interprogram-cut-function nil)
          (copied-text (gpastel-get-copied-text)))
      ;; Prevent killed text from Emacs that have been sent to the
      ;; system clipboard with `interprogram-cut-function' to be
      ;; saved again to the `kill-ring':
      (unless (string= copied-text (car kill-ring))
        (kill-new copied-text)
        (run-hooks 'gpastel-update-hook)))))

(defun gpastel--start-gpaste-daemon ()
  "(Re)Start GPaste daemon and return non-nil upon success."
  (zerop (condition-case nil
             (call-process gpastel-gpaste-client-command nil nil nil "daemon-reexec")
           (error 1)))) ;; ⇐ should be a non-zero number

(defun gpastel-dbus-call (function &rest args)
  "Call FUNCTION passing `gpastel--dbus-arguments' and ARGS."
  (apply function (append gpastel--dbus-arguments args)))

(defun gpastel-get-copied-text (&optional index)
  "Return GPaste clipboard content at INDEX, or 0."
  (gpastel-dbus-call #'dbus-call-method "GetElement" :uint64 (or index 0)))

(defun gpastel--start-listening ()
  "Start listening for GPaste events."
  (when (gpastel--start-gpaste-daemon)
    ;; No need for `interprogram-paste-function' because GPaste will
    ;; tell us as soon as text is added to clipboard:
    (advice-add interprogram-paste-function :override #'ignore)
    ;; No need to save the system clipboard before killing in
    ;; Emacs because Emacs already knows about its content:
    (setq gpastel--save-interprogram-paste-before-kill-orig save-interprogram-paste-before-kill)
    (setq save-interprogram-paste-before-kill nil)
    ;; Register a handler for GPaste Update signals so we can
    ;; immediately update the `kill-ring':
    (setq gpastel--dbus-object
          (gpastel-dbus-call #'dbus-register-signal "Update" #'gpastel--update-handler))))

(defun gpastel--stop-listening ()
  "Stop listening for GPaste events."
  (when (dbus-unregister-object gpastel--dbus-object)
    (setq gpastel--dbus-object nil)
    (setq save-interprogram-paste-before-kill gpastel--save-interprogram-paste-before-kill-orig)
    (advice-remove interprogram-paste-function #'ignore)))

;;;###autoload
(define-minor-mode gpastel-mode
  "Listen to GPaste events."
  :global t
  :init-value nil
  (if gpastel-mode
      (gpastel--start-listening)
    (gpastel--stop-listening)))

(cl-defmethod gui-backend-set-selection (selection-symbol value
                                                          &context (window-system nil))
  (if (not (and gpastel-mode (eq selection-symbol 'CLIPBOARD)))
      (cl-call-next-method)
    (gpastel-dbus-call #'dbus-call-method "Add" value)))

;; BIG UGLY HACK!
;; xterm.el has a defmethod to use some (poorly supported) escape
;; sequences (code named OSC 52) for clipboard interaction, and enables
;; it by default.
;; Problem is, that its defmethod takes precedence over our defmethod,
;; so we need to disable it in order to be called.
(cl-defmethod gui-backend-set-selection :extra "gpastel-override"
  (selection-symbol value
                    &context (window-system nil)
                    ((terminal-parameter nil 'xterm--set-selection) (eql t)))
  ;; Disable this method which doesn't work anyway in 99% of the cases!
  (setf (terminal-parameter nil 'xterm--set-selection) nil)
  ;; Try again!
  (gui-backend-set-selection selection-symbol value))

(provide 'gpastel)
;;; gpastel.el ends here
