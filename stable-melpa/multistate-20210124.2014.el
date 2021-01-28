;;; multistate.el --- Multistate mode -*- lexical-binding: t -*-

;; Author: Matsievskiy S.V.
;; Maintainer: Matsievskiy S.V.
;; Keywords: convenience
;; Package-Version: 20210124.2014
;; Package-Commit: a7ab9dc7aac0b6d6d2f872de4e0d1b8550834a9b
;; Version: 0.2
;; Package-Requires: ((emacs "25.1") (ht "2.3"))
;; Homepage: https://gitlab.com/matsievskiysv/multistate


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
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Multistate mode is basically an evil-mode without vi.
;; It allows to define states for modal editing.
;; Unlike evil-mode it doesn't come with predefined states and key bindings, doesn't set hooks but
;; allows you to configure your system from the ground up.
;;
;; See README for more details.
;;
;; The following example recreates some of evil-mode states keybindings
;;
;; Note: in this example ` key is used instead of ESC to return to normal state.
;; (use-package multistate
;;   :hook
;;   ;; enable selection is Visual state
;;   (multistate-visual-state-enter . (lambda () (set-mark (point))))
;;   (multistate-visual-state-exit .  deactivate-mark)
;;   ;; enable overwrite-mode in Replace state
;;   (multistate-replace-state-enter . overwrite-mode)
;;   (multistate-replace-state-exit .  (lambda () (overwrite-mode 0)))
;;   :init
;;   ;; Emacs state
;;   (multistate-define-state 'emacs :lighter "E")
;;   ;; Insert state
;;   (multistate-define-state
;;    'insert
;;    :lighter "I"
;;    :cursor 'bar
;;    :parent 'multistate-emacs-state-map)
;;   ;; Normal state
;;   (multistate-define-state
;;    'normal
;;    :default t
;;    :lighter "N"
;;    :cursor 'hollow
;;    :parent 'multistate-suppress-map)
;;   ;; Replace state
;;   (multistate-define-state
;;    'replace
;;    :lighter "R"
;;    :cursor 'hbar)
;;   ;; Motion state
;;   (multistate-define-state
;;    'motion
;;    :lighter "M"
;;    :cursor 'hollow
;;    :parent 'multistate-suppress-map)
;;   ;; Visual state
;;   (multistate-define-state
;;    'visual
;;    :lighter "V"
;;    :cursor 'hollow
;;    :parent 'multistate-motion-state-map)
;;   ;; Enable multistate-mode globally
;;   (multistate-global-mode 1)
;;   :bind
;;   (:map multistate-emacs-state-map
;;         ("C-z" . multistate-normal-state))
;;   (:map multistate-insert-state-map
;;         ("`" . multistate-normal-state))
;;   (:map multistate-normal-state-map
;;         ("C-z" . multistate-emacs-state)
;;         ("i" . multistate-insert-state)
;;         ("R" . multistate-replace-state)
;;         ("v" . multistate-visual-state)
;;         ("m" . multistate-motion-state)
;;         ("/" . search-forward)
;;         ("?" . search-backward)
;;         ("x" . delete-char)
;;         ("X" . backward-delete-char))
;;   (:map multistate-motion-state-map
;;         ("`" . multistate-normal-state)
;;         ("h" . backward-char)
;;         ("j" . next-line)
;;         ("k" . previous-line)
;;         ("l" . forward-char)
;;         ("^" . move-beginning-of-line)
;;         ("$" . move-end-of-line)
;;         ("gg" . beginning-of-buffer)
;;         ("G" . end-of-buffer))
;;   (:map multistate-replace-state-map
;;         ("`" . multistate-normal-state)))


;;; Code:

