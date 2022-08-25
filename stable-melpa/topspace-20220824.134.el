;;; topspace.el --- Recenter line 1 with scrollable upper margin/padding -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022 Free Software Foundation, Inc.

;; Author: Trevor Edwin Pogue <trevor.pogue@gmail.com>
;; Maintainer: Trevor Edwin Pogue <trevor.pogue@gmail.com>
;; URL: https://github.com/trevorpogue/topspace
;; Package-Version: 20220824.134
;; Package-Commit: 33c2a6f0a11d1d88cdb2065c5a897e33507f4c86
;; Keywords: convenience, scrolling, center, cursor, margin, padding
;; Version: 0.3.1
;; Package-Requires: ((emacs "25.1"))

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TopSpace lets you display a buffer's first line in the center of a window
;; instead of just at the top.
;; This is done by automatically drawing an upper margin/padding above line 1
;; as you recenter and scroll it down.

;; See https://github.com/trevorpogue/topspace for a GIF demo & documentation.

;; Features:

;; - Easier on the eyes: Recenter or scroll down top text to a more
;;   comfortable eye level for reading, especially when in full-screen
;;   or on a large monitor.

;; - Easy to use: No new keybindings are required, keep using all
;;   your previous scrolling & recentering commands, except now you
;;   can also scroll down the first line.  It also integrates
;;   seamlessly with `centered-cursor-mode' to keep the cursor
;;   centered all the way to the first line.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Private variables

(defvar-local topspace--heights '()
  "Stores top space heights of each window that buffer has been selected in.")

(defvar-local topspace--buffer-was-scrolled '()
  "Stores if user has scrolled buffer in selected window before.
Only recorded if topspace is active in the buffer at the time of scrolling.")

(defvar-local topspace--previous-window-heights '()
  "Stores the window heights of each window that buffer has been selected in.")

(defvar-local topspace--window-start-before-scroll 2
  "Helps to identify if more top space must be drawn after scrolling up.")

(defvar-local topspace--total-lines-scrolling 0
  "Stores the total lines that the user is scrolling until scroll is complete.")

(defvar-local topspace--pre-command-point 1
  "Used for performance improvement by abandoning extra calculations.
In the post command hook, this determines if point moved further than the
window height, in which case there is no point checking if the top space
should be reduced in size or not.  It also determines the direction of
movement that the user is moving point in since some `post-command-hook'
operations are only needed when moving downward.")

