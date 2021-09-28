;;; idle-highlight-mode.el --- Highlight the word the point is on -*- lexical-binding: t -*-

;; Copyright (C) 2008-2011 Phil Hagelberg, Cornelius Mika

;; Author: Phil Hagelberg, Cornelius Mika, Campbell Barton
;; URL: http://www.emacswiki.org/cgi-bin/wiki/IdleHighlight
;; Package-Version: 20210928.1134
;; Package-Commit: a801e7113fa6b43a29ac380b91c21784ba55d457
;; Version: 1.1.3
;; Created: 2008-05-13
;; Keywords: convenience
;; EmacsWiki: IdleHighlight
;; Package-Requires: ((emacs "27.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Based on some snippets by fledermaus from the Emacs channel.

;; M-x idle-highlight-mode sets an idle timer that highlights all
;; occurrences in the buffer of the word under the point.

;; Enabling it in a hook is recommended. But you don't want it enabled
;; for all buffers, just programming ones.
;;
;; Example:
;;
;; (defun my-coding-hook ()
;;   (when window-system (hl-line-mode t))
;;   (idle-highlight-mode t))
;;
;; (add-hook 'emacs-lisp-mode-hook 'my-coding-hook)
;; (add-hook 'ruby-mode-hook 'my-coding-hook)
;; (add-hook 'js2-mode-hook 'my-coding-hook)

;;; Code:


;; ---------------------------------------------------------------------------
;; Require Dependencies

(require 'thingatpt)


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup idle-highlight nil "Highlight other occurrences of the word at point." :group 'faces)

(defface idle-highlight
  '((t (:inherit region)))
  "Face used to highlight other occurrences of the word at point."
  :group 'idle-highlight)

(defcustom idle-highlight-exceptions nil
  "List of words to be excepted from highlighting."
  :group 'idle-highlight
  :type '(repeat string))

(defcustom idle-highlight-exceptions-face '(font-lock-keyword-face font-lock-string-face)
  "List of exception faces."
  :group 'idle-highlight
  :type '(repeat symbol))

(defcustom idle-highlight-exclude-point nil
  "Exclude the current symbol from highlighting."
  :group 'idle-highlight
  :type 'boolean)

(defcustom idle-highlight-idle-time 0.35
  "Time after which to highlight the word at point."
  :group 'idle-highlight
  :type 'float)

(defcustom idle-highlight-ignore-modes nil
  "List of major-modes to exclude when `idle-highlight' has been enabled globally."
  :type '(repeat symbol)
  :group 'idle-highlight)

(defvar-local global-idle-highlight-ignore-buffer nil
  "When non-nil, the global mode will not be enabled for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `idle-highlight' Mode not
check this buffer.")

;; ---------------------------------------------------------------------------
;; Internal Variables

(defvar-local idle-highlight--overlays nil "Buffer-local list of overlays.")

;; ---------------------------------------------------------------------------
;; Internal Functions

(defun idle-highlight--faces-at-point (pos)
  "Add the named faces that the `read-face-name' or `face' property use.
Argument POS return faces at this point."
  (let
    ( ;; List of faces to return.
      (faces nil)
      (faceprop (or (get-char-property pos 'read-face-name) (get-char-property pos 'face))))
    (cond
      ((facep faceprop)
        (push faceprop faces))
      ((face-list-p faceprop)
        (dolist (face faceprop)
          (when (facep face)
            (push face faces)))))
    faces))

(defun idle-highlight--check-faces-at-point (pos)
  "Check if the position POS has faces that match the exclude argument."
  (cond
    (idle-highlight-exceptions-face
      (let
        (
          (result t)
          (faces-at-pos (idle-highlight--faces-at-point pos)))
        (while faces-at-pos
          (let ((face (pop faces-at-pos)))
            (when (memq face idle-highlight-exceptions-face)
              (setq result nil)
              ;; Break.
              (setq faces-at-pos nil))))
        result))
    (t ;; Default to true, if there are no exceptions.
      t)))

(defun idle-highlight--unhighlight ()
  "Clear current highlight."
  (when idle-highlight--overlays
    (mapc 'delete-overlay idle-highlight--overlays)
    (setq idle-highlight--overlays nil)))

(defsubst idle-highlight--highlight (target beg end)
  "Highlight TARGET found between BEG and END.h."
  (idle-highlight--unhighlight)
  (save-excursion
    (let
      (
        (target-regexp (concat "\\<" (regexp-quote target) "\\>"))
        (beg-ex
          (progn
            (goto-char (max (point-min) (min beg (window-start))))
            (beginning-of-line)
            (point)))
        (end-ex
          (progn
            (goto-char (min (point-max) (max end (window-end))))
            (beginning-of-line)
            (end-of-line)
            (point))))
      (dolist
        (range
          (cond
            (idle-highlight-exclude-point
              (list (cons beg-ex beg) (cons end end-ex)))
            (t
              (list (cons beg-ex end-ex)))))
        (goto-char (car range))
        (while (re-search-forward target-regexp (cdr range) t)
          (let ((ov (make-overlay (match-beginning 0) (match-end 0))))
            (overlay-put ov 'face 'idle-highlight)
            (push ov idle-highlight--overlays)))))))

(defun idle-highlight--word-at-point ()
  "Highlight the word under the point."
  (idle-highlight--unhighlight)
  (let ((target-range (bounds-of-thing-at-point 'symbol)))
    (when
      (and
        target-range (idle-highlight--check-faces-at-point (point))
        ;; Symbol characters.
        (looking-at-p "\\s_\\|\\sw"))
      (pcase-let* ((`(,beg . ,end) target-range))
        (let ((target (buffer-substring-no-properties beg end)))
          (when (not (member target idle-highlight-exceptions))
            (idle-highlight--highlight target beg end)))))))


;; ---------------------------------------------------------------------------
;; Internal Timer Management
;;
;; This works as follows:
;;
;; - The timer is kept active as long as the local mode is enabled.
;; - Entering a buffer runs the buffer local `window-state-change-hook'
;;   immediately which checks if the mode is enabled,
;;   set up the global timer if it is.
;; - Switching any other buffer wont run this hook,
;;   rely on the idle timer it's self running, which detects the active mode,
;;   canceling it's self if the mode isn't active.
;;
;; This is a reliable way of using a global,
;; repeating idle timer that is effectively buffer local.
;;

;; Global idle timer (repeating), keep active while the buffer-local mode is enabled.
(defvar idle-highlight--global-timer nil)
;; When t, the timer will update buffers in all other visible windows.
(defvar idle-highlight--dirty-flush-all nil)
;; When true, the buffer should be updated when inactive.
(defvar-local idle-highlight--dirty nil)

(defun idle-highlight--time-callback-or-disable ()
  "Callback that run the repeat timer."

  ;; Ensure all other buffers are highlighted on request.
  (let ((is-mode-active (bound-and-true-p idle-highlight-mode)))
    ;; When this buffer is not in the mode, flush all other buffers.
    (cond
      (is-mode-active
        ;; Don't update in the window loop to ensure we always
        ;; update the current buffer in the current context.
        (setq idle-highlight--dirty nil))
      (t
        ;; If the timer ran when in another buffer,
        ;; a previous buffer may need a final refresh, ensure this happens.
        (setq idle-highlight--dirty-flush-all t)))

    (when idle-highlight--dirty-flush-all
      ;; Run the mode callback for all other buffers in the queue.
      (dolist (frame (frame-list))
        (dolist (win (window-list frame -1))
          (let ((buf (window-buffer win)))
            (when
              (and
                (buffer-local-value 'idle-highlight-mode buf)
                (buffer-local-value 'idle-highlight--dirty buf))
              (with-selected-frame frame
                (with-selected-window win
                  (with-current-buffer buf
                    (setq idle-highlight--dirty nil)
                    (idle-highlight--word-at-point)))))))))
    ;; Always keep the current buffer dirty
    ;; so navigating away from this buffer will refresh it.
    (if is-mode-active
      (setq idle-highlight--dirty t))

    (cond
      (is-mode-active
        (idle-highlight--word-at-point))
      (t ;; Cancel the timer until the current buffer uses this mode again.
        (idle-highlight--time-ensure nil)))))

(defun idle-highlight--time-ensure (state)
  "Ensure the timer is enabled when STATE is non-nil, otherwise disable."
  (cond
    (state
      (unless idle-highlight--global-timer
        (setq idle-highlight--global-timer
          (run-with-idle-timer
            idle-highlight-idle-time
            :repeat 'idle-highlight--time-callback-or-disable))))
    (t
      (when idle-highlight--global-timer
        (cancel-timer idle-highlight--global-timer)
        (setq idle-highlight--global-timer nil)))))

(defun idle-highlight--time-reset ()
  "Run this when the buffer changes."
  ;; Ensure changing windows doesn't leave other buffers with stale highlight.
  (cond
    ((bound-and-true-p idle-highlight-mode)
      (setq idle-highlight--dirty-flush-all t)
      (setq idle-highlight--dirty t)
      (idle-highlight--time-ensure t))
    (t
      (idle-highlight--time-ensure nil))))

(defun idle-highlight--time-buffer-local-enable ()
  "Ensure buffer local state is enabled."
  ;; Needed in case focus changes before the idle timer runs.
  (setq idle-highlight--dirty-flush-all t)
  (setq idle-highlight--dirty t)
  (idle-highlight--time-ensure t)
  (add-hook 'window-state-change-hook #'idle-highlight--time-reset nil t))

(defun idle-highlight--time-buffer-local-disable ()
  "Ensure buffer local state is disabled."
  (kill-local-variable 'idle-highlight--dirty)
  (idle-highlight--time-ensure nil)
  (remove-hook 'window-state-change-hook #'idle-highlight--time-reset t))


;; ---------------------------------------------------------------------------
;; Internal Mode Management

(defun idle-highlight--enable ()
  "Enable the buffer local minor mode."
  (idle-highlight--time-buffer-local-enable))

(defun idle-highlight--disable ()
  "Disable the buffer local minor mode."
  (idle-highlight--time-buffer-local-disable)
  (idle-highlight--unhighlight)
  (kill-local-variable 'idle-highlight--overlays))

(defun idle-highlight--turn-on ()
  "Enable command `idle-highlight-mode'."
  (when
    (and
      ;; Not already enabled.
      (not (bound-and-true-p idle-highlight-mode))
      ;; Not in the mini-buffer.
      (not (minibufferp))
      ;; Not a special mode (package list, tabulated data ... etc)
      ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
      (not (derived-mode-p 'special-mode))
      ;; Not explicitly ignored.
      (not (memq major-mode idle-highlight-ignore-modes))
      ;; Optionally check if a function is used.
      (or
        (null global-idle-highlight-ignore-buffer)
        (if (functionp global-idle-highlight-ignore-buffer)
          (not (funcall global-idle-highlight-ignore-buffer (current-buffer)))
          nil)))
    (idle-highlight-mode 1)))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(define-minor-mode idle-highlight-mode
  "Idle-Highlight Minor Mode."
  :group 'idle-highlight
  :global nil

  (cond
    (idle-highlight-mode
      (idle-highlight--enable))
    (t
      (idle-highlight--disable))))

;;;###autoload
(define-globalized-minor-mode
  global-idle-highlight-mode

  idle-highlight-mode idle-highlight--turn-on
  :group 'idle-highlight)

(provide 'idle-highlight-mode)
;;; idle-highlight-mode.el ends here