(require 'cl-lib)
(require 'ht)

(defgroup multistate nil
  "Multiple state modal bindings."
  :group  'editing
  :tag    "Multistate"
  :prefix "multistate-"
  :link   '(url-link :tag "gitlab" "https://gitlab.com/matsievskiysv/multistate"))

(defcustom multistate-lighter-indicator " ꟽ"
  "Multistate lighter will be shown when mode is active."
  :tag  "Multistate lighter indicator."
  :type 'string)

(defcustom multistate-lighter-format "❲%s❳"
  "Format of state indicator which will be appended to the lighter."
  :tag  "Multistate lighter format."
  :type 'string)

(defcustom multistate-run-deferred-hooks t
  "Run current state enter and exit hooks when entering and exiting multistate mode."
  :tag  "Run deferred hooks."
  :type 'boolean)

(defcustom multistate-suppress-no-digits nil
  "Do not use digits and minus sign as prefix arguments in `multistate-suppress-map'."
  :tag  "Suppress digits in `multistate-suppress-map'."
  :type 'boolean)

(defcustom multistate-deactivate-input-method-on-switch t
  "Deactivate multilingual input when switching states."
  :tag  "Deactivate input method on switch."
  :type 'boolean)

(defvar multistate--state nil "Current multistate state.")
(make-variable-buffer-local 'multistate--state)

(defvar multistate--state-htable (ht-create) "Multistate state registry.")

(defvar multistate--emulate-alist (list) "Multistate variable for `emulation-mode-map-alists'.")
(add-to-list 'emulation-mode-map-alists 'multistate--emulate-alist)

(defvar multistate-suppress-map (make-keymap)
  "Multistate suppress map may be used as a parent for new states in order to suppress global keybindings.")
(suppress-keymap multistate-suppress-map
                 multistate-suppress-no-digits)

(defvar multistate-mode-enter-hook (list) "Hook to run when entering multistate mode.")

(defvar multistate-mode-exit-hook (list) "Hook to run when exiting multistate mode.")

(defvar multistate-change-state-hook (list) "Hook to run when changing multistate state.")

(defvar multistate--mode-line-message multistate-lighter-indicator
  "Multistate lighter string.")
(make-variable-buffer-local 'multistate--mode-line-message)

(defun multistate--new-name (state &optional suffix internal)
  "Create name from STATE and SUFFIX.

If INTERNAL is t, add extra dash in the middle of the name."
  (intern (concat "multistate-" (when internal "-") (symbol-name state) "-state"
		  (when suffix (concat "-" (symbol-name suffix))))))

(defun multistate--set-parents ()
  "Set parents for all keymaps."
  (let ((keymap-parent-list (ht-map (lambda (_ table)
                                      (cons (ht-get table 'keymap)
                                            (ht-get table 'parent)))
                                    multistate--state-htable)))
    ;; This will probably fail until all keymaps are defined
    (ignore-errors
      (dolist (pair keymap-parent-list)
        (multistate--set-keymap-parent (car pair) (cdr pair)
                                       keymap-parent-list)))))

(defun multistate--set-keymap-parent (keymap parent list)
  "Set KEYMAP PARENT recursively.

LIST is an alist of KEYMAP PARENT pairs from `multistate--state-htable'."
  (when (and keymap parent (not (keymap-parent (eval keymap))))
    ;; (message "Multistate setting %s parent keymap for %s keymap" parent keymap)
    (set-keymap-parent (eval keymap) (eval parent))
    (let* ((keymap parent)
           (parent (alist-get keymap list)))
      ;; setup parent if it is deferred
      (when parent
	(multistate--set-keymap-parent keymap parent list)))))

(defmacro multistate--maybe-create-state-keymap (name var)
  "Create NAME state keymap controlled by variable VAR."
  `(unless (and (boundp (quote ,name)) (boundp (quote ,var)))
     (defvar ,name (make-sparse-keymap) ,(format "Multistate %s state keymap." name))
     (defvar ,var nil ,(format "Multistate %s state keymap enable." var))))

(defmacro multistate--maybe-create-state-hooks (name enter-name exit-name)
  "Create ENTER-NAME and EXIT-NAME hooks for state NAME."
  `(progn
     (unless (boundp (quote ,enter-name))
       (defvar ,enter-name (list)
         ,(format "Multistate %s enter hook." (symbol-name name))))
     (unless (boundp (quote ,exit-name))
       (defvar ,exit-name (list)
         ,(format "Multistate %s exit hook." (symbol-name name))))))

(defmacro multistate--maybe-create-state-function (name enable-name test-name)
  "Create ENABLE-NAME and TEST-NAME functions for state NAME."
  `(progn
     (unless (boundp (quote ,enable-name))
       (defun ,enable-name (&optional no-exit-hook no-enter-hook)
         ,(format "Multistate switch to state %s.

Do not run exit or enter hooks when NO-EXIT-HOOK or NO-ENTER-HOOK is t respectively."
                  (symbol-name name))
         (interactive)
         (unless (,test-name)
           (when multistate-mode
             ;; CAUTION: previous state may be nil
             (let* ((state (ht-get multistate--state-htable multistate--state))
                    (hook (when state (ht-get state 'exit-hook)))
                    (control (when state (ht-get state 'control))))
               ;; run previous state exit hook
               (unless no-exit-hook (run-hooks hook))
               ;; turn off previous state keymap
               (when control (set control nil))))
           (let* ((state (ht-get multistate--state-htable (quote ,name)))
                  (keymap (ht-get state 'keymap))
                  (parent (ht-get state 'parent))
                  (hook (ht-get state 'enter-hook))
                  (cursor (ht-get state 'cursor))
                  (control (ht-get state 'control))
                  (lighter (ht-get state 'lighter)))
             ;; these actions do not require multistate mode to be enabled
             ;; set current name
             (setq-local multistate--state (quote ,name))
             (when multistate-mode
               ;; enable keymap
               (set control t)
               ;; deactivate input method
               (when multistate-deactivate-input-method-on-switch
                 (deactivate-input-method))
               ;; set lighter
               (setq-local multistate--mode-line-message
                           (concat multistate-lighter-indicator
                                   (when lighter
                                     (format multistate-lighter-format lighter))))
               (force-mode-line-update)
               ;; change cursor
               (setq-local cursor-type cursor)
               ;; run enter hooks
               (unless no-enter-hook
                 (run-hooks hook)
                 (run-hooks 'multistate-change-state-hook)))))))
     (unless (boundp (quote ,test-name))
       (defun ,test-name ()
         ,(format "Multistate test that current state is %s." (symbol-name name))
         (string= (symbol-name multistate--state) ,(symbol-name name))))))

;;;###autoload
(defun multistate-manage-variables (variable &optional write value)
  "Manage multistate internal data structure for current state.

Return current hash table VARIABLE when WRITE is nil,
assign VALUE to hash table VARIABLE when WRITE is t.
Internal variables are: name, lighter, cursor,
keymap, parent, control, enter-hook, exit-hook.
Arbitrary variable may be used to store user data."
  (when multistate--state
    (let ((state (ht-get multistate--state-htable multistate--state)))
      (when state
        (if write
            (ht-set state variable value)
          (ht-get state variable))))))

;;;###autoload
(cl-defun multistate-define-state (name &key lighter (cursor t) parent default)
  "Define new NAME state.

LIGHTER will be passed to `multistate-lighter-format' to indicate state.
CURSOR will be applied when switched to this state.
PARENT keymap will be setup for state keymap.
Use `multistate-suppress-map' to suppress global keymap bindings.
Mark state to be DEFAULT if t."
  (when (ht-contains? multistate--state-htable name)
    (error (format "state %s already exists." name)))
  (let ((map-name (multistate--new-name name 'map))
        (control-name (multistate--new-name name nil t))
        (enter-name (multistate--new-name name 'enter-hook))
        (exit-name (multistate--new-name name 'exit-hook))
        (enable-name (multistate--new-name name))
	(test-name (multistate--new-name name 'p)))
    ;; create keymap, hooks and functions
    (eval `(multistate--maybe-create-state-keymap ,map-name ,control-name))
    (add-to-list 'multistate--emulate-alist `(,control-name . ,(eval map-name)))
    (eval `(multistate--maybe-create-state-hooks ,name ,enter-name ,exit-name))
    (eval `(multistate--maybe-create-state-function ,name ,enable-name ,test-name))
    (when default (setq-default multistate--state name))
    (make-variable-buffer-local control-name)
    (ht-set! multistate--state-htable name (ht<-alist `((name . ,name)
                                                        (lighter . ,lighter)
                                                        (cursor . ,cursor)
                                                        (keymap . ,map-name)
                                                        (parent . ,parent)
                                                        (control . ,control-name)
                                                        (enter-hook . ,enter-name)
                                                        (exit-hook . ,exit-name))))
    (multistate--set-parents)
    map-name))

;;;###autoload
(define-minor-mode multistate-mode
  "Toggle `multistate-mode' minor mode.

With a prefix argument ARG, enable `multistate-mode' if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is
`toggle'.

This minor mode provides modal editing features by creating
multiple keymaps and swapping them on demand."
  :group nil
  :lighter (:eval multistate--mode-line-message)
  :keymap nil
  (let* ((state (ht-get multistate--state-htable multistate--state))
         (control (when state (ht-get state 'control)))
         (cursor (when state (ht-get state 'cursor)))
         (lighter (when state (ht-get state 'lighter)))
         (enter-hook (when state (ht-get state 'enter-hook)))
         (exit-hook (when state (ht-get state 'exit-hook))))
      (if multistate-mode
          (progn
            ;; run multistate enter hook
            (run-hooks 'multistate-mode-enter-hook)
            (when state
              ;; set cursor
              (setq-local cursor-type cursor)
              ;; set lighter
              (setq-local multistate--mode-line-message
                          (concat multistate-lighter-indicator
                                  (when lighter
                                    (format multistate-lighter-format lighter))))
              (force-mode-line-update)
              ;; enable keybinding
              (set control t)
              ;; run deferred state enter hook
              (when multistate-run-deferred-hooks (run-hooks enter-hook))))
        (progn
          ;; disable all keymaps
          (ht-map (lambda (_ table) (eval `(setq-local ,(ht-get table 'control) nil)))
                  multistate--state-htable)
          ;; unset cursor
          ;; WARNING: this will break things if other modes would use local cursor-type
          (kill-local-variable 'cursor-type)
          ;; run deferred state exit hook
          (when multistate-run-deferred-hooks (run-hooks exit-hook))
          ;; run multistate exit hook
          (run-hooks 'multistate-mode-exit-hook)))))

(defun multistate--maybe-activate ()
  "Activate multistate mode if current buffer is not minibuffer.

This is used by function `multistate-global-mode'."
  (unless (minibufferp)
    (multistate-mode 1)))

;;;###autoload
(define-globalized-minor-mode multistate-global-mode
  multistate-mode
  multistate--maybe-activate)

(provide 'multistate)

;;; multistate.el ends here