(defvar-local topspace--pre-command-window-start 2
  "Used for performance improvement by abandoning extra calculations.
In the post command hook, this determines if any top space was present
before the command, otherwise there is no point checking if the top
space should be reduced in size or not.")

(defvar-local topspace--got-first-window-configuration-change nil
  "Displaying top space before the first window config change can cause errors.
This flag signals to wait until then to display top space.")

(defvar topspace--advice-added nil
  "Keeps track of if `advice-add' has been done already.")

(defvar topspace--scroll-down-scale-factor 1
  "For eliminating an error when testing in non-interactive batch mode.
An error occurs in this mode any time `scroll-down' is passed a
non-zero value, which halts tests and makes testing many topspace features
impossible.  So this variable is set to zero when testing in this mode.")

(defvar topspace--context-lines 1
  "Determines how many lines away from `window-end' the cursor can get.
This is relevant when scrolling in such a way that the cursor tries to
move past `window-end'.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Customization

(defgroup topspace nil
  "Scroll down & recenter top lines / get upper margins/padding."
  :group 'scrolling
  :group 'convenience
  :link '(emacs-library-link :tag "Source Lisp File" "topspace.el")
  :link '(url-link "https://github.com/trevorpogue/topspace")
  :link '(emacs-commentary-link :tag "Commentary" "topspace"))

(defcustom topspace-active #'topspace-default-active
  "Determine when `topspace-mode' mode is active / has any effect on buffer.
This is useful in particular when `global-topspace-mode' is enabled but you want
`topspace-mode' to be inactive in certain buffers or in any specific
circumstance.  When inactive, `topspace-mode' will still technically be on,
but will be effectively off and have no effect on the buffer.
Note that if `topspace-active' returns non-nil but `topspace-mode' is off,
`topspace-mode' will still be disabled.

With the default value, topspace will only be inactive in child frames.

If non-nil, then always be active.  If nil, never be active.
If set to a predicate function (function that returns a boolean value),
then be active only when that function returns a non-nil value."
  :type '(choice (const :tag "always" t)
                 (const :tag "never" nil)
                 (function :tag "predicate function")))

(defcustom topspace-autocenter-buffers #'topspace-default-autocenter-buffers
  "Center small buffers with top space when first opened or window sizes change.
This is done by automatically calling `topspace-recenter-buffer'
and the positioning can be customized with `topspace-center-position'.
Top space will not be added if the number of text lines in the buffer is larger
than or close to the selected window's height, or if `window-start' is greater
than 1.

With the default value, buffers will not be centered if in a child frame
or if the user has already scrolled or used `recenter' with buffer in the
selected window.

If non-nil, then always autocenter.  If nil, never autocenter.
If set to a predicate function (function that returns a boolean value),
then do auto-centering only when that function returns a non-nil value."
  :group 'topspace
  :type '(choice (const :tag "always" t)
                 (const :tag "never" nil)
                 (function :tag "predicate function")))

(defcustom topspace-center-position 0.4
  "Target position when centering buffers.

Used in `topspace-recenter-buffer' when called without an argument, or when
opening/resizing buffers if `topspace-autocenter-buffers' returns non-nil.

Can be set to a floating-point number, integer, or function that returns a
floating-point number or integer.

If a floating-point number, it represents the position to center buffers as a
ratio of frame height, and can be a value from 0.0 to 1.0 where lower values
center buffers higher up in the screen.

If a positive or negative integer value, buffers will be centered by putting
their center line at a distance of `topspace-center-position' lines away
from the top of the selected window when positive, or from the bottom
of the selected window when negative.
The distance will be in units of lines with height `default-line-height',
and the value should be less than the height of the window.

If a function, the same rules above apply to the function's return value."
  :group 'topspace
  :type '(choice float integer
                 (function :tag "floating-point number or integer function")))

(defcustom topspace-empty-line-indicator
  #'topspace-default-empty-line-indicator
  "Text that will appear in each empty topspace line above the top text line.
Can be set to either a constant string or a function that returns a string.

The conditions in which the indicator string is present are also customizable
by setting `topspace-empty-line-indicator' to a function, where the function
returns \"\" (an empty string) under any conditions in which you don't want
the indicator string to be shown.

By default it will show the empty-line bitmap in the left fringe
if `indicate-empty-lines' is non-nil, otherwise nothing.
This is done by adding a 'display property to the string (see
`topspace-default-empty-line-indicator' for more details).
The default bitmap is the one that the `empty-line' logical fringe indicator
maps to in `fringe-indicator-alist'.

You can alternatively show the string text in the body of each top space line by
having `topspace-empty-line-indicator' return a string without the 'display
property added.  If you do this you may be interested in also changing the
string's face like so: (propertize indicator-string 'face 'fringe)."
  :type '(choice 'string (function :tag "String function")))

(defcustom topspace-mode-line " T"
  "Mode line lighter for Topspace.
The value of this variable is a mode line template as in
`mode-line-format'.  See Info Node `(elisp)Mode Line Format' for
more information.  Note that it should contain a _single_ mode
line construct only.
Set this variable to nil to disable the mode line completely."
  :group 'topspace
  :type 'sexp)

(defvar topspace-keymap (make-sparse-keymap)
  "Keymap for Topspace commands.
By default this is left empty for users to set with their own
preferred bindings.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; User functions

;;;###autoload
(defun topspace-height ()
  "Return the top space height in lines for current buffer in selected window.
The top space is the empty region in the buffer above the top text line.
The return value is a floating-point number, and is equivalent to
the top space pixel height / `default-line-height'.

If the height does not exist yet, zero will be returned if
`topspace-autocenter-buffers' returns nil, otherwise a value that centers
the buffer will be returned according to `topspace-center-position'.

If the stored height is now invalid, it will first be corrected by
`topspace--correct-height' before being returned.
Valid top space line heights are:
- never negative,
- only positive when `window-start' equals 1,
  `topspace-active' returns non-nil, and `topspace-mode' is enabled,
- not larger than `window-text-height' minus `topspace--context-lines'."
  (let ((height) (window (selected-window)))
    ;; First try returning previously stored top space height
    (setq height (alist-get window topspace--heights))
    (unless height
      ;; If it has never been created before then get the default value
      (setq height (if (topspace--eval-choice topspace-autocenter-buffers)
                       (topspace--height-to-recenter-buffer) 0.0)))
    ;; Correct, store, and return the new value
    (topspace--set-height height)))

;;;###autoload
(defun topspace-set-height (&optional total-lines)
  "Set and redraw the top space overlay to have a target height of TOTAL-LINES.
This sets the top space height for the current buffer in the selected window.
Integer or floating-point numbers are accepted for TOTAL-LINES, and the value is
considered to be in units of `default-line-height'.

If argument TOTAL-LINES is not provided, the top space height will be set to
the value returned by `topspace-height', which can be useful when redrawing a
previously stored top space height in a window after a new buffer is
displayed in it, or when first setting the height to an initial default value
according to `topspace-height'.

If TOTAL-LINES is invalid, it will be corrected by `topspace--correct-height'.
Valid top space line heights are:
- never negative,
- only positive when `window-start' equals 1,
  `topspace-active' returns non-nil, and `topspace-mode' is enabled,
- not larger than `window-text-height' minus `topspace--context-lines'."
  (interactive "P")
  (let ((old-height) (window (selected-window)))
    ;; Get the previous top space height
    (unless old-height (setq old-height (topspace-height)))
    ;; Get the default value if TOTAL-LINES arg not provided
    (unless total-lines (setq total-lines old-height))
    ;; Update or correct the stored top space height to new value
    (setq total-lines (topspace--correct-height
                       (topspace--set-height total-lines)))
    (when (and (> total-lines 0) (> total-lines old-height))
      ;; If top space height is increasing, make sure it doesn't push the
      ;; cursor off the screen
      (let ((lines-past-max (topspace--total-lines-past-max total-lines)))
        (when (> lines-past-max 0)
          (topspace--previous-line (ceiling lines-past-max)))))
    (let ((topspace (make-overlay 1 1)))
      ;; Redraw top space with the new height by drawing a new overlay and
      ;; erasing any previously drawn overlays for current buffer in
      ;; selected window
      (remove-overlays 1 1 'topspace--remove-from-window-tag window)
      (overlay-put topspace 'window window)
      (overlay-put topspace 'topspace--remove-from-window-tag window)
      (overlay-put topspace 'topspace--remove-from-buffer-tag t)
      (overlay-put topspace 'before-string (topspace--text total-lines)))
    ;; Return the new height
    total-lines))

;;;###autoload
(defun topspace-recenter-buffer (&optional position)
  "Add enough top space to center small buffers according to POSITION.
POSITION defaults to `topspace-center-position'.
Top space will not be added if the number of text lines in the buffer is larger
than or close to the selected window's height, or if `window-start' is greater
than 1.

If POSITION is a floating-point, it represents the position to center buffer as
a ratio of frame height, and can be a value from 0.0 to 1.0 where lower values
center the buffer higher up in the screen.

If POSITION is a positive or negative integer value, buffer will be centered
by putting its center line at a distance of `topspace-center-position' lines
away from the top of the selected window when positive, or from the bottom
of the selected window when negative.
The distance will be in units of lines with height `default-line-height',
and the value should be less than the height of the window.

Top space will not be added if the number of text lines in the buffer is larger
than or close to the selected window's height, or if `window-start' is greater
than 1.

Customize `topspace-center-position' to adjust the default centering position.
Customize `topspace-autocenter-buffers' to run this command automatically
after first opening buffers and after window sizes change."
  (interactive)
  (cond
   ((not (topspace--enabled)) (topspace-set-height 0.0))
   (t (topspace-set-height (topspace--height-to-recenter-buffer position)))))

;;;###autoload
(defun topspace-default-active ()
  "Default function that `topspace-active' is set to.
Return nil if the selected window is in a child-frame."
  (or ;; frame-parent is only provided in Emacs 26.1, so first check
   ;; if fhat function exists.
   (not (fboundp 'frame-parent))
   (not (frame-parent))))

;;;###autoload
(defun topspace-default-autocenter-buffers ()
  "Default function that `topspace-autocenter-buffers' is set to.
Return nil if the selected window is in a child-frame or user has scrolled
buffer in selected window."
  (and (not (topspace-buffer-was-scrolled-p))
       (or ;; frame-parent is only provided in Emacs 26.1, so first check
        ;; if fhat function exists.
        (not (fboundp 'frame-parent))
        (not (frame-parent)))))

;;;###autoload
(defun topspace-default-empty-line-indicator ()
  "Default function that `topspace-empty-line-indicator' is set to.
Put the empty-line bitmap in fringe if `indicate-empty-lines' is non-nil.
This is done by adding a 'display property to the returned string.
The bitmap used is the one that the `empty-line' logical fringe indicator
maps to in `fringe-indicator-alist'."
  (if indicate-empty-lines
      (let ((bitmap
             (catch 'tag
               (dolist (x fringe-indicator-alist)
                 (when (eq (car x) 'empty-line) (throw 'tag (cdr x)))))))
        (propertize " " 'display (list `left-fringe bitmap `fringe)))
    ""))

;;;###autoload
(defun topspace-buffer-was-scrolled-p ()
  "Return t if current buffer has been scrolled in the selected window before.
This is provided since it is used in `topspace-default-autocenter-buffers'.
Scrolling is only recorded if topspace is active in the buffer at the time of
scrolling."
  (alist-get (selected-window) topspace--buffer-was-scrolled))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Advice for `scroll-up', `scroll-down', and `recenter'

(defun topspace--scroll (total-lines)
  "Run before `scroll-up'/`scroll-down' for updating top space before scrolling.
TOTAL-LINES is used in the same way as in `scroll-down'."
  (setf (alist-get (selected-window) topspace--buffer-was-scrolled) t)
  (let ((old-topspace-height (topspace-height))
        (new-topspace-height))
    (setq new-topspace-height (topspace--correct-height
                               (+ old-topspace-height total-lines)))
    (setq topspace--window-start-before-scroll (window-start))
    (topspace-set-height new-topspace-height)
    (setq total-lines
          (- total-lines (- new-topspace-height old-topspace-height)))
    (round total-lines)))

(defun topspace--filter-args-scroll-down (&optional total-lines)
  "Run before `scroll-down' for scrolling above the top line.
TOTAL-LINES is used in the same way as in `scroll-down'."
  (cond
   ((not (topspace--enabled)) (topspace-set-height 0.0) total-lines)
   (t
    (setq total-lines (car total-lines))
    (setq total-lines (or total-lines (- (window-text-height)
                                         next-screen-context-lines)))
    (setq topspace--total-lines-scrolling total-lines)
    (list (* topspace--scroll-down-scale-factor
             (topspace--scroll total-lines))))))

(defun topspace--filter-args-scroll-up (&optional total-lines)
  "Run before `scroll-up' for scrolling above the top line.
TOTAL-LINES is used in the same way as in `scroll-up'."
  (cond
   ((not (topspace--enabled)) (topspace-set-height 0.0) total-lines)
   (t
    (setq total-lines (car total-lines))
    (setq total-lines (* (or total-lines (- (window-text-height)
                                            next-screen-context-lines)) -1))
    (setq topspace--total-lines-scrolling total-lines)
    (list (* (topspace--scroll total-lines) -1)))))

(defun topspace--after-scroll (&optional total-lines)
  "Run after `scroll-up'/`scroll-down' for scrolling above the top line.
TOTAL-LINES is used in the same way as in `scroll-down'.
This is needed when scrolling down (moving buffer text lower in the screen)
and no top space was present before scrolling but it should be after scrolling.
The reason this is needed is because `topspace-set-height' only draws the
overlay when `window-start` equals 1, which can only be true after the scroll
command is run in the described case above."
  (cond
   ((not (topspace--enabled)))
   (t
    (setq total-lines topspace--total-lines-scrolling)
    (when (and (> topspace--window-start-before-scroll 1) (= (window-start) 1))
      (let ((lines-already-scrolled (topspace--count-lines
                                     1 topspace--window-start-before-scroll)))
        (setq total-lines (abs total-lines))
        (set-window-start (selected-window) 1)
        (topspace-set-height (- total-lines lines-already-scrolled)))
      (when (and (bound-and-true-p linum-mode) (fboundp 'linum-update-window))
        (linum-update-window (selected-window)))))))

(defun topspace--after-recenter (&optional line-offset redisplay)
  "Recenter near the top of buffers by adding top space appropriately.
LINE-OFFSET and REDISPLAY are used in the same way as in `recenter'."
  ;; redisplay is unused but needed since this function
  ;; must take the same arguments as `recenter'
  redisplay  ; remove flycheck warning for unused argument (see above)
  (cond
   ((not (topspace--enabled)))
   (t
    (setf (alist-get (selected-window) topspace--buffer-was-scrolled) t)
    (when (= (window-start) 1)
      (setq line-offset (topspace--calculate-recenter-line-offset line-offset))
      (topspace-set-height (- line-offset (topspace--count-lines
                                           (window-start)
                                           (point))))))))

(defun topspace--smooth-scroll-lines-above-point (&rest args)
  "Add support for `smooth-scroll-mode', ignore ARGS.
ARGS are needed for compatibility with `advice-add'."
  ;; remove flycheck warnings by using R and checking smooth-scroll functions
  args
  (when (and (fboundp 'smooth-scroll-count-lines)
             (fboundp 'smooth-scroll-line-beginning-position))
    (+ (topspace-height)
       (smooth-scroll-count-lines
        (window-start) (smooth-scroll-line-beginning-position)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Top space line height calculation

(defun topspace--set-height (height)
  "Set the stored top space line height for the selected window to HEIGHT.
Will only set to HEIGHT if HEIGHT is a valid value as per
`topspace--correct-height'.  This only sets the underlying stored value for
top space height, and it does not redraw the top space."
  (setq height (topspace--correct-height height))
  (setf (alist-get (selected-window) topspace--heights) height)
  height)

(defun topspace--correct-height (height)
  "Return HEIGHT if a valid top space line height, else a valid value.
Valid top space line heights are:
- never negative,
- only positive when `window-start' equals 1,
  `topspace-active' returns non-nil, and `topspace-mode' is enabled,
- not larger than `window-text-height' minus `topspace--context-lines'."
  (let ((max-height (- (window-text-height) topspace--context-lines)))
    (setq height (float height))
    (when (> (window-start) 1) (setq height 0.0))
    (when (< height 0) (setq height 0.0))
    (when (> height max-height) (setq height max-height))
    (unless (topspace--enabled) (setq height 0.0)))
  height)

(defun topspace--window-end ()
  "Return the up-to-date `window-end'."
  (or (window-end (selected-window) t)))

(defun topspace--total-lines-past-max (&optional topspace-height)
  "Used when making sure top space height does not push cursor off-screen.
Return how many lines past the bottom of the window the cursor would get pushed
if setting the top space to the target value TOPSPACE-HEIGHT.
Any value above 0 flags that the target TOPSPACE-HEIGHT is too large."
  (- (topspace--current-line-plus-topspace topspace-height)
     (- (window-text-height) topspace--context-lines)))

(defun topspace--current-line-plus-topspace (&optional topspace-height)
  "Used when making sure top space height does not push cursor off-screen.
Return the current line plus the top space height TOPSPACE-HEIGHT."
  (+ (topspace--count-lines (window-start) (point))
     (or topspace-height (topspace-height))))

(defun topspace--calculate-recenter-line-offset (&optional line-offset)
  "Convert LINE-OFFSET to a line offset from the top of the window.
It is interpreted in the same way as the first ARG in `recenter'."
  (unless line-offset (setq line-offset (/ (float (window-text-height)) 2)))
  (when (< line-offset 0)
    ;; subtracting 1 below made `recenter-top-bottom' act correctly
    ;; when it moves point to bottom and top space is added to get there
    (setq line-offset (- (- (window-text-height) line-offset)
                         topspace--context-lines
                         1)))
  line-offset)

(defun topspace--center-line (&optional position)
  "Calculate the centering position when using `topspace-recenter-buffer'.
Return how many lines away from the top of the selected window that the
buffer's center line will be moved to based on POSITION, which defaults to
`topspace-center-position'.  Note that when POSITION
is a floating-point number, the return value is only valid for windows
starting at the top of the frame, which must be accounted for in the calling
functions."
  (setq position (or position (topspace--eval-choice topspace-center-position)))
  (if (floatp position)
      (* (topspace--frame-height) position)
    (topspace--calculate-recenter-line-offset position)))

(defun topspace--height-to-recenter-buffer (&optional position)
  "Return the necessary top space height to center selected window's buffer.
Buffer will be centered according to POSITION, which defaults to
`topspace-center-position'."
  (setq position (or position (topspace--eval-choice topspace-center-position)))
  (let ((buffer-height (topspace--count-lines
                        (window-start)
                        (topspace--window-end)))
        (result)
        (window-height (window-text-height)))
    (setq result (- (topspace--center-line position) (/ buffer-height 2)))
    (when (floatp position) (setq result (- result (window-top-line))))
    (when (> (+ result buffer-height)
             (- window-height topspace--context-lines))
      (setq result (- (- window-height buffer-height)
                      topspace--context-lines)))
    result))

(defun topspace--frame-height ()
  "Return the number of lines in the selected frame's text area.
Subtract 3 from `frame-text-lines' to discount echo area and bottom
mode-line in centering."
  (- (frame-text-lines) 3))

(defun topspace--count-pixel-height (start end)
  "Return total pixels between points START and END as if they're both visible."
  (let ((result 0))
    (save-excursion
      (goto-char end)
      (beginning-of-visual-line)
      (setq end (point))
      (goto-char start)
      (beginning-of-visual-line)
      (while (< (point) end)
        (setq result (+ result (line-pixel-height)))
        (vertical-motion 1)))
    result))

(defun topspace--count-lines-slow (start end)
  "Return screen lines between points START and END.
Like `topspace--count-lines' but is a slower backup alternative."
  (/ (topspace--count-pixel-height start end) (float (default-line-height))))

(defun topspace--count-lines (start end)
  "Return screen lines between points START and END.
Like `count-screen-lines' except `count-screen-lines' will
return unexpected value when END is in column 0. This fixes that issue.
This function also tries to first count the lines using a potentially faster
technique involving `window-absolute-pixel-position'.
If that doesn't work it uses `topspace--count-lines-slow'."
  (let ((old-end) (old-start) (swap)
        (line-height (float (default-line-height))))
    (when (> start end) (setq swap end) (setq end start) (setq start swap))
    (setq old-end end) (setq old-start start)
    ;; use faster visual method for counting portion of lines in screen:
    (when (< start (topspace--window-end))
      (setq end (min end (topspace--window-end))))
    (when (> end (window-start))
      (setq start (max start (window-start))))
    (let ((end-y (window-absolute-pixel-position end))
          (start-y (window-absolute-pixel-position start)))
      (+
       (if (> old-end end) (topspace--count-lines-slow end old-end) 0.0)
       (if (< old-start start) (topspace--count-lines-slow old-start start) 0.0)
       (condition-case nil
           ;; first try counting lines by getting the pixel difference
           ;; between end and start and dividing by `default-line-height'
           (/ (- (cdr end-y) (cdr start-y)) line-height)
         ;; if the pixel method above doesn't work do this slower method
         ;; (it won't work if either START or END are not visible in window)
         (error (topspace--count-lines-slow start end)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Overlay drawing

(defun topspace--text (height)
  "Return the topspace text that appears in the top overlay with height HEIGHT."
  (cond
   ((= (round height) 0) "")
   ((= (round height) 1)
    ;; comment a) You cannot set a string's line-height
    ;; to a positive float less than 1.  So in this condition,
    ;; settle for rounding the top space height up to 1
    "\n")
   (t
    ;; set the text to a series of newline characters with the last line
    ;; having a line-height set to a float accounting for the potential
    ;; fractional portion of the top space height
    (let ((text "")
          (indicator-line (topspace--eval-choice
                           topspace-empty-line-indicator)))
      (setq indicator-line (cl-concatenate 'string indicator-line "\n"))
      (dotimes (n (1- (floor height)))
        n ;; remove flycheck warning
        (setq text (cl-concatenate 'string text indicator-line)))
      (setq indicator-line
            ;; set that last line with a float line-height.
            ;; The float will be set to >1 due to comment a) above
            (propertize indicator-line 'line-height
                        (- (1+ height) (floor height))))
      (cl-concatenate 'string text indicator-line)))))

(defun topspace--increase-height (total-lines)
  "Increase the top space line height by the target amount of TOTAL-LINES."
  (topspace-set-height (+ (topspace-height) total-lines)))

(defun topspace--decrease-height (total-lines)
  "Decrease the top space line height by the target amount of TOTAL-LINES."
  (topspace-set-height (- (topspace-height) total-lines)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Utilities

(defun topspace--eval-choice (variable-or-function)
  "Evaluate VARIABLE-OR-FUNCTION which is either var or func'n of type var.
If it is a variable, return its value, if it is a function,
evaluate the function and return its return value.
VARIABLE-OR-FUNCTION is most likely a user customizable variable of choice
type."
  (condition-case nil
      (funcall variable-or-function)
    (error variable-or-function)))

(defun topspace--previous-line (&optional arg try-vscroll)
  "Functionally identical to `previous-line' but for non-interactive use.
Use TRY-VSCROLL to control whether to vscroll tall
lines: if either `auto-window-vscroll' or TRY-VSCROLL is nil, this
function will not vscroll.
ARG defaults to 1."
  (or arg (setq arg 1))
  (line-move (- arg) nil nil try-vscroll)
  nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hooks

(defun topspace--window-configuration-change ()
  "Update top spaces when window buffers change or windows are resized."
  (setq topspace--got-first-window-configuration-change t)
  (let ((current-height (window-text-height)) (window (selected-window)))
    (let ((previous-height (alist-get window topspace--previous-window-heights
                                      0.0)))
      (if (and (topspace--eval-choice topspace-autocenter-buffers)
               (not (= previous-height current-height)))
          (topspace-recenter-buffer)
        (topspace-set-height))
      (setf (alist-get window topspace--previous-window-heights)
            current-height))))

(defun topspace--pre-command ()
  "Reduce the amount of code that must execute in `topspace--post-command'."
  (setq-local topspace--pre-command-point (point))
  (setq-local topspace--pre-command-window-start (window-start)))

(defun topspace--post-command ()
  "Reduce top space height before the cursor can move past `window-end'."
  (when (and (= topspace--pre-command-window-start 1)
             (> (point) topspace--pre-command-point))
    (let ((next-line-point))
      (save-excursion
        (goto-char topspace--pre-command-point)
        (vertical-motion 1)
        (beginning-of-visual-line)
        (setq next-line-point (point)))
      (when (and
             ;; These checks are for improving performance by only running
             ;; `topspace--count-lines' run by `topspace--total-lines-past-max'
             ;; when necessary because `topspace--count-lines' is slow
             (>= (point) next-line-point)
             (< (- (line-number-at-pos (point))
                   (line-number-at-pos topspace--pre-command-point))
                (window-text-height)))
        (let ((topspace-height (topspace-height)) (total-lines-past-max))
          (when (> topspace-height 0)
            (setq total-lines-past-max (topspace--total-lines-past-max
                                        topspace-height))
            (when (> total-lines-past-max 0)
              (topspace--decrease-height total-lines-past-max)))))))
  (when (and (= (window-start) 1)
             topspace--got-first-window-configuration-change)
    (topspace-set-height)))

(defvar topspace--hook-alist
  '((window-configuration-change-hook . topspace--window-configuration-change)
    (pre-command-hook . topspace--pre-command)
    (post-command-hook . topspace--post-command))
  "A list of hooks to add/remove in the format (hook-variable . function).")

(defun topspace--add-hooks ()
  "Add hooks defined in `topspace--hook-alist'."
  (dolist (hook-func-pair topspace--hook-alist)
    (add-hook (car hook-func-pair) (cdr hook-func-pair) -90 t)))

(defun topspace--remove-hooks ()
  "Remove hooks defined in `topspace--hook-alist'."
  (dolist (hook-func-pair topspace--hook-alist)
    (remove-hook (car hook-func-pair) (cdr hook-func-pair) t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mode definition and setup

(defun topspace--enable-p ()
  "Return non-nil if buffer is allowed to enable `topspace-mode.'.
Topspace will not be enabled for:
- minibuffers
- ephemeral buffers (See Info node `(elisp)Buffer Names')
- if `topspace-mode' is already enabled"
  (not (or (minibufferp) (string-prefix-p " " (buffer-name)))))

(defun topspace--enable ()
  "Enable `topspace-mode' and do mode setup."
  (when (topspace--enable-p)
    (topspace--add-hooks)
    (unless topspace--advice-added
      (setq topspace--advice-added t)
      (advice-add #'scroll-up :filter-args #'topspace--filter-args-scroll-up)
      (advice-add #'scroll-down :filter-args
                  #'topspace--filter-args-scroll-down)
      (advice-add #'scroll-up :after #'topspace--after-scroll)
      (advice-add #'scroll-down :after #'topspace--after-scroll)
      (advice-add #'recenter :after #'topspace--after-recenter)
      (when (fboundp 'smooth-scroll-lines-above-point)
        (advice-add #'smooth-scroll-lines-above-point
                    :override #'topspace--smooth-scroll-lines-above-point)))
    (dolist (window (get-buffer-window-list))
      (with-selected-window window (topspace-set-height)))))

(defun topspace--disable ()
  "Disable `topspace-mode' and do mode cleanup."
  (remove-overlays 1 1 'topspace--remove-from-buffer-tag t)
  (topspace--remove-hooks))

;;;###autoload
(define-minor-mode topspace-mode
  "Recenter line 1 with scrollable upper margin/padding.

TopSpace lets you display a buffer's first line in the center of a window
instead of just at the top.
This is done by automatically drawing an upper margin/padding above line 1
as you recenter and scroll it down.

See https://github.com/trevorpogue/topspace for a GIF demo & documentation.

Features:

- Easier on the eyes: Recenter or scroll down top text to a more
  comfortable eye level for reading, especially when in full-screen
  or on a large monitor.

- Easy to use: No new keybindings are required, keep using all
  your previous scrolling & recentering commands, except now you
  can also scroll above the top lines.  It also integrates
  seamlessly with `centered-cursor-mode' to keep the cursor
  centered all the way to the top line.

Enabling/disabling:
When called interactively, toggle `topspace-mode'.

With prefix ARG, enable `topspace-mode' if
ARG is positive, otherwise disable it.

When called from Lisp, enable `topspace-mode' if
ARG is omitted, nil or positive.

If ARG is `toggle', toggle `topspace-mode'.
Otherwise behave as if called interactively."
  :init-value nil
  :ligher topspace-mode-line
  :keymap topspace-keymap
  :group 'topspace
  (if topspace-mode (topspace--enable) (topspace--disable)))

;;;###autoload
(define-globalized-minor-mode global-topspace-mode topspace-mode
  topspace-mode
  :group 'topspace)

(defun topspace--enabled ()
  "Return t only if both `topspace-mode' and `topspace-active' are non-nil."
  (and (topspace--eval-choice topspace-active) topspace-mode))

(provide 'topspace)

;;; topspace.el ends here
