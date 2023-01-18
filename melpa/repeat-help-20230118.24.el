;;; repeat-help.el --- Display keybindings for repeat-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Karthik Chikmagalur

;; Author: Karthik Chikmagalur <karthikchikmagalur@gmail.com>
;; version: 0.10
;; Package-Version: 20230118.24
;; Package-Commit: 41dea6fba2edd6ac748d0ca7a6da4058290feede
;; Keywords: convenience
;; Package-Requires: ((emacs "28.1"))
;; URL: https://github.com/karthink/repeat-help

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

;; repeat-help shows key descriptions when using Emacs' `repeat-mode'.
;;
;; The description can be in the form a Which Key popup or an Embark indicator
;; (which see). To use it, enable `repeat-mode' (Emacs 28.0.5 and up) and
;; `repeat-help-mode'. When using a repeated key binding, you can press `C-h' to
;; toggle a popup with the available keybindings.
;;
;; To change the key to toggle the popup type, customize `repeat-help-key'.
;;
;; To have the popup show automatically, set `repeat-help-auto' to true.
;;
;; By default the package tries to use an Embark key indicator. To use Which-Key
;; or the built-in hints, customize `repeat-help-popup-type'.

;;; Code:
(require 'repeat)

(declare-function which-key--popup-showing-p "which-key")
(declare-function which-key--create-buffer-and-show "which-key")
(declare-function which-key--hide-popup "which-key")
(declare-function embark-verbose-indicator "embark")
(defvar embark-verbose-indicator-buffer-sections)
(defvar embark--verbose-indicator-buffer)
(defvar embark-verbose-indicator-display-action)

(defgroup repeat-help nil
  "Repeat-Help: Display keybindings for `repeat-mode'."
  :group 'repeat
  :prefix "repeat-help-")

