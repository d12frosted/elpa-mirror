;;; auto-dim-other-buffers.el --- Makes windows without focus less prominent -*- lexical-binding: t -*-
;; Author: Michal Nazarewicz <mina86@mina86.com>
;; Maintainer: Michal Nazarewicz <mina86@mina86.com>
;; URL: https://github.com/mina86/auto-dim-other-buffers.el
;; Package-Version: 20210210.1744
;; Package-Commit: 62c936d502f35d168b9e59a66c994d74a62ad2cf
;; Version: 2.0.5

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; The ‘auto-dim-other-buffers-mode’ is a global minor mode which makes windows
;; without focus less prominent.  With many windows in a frame, the idea is that
;; this mode helps recognise which is the selected window by providing
;; a non-intrusive but still noticeable visual indicator.

;; The preferred way to install the mode is by grabbing ‘auto-dim-other-buffers’
;; package form MELPA:
;;
;;     M-x package-install RET auto-dim-other-buffers RET

;; Once installed, the mode can be turned on (globally) with:
;;
;;     M-x auto-dim-other-buffers-mode RET

;; To make the mode enabled every time Emacs starts, add the following
;; to Emacs initialisation file (~/.emacs or ~/.emacs.d/init.el):
;;
;;     (add-hook 'after-init-hook (lambda ()
;;       (when (fboundp 'auto-dim-other-buffers-mode)
;;         (auto-dim-other-buffers-mode t))))

;; To configure how dimmed buffers look like, customise
;; `auto-dim-other-buffers-face'.  This can be accomplished by:
;;
;;     M-x customize-face RET auto-dim-other-buffers-face RET

;; More customisation can be found in ‘auto-dim-other-buffers’ customisation
;; group which can be accessed with:
;;
;;     M-x customize-group RET auto-dim-other-buffers RET

;; Note that despite it’s name, since Emacs 27 the mode operates on *windows*
;; rather than buffers.  I.e. selected window is highlighted and all other
;; windows are dimmed even if they display the same buffer.  In older Emacs
;; versions the mode falls back to the old behaviour where all windows
;; displaying selected buffer are highlighted.  This historic behaviour
;; is where the mode gets its name from.

;;; Code:

(require 'face-remap)


(defgroup auto-dim-other-buffers nil
  "Visually makes windows without focus less prominent."
  :group 'convenience)

(defface auto-dim-other-buffers-face
  '((((background light)) :background "#eff") (t :background "#122"))
  "Face (presumably dimmed somehow) for non-selected window."
  :group 'auto-dim-other-buffers)

(defcustom auto-dim-other-buffers-dim-on-focus-out t
  "Whether to dim all windows when frame looses focus."
  :type 'boolean
  :group 'auto-dim-other-buffers)

(defcustom auto-dim-other-buffers-dim-on-switch-to-minibuffer t
  "Whether to dim last buffer when switching to minibuffer or echo area."
  :type 'boolean
  :group 'auto-dim-other-buffers)


(defconst adob--adow-mode (not (version< emacs-version "27.0.90"))
  "Whether Emacs supports :filtered faces.
If t, the code will run in ‘auto dim other window’ mode (hence
‘adow-mode’) which operates on windows rather than buffers.  To
operate on windows, Emacs must support :filtered face predicate
which has been added in Emacs 27.")

(defconst adob--remap-face
  (if adob--adow-mode
      '(:filtered (:window adob--dim t) auto-dim-other-buffers-face)
    'auto-dim-other-buffers-face)
  "Face to use when adding relative face remapping.
Depending on whether Emacs supports :filtered predicate, this
will or will not use it.  See ‘adob--adow-mode’.")

(defvar adob--last-buffer nil
  "Last selected buffer, i.e. buffer which is currently not dimmed.")
(defvar adob--last-window nil
  "Last selected window, i.e. window which is currently not dimmed.")

(defun adob--never-dim-p (buffer)
  "Return whether to never dim BUFFER.
Call ‘auto-dim-other-buffers-never-dim-buffer-functions’ to see
if any of them return non-nil in which case the BUFFER won’t
dimmed.  In addition to that, outside of adow-mode (see
‘adob--adow-mode’), no hidden buffers will be dimmed."
  (or (and (not adob--adow-mode) (eq ?\s (aref (buffer-name buffer) 0)))
      (run-hook-with-args-until-success
       'auto-dim-other-buffers-never-dim-buffer-functions buffer)))

(defvar-local adob--face-mode-remapping nil
  "Current face remapping cookie for `auto-dim-other-buffers-mode'.")
