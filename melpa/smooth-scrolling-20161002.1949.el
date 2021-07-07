;;; smooth-scrolling.el --- Make emacs scroll smoothly
;;
;; Copyright (c) 2007-2016 Adam Spiers
;;
;; Filename: smooth-scrolling.el
;; Description: Make emacs scroll smoothly
;; Author: Adam Spiers <emacs-ss@adamspiers.org>
;;         Jeremy Bondeson <jbondeson@gmail.com>
;;         Ryan C. Thompson <rct+github@thompsonclan.org>
;; Maintainer: Adam Spiers <emacs-ss@adamspiers.org>
;; Homepage: http://github.com/aspiers/smooth-scrolling/
;; Version: 2.0.0
;; Package-Version: 20161002.1949
;; Package-Commit: 2462c13640aa4c75ab3ddad443fedc29acf68f84
;; Keywords: convenience
;; GitHub: http://github.com/aspiers/smooth-scrolling/

;; This file is not part of GNU Emacs

;;; License:
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

;;; Commentary:

;; To interactively toggle the mode on / off:
;;
;;     M-x smooth-scrolling-mode
;;
;; To make the mode permanent, put this in your .emacs:
;;
;;     (require 'smooth-scrolling)
;;     (smooth-scrolling-mode 1)
;;
;; This package offers a global minor mode which make emacs scroll
;; smoothly.  It keeps the point away from the top and bottom of the
;; current buffer's window in order to keep lines of context around
;; the point visible as much as possible, whilst minimising the
;; frequency of sudden scroll jumps which are visually confusing.
;;
;; This is a nice alternative to all the native `scroll-*` custom
;; variables, which unfortunately cannot provide this functionality
;; perfectly.  For example, when using the built-in variables, clicking
;; with the mouse in the margin will immediately scroll the window to
;; maintain the margin, so the text that you clicked on will no longer be
;; under the mouse.  This can be disorienting.  In contrast, this mode
;; will not do any scrolling until you actually move up or down a line.
;;
;; Also, the built-in margin code does not interact well with small
;; windows.  If the margin is more than half the window height, you get
;; some weird behavior, because the point is always hitting both the top
;; and bottom margins.  This package auto-adjusts the margin in each
;; buffer to never exceed half the window height, so the top and bottom
;; margins never overlap.

;; See the README.md for more details.

;;; Change Log:
;; 27 Feb 2016 -- v2.0.0
;;      * Converted to global minor mode "smooth-scrolling-mode". This
;;        means that simply loading the file no longer enables smooth
;;        scrolling; you must also enable the mode.
;;      * Internal code restructuring that should improve some edge
;;        cases, but otherwise have no user-visible effects.
;; 19 Dec 2013 -- v1.0.4
;;      * Disabled scrolling while a keyboard macro is executing in
;;        order to prevent a premature termination of the macro by
;;        the mode throwing an error such as "End of Buffer"
;; 02 Jun 2013 -- v1.0.3
;;      * Fixed Issue #3 where bounds checking was not being performed
;;        prior to calls to 'count-lines' and 'count-screen-lines'
;;        functions.
;; 14 Apr 2013 -- v1.0.2
;;      * Adam Spiers GitHub account now houses the canonical
;;        repository.
;; 06 Dec 2011 -- v1.0.1
;;	* Altered structure to conform to package.el standards.
;;	* Restructured code to group settings changes
;;	* Set "redisplay-dont-pause" to true.
;; ?? ??? 2007 -- v1.0.0
;;      * Original version from Adam Spiers

;;; Code:

;;;_ + internal variables
(defvar smooth-scroll-orig-scroll-margin nil)

;;;_ + defcustoms

(defgroup smooth-scrolling nil
  "Make emacs scroll smoothly"
  :group 'convenience)

;;;###autoload
(define-minor-mode smooth-scrolling-mode
  "Make emacs scroll smoothly"
  :init-value nil
  :global t
  :group 'smooth-scrolling
  (if smooth-scrolling-mode
      (setq smooth-scroll-orig-scroll-margin scroll-margin
            scroll-margin 0)
    (setq scroll-margin smooth-scroll-orig-scroll-margin
          smooth-scroll-orig-scroll-margin nil)))

;;;###autoload
(defcustom smooth-scroll-margin 10
  "Number of lines of visible margin at the top and bottom of a window.
If the point is within these margins, then scrolling will occur
smoothly for `previous-line' at the top of the window, and for
`next-line' at the bottom.

This is very similar in its goal to `scroll-margin'.  However, it
is implemented by activating `smooth-scroll-down' and
`smooth-scroll-up' advise via `defadvice' for `previous-line' and
`next-line' respectively.  As a result it avoids problems
afflicting `scroll-margin', such as a sudden jump and unexpected
highlighting of a region when the mouse is clicked in the margin.

Scrolling only occurs when the point is closer to the window
boundary it is heading for (top or bottom) than the middle of the
window.  This is to intelligently handle the case where the
margins cover the whole buffer (e.g. `smooth-scroll-margin' set
to 5 and `window-height' returning 10 or less).

See also `smooth-scroll-strict-margins'."
  :type  'integer
  :group 'smooth-scrolling)

;;;###autoload
(defcustom smooth-scroll-strict-margins t
  "If true, the advice code supporting `smooth-scroll-margin'
will use `count-screen-lines' to determine the number of
*visible* lines between the point and the window top/bottom,
rather than `count-lines' which obtains the number of actual
newlines.  This is because there might be extra newlines hidden
by a mode such as folding-mode, outline-mode, org-mode etc., or
fewer due to very long lines being displayed wrapped when
`truncate-lines' is nil.

However, using `count-screen-lines' can supposedly cause
performance issues in buffers with extremely long lines.  Setting
`cache-long-line-scans' may be able to address this;
alternatively you can set this variable to nil so that the advice
code uses `count-lines', and put up with the fact that sometimes
the point will be allowed to stray into the margin."
  :type  'boolean
  :group 'smooth-scrolling)

;;;_ + helper functions
(defmacro smooth-scroll-ignore-scroll-errors (&rest body)
  "Like `progn', but ignores beginning/end of line errors.

If BODY encounters such an error, further evaluation is stopped
and this form returns nil. Any other error is raised as normal."
  (declare (indent 0))
  `(condition-case err
       (progn ,@body)
     (end-of-buffer nil)
     (beginning-of-buffer nil)
     (error (signal (car err) (cdr err)))))

(defun smooth-scroll-line-beginning-position ()
  "Return position at beginning of (logical/visual) line.

If `smooth-scroll-strict-margins' is non-nil, this looks to the
beginning of the visual line. Otherwise it uses the beginning of
the logical line."
  (save-excursion
    ;; Cannot use `line-beginning-position' here because there is no
    ;; visual-line equivalent.
    (funcall (if smooth-scroll-strict-margins
                 #'beginning-of-visual-line
               #'beginning-of-line))
    (point)))

(defun smooth-scroll-count-lines (start end)
  "Return number of (logical/visual) lines between START and END.

If `smooth-scroll-strict-margins' is non-nil, this counts visual
lines. Otherwise it counts logical lines.

If END is less than START, this returns zero, so it is important
to pass them in order."
  (if (< end start)
      0
    (funcall (if smooth-scroll-strict-margins
                 #'count-screen-lines
               #'count-lines)
             start end)))

(defun smooth-scroll-lines-above-point ()
  "Return the number of lines in window above point.

This does not include the line that point is on."
  (smooth-scroll-count-lines (window-start)
                             (smooth-scroll-line-beginning-position)))

(defun smooth-scroll-lines-below-point ()
  "Return the number of lines in window above point.

This does not include the line that point is on."
  ;; We don't rely on `window-end' because if we are scrolled near the
  ;; end of the buffer, it will only give the number of lines
  ;; remaining in the file, not the number of lines to the bottom of
  ;; the window.
  (- (window-height) 2 (smooth-scroll-lines-above-point)))

(defun smooth-scroll-window-allowed-margin ()
  "Return the maximum allowed margin above or below point.

This only matters for windows whose height is
`smooth-scroll-margin' * 2 lines or less."
  ;; We subtract 1 for the modeline, which is counted in
  ;; `window-height', and one more for the line that point is on. Then
  ;; we divide by 2, rouding down.
  (/ (- (window-height) 2) 2))

(defsubst window-is-at-bob-p ()
  "Returns non-nil if `(window-start)' is 1 (or less)."
  (<= (window-start) 1))

;;;_ + main function
(defun do-smooth-scroll ()
  "Ensure that point is not to close to window edges.

This function scrolls the window until there are at least
`smooth-scroll-margin' lines between the point and both the top
and bottom of the window. If this is not possible because the
window is too small, th window is scrolled such that the point is
roughly centered within the window."
  (interactive)
  (when smooth-scrolling-mode
    (let* ((desired-margin
            ;; For short windows, we reduce `smooth-scroll-margin' to
            ;; half the window height minus 1.
            (min (smooth-scroll-window-allowed-margin)
                 smooth-scroll-margin))
           (upper-margin (smooth-scroll-lines-above-point))
           (lower-margin (smooth-scroll-lines-below-point)))
      (smooth-scroll-ignore-scroll-errors
        (cond
         ((< upper-margin desired-margin)
          (save-excursion
            (dotimes (i (- desired-margin upper-margin))
              (scroll-down 1))))
         ((< lower-margin desired-margin)
          (save-excursion
            (dotimes (i (- desired-margin lower-margin))
              (scroll-up 1)))))))))

;;;_ + advice setup

;;;###autoload
(defmacro enable-smooth-scroll-for-function (func)
  "Define advice on FUNC to do smooth scrolling.

This adds after advice with name `smooth-scroll' to FUNC.

Note that the advice will not have an effect unless
`smooth-scrolling-mode' is enabled."
  `(defadvice ,func (after smooth-scroll activate)
     "Do smooth scrolling after command finishes.

This advice only has an effect when `smooth-scrolling-mode' is
enabled. See `smooth-scrolling-mode' for details. To remove this
advice, use `disable-smooth-scroll-for-function'."
     (do-smooth-scroll)))

(defmacro enable-smooth-scroll-for-function-conditionally (func cond)
  "Define advice on FUNC to do smooth scrolling conditionally.

This adds after advice with name `smooth-scroll' to FUNC. The
advice runs smooth scrolling if expression COND evaluates to
true. COND is included within the advice and therefore has access
to all of FUNC's arguments.

Note that the advice will not have an effect unless
`smooth-scrolling-mode' is enabled."
  (declare (indent 1))
  `(defadvice ,func (after smooth-scroll activate)
     ,(format "Do smooth scrolling conditionally after command finishes.

Smooth sccrolling will only be performed if the following
expression evaluates to true after the function has run:

%s
This advice only has an effect when `smooth-scrolling-mode' is
enabled. See `smooth-scrolling-mode' for details. To remove this
advice, use `disable-smooth-scroll-for-function'."
              (pp-to-string cond))
     (when ,cond
       (do-smooth-scroll))))

(defmacro disable-smooth-scroll-for-function (func)
  "Delete smooth-scroll advice for FUNC."
  ;; This doesn't actually need to be a macro, but it is one for
  ;; consistency with the enabling macro.  Errors are ignored in case
  ;; the advice has already been removed.
  `(ignore-errors
     (ad-remove-advice ',func 'after 'smooth-scroll)
     (ad-activate ',func)))

(progn
  (enable-smooth-scroll-for-function previous-line)
  (enable-smooth-scroll-for-function next-line)
  (enable-smooth-scroll-for-function dired-previous-line)
  (enable-smooth-scroll-for-function dired-next-line)
  (enable-smooth-scroll-for-function isearch-repeat)
  (enable-smooth-scroll-for-function-conditionally scroll-up-command
    (not (window-is-at-bob-p)))
  (enable-smooth-scroll-for-function-conditionally scroll-down-command
    (not (window-is-at-bob-p))))

;;;_ + provide
(provide 'smooth-scrolling)
;;; smooth-scrolling.el ends here
