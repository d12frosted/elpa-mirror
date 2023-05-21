;;; exwm-mff.el --- Mouse Follows Focus           -*- lexical-binding: t; -*-

;; Copyright (C) 2019, 2020, 2021  Ian Eure

;; Author: Ian Eure <public@lowbar.fyi>
;; URL: https://github.com/ieure/exwm-mff
;; Package-Version: 20210603.1723
;; Package-Commit: 89206f2e3189f589c27c56bd2b6203e906ee7100
;; Version: 1.2.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: unix

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

;; Mouse Follows Focus
;; ===================
;;
;; Traditional window managers are mouse-centric: the window to receive
;; input is usually selected with the pointing device.
;;
;; Emacs is keybord-centric: the window to receive key input is usually
;; selected with the keyboard.  When you use the keyboard to focus a
;; window, the spatial relationship between pointer and active window is
;; broken -- the pointer can be anywhere on the screen, instead of over
;; the active window, which can make it hard to find.
;;
;; The same problem also exists in traditional windowing systems when
;; you use the keyboard to switch windows, e.g. with Alt-Tab.
;;
;; Because Emacs’ model is inverted, this suggests that the correct
;; behavior is also the inverse -- instead of using the mouse to
;; select a window to receive keyboard input, the keyboard should be
;; used to select the window to receive mouse input.
;;
;; `EXWM-MFF-MODE' is a global minor mode which does exactly this.
;; When the selected window in Emacs changes, the mouse pointer is
;; moved to its center, unless the pointer is already somewhere inside
;; the window’s bounds.  While it's especially helpful for for EXWM
;; users, it works for any Emacs window in a graphical session.
;;
;; This package also offers the `EXWM-MFF-WARP-TO-SELECTED' command,
;; which allows you to summon the pointer with a hotkey.  Unlike the
;; minor mode, summoning is unconditional, and will place the pointer in
;; the center of the window even if it already resides within its bounds
;; -- a handy feature if you’ve lost your pointer, even if you’re using
;; the minor mode.
;;
;;
;; Limitations
;; ~~~~~~~~~~~
;;
;; None known at this time.

;;; Code:

(require 'subr-x)
(require 'cl-macs)

(defcustom exwm-mff-ignore-if nil
  "List of predicate functions for windows to ignore.

Predicates accept one argument, WINDOW, and return non-NIL if
automatic pointer warping should be suppressed."
  :type 'hook
  :group 'exwm-mff)

(defconst exwm-mff--debug-buffer " *exwm-mff-debug*"
  "Name of the buffer exwm-mff will write debug messages into.")

(defvar exwm-mff--debug 0
  "Whether (and how) to debug exwm-mff.
0 = don't debug.
1 = log messages to *exwm-mff-debug*.
2 = log messages to *exwm-mff-debug* and the echo area.")

(defvar exwm-mff--last-window nil
  "The last selected window.")

(defun exwm-mff--guard ()
  "Raise an error unless this is a graphic session with mouse support."
  (unless (and (display-graphic-p) (display-mouse-p))
    (error "EXWM-MFF-MODE doesn't work on non-graphic or non-mouse sessions")))

(defun exwm-mff--contains-pointer? (window)
  "Return non-NIL when the mouse pointer is within FRAME and WINDOW."
  (cl-destructuring-bind ((mouse-x . mouse-y) (left top right bottom))
      (list (mouse-absolute-pixel-position)
            (window-absolute-pixel-edges window))
    (and (<= left mouse-x right)
         (<= top mouse-y bottom))))

(defun exwm-mff--debug (string &rest objects)
  "Log debug message STRING, using OBJECTS to format it."
  (let ((debug-level (or exwm-mff--debug 0)))
    (when (> debug-level 0)
      (let ((str (apply #'format (concat "[%s] " string)
                        (cons (current-time-string) objects))))
        (when (>= debug-level 1)
          (with-current-buffer (get-buffer-create exwm-mff--debug-buffer)
            (goto-char (point-max))
            (insert (concat str "\n")))
          (when (>= debug-level 2)
            (message str)))))))

(defun exwm-mff-show-debug ()
  "Enable exwm-mff debugging, and show the buffer with debug logs."
  (interactive)
  (setq exwm-mff--debug 1)
  (pop-to-buffer (get-buffer-create exwm-mff--debug-buffer)))

(defun exwm-mff--window-center (window)
  "Return a list of (x y) coordinates of the center of WINDOW in FRAME."
  (cl-destructuring-bind (left top right bottom) (window-pixel-edges window)
    (list (+ left (/ (- right left) 2))
          (+ top (/ (- bottom top) 2)))))

(defun exwm-mff-warp-to (frame window)
  "Place the pointer in the center of WINDOW in FRAME."
  (apply #'set-mouse-pixel-position frame
         (exwm-mff--window-center window)))

;;;###autoload
(defun exwm-mff-warp-to-selected ()
  "Place the pointer in the center of the selected window."
  (interactive)
  (exwm-mff--guard)
  (exwm-mff-warp-to (selected-frame) (selected-window)))

(defun exwm-mff--explain (selected-window same-window? contains-pointer? mini? ignored?)
  "Use SELECTED-WINDOW, SAME-WINDOW?, CONTAINS-POINTER?, MINI?
and IGNORED? to return an explanation of focusing behavior."
  (cond
   (same-window? "selected window hasn't changed")
   (contains-pointer? "already contains pointer")
   (mini? "is minibuffer")
   (ignored? "one or more functions in `exwm-mff-ignore-if' matches")
   (t (format "doesn't contain pointer (in %s)" selected-window))))

(defun exwm-mff-hook (sw &optional norecord)
  "EXWM-MFF-MODE hook.

This is after-advice placed on SELECT-WINDOW.  It moves the
pointer to SW (the currently selected window), if NORECORD is
nil, and if it's not already in it."
  (unless norecord
    (if-let ((same-window? (eq sw exwm-mff--last-window)))
        ;; The selected window is unchanged, we don't need to check
        ;; anything else.
        (exwm-mff--debug
         "nop-> %s" (exwm-mff--explain sw same-window? nil nil nil))

      (let* ((sf (window-frame sw))
             (contains-pointer? (exwm-mff--contains-pointer? sw))
             (mini? (minibufferp (window-buffer sw)))
             (ignore? (run-hook-with-args-until-success 'exwm-mff-ignore-if sw)))
        (if (or same-window? contains-pointer? mini? ignore?)
            (exwm-mff--debug
             "nop-> %s::%s (%s)" sf sw (exwm-mff--explain sw nil contains-pointer? mini? ignore?))
          (exwm-mff--debug
           "warp-> %s::%s (%s)" sf sw (exwm-mff--explain sw nil contains-pointer? mini? ignore?))
          (exwm-mff-warp-to sf (setq exwm-mff--last-window sw)))))))

(defgroup exwm-mff nil
  "Mouse-Follows-Focus mode for EXWM."
  :group 'exwm)

;;;###autoload
(define-minor-mode exwm-mff-mode
  "Mouse follows focus mode for EXWM."
  :global t
  :require 'exwm-mff
  :group 'exwm-mff
  (exwm-mff--guard)
  (if exwm-mff-mode
      (advice-add 'select-window :after #'exwm-mff-hook)
    (advice-remove 'select-window #'exwm-mff-hook)))

(provide 'exwm-mff)

;;; exwm-mff.el ends here
