;;; auto-dim-other-buffers.el --- Makes windows without focus less prominent -*- lexical-binding: t -*-
;; Author: Michal Nazarewicz <mina86@mina86.com>
;; Maintainer: Michal Nazarewicz <mina86@mina86.com>
;; URL: https://github.com/mina86/auto-dim-other-buffers.el
;; Package-Version: 20211101.1155
;; Package-Commit: a1c67bf557277934f6dae9f2de6624d949ef2c8a
;; Version: 2.1.0

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

;; To configure how dimmed buffers look like, change
;; `auto-dim-other-buffers-face' and `auto-dim-other-buffers-hide-face' faces.
;; Those faces as well as other settings can be found in
;; ‘auto-dim-other-buffers’ group which can be accessed with:
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
  "Face with a (presumably) dimmed background for non-selected window.

By default the face is applied to, among others, the ‘default’
face and is intended to affect the background of the non-selected
windows.  A related ‘auto-dim-other-buffers-hide-face’ face is
intended for faces which need their foreground to be changed in
sync.  Which faces are actually modified is configured by the
‘auto-dim-other-buffers-affected-faces’ variable."
  :group 'auto-dim-other-buffers)

(defface auto-dim-other-buffers-hide-face
  '((((background light)) :foreground "#eff" :background "#eff")
    (t                    :foreground "#122" :background "#122"))
  "Face with a (presumably) dimmed background and matching foreground.

The intention is that the face has the same foreground and
background as the background of ‘auto-dim-other-buffers-face’ and
that it’s used as remapping for faces which hide the text by
rendering it in the same colour as background.

By default it is applied to the ‘org-hide’ face and is intended
to modify foreground of faces which hide the text by rendering it
in the same colour as the background.  Since the mode alters the
background in a window such faces need to be updated as well.

Which faces are actually modified is configured by the
‘auto-dim-other-buffers-affected-faces’ variable."
  :group 'auto-dim-other-buffers)

(defvar auto-dim-other-buffers-affected-faces) ; Forward declaration.

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

