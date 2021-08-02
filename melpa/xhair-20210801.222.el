;;; xhair.el --- Highlight the current line and column

;; Copyright © 2020-2021, Boruch Baum <boruch_baum@gmx.com>

;; Author/Maintainer: Boruch Baum <boruch_baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-xhair
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: convenience faces maint
;; Package-Version: 20210801.222
;; Package-Commit: c7bd7c501c3545aa99dadac386c882fe7c5edd9c
;; Package: xhair
;; Version: 1.0
;; Package-Requires: ((emacs "24.3") (vline "1.0"))

;;   (emacs "24.3") ; for: defvar-local, setq-local

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your
;; option) any later version.

;; This software is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this software. If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;;   This package simultaneously applies `vline-mode' and
;;   `hl-line-mode', with tweaks, to present POINT in highlighted
;;   cross-hairs, reporting the value of POINT as a message in the
;;   echo area. This will remain in effect until toggled manually
;;   (function `xhair-mode' by default), or until the next keypress
;;   (function `xhair' by default), or for a set interval (function
;;   `xhair-flash' by default).

;;; Usage:

;;   After installing the package, run any of the following:

;;     M-x `xhair-mode'  - Apply until manually toggled

;;     M-x `xhair'       - Apply until next keypress

;;     M-x `xhair-flash' - Apply for a set interval

;;   Refer to the function docstrings for further details.

;;; Customization:

;;   See variables `xhair-eldoc-idle-delay', `xhair-flash-interval',
;;   and `xhair-face'.

;;; Compatibility:

;;   * Tested on Debian Emacs 27 nox.

;;   * Includes support to operate nicely with `yascroll-bar-mode'. It
;;     temporarily suspends that mode locally in order not to make the
;;     buffer display jump around.

;;   * Includes support to operate nicely with `eldoc-mode'. It delays
;;     eldoc messages to give the user time to read the value of POINT from
;;     the echo area.

;;; Feedback:

;;   * It's best to contact me by opening an 'issue' on the package's
;;     github repository (see above) or, distant second-best, by
;;     direct e-mail.

;;   * Code contributions are welcome and github starring is
;;     appreciated.

;; Antecedent:

;;  This package is based upon `crosshairs.el' by Drew Adams, available at:

;;    https://www.emacswiki.org/emacs/download/crosshairs.el

;;  Its main differences from Drew's package is that it:
;;  * Is MELPA-friendly
;;  * Reduces dependencies
;;  * Reduces features (notably: `crosshairs-toggle-when-idle')
;;  * Simplifies code-base
;;  * Applies a single unique face, by default
;;  * Suspends `yascroll-bar-mode', to not interfere with `vline-mode'
;;  * Reports POINT for all navgitaion for duration of mode
;;  * Delays `eldoc-mode' messages, to not interfere with reporting POINT
;;  * Suppresses output to *Messages* buffer
;;  * Changes documentation
;;  * Eschews all use of macro `define-minor-mode'



;;; Code:

(require 'hl-line) ; Part of Emacs
(require 'vline)   ; Available via MELPA


;;; External functions
(declare-function yascroll-bar-mode         "ext:yascroll.el")
(declare-function yascroll:show-scroll-bar  "ext:yascroll.el")
(declare-function vline-mode                "ext:vline.el")



;;; Customizations:

(defcustom xhair-face
  '(:foreground "Black" :background "DarkOrange1")
  "Face used for option `xhair-mode'.
Set this to NIL in order to inherit the individual default faces
for option `vline-mode' and option `hl-line-mode'."
  :type  'face
  :group 'xhair)

(defcustom xhair-flash-interval 2.0
  "Floating point seconds to temporarily display cross-hairs."
  :type 'number
  :group 'xhair)

(defcustom xhair-eldoc-idle-delay 3.0
  "Seconds to delay option `eldoc-mode' messages.
Eldoc messages will overwrite xhair reporting of POINT. See
variable `eldoc-idle-delay'."
  :type 'number
  :group 'xhair)



;;; Buffer-local variables:

(defvar-local xhair-mode nil
  "Whether `xhair-mode' is active.
Never set this variable directly! Always use function
`xhair-mode'.")

(defvar-local xhair--flash-timer (timer-create)
  "Timer used to unhighlight current line for command `xhair-flash'.")

(defvar-local xhair--true-eldoc-idle-delay eldoc-idle-delay
  "Holding for variable `eldoc-idle-delay'")

(defvar-local xhair--yascroll-bar nil
  "Holding state for minor mode `yascroll-bar-mode'.")



;;; Hook functions:

(defun xhair--report-point ()
  "Report POINT.
Hook function for `post-command-hook'."
  (let ((message-log-max 0))
    (message "Xhair point: %d" (point))))

;; NOTE: Interactive function `xhair-unhighlight' also serves as a
;;       hook function for `pre-command-hook'.



;;; Interactive functions:

(defun xhair-highlight (&optional mode nomsg only-until-next-event seconds)
  "Report POINT and highlight it with xhair.

Interactively, a negative prefix arg highlights only the column,
and a non-negative prefix arg highlights only the line. All
interactive highlighting is active only until the next keypress.
Thus, calling this function interactively without a prefix arg is
equivalent to calling function `xhair'.

Non-interactively, optional arg MODE may be symbol `line-only' or
`col-only' to highlight only that axis. Optional arg NOMSG
non-nil means don't report POINT. When optional arg
ONLY-UNTIL-NEXT-EVENT is non-nil, highlighting ends upon the next
keypress; otherwise if SECONDS is a positive number then for that
interval.

Returns current position as a marker."
  (interactive (list (and current-prefix-arg
                          (if (wholenump (prefix-numeric-value current-prefix-arg))
                              'line-only
                            'col-only))
                     nil   ; nomsg
                     t     ; only-until-next-event
                     nil)) ; seconds
  (prog1 (point-marker)
    (setq mark-active  nil)
    (xhair-unhighlight 'even-if-frame-switch)
    (setq xhair-mode t)
    (when xhair-face
      (face-remap-set-base 'vline    xhair-face)
      (face-remap-set-base 'hl-line  xhair-face))
    (unless (eq mode 'line-only)
      (when (bound-and-true-p yascroll-bar-mode)
        (setq-local xhair--yascroll-bar t)
        (yascroll-bar-mode -1))
      (vline-mode 1))
    (unless (eq mode 'col-only)
      (unless global-hl-line-mode
        (global-hl-line-mode 1)
        (global-hl-line-highlight)))
    (redisplay t)
    (when (bound-and-true-p eldoc-idle-delay)
      (setq-local xhair--true-eldoc-idle-delay eldoc-idle-delay)
      (setq-local eldoc-idle-delay xhair-eldoc-idle-delay))
    (add-hook 'post-command-hook #'xhair--report-point 100 'local)
    (if only-until-next-event
      (add-hook 'pre-command-hook #'xhair-unhighlight nil 'local)
     (when seconds
       (cancel-timer xhair--flash-timer) ; Cancel to prevent duplication.
       (setq xhair--flash-timer
         (run-at-time (max 0.01
                           (if (and seconds (numberp seconds))
                             seconds
                            xhair-flash-interval))
                      nil
                      #'xhair-unhighlight))))))

(defun xhair-unhighlight (&optional arg)
  "Turn off xhair highlighting of current position.
Optional ARG nil means do nothing if this event is a frame
switch. Thus, without the prefix arg, this function is equivalent
to using function `xhair' to toggle off highlighting."
  (interactive)
  (when (or arg (not (and (consp last-input-event)
                          (eq (car last-input-event) 'switch-frame))))
    (global-hl-line-mode -1)
    (global-hl-line-unhighlight)
    (when (fboundp 'global-hl-line-unhighlight-all)
      (global-hl-line-unhighlight-all))
    (vline-mode -1)
    (face-remap-reset-base 'vline)
    (face-remap-reset-base 'hl-line)
    (when xhair--yascroll-bar
      (setq xhair--yascroll-bar nil)
      (yascroll-bar-mode 1)
      (yascroll:show-scroll-bar))
    (setq xhair-mode nil)
    (when (bound-and-true-p eldoc-idle-delay)
      (setq-local eldoc-idle-delay xhair--true-eldoc-idle-delay))
    (remove-hook 'post-command-hook #'xhair--report-point 'local)
    (remove-hook 'pre-command-hook  #'xhair-unhighlight 'local)))

;;;###autoload
(defun xhair-mode (&optional arg only-until-next-event seconds)
    "Toggle highlighting the current line and column.

This function is the 'easiest' to use if you want to manually
toggle the mode. The parallel function `xhair' defaults to
highlight until the next keypress. The parallel function
`xhair-flash' defaults to highlight for
`xhair-flash-interval' seconds.

This function, when called interactively with a prefix-ARG, if
ARG is a positive integer performs the equivalent of function
`xhair-flash'. For other values of ARG highlights until the
next keypress.

Non-interactively, this function turns highlighting on if ARG is
NIL or positive; otherwise turns it off. When
ONLY-UNTIL-NEXT-EVENT is non-nil, highlighting is turned off at
the next key event. Otherwise, if SECONDS is a number,
highlighting remains on for the maximum of one or SECONDS
seconds. If SECONDS is otherwise non-nil, highlighting remains on
for the maximum of one or variable `xhair-flash-interval'
seconds."
  (interactive)
  (cond
    ((called-interactively-p 'interactive)
      (setq xhair-mode (not xhair-mode)))
    (arg
     (setq xhair-mode (if (< 0 arg) t nil)))
    (t
     (setq xhair-mode t)))
  (unless arg
    (cond
     ((and global-hl-line-mode vline-mode)
       (setq xhair-mode nil))
     ((and (not global-hl-line-mode) (not vline-mode))
      (setq xhair-mode t))))
  (cond
   (xhair-mode
    (xhair-highlight
      t 'msg
      (or only-until-next-event
          (and current-prefix-arg
               (>= current-prefix-arg)))
      (if (and current-prefix-arg
               (< 0 current-prefix-arg))
        current-prefix-arg
       seconds)))
   (t
     (xhair-unhighlight)
     (let ((message-log-max 0))
       (message "Xhair mode disabled")))))

;;;###autoload
(defun xhair-flash (&optional seconds)
  "Highlight the current line and column briefly.
Defaults to `xhair-flash-interval' seconds or to a numeric
prefix arg SECONDS greater than one second."
  (interactive "p")
  (xhair-mode 1 nil (if current-prefix-arg
                          seconds
                         xhair-flash-interval)))

;;;###autoload
(defun xhair (&optional arg)
  "Toggle highlighting current position with xhairs.

This function is the 'easiest' to use if you only want
highlighting until the next keypress. The parallel function
`xhair-mode' defaults to highlight until manually toggled.
The parallel function `xhair-flash' defaults to highlight for
`xhair-flash-interval' seconds.

This function, with a non-nil prefix ARG, retains highlighting
until you manually toggle it off."
  (interactive "P")
  (setq current-prefix-arg nil)
  (xhair-mode (if xhair-mode -1 1) (not arg)))



;;; Conclusion:

(provide 'xhair)

;;; xhair.el ends here
