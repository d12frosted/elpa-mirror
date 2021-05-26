;;; mode-line-debug.el --- show status of `debug-on-error' in the mode-line  -*- lexical-binding: t -*-

;; Copyright (C) 2012-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/mode-line-debug
;; Keywords: convenience, lisp
;; Package-Version: 20210525.2014
;; Package-Commit: 41184eb66a3205abcc32a885780004207df86dbd

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Show the status of `debug-on-error' and `debug-on-quit'
;; in the `mode-line'.

;;; Code:

(require 'cl-lib)

(defconst mode-line-debug
  '(mode-line-debug-mode (:eval (mode-line-debug-control))))

;;;###autoload
(define-minor-mode mode-line-debug-mode
  "Mode to show the status of `debug-on-error' in the mode-line.

Depending on the state of `debug-on-error' this mode inserts a
different string into the mode-line before the list of active
modes.  The inserted character can be used to toggle the state of
`debug-on-error'."
  :global t
  :group 'mode-line
  (setq mode-line-misc-info
        (if mode-line-debug-mode
            (cons mode-line-debug mode-line-misc-info)
          (delete mode-line-debug mode-line-misc-info))))

(defcustom mode-line-debug-on-error-indicators '("e" . "e")
  "Strings indicating the state of `debug-on-error' in the mode-line.

The car is used when `debug-on-error' is off, the cdr when it is
off.  For the off state a string consisting of one space makes
most sense; this avoids cluttering the mode-line but still allows
clicking before the list of modes to toggle `debug-on-error'.

Also see `mode-line-debug-mode' which has to be enabled for this
to have any effect."
  :group 'mode-line
  :type '(cons (string :tag "On Indicator")
               (string :tag "Off Indicator")))

(defcustom mode-line-debug-on-quit-indicators '("q" . "q")
  "Strings indicating the state of `debug-on-quit' in the mode-line.

The car is used when `debug-on-quit' is off, the cdr when it is
off.  For the off state a string consisting of one space makes
most sense; this avoids cluttering the mode-line but still allows
clicking before the list of modes to toggle `debug-on-quit'.

Also see `mode-line-debug-mode' which has to be enabled for this
to have any effect."
  :group 'mode-line
  :type '(cons (string :tag "On Indicator")
               (string :tag "Off Indicator")))

(defcustom mode-line-debug-on-signal-indicators '("s" . "s")
  "Strings indicating the state of `debug-on-signal' in the mode-line.

The car is used when `debug-on-signal' is off, the cdr when it is
off.  For the off state a string consisting of one space makes
most sense; this avoids cluttering the mode-line but still allows
clicking before the list of modes to toggle `debug-on-signal'.

Also see `mode-line-debug-mode' which has to be enabled for this
to have any effect."
  :group 'mode-line
  :type '(cons (string :tag "On Indicator")
               (string :tag "Off Indicator")))

(defface mode-line-debug-enabled nil
  "Face indicating an enabled `debug-on-*' in the mode-line."
  :group 'mode-line)

(defface mode-line-debug-disabled '((t :foreground "gray80"))
  "Face indicating an disabled `debug-on-*' in the mode-line."
  :group 'mode-line)

(defun mode-line-debug-control ()
  (list (mode-line-debug-control-1 'debug-on-quit  "Debug on Quit"
                                   mode-line-debug-on-quit-indicators
                                   'mode-line-toggle-debug-on-quit)
        (mode-line-debug-control-1 'debug-on-error "Debug on Error"
                                   mode-line-debug-on-error-indicators
                                   'mode-line-toggle-debug-on-error)
        (mode-line-debug-control-1 'debug-on-signal "Debug on Signal"
                                   mode-line-debug-on-signal-indicators
                                   'mode-line-toggle-debug-on-signal)))

(defun mode-line-debug-control-1 (var dsc strings cmd)
  (cond ((symbol-value var)
         (propertize
          (car strings)
          'face 'mode-line-debug-enabled
          'help-echo (concat dsc " is enabled\nmouse-1 toggle")
          'mouse-face 'mode-line-highlight
          'local-map (purecopy (make-mode-line-mouse-map 'mouse-1 cmd))))
        (t
         (propertize
          (cdr strings)
          'face 'mode-line-debug-disabled
          'help-echo (concat dsc " is disabled\nmouse-1 toggle")
          'mouse-face 'mode-line-highlight
          'local-map (purecopy (make-mode-line-mouse-map 'mouse-1 cmd))))))

(defun mode-line-toggle-debug-on-error (event)
  "Toggle `debug-on-error' from the mode-line."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (toggle-debug-on-error)
    (force-mode-line-update)))

(defun mode-line-toggle-debug-on-quit (event)
  "Toggle `debug-on-quit' from the mode-line."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (toggle-debug-on-quit)
    (force-mode-line-update)))

;; Emacs 28 deprecates the `menu-bar-make-toggle' macro in favor
;; of `menu-bar-make-toggle-command', but we have keep using the
;; former until we stop supporting Emacs 27, i.e. in a decade or
;; two.  Wrapping the use of that macro using `with-no-warning'
;; does not prevent the warning and because I am not willing to
;; look at it for a decade or so we have to do this dance:
(eval-when-compile
  (put 'menu-bar-make-toggle 'byte-obsolete-info nil))
(cl-eval-when (compile load eval)
  (unless (fboundp 'toggle-debug-on-signal)
    (menu-bar-make-toggle
     toggle-debug-on-signal debug-on-signal
     "Enter Debugger on Signal" "Debug on Signal %s"
     "Enter Lisp debugger regardless of condition handlers")))
(eval-when-compile
  (put 'menu-bar-make-toggle 'byte-obsolete-info
       (list 'menu-bar-make-toggle-command nil "28.1")))

(defun mode-line-toggle-debug-on-signal (event)
  "Toggle `debug-on-signal' from the mode-line."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (toggle-debug-on-signal)
    (force-mode-line-update)))

(put 'mode-line-debug 'risky-local-variable t)
(make-variable-buffer-local 'mode-line-debug)

;;; _
(provide 'mode-line-debug)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; mode-line-debug.el ends here