(defun adob--remap-add-relative ()
  "Adds all necessary relative face mappings.
Updates ‘adob--face-mode-remapping’ variable accordingly."
  (let ((make-face (if adob--adow-mode
                       (lambda (face) `(:filtered (:window adob--dim t) ,face))
                     #'identity)))
    (setq adob--face-mode-remapping
          (mapcar (lambda (spec)
                    (face-remap-add-relative (car spec)
                                             (funcall make-face (cdr spec))))
                  auto-dim-other-buffers-affected-faces))))

(defun adob--remap-remove-relative ()
  "Remove all relative mappings that we’ve added.
List of existing mappings is taken from ‘adob--face-mode-remapping’
variable which is set to nil afterwards."
  (mapc #'face-remap-remove-relative adob--face-mode-remapping)
  (setq adob--face-mode-remapping nil))

(defun adob--remap-cycle-all ()
  "Removes and re-adds face remappings in all buffers when they exist.
If ‘auto-dim-other-buffers-mode’ is enabled, this function needs
to be called after ‘auto-dim-other-buffers-affected-faces’
variable is changed to update state of all affected buffers.
Note that it is called automatically as necessary when setting
than variable via Customise."
  (save-current-buffer
    (mapc (lambda (buffer)
            ;; It’s tempting to read the value of the variable and not bother
            ;; with the buffer if the value is nil since in that case the
            ;; buffer is presumably never-dim and thus we won’t remap any
            ;; faces in it.  There is one corner case when this is not true
            ;; however.  If at one point user set list of faces to affect to
            ;; nil the list of remapping will be nil as well and when user
            ;; changes the variable we’ll need to add remappings.
            (when (local-variable-p 'adob--face-mode-remapping buffer)
              (set-buffer buffer)
              (let ((had-none (not adob--face-mode-remapping)))
                (adob--remap-remove-relative)
                (unless (adob--never-dim-p buffer)
                  (adob--remap-add-relative))
                (unless (eq had-none (not adob--face-mode-remapping))
                  (force-window-update buffer)))))
          (buffer-list))))

(defun adob--remap-faces (buffer object)
  "Make sure face remappings are active in BUFFER unless its never-dim.

Does not preserve current buffer.

If BUFFER is never-dim (as determined by ‘adob--never-dim-p’),
remove adob face remappings from it.  Otherwise, make sure the
remappings are active by adding them if it’s missing.

If face remapping had to be changed, force update of OBJECT,
which can be a window or a buffer.

Return non-nil if remappings have been added to BUFFER."
  (let ((wants (not (adob--never-dim-p buffer)))
        (has (buffer-local-value 'adob--face-mode-remapping buffer)))
    (when (eq wants (not has))
      (set-buffer buffer)
      (if wants
          (adob--remap-add-relative)
        (adob--remap-remove-relative))
      (force-window-update object)
      wants)))

(defun adob--kill-all-local-variables-advice (kill)
  "Restores face remapping after killing all local variables.
This is intended as an advice around ‘kill-all-local-variables’
function which removes all buffer face remapping which is
something we don’t want."
  (when (prog1 adob--face-mode-remapping (funcall kill))
    (adob--remap-add-relative)
    nil))

(defun adob--unmap-face (buffer object)
  "Make sure face remapping is inactive in BUFFER.

Does not preserve current buffer.

If face remapping had to be changed, force update of OBJECT which
can be a window or a buffer."
  (when (buffer-local-value 'adob--face-mode-remapping buffer)
    (set-buffer buffer)
    (adob--remap-remove-relative)
    (force-window-update object)))

(defun adob--dim-buffer (buffer &optional except-in)
  "Dim BUFFER if not already dimmed except in EXCEPT-IN window.

Does not preserve current buffer.

EXCEPT-IN only works if the code is running in adow mode (see
‘adob--adow-mode’) and it works by deactivating the dimmed face
in specified window."
  (when (adob--remap-faces buffer buffer)
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
              (adob--remap-faces buf buf)
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
                 (adob--remap-faces buf wnd))
                ;; Outside of adow-mode, add or remove face remapping depending
                ;; on whether current buffer selected buffer or not.
                ((eq buf selected-buffer)
                 (adob--unmap-face buf wnd))
                ((adob--remap-faces buf wnd))))))))

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
applying ‘auto-dim-other-buffers-face’ to them.  With many windows
in a frame, the idea is that this mode helps recognise which is
the selected window by providing a non-intrusive but still
noticeable visual indicator.

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

(defcustom auto-dim-other-buffers-affected-faces
  '((default   . auto-dim-other-buffers-face)
    (org-block . auto-dim-other-buffers-face)
    (org-hide  . auto-dim-other-buffers-hide-face))
  "A list of faces affected when dimming a window.

The list consists of (FACE . REMAP-FACE) pairs where FACE is an
existing face which should be affected when dimming a window and
REMAP-FACE is remapping which should be added to it.

Typically, REMAP-FACE is either ‘auto-dim-other-buffers-face’ or
‘auto-dim-other-buffers-hide-face’.  The former is used when the
background of the face needs to be dimmed while the latter when
in addition the foreground needs to be set to match the
background.  For example, ‘default’ face is altered by overriding
it with the former which causes background of the window to be
changed.  On the other hand, ‘org-hide’ (which hides text by
rendering it in the same colour as the background) is changed by
the latter so that the hidden text stays hidden.

Changing this variable outside of customize does not update
display state of affected buffers."
  :type '(list (cons face face))
  :group 'auto-dim-other-buffers
  :set (lambda (symbol value)
         (set-default symbol value)
         (when auto-dim-other-buffers-mode
           (adob--remap-cycle-all))))


(provide 'auto-dim-other-buffers)

;;; auto-dim-other-buffers.el ends here
