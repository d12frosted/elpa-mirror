;;; fast-scroll.el --- Some utilities for faster scrolling over large buffers. -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Matthew Carter <m@ahungry.com>

;; Author: Matthew Carter <m@ahungry.com>
;; Maintainer: Matthew Carter <m@ahungry.com>
;; URL: https://github.com/ahungry/fast-scroll
;; Package-Version: 20191016.327
;; Package-Commit: 3f6ca0d5556fe9795b74714304564f2295dcfa24
;; Version: 0.0.6
;; Keywords: ahungry convenience fast scroll scrolling
;; Package-Requires: ((emacs "25.1") (cl-lib "0.6.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; An enhanced scrolling experience when quickly navigating through a buffer
;; with fast scrolling (usually via key-repeat instead of manual scrolling).

;;; Code:

(require 'cl-lib)

;; Fix for slow scrolling
(declare-function evil-scroll-up "ext:evil-commands.el" (count) t)
(declare-function evil-scroll-down "ext:evil-commands.el" (count) t)

(defvar fast-scroll-mode nil)
(defvar fast-scroll-mode-line-original nil)
(defvar fast-scroll-pending-reset nil)
(defvar fast-scroll-timeout 0)
(defvar fast-scroll-count 0)
(defvar fast-scroll-throttle 0.2)
(defvar fast-scroll-throttling-p nil)

(defvar fast-scroll-start-hook '())
(defvar fast-scroll-end-hook '())

;; This is more for internal use only to resolve timing issues with
;; flip-flopping between buffers quickly.
;; Initial idea was a single store to restore settings on, but that
;; could end up "locking" a buffer if for some reason end fails to run
;; for some odd reason.
;; If the user does aggressively switch buffers and scroll fast in them,
;; the worst case is prevented (all buffers become un-fast after the timer).
;; However, no attempt is going to be made to 'fast-scroll' every buffer in this way,
;; because all the timing sensitive code is a global package variable.
(defvar fast-scroll--fn-called-in-buffer '())

(defun fast-scroll-default-mode-line ()
  "An Emacs default/bare bones mode-line."
  (list "%e" mode-line-front-space
        mode-line-client
        mode-line-modified
        mode-line-frame-identification
        mode-line-buffer-identification "   "
        mode-line-position
        "  " mode-line-modes mode-line-misc-info mode-line-end-spaces))

(defun fast-scroll-get-milliseconds ()
  "Get the current MS in float up to 3 precision."
  (string-to-number (format-time-string "%s.%3N")))

(defun fast-scroll-end-p ()
  "See if we can end or not."
  (> (- (fast-scroll-get-milliseconds) fast-scroll-timeout) (- fast-scroll-throttle 0.01)))

(defun fast-scroll--end (buf)
  "Re-enable the things we disabled during the fast scroll for buffer BUF."
  (when (fast-scroll-end-p)
    (with-current-buffer buf
      (setq fast-scroll--fn-called-in-buffer nil)
      (setq mode-line-format fast-scroll-mode-line-original)
      (font-lock-mode 1)
      (run-hooks 'fast-scroll-end-hook)
      (setq fast-scroll-throttling-p nil)
      (setq fast-scroll-count 0))))

(defun fast-scroll-end ()
  "Re-enable the things we disabled during the fast scrolls."
  (mapcar #'fast-scroll--end fast-scroll--fn-called-in-buffer))

(defun fast-scroll--run-fn-minimally (f &rest r)
  "Inner function for applying the function F of args R with the minimized modes.

The outer function is the non-private prefixed one, which will only run when it has set
a new buffer name (or found the existing buffer name to match the current one)."
  (unless fast-scroll-mode-line-original
    (setq fast-scroll-mode-line-original mode-line-format))
  (setq fast-scroll-count (+ 1 fast-scroll-count))
  (if (< fast-scroll-count 2)
      (progn
        (ignore-errors (apply f r))
        (run-at-time fast-scroll-throttle nil (lambda () (setq fast-scroll-count 0))))
    (setq fast-scroll-timeout (fast-scroll-get-milliseconds))
    (if fast-scroll-throttling-p
        (ignore-errors (apply f r))
      (progn
        (setq mode-line-format (fast-scroll-default-mode-line))
        (font-lock-mode 0)
        (run-hooks 'fast-scroll-start-hook)
        (ignore-errors (apply f r))))
    (run-at-time fast-scroll-throttle nil #'fast-scroll-end)
    (setq fast-scroll-throttling-p t)))

(defun fast-scroll-run-fn-minimally (f &rest r)
  "Enables fast execution on function F with args R, by disabling certain modes."
  (cl-pushnew (buffer-name) fast-scroll--fn-called-in-buffer :test #'string=)
  (apply #'fast-scroll--run-fn-minimally f r))

(defun fast-scroll-scroll-up-command ()
  "Scroll up quickly - comparative to `scroll-up-command'."
  (interactive)
  (fast-scroll-run-fn-minimally #'scroll-up-command))

(defun fast-scroll-scroll-down-command ()
  "Scroll down quickly - comparative to `scroll-down-command'."
  (interactive)
  (fast-scroll-run-fn-minimally #'scroll-down-command))

(defun fast-scroll-evil-scroll-up ()
  "Scroll down quickly - comparative to `evil-scroll-up'."
  (interactive)
  (fast-scroll-run-fn-minimally #'evil-scroll-up))

(defun fast-scroll-evil-scroll-down ()
  "Scroll down quickly - comparative to `evil-scroll-down'."
  (interactive)
  (fast-scroll-run-fn-minimally #'evil-scroll-down))

;;;###autoload
(defun fast-scroll-config ()
  "Load some config defaults / binds."
  (interactive)
  (global-set-key (kbd "<prior>") 'fast-scroll-scroll-down-command)
  (global-set-key (kbd "<next>") 'fast-scroll-scroll-up-command))

;;;###autoload
(defun fast-scroll-advice-scroll-functions ()
  "Wrap as many scrolling functions that we know of in this advice."
  (interactive)
  (advice-add #'scroll-up-command :around #'fast-scroll-run-fn-minimally)
  (advice-add #'scroll-down-command :around #'fast-scroll-run-fn-minimally)
  (advice-add #'evil-scroll-up :around #'fast-scroll-run-fn-minimally)
  (advice-add #'evil-scroll-down :around #'fast-scroll-run-fn-minimally))

(defun fast-scroll-unload-function ()
  "Remove advice added by `fast-scroll-advice-scroll-functions'.
Note this function's name implies compatibility with `unload-feature'."
  (interactive)
  (advice-remove #'scroll-up-command #'fast-scroll-run-fn-minimally)
  (advice-remove #'scroll-down-command #'fast-scroll-run-fn-minimally)
  (advice-remove #'evil-scroll-up #'fast-scroll-run-fn-minimally)
  (advice-remove #'evil-scroll-down #'fast-scroll-run-fn-minimally)
  nil)

;;;###autoload
(define-minor-mode fast-scroll-mode
  "Minor mode to speed up scrolling.

When fast-scroll-mode is on, certain features/modes of Emacs will be
shut off or minimized during the scrolling activity, to ensure
the user experience the least amount of scroll-lag as possible.

By default, enabling this global minor mode will advice the following
scrolling built-ins (or commonly installed scroll functions): `scroll-up-command',
`scroll-down-command', `evil-scroll-up', `evil-scroll-down'.

Disabling this mode will unload the advice that was added when enabling.

The mode-line format will also be set to a minimal mode-line
during scrolling activity."
  :group 'fast-scroll
  :global t
  :lighter " fs"
  (if fast-scroll-mode
      (progn
        (fast-scroll-advice-scroll-functions))
    (progn
      (fast-scroll-unload-function))))

(provide 'fast-scroll)
;;; fast-scroll.el ends here