(put 'adob--face-mode-remapping 'permanent-local nil)

(defun adob--remap-face (buffer object)
  "Make sure face remapping is active in BUFFER unless its never-dim.

Does not preserve current buffer.

If BUFFER is never-dim (as determined by ‘adob--never-dim-p’),
remove adob face remapping (if present) from BUFFER.  Otherwise,
make sure the remapping is active by adding it if it’s missing.

If face remapping had to be changed, force update of OBJECT,
which can be a window or a buffer.

Return non-nil if remapping has been added to BUFFER."
  (let ((wants (not (adob--never-dim-p buffer)))
        (has (buffer-local-value 'adob--face-mode-remapping buffer)))
    (when (eq wants (not has))
      (set-buffer buffer)
      (setq adob--face-mode-remapping
            (if wants
                (face-remap-add-relative 'default adob--remap-face)
              (face-remap-remove-relative adob--face-mode-remapping)
              nil))
      (force-window-update object)
      wants)))

(defun adob--kill-all-local-variables-advice (kill)
  "Restores face remapping after killing all local variables.
This is intended as an advice around ‘kill-all-local-variables’
function which removes all buffer face remapping which is
something we don’t want."
  (unless (prog1 (not adob--face-mode-remapping)
          (funcall kill))
    (setq adob--face-mode-remapping
          (face-remap-add-relative 'default adob--remap-face))
    nil))

(defun adob--unmap-face (buffer object)
  "Make sure face remapping is inactive in BUFFER.

Does not preserve current buffer.

If face remapping had to be changed, force update of OBJECT which
can be a window or a buffer."
  (when (buffer-local-value 'adob--face-mode-remapping buffer)
    (set-buffer buffer)
    (face-remap-remove-relative adob--face-mode-remapping)
    (setq adob--face-mode-remapping nil)
    (force-window-update object)))

(defun adob--dim-buffer (buffer &optional except-in)
  "Dim BUFFER if not already dimmed except in EXCEPT-IN window.

Does not preserve current buffer.

EXCEPT-IN only works if the code is running in adow mode (see
‘adob--adow-mode’) and it works by deactivating the dimmed face
in specified window."
  (when (adob--remap-face buffer buffer)
    (dolist (wnd (and adob--adow-mode
                      (get-buffer-window-list buffer 'n 'visible)))
      (set-window-parameter wnd 'adob--dim (not (eq wnd except-in))))))

(defun adob--update ()
  "Make sure that selected window is not dimmed.
Dim previously selected window if selection has changed."
  (when (or auto-dim-other-buffers-dim-on-switch-to-minibuffer
            (not (window-minibuffer-p)))
    (let* ((wnd (selected-window))
           (buf (window-buffer wnd)))

      (cond
       ((eq wnd adob--last-window))
       (adob--adow-mode
        ;; adow-mode is active and window has changed.  Update the adob--dim
        ;; parameter accordingly.
        (when (and (window-live-p adob--last-window)
                   (not (window-minibuffer-p adob--last-window)))
          (set-window-parameter adob--last-window 'adob--dim t)
          (force-window-update adob--last-window))
        (setq adob--last-window wnd)
        (unless (window-minibuffer-p adob--last-window)
          (set-window-parameter adob--last-window 'adob--dim nil)
          (force-window-update adob--last-window)))
       (t
        ;; Window has changed but adow-mode is not active.  Make sure buffer
        ;; displayed in the old window is dimmed.  This is necessary because
        ;; a command (e.g. ‘quit-window’) could change to a different window
        ;; while at the same time changing buffer in the old window.  In this
        ;; scenario, we’re never dimming the buffer in the old window.
        (and (window-live-p adob--last-window)
             (not (window-minibuffer-p adob--last-window))
             (let ((old-buf (window-buffer adob--last-window)))
               (unless (or (eq old-buf buf)
                           (eq old-buf adob--last-buffer))
                 (save-current-buffer
                   (adob--dim-buffer old-buf))
                 (force-window-update adob--last-window))))
        (setq adob--last-window wnd)))

      ;; If buffer has changed, update its status.
      (unless (eq buf adob--last-buffer)
        (save-current-buffer
          (when (buffer-live-p adob--last-buffer)
            (adob--dim-buffer adob--last-buffer wnd))
          (setq adob--last-buffer buf)
          (if adob--adow-mode
              (adob--remap-face buf buf)
            (adob--unmap-face buf buf)))))))

(defun adob--rescan-windows ()
  "Rescan all windows in selected frame and dim all non-selected windows."
  (let* ((selected-window (selected-window))
         (selected-buffer (window-buffer selected-window)))
    (save-current-buffer
      (dolist (wnd (window-list nil 'n))
        (let ((buf (window-buffer wnd)))
          (cond (adob--adow-mode
                 ;; Update window’s ‘adob--dim’ parameter.  If it changes set
                 ;; we’ll also later tell Emacs to redisplay the window.
                 (let ((new (not (eq wnd selected-window))))
                   (unless (eq new (window-parameter wnd 'adob--dim))
                     (set-window-parameter wnd 'adob--dim new)
                     (force-window-update wnd)))
                 ;; In adow-mode, make sure that the buffer has remapped faces.
                 (adob--remap-face buf wnd))
                ;; Outside of adow-mode, add or remove face remapping depending
                ;; on whether current buffer selected buffer or not.
                ((eq buf selected-buffer)
                 (adob--unmap-face buf wnd))
                ((adob--remap-face buf wnd))))))))

(defun adob--buffer-list-update-hook ()
  "React to buffer list changes.
If selected buffer has changed, change which buffer is dimmed.
Otherwise, if a new buffer is displayed somewhere, dim it."
  (let ((current (current-buffer)))
    (if (eq (window-buffer) current)
        ;; Selected buffer has changed.  Update what we dim.
        (adob--update)
      ;; A new buffer is displayed somewhere but it’s not the selected one so
      ;; dim it.
      (adob--dim-buffer current))))

(defun adob--focus-out-hook ()
  "Dim all buffers if `auto-dim-other-buffers-dim-on-focus-out'."
  (when (and auto-dim-other-buffers-dim-on-focus-out
             (buffer-live-p adob--last-buffer))
    (if adob--adow-mode
        (when (and (window-live-p adob--last-window)
                   (not (window-minibuffer-p adob--last-window)))
          (set-window-parameter adob--last-window 'adob--dim t)
          (force-window-update adob--last-window))
      (save-current-buffer
        (adob--dim-buffer adob--last-buffer)))
    (setq adob--last-buffer nil
          adob--last-window nil)))

(defvar adob--focus-change-debounce-delay 0.015
  "Delay in seconds to use when debouncing focus change events.
Window manager may send spurious focus change events.  To filter
them, the code delays handling of focus-change events by this
number of seconds.  Based on rudimentary testing, 0.015 (i.e. 15
milliseconds) is a good compromise between performing the
filtering and introducing a visible delay.

Setting this variable to zero will disable the debouncing.")

(defvar adob--focus-change-timer nil
  "Timer used to debounce focus change events.
Timer used by ‘adob--focus-change-hook’ when debouncing focus
change events.  The actual delay is specified by the
`adob--focus-change-debounce-delay` variable.")

(defvar adob--focus-change-last-state 'force-update
  "Last ‘frame-focus-state’ when handling focus change event.
Window manager may send spurious focus change events.  The code
attempts to debounce them but this may result in getting a change
event even if the focus state hasn’t changed.  This variable
stores the last state we’ve seen so that we can skip doing any
work if it hasn’t changed.")

(defun adob--focus-change ()
    ;; Reset the timer variable so `adob--focus-change-hook’ will schedule us
    ;; again.
  (setq adob--focus-change-timer nil)
  ;; ‘after-focus-change-function’ has been added at the same time as
  ;; ‘frame-focus-state’ function so if we’re here we know that function is
  ;; defined.
  (let ((state (with-no-warnings (frame-focus-state))))
    (unless (eq adob--focus-change-last-state state)
      (setq adob--focus-change-last-state state)
      (if state (adob--update)
        (adob--focus-out-hook)))))

(defun adob--focus-change-hook ()
  "Based on focus status of selected frame dim or undim selected buffer.
Do nothing if `auto-dim-other-buffers-dim-on-focus-out' is nil
and frame’s doesn’t have focus."
  (if (<= adob--focus-change-debounce-delay 0)
      (adob--focus-change)
    (unless adob--focus-change-timer
      (setq adob--focus-change-timer
            (run-with-timer adob--focus-change-debounce-delay nil
                            #'adob--focus-change)))))

(defun adob--initialize ()
  "Dim all except for the selected buffer."
  ;; In adow mode, dim current buffer as well except for in selected window.  If
  ;; not running in adow mode, don’t dim hidden buffers either (most notably we
  ;; care about Minibuffer and Echo Area buffers).
  (setq adob--last-window (selected-window)
        adob--last-buffer (window-buffer adob--last-window))
  (dolist (buffer (buffer-list))
    (when (or adob--adow-mode
              (not (eq buffer adob--last-buffer)))
      (adob--dim-buffer buffer adob--last-window))))

;;;###autoload
(define-minor-mode auto-dim-other-buffers-mode
  "Visually makes windows without focus less prominent.

Windows without input focus are made to look less prominent by
applying ‘auto-dim-other-buffers-face’ to them.  With many
windows in a frame, the idea is that this mode helps recognise
which is the selected window by providing a non-intrusive but
still noticeable visual indicator.

Note that despite it’s name, since Emacs 27 this mode operates
on *windows* rather than buffers.  In older versions of Emacs, if
a buffer was displayed in multiple windows, none of them would be
dimmed even though at most one could have focus.  This historic
behaviour is where the mode gets its name from."
  :global t
  :group 'auto-dim-other-buffers
  ;; Add/remove all hooks
  (let ((callback (if auto-dim-other-buffers-mode #'add-hook #'remove-hook)))
    (funcall callback 'window-configuration-change-hook #'adob--rescan-windows)
    (funcall callback 'buffer-list-update-hook #'adob--buffer-list-update-hook)
    ;; Prefer ‘after-focus-change-function’ (which was added in Emacs 27)
    ;; to ‘focus-out-hook’ and ‘focus-in-hook’.
    (if (boundp 'after-focus-change-function)
        (if auto-dim-other-buffers-mode
            (add-function :after after-focus-change-function
                          #'adob--focus-change-hook)
          (remove-function after-focus-change-function
                           #'adob--focus-change-hook))
      (funcall callback 'focus-out-hook #'adob--focus-out-hook)
      (funcall callback 'focus-in-hook #'adob--update)))

  ;; Kill focus change timer if present.  If we’re enabling the mode we want to
  ;; start from fresh state.  If we’re disabling the mode, we don’t want the
  ;; timer anyway.
  (when adob--focus-change-timer
    (cancel-timer adob--focus-change-timer)
    (setq adob--focus-change-timer nil))

  (save-current-buffer
    (if auto-dim-other-buffers-mode
        (progn
          (advice-add #'kill-all-local-variables :around
                      #'adob--kill-all-local-variables-advice)
          ;; Dim all except for selected buffer.
          (adob--initialize))

      (advice-remove #'kill-all-local-variables
                     #'adob--kill-all-local-variables-advice)
      ;; Clean up by removing all face remaps.
      (setq adob--last-buffer nil
            adob--last-window nil)
      (dolist (buffer (buffer-list))
        ;; Kill the local variable even if it’s already set to nil.  This is why
        ;; we’re checking whether it’s a local variable rather than it’s value
        ;; in the buffer.
        (when (local-variable-p 'adob--face-mode-remapping buffer)
          (set-buffer buffer)
          (adob--unmap-face buffer buffer)
          (kill-local-variable 'adob--face-mode-remapping))))))


(defcustom auto-dim-other-buffers-never-dim-buffer-functions nil
  "A list of functions run to determine if a buffer should stay lit.
Each function is called with buffer as its sole argument.  If any
of them returns non-nil, the buffer will not be dimmed even if
it’s not selected one.

Each hook function should return the same value for the lifespan
of a buffer.  Otherwise, display state of a buffers may be
inconsistent with the determination of a hook function and remain
stale until the buffer is selected.  Tests based on buffer name
will work well, but tests based on major mode, buffer file name
or other properties which may change during lifespan of a buffer
may be problematic.

Changing this variable outside of customize does not immediately
update display state of all affected buffers."
  :type 'hook
  :group 'auto-dim-other-buffers
  :set (lambda (symbol value)
         (set-default symbol value)
         (when auto-dim-other-buffers-mode
           (save-current-buffer
             (adob--initialize)))
         value))


(provide 'auto-dim-other-buffers)

;;; auto-dim-other-buffers.el ends here