(defcustom repeat-help-auto nil
  "Boolean to determine the auto-prompting behavior of repeat-help.

When true, repeat-help displays a prompts automatically when
repeating commands with `repeat-mode'.

When nil, the help prompt can be invoked by pressing the
`repeat-help-key', bound to `C-h' by default. This is
a Boolean."
  :group 'repeat-help
  :type 'boolean)

(defcustom repeat-help-key "C-h"
  "Keybinding to invoke the repeat-help prompt.

This is available when repeating commands with `repeat-mode'.

This is a string suitable for input to `kbd'."
  :group 'repeat-help
  :type 'string)

(defcustom repeat-help-popup-type
  (cond ((featurep 'embark) 'embark)
        ((featurep 'which-key) 'which-key)
        (t t))
  "The backend for displaying the repeat-help prompt.

This is a symbol. The choices are embark, which-key or t. The
latter will fall back on the echo area message built into
`repeat-mode'."
  :group 'repeat-help
  :type '(choice
          (const :tag "Embark indicator" embark)
          (const :tag "Which Key indicator" which-key)
          (const :tag "Default indicator" t)))

;; Choose between Embark and Which Key when dispatching
;;; Manual activation
(defsubst repeat-help--prompt-function ()
  "Select function to prompt."
  (pcase repeat-help-popup-type
    ('embark #'repeat-help-embark-toggle)
    ('which-key #'repeat-help-which-key-toggle)
    (_ (lambda (keymap)
         (interactive (list (or repeat-map
                                (let ((this-command last-command))
                                  (repeat--command-property 'repeat-map)))))
         (repeat-echo-message keymap)))))

;;; Auto activation
(defsubst repeat-help--autoprompt-function ()
  "Select function to prompt automatically."
  (pcase repeat-help-popup-type
    ('embark #'repeat-help--embark-indicate)
    ('which-key #'repeat-help--which-key-popup)
    (_ #'repeat-echo-message)))

(defsubst repeat-help--abort-function ()
  "Select function to abort prompt."
  (pcase repeat-help-popup-type
    ('embark #'repeat-help--embark-abort)
    ('which-key #'which-key--hide-popup)
    (_ (lambda () (repeat-echo-message nil)))))

;; Which-key specific code
(defsubst repeat-help--which-key-popup (keymap)
  "Display a Which Key popup for KEYMAP."
  (which-key--create-buffer-and-show
   nil (symbol-value keymap)))

(defun repeat-help-which-key-toggle (keymap)
  "Toggle the Which Key popup for KEYMAP."
  (interactive (list (or repeat-map
                         (let ((this-command last-command))
                           (repeat--command-property 'repeat-map)))))
  (setq this-command last-command)
  (if (which-key--popup-showing-p)
      (which-key--hide-popup)
    (repeat-help--which-key-popup keymap)))

;; Embark-specific code

;; FIXME: Do not use quit-window, the prompt window's quit-restore parameter can
;; be out of date. We use delete-window since we control its display fully.
(defun repeat-help-embark-toggle (keymap)
  "Toggle the Embark verbose key indicator for KEYMAP."
  (interactive (list (or repeat-map
                         (let ((this-command last-command))
                           (repeat--command-property 'repeat-map)))))
  (setq this-command last-command)
  (if-let ((win (get-buffer-window
                 "*Repeat Commands*" 'visible)))
      ;; (quit-window nil win)
      (delete-window win)
    (repeat-help--embark-indicate keymap)))

(defun repeat-help--embark-indicate (keymap)
  "Display an Embark verbose key indicator for KEYMAP."
  (let* ((bufname "*Repeat Commands*")
         (embark-verbose-indicator-buffer-sections
         '(bindings))
        (embark--verbose-indicator-buffer bufname)
        (embark-verbose-indicator-display-action
         '(display-buffer-at-bottom
           (window-height . fit-window-to-buffer)
           (window-parameters . ((no-other-window . t)))
           (body-function . (lambda (win)
                              (with-selected-window win
                               (setq-local mode-line-format nil)))))))
    (funcall
     (embark-verbose-indicator)
     (symbol-value keymap))
    (setq other-window-scroll-buffer (get-buffer bufname))))

(defun repeat-help--embark-abort ()
  "Kill Embark indicator."
  (when-let ((win
              (get-buffer-window
               "*Repeat Commands*" 'visible)))
    ;; (quit-window 'kill-buffer win)
    (kill-buffer (window-buffer win))
    (delete-window win)))

;; Backend-independent code
(defvar repeat-help--echo-function #'ignore)

(defun repeat-help--no-quit (cmd &optional prefix)
  "Return a function to Call CMD without exiting the repeat state.

Optional PREFIX is supplied as the prefix arg to CMD."
  (lambda (arg)
    (interactive "p")
    (setq this-command last-command)
    (let ((current-prefix-arg (or prefix arg)))
      (call-interactively cmd))))

(defvar repeat-help-persist-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap scroll-other-window]
      (repeat-help--no-quit #'scroll-other-window))
    (define-key map [remap scroll-other-window-down]
      (repeat-help--no-quit #'scroll-other-window-down))
    (define-key map [remap recenter-top-bottom]
      (repeat-help--no-quit #'recenter-top-bottom '(4)))
    (define-key map [remap reposition-window]
      (repeat-help--no-quit #'reposition-window))
    map))

(defun repeat-help--activate ()
  "Allow displaying a help prompt for the active `repeat-map'.

The key to toggle the prompt (`C-h' by default) is customizable
via `repeat-help-key'."
  (when repeat-mode
    (if-let* ((rep-map-sym (or repeat-map
                               (repeat--command-property 'repeat-map)))
                (keymap (and (symbolp rep-map-sym)
                             (symbol-value rep-map-sym))))
        (set-transient-map
         (make-composed-keymap
          (list (let ((map (make-sparse-keymap)))
                  (define-key map (kbd repeat-help-key) (repeat-help--prompt-function))
                  map)
                repeat-help-persist-map
                keymap)))
      (funcall (repeat-help--abort-function)))))

(defun repeat-help--activate-auto ()
  "Auto-activate a keymap indicator/popup for the active `repeat-map'."
  (if-let ((cmd (or this-command real-this-command))
           (keymap (or repeat-map
                       (repeat--command-property 'repeat-map))))
      (run-at-time 0 nil (repeat-help--autoprompt-function) keymap)
    (funcall (repeat-help--abort-function))))

;;;###autoload
(define-minor-mode repeat-help-mode
  "Enable a prompt with key descriptions for `repeat-mode'.
   
Repeat Help Mode enables a prompt with available keys and actions
when repeating commands using `repeat-mode'.

The prompt can be displayed using Embark (default) or a Which Key
menu. If neither package is available, it falls back on the echo
area message built into `repeat-mode'."
  :global t
  :lighter nil
  :keymap nil
  (if repeat-help-mode
      (progn
        (setq repeat-help--echo-function repeat-echo-function)
        (setq repeat-echo-function #'ignore)
        (advice-add 'repeat-post-hook :after
                    (if repeat-help-auto
                        #'repeat-help--activate-auto
                      #'repeat-help--activate)))
    (setq repeat-echo-function repeat-help--echo-function
          repeat-help--echo-function #'ignore)
    (advice-remove 'repeat-post-hook #'repeat-help--activate-auto)
    (advice-remove 'repeat-post-hook #'repeat-help--activate)))

(provide 'repeat-help)
;;; repeat-help.el ends here
