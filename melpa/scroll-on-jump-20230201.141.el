;;; scroll-on-jump.el --- Scroll when jumping to a new point -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.com/ideasman42/emacs-scroll-on-jump
;; Package-Version: 20230201.141
;; Package-Commit: 220e4a8f21cc0b430c693a3ecac08156da2602c1
;; Version: 0.2
;; Package-Requires: ((emacs "26.2"))

;;; Commentary:

;; Lets users call any existing function that jumps to another point,
;; adding additional (optional) scrolling functionality.
;;
;; - Re-center after the jump.
;; - Animate the scroll-motion by redrawing.

;;; Usage

;; See readme.rst.
;;

;;; Code:


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup scroll-on-jump nil
  "Configure smooth scrolling when jumping to new locations."
  :group 'scrolling)

(defcustom scroll-on-jump-duration 0.4
  "Duration (in seconds) for scrolling to the next position (zero disables)."
  :type 'float)

(defcustom scroll-on-jump-smooth t
  "Use smooth (pixel) scrolling, otherwise scroll by lines."
  :type 'boolean)

(defcustom scroll-on-jump-curve 'smooth
  "The the method scrolling is calculated."
  :type
  '(choice (const :tag "Smooth in/out, starts & ends slow" smooth)
           (const :tag "Smooth in, starts slow" smooth-in)
           (const :tag "Smooth out, ends slow" smooth-out)
           (const :tag "Linear" linear)))

(defcustom scroll-on-jump-curve-power 3.0
  "The strength of the curve (when set to linear).
A value of 1.0 is linear, values between 2 and 8 work well."
  :type 'float)

(defcustom scroll-on-jump-mode-line-format nil
  "The `mode-line-format' to use or nil to leave the `mode-line-format' unchanged.

This can be useful to use a simplified or event disabling the mode-line
while scrolling, as a complex mode-line can interfere with smooth scrolling."
  :type '(choice (const nil) string))

;; ---------------------------------------------------------------------------
;; Generic Utilities

(defun scroll-on-jump--scroll-by-lines-simple (window lines also-move-point)
  "A simple version of `scroll-on-jump--scroll-by-lines'.

Move LINES in WINDOW, when ALSO-MOVE-POINT is set, the point is moved too."
  (when also-move-point
    (forward-line lines))
  (set-window-start window
                    (save-excursion
                      (goto-char (window-start window))
                      (forward-line lines)
                      (point))
                    t))

;; Per-line Scroll.
;; return remainder of lines to scroll (matching forward-line).
(defun scroll-on-jump--scroll-by-lines (window lines also-move-point)
  "Line based scroll that optionally move the point.
Argument WINDOW The window to scroll.
Argument LINES The number of lines to scroll (signed).
Argument ALSO-MOVE-POINT When non-nil, move the POINT as well."
  (let ((lines-remainder 0))
    (when also-move-point
      (let ((lines-point-remainder (forward-line lines)))
        (unless (zerop lines-point-remainder)
          (setq lines (- lines lines-point-remainder)))))
    (unless (zerop lines)
      (set-window-start window
                        (save-excursion
                          (goto-char (window-start window))
                          (setq lines-remainder (forward-line lines))
                          (point))
                        t)
      (when also-move-point
        (unless (zerop lines-remainder)
          (forward-line (- lines-remainder)))))
    lines-remainder))


;; Per-pixel Scroll,
;; return remainder of lines to scroll (matching forward-line).
(defun scroll-on-jump--scroll-by-pixels (window char-height delta-px also-move-point)
  "Line based scroll that optionally move the point.
Argument WINDOW The window to scroll.
Argument CHAR-HEIGHT The result of `frame-char-height'.
Argument DELTA-PX The number of pixels to scroll (signed).
Argument ALSO-MOVE-POINT When non-nil, move the POINT as well."
  (cond
   ((< delta-px 0)
    (let* ((scroll-px-prev (window-vscroll nil t))
           (scroll-px-next (+ scroll-px-prev delta-px))
           (lines (/ scroll-px-next char-height))
           (scroll-px (- scroll-px-next (* lines char-height)))
           (lines-remainder 0))

      (when (< scroll-px 0)
        (setq lines (1- lines))
        (setq scroll-px (+ char-height scroll-px)))

      (unless (zerop lines)
        (setq lines-remainder (- (scroll-on-jump--scroll-by-lines window lines also-move-point)))
        (unless (zerop lines-remainder)
          (setq scroll-px 0)))
      (set-window-vscroll window scroll-px t)

      (cons lines-remainder lines)))
   ((> delta-px 0)
    (let* ((scroll-px-prev (window-vscroll nil t))
           (scroll-px-next (+ scroll-px-prev delta-px))
           (lines (/ scroll-px-next char-height))
           (scroll-px (- scroll-px-next (* lines char-height)))
           (lines-remainder 0))
      (unless (zerop lines)
        (setq lines-remainder (scroll-on-jump--scroll-by-lines window lines also-move-point))
        (unless (zerop lines-remainder)
          (setq scroll-px char-height)))
      (set-window-vscroll window scroll-px t)
      (cons lines-remainder lines)))
   ;; no lines scrolled.
   (t
    (cons 0 0))))

(defsubst scroll-on-jump--evil-visual-mode-workaround ()
  "Workaround for `evil-mode' line-mode."
  ;; Without this, the line mode point jumps back to the origin,
  ;; the mark needs to be set to the `point'.
  ;; https://github.com/emacs-evil/evil/issues/1708
  (when (and (fboundp 'evil-visual-state-p)
             (funcall #'evil-visual-state-p)
             (fboundp 'evil-visual-type)
             (eq (funcall #'evil-visual-type) 'line)
             (boundp 'evil-visual-point))
    (let ((mark (symbol-value 'evil-visual-point)))
      (when (markerp mark)
        (set-marker mark (point))))))


;; ---------------------------------------------------------------------------
;; Internal Interpolation Functions

(defsubst scroll-on-jump--interp-linear-impl (a b factor)
  "Internal macro for to blend A, B by FACTOR."
  (+ a (* (- b a) factor)))

(defun scroll-on-jump--interp-linear (a b factor)
  "Blend FACTOR between A and B using linear curvature."
  (scroll-on-jump--interp-linear-impl a b factor))

(defun scroll-on-jump--interp-ease-in (a b factor)
  "Blend FACTOR between A and B using ease-in curvature."
  (scroll-on-jump--interp-linear-impl a b (expt factor scroll-on-jump-curve-power)))

(defun scroll-on-jump--interp-ease-out (a b factor)
  "Blend FACTOR between A and B using ease-in curvature."
  (scroll-on-jump--interp-linear-impl
   a b (- 1.0 (expt (- 1.0 factor) scroll-on-jump-curve-power))))

(defun scroll-on-jump--interp-ease-in-out (a b factor)
  "Blend FACTOR between A and B using ease-in-out curvature."
  (cond
   ((< factor 0.5)
    (let ((f (* (expt (* factor 2.0) scroll-on-jump-curve-power) 0.5)))
      (scroll-on-jump--interp-linear-impl a b f)))
   (t
    (let ((f (- 1.0 (* (expt (* (- 1.0 factor) 2.0) scroll-on-jump-curve-power) 0.5))))
      (scroll-on-jump--interp-linear-impl a b f)))))

(defun scroll-on-jump--interp-fn-get (curve)
  "Return the interpolation function associated with CURVE."
  (cond
   ((<= scroll-on-jump-curve-power 1.0)
    ;; A curve of 1.0 is linear by definition,
    ;; also catches users entering in bad values (negative numbers for e.g.)
    ;; that will only cause problems.
    #'scroll-on-jump--interp-linear)
   (t
    (pcase curve
      ('linear #'scroll-on-jump--interp-linear)
      ('smooth #'scroll-on-jump--interp-ease-in-out)
      ('smooth-in #'scroll-on-jump--interp-ease-in)
      ('smooth-out #'scroll-on-jump--interp-ease-out)
      (_
       (message "Unknown curve (%S), using linear" curve)
       ;; Fall back to linear (as good an option as any).
       #'scroll-on-jump--interp-linear)))))


;; ---------------------------------------------------------------------------
;; Internal Logic

(defun scroll-on-jump--immediate-scroll (window lines-scroll _dir)
  "Non animated scroll for WINDOW to move LINES-SCROLL."
  (scroll-on-jump--scroll-by-lines-simple window lines-scroll nil))

(defun scroll-on-jump--animated-scroll-by-line (window lines-scroll dir also-move-point)
  "Animated scroll WINDOW LINES-SCROLL lines along DIR direction.
Moving the point when ALSO-MOVE-POINT is set."
  (let ((time-init (current-time))
        ;; For motion less than a window, scale down the time allowed.
        ;; This means moving a short distance wont be given the full time.
        (time-limit
         (* scroll-on-jump-duration
            (min 1.0 (/ (float (abs lines-scroll)) (float (window-body-height window))))))
        (interp-fn (scroll-on-jump--interp-fn-get scroll-on-jump-curve))
        ;; FIXME: for some reason a short sleep is needed to prevent choppy scrolling.
        (use-pgtk-workaround (eq (window-system) 'pgtk)))

    ;; Animated scrolling (early exit on input to avoid annoying lag).
    (cond
     ((not (zerop lines-scroll))
      (let ((is-early-exit t)
            (inhibit-point-motion-hooks t)
            (lines-done-abs 0)
            (lines-scroll-abs (abs lines-scroll)))
        (while-no-input
          (while (< lines-done-abs lines-scroll-abs)
            ;; Inhibit quit in all of this logic except re-display.
            (let ((inhibit-quit t)
                  ;; Number of lines to move for this redraw.
                  (step
                   (let* ((time-elapsed (float-time (time-subtract (current-time) time-init)))
                          (factor (min 1.0 (/ time-elapsed time-limit)))
                          (lines-target (floor (funcall interp-fn 0.0 lines-scroll-abs factor)))
                          (lines-remainder (- lines-target lines-done-abs)))
                     ;; Step result, we must move at least one line.
                     (* dir (max 1 lines-remainder)))))

              ;; Check if this is the last step.
              (setq lines-done-abs (+ lines-done-abs (abs step)))
              (when (> lines-done-abs lines-scroll-abs)
                (setq step (- step (* dir (- lines-done-abs lines-scroll-abs)))))

              ;; Faster alternative to scroll.
              (scroll-on-jump--scroll-by-lines-simple window step nil)

              (when also-move-point
                (forward-line step))

              (setq lines-scroll (- lines-scroll step)))

            ;; Skip the last redraw, so there isn't 2x update when
            ;; the caller moves the point to the final location.
            (when (< lines-done-abs lines-scroll-abs)
              ;; Force `redisplay', without this redrawing can be a little choppy.
              (redisplay t)
              (when use-pgtk-workaround
                (sit-for 0.01))))
          (setq is-early-exit nil))

        ;; Re-enable when editing logic.
        (when (and (null is-early-exit) (not (zerop lines-scroll)))
          (error "Internal error, 'lines-scroll' should be zero"))

        ;; If we exit early because of input.
        (when is-early-exit
          (scroll-on-jump--scroll-by-lines-simple window lines-scroll nil))))

     ;; Non-animated scrolling (immediate).
     (t
      (scroll-on-jump--scroll-by-lines-simple window lines-scroll nil))))

  (run-window-scroll-functions window))

(defun scroll-on-jump--animated-scroll-by-px (window lines-scroll dir also-move-point)
  "Animated scroll WINDOW LINES-SCROLL lines along DIR direction.
Argument ALSO-MOVE-POINT moves the point while scrolling."
  (let ((time-init (current-time))
        ;; For motion less than a window, scale down the time allowed.
        ;; This means moving a short distance wont be given the full time.
        (time-limit
         (* scroll-on-jump-duration
            (min 1.0 (/ (float (abs lines-scroll)) (float (window-body-height window))))))
        (interp-fn (scroll-on-jump--interp-fn-get scroll-on-jump-curve))
        (char-height (frame-char-height (window-frame window)))
        ;; FIXME: for some reason a short sleep is needed to prevent choppy scrolling.
        (use-pgtk-workaround (eq (window-system) 'pgtk)))

    ;; Animated scrolling (early exit on input to avoid annoying lag).
    (cond
     ((not (zerop lines-scroll))
      (let ((is-early-exit t)
            (inhibit-point-motion-hooks t)
            (px-done-abs 0)
            (px-scroll-abs (abs (* lines-scroll char-height)))
            (px-scroll (* lines-scroll char-height)))

        ;; Workaround for situations when the `point' starts at the window bounds.
        ;; If this happens we can't do any sub-pixel scrolling as the `point' locks scrolling.
        ;; This is only needed for pixel level scrolling.
        ;;
        ;; We can move arbitrary lines here since the final point is set at the very end.
        (when also-move-point
          (forward-line dir))

        (while-no-input
          (while (< px-done-abs px-scroll-abs)
            ;; Inhibit quit in all of this logic except re-display.
            (let ((inhibit-quit t)
                  ;; Number of pixels to move for this redraw.
                  (step
                   (let* ((time-elapsed (float-time (time-subtract (current-time) time-init)))
                          (factor (min 1.0 (/ time-elapsed time-limit)))
                          (px-target (floor (funcall interp-fn 0.0 px-scroll-abs factor)))
                          (px-remainder (- px-target px-done-abs)))
                     (* dir px-remainder))))

              ;; Check if this is the last step.
              (setq px-done-abs (+ px-done-abs (abs step)))
              (when (> px-done-abs px-scroll-abs)
                (setq step (- step (* dir (- px-done-abs px-scroll-abs)))))

              (pcase-let ((`(,_lines-remainder . ,lines-handled)
                           (scroll-on-jump--scroll-by-pixels window char-height step nil)))

                ;; Forward lines separately since we might be at end of the buffer
                ;; and we want to be able to scroll - even if the point has reached it's limit.
                (when also-move-point
                  (forward-line lines-handled))

                (setq lines-scroll (- lines-scroll lines-handled)))

              (setq px-scroll (- px-scroll step)))

            ;; Skip the last redraw, so there isn't 2x update when
            ;; the caller moves the point to the final location.
            (when (< px-done-abs px-scroll-abs)
              ;; Force `redisplay', without this redrawing can be a little choppy.
              (redisplay t)
              (when use-pgtk-workaround
                (sit-for 0.01))))
          (setq is-early-exit nil))

        (cond
         ;; If we exit early because of input.
         (is-early-exit
          ;; Early exit, reset pixel scroll and scroll lines.
          (set-window-vscroll window 0 t)
          (scroll-on-jump--scroll-by-lines-simple window lines-scroll nil))

         ;; Sanity check, if this fails there is an issue with internal logic.
         ((not (zerop px-scroll))
          (set-window-vscroll window 0 t)
          (error "Internal error, 'px-scroll' should be zero"))

         ;; Also should never happen.
         ((not (zerop (window-vscroll window t)))
          (set-window-vscroll window 0 t)
          (message "Warning, sub-pixel scroll left set!")))))

     ;; Non-animated scrolling (immediate).
     (t
      (scroll-on-jump--scroll-by-lines-simple window lines-scroll nil))))

  (run-window-scroll-functions window))

(defun scroll-on-jump--scroll-animated (window lines-scroll dir also-move-point)
  "Perform an animated scroll.
see `scroll-on-jump--scroll-impl' for doc-strings for WINDOW, LINES-SCROLL, DIR & ALSO-MOVE-POINT."
  (cond
   ;; Use pixel scrolling.
   ;;
   ;; NOTE: only pixel scroll >1 lines so actions that move the cursor up/down one
   ;; don't attempt to smooth scroll.
   ;; While this works without problems, it does cause a flicker redrawing the point.
   ;; Harmless but seems like a glitch if `scroll-on-jump' is being applied to
   ;; `next-line' or `previous-line'.
   ;; So it's simplest not to use smooth scroll in this particular case.
   ((and scroll-on-jump-smooth (display-graphic-p) (> (abs lines-scroll) 1))
    (scroll-on-jump--animated-scroll-by-px window lines-scroll dir also-move-point))
   ;; Use line scrolling.
   (t
    (scroll-on-jump--animated-scroll-by-line window lines-scroll dir also-move-point))))

(defun scroll-on-jump--scroll-impl (window lines-scroll dir also-move-point)
  "Scroll WINDOW LINES-SCROLL lines along DIR direction.
Moving the point when ALSO-MOVE-POINT is set."
  (cond
   ;; No animation.
   ((zerop scroll-on-jump-duration)
    (scroll-on-jump--immediate-scroll window lines-scroll dir))
   ;; Animated scroll.
   (scroll-on-jump-mode-line-format
    (prog1 (let ((mode-line-format scroll-on-jump-mode-line-format))
             (scroll-on-jump--scroll-animated window lines-scroll dir also-move-point))
      (force-mode-line-update)))
   (t
    (scroll-on-jump--scroll-animated window lines-scroll dir also-move-point))))

(defun scroll-on-jump-auto-center (window point-prev point-next)
  "Re-frame WINDOW from POINT-PREV to POINT-NEXT, optionally animating."
  ;; Count lines, excluding the current line.
  (let ((lines (1- (count-screen-lines point-prev point-next t window))))
    (when (> lines 0)
      (let ((height (window-body-height window))
            (lines-scroll 0)
            (dir
             (cond
              ((< point-prev point-next)
               1)
              (t
               -1))))

        (cond
         ((eq dir 1)
          (let* ((window-lines-prev (count-screen-lines (window-start window) point-prev t window))
                 (window-lines-next (+ window-lines-prev lines))
                 (lines-limit (max (/ height 2) window-lines-prev)))
            (when (>= window-lines-next lines-limit)
              (setq lines-scroll (- window-lines-next lines-limit))
              ;; Clamp lines-scroll by the window end
              ;; Only needed when scrolling down.
              ;;
              ;; Do this so we don't scroll past the end.
              (setq lines-scroll
                    (- lines-scroll
                       (save-excursion
                         (goto-char (window-end))
                         (forward-line lines-scroll)))))))
         (t
          ;; Note that we can't use `window-end' here as we may
          ;; be scrolled past the screen end-point.
          (let* ((window-lines-prev
                  (- height (count-screen-lines (window-start window) point-prev t window)))
                 (window-lines-next (+ window-lines-prev lines))
                 (lines-limit (max (/ height 2) window-lines-prev)))
            (when (>= window-lines-next lines-limit)
              (setq lines-scroll (- lines-limit window-lines-next))
              ;; Clamp lines-scroll by the window start
              ;; Only needed when scrolling up.
              ;;
              ;; Even though scroll can't scroll past the start,
              ;; we don't want to try to animate scrolling up in this case.
              (setq lines-scroll
                    (- lines-scroll
                       (save-excursion
                         (goto-char (window-start window))
                         (forward-line lines-scroll))))))))

        (let ((also-move-point (not (eq (point) point-next))))
          (scroll-on-jump--scroll-impl window lines-scroll dir also-move-point)))))

  (goto-char point-next))

;; We cannot store the point before running BODY because
;; that point may be invalid (outside point-min / point-max for e.g)
;; after BODY is complete.
;; Use `save-excursion' & `prog1' so the point's can be retrieved relative
;; to the modified buffers state.
;; We could use markers but properly clearing them for garbage-collection
;; would involve error handling (see note below).
(defmacro scroll-on-jump--outer-scoped-mark (point-init point-out &rest body)
  "Set POINT-INIT and store its value in POINT-OUT outside the scope of BODY."
  (declare (indent 2))
  `(prog1 (save-excursion
            (goto-char ,point-init)
            ,@body)
     (setq ,point-out (point))))

(defmacro scroll-on-jump--inner-scoped-mark (point-init point-out &rest body)
  "Set POINT-INIT and store its value in POINT-OUT in the scope of BODY."
  (declare (indent 2))
  `(save-excursion
     (prog1 (progn
              (goto-char ,point-init)
              ,@body)
       (setq ,point-out (point)))))

(defmacro scroll-on-jump--impl (use-window-start &rest body)
  "Main macro that wraps BODY in logic that reacts to change in `point'.
Argument USE-WINDOW-START detects window scrolling when non-nil."
  (declare (indent 1))
  `(let ((buf (current-buffer)) ; Set in case we have an error.
         (window (selected-window))

         (point-prev nil)
         (point-next nil)

         (window-start-prev nil)
         (window-start-next nil))

     (prog1 (let ((point-orig (point))
                  ;; Postpone point-motion-hooks until later.
                  (inhibit-point-motion-hooks t))
              ;; Note, we could catch and re-raise errors,
              ;; this has the advantage that we could get the resulting cursor location
              ;; even in the case of an error.
              ;; However - this makes troubleshooting problems considerably more difficult.
              ;; As it wont show the full back-trace, only the error message.
              ;; So don't prioritize correct jumping in the case of errors and assume errors
              ;; are not something that happen after cursor motion.
              (scroll-on-jump--outer-scoped-mark point-orig point-prev
                (scroll-on-jump--inner-scoped-mark (window-start window) window-start-prev
                  (scroll-on-jump--inner-scoped-mark point-orig point-next
                    ;; Run the main body of this macro.
                    ;; It's important the result if returned (hence the `prog1' use).
                    ,@body))))


       (cond
        ;; Context changed or recursed, simply jump.
        ((not
          ;; Check if the buffer/context changed.
          (and (eq buf (window-buffer window))
               (eq buf (current-buffer))
               (eq window (selected-window))))

         (goto-char point-next))

        (t ; Perform animated scroll.

         ;; It's possible the requested `point-next' exceeds the maximum point.
         ;; This causes an error counting lines and calculating offsets,
         ;; so clamp it here to avoid complications later.
         (setq point-next (min point-next (point-max)))

         (cond
          (,use-window-start
           (setq window-start-next (window-start window))
           (unless (eq window-start-prev window-start-next)
             (set-window-start window window-start-prev)
             (let ((lines-scroll
                    (1- (count-screen-lines window-start-prev window-start-next t window)))
                   (dir
                    (cond
                     ((< window-start-prev window-start-next)
                      1)
                     (t
                      -1)))
                   (also-move-point (not (eq (point) point-next))))
               (scroll-on-jump--scroll-impl window (* dir lines-scroll) dir also-move-point)))
           (prog1 (goto-char point-next)
             (redisplay t)))
          (t
           (scroll-on-jump-auto-center window point-prev point-next)))

         (scroll-on-jump--evil-visual-mode-workaround))))))


;; ---------------------------------------------------------------------------
;; Public Functions

;; ----------------
;; Default Behavior
;;
;; Use for wrapping functions that set the point.

;;;###autoload
(defmacro scroll-on-jump (&rest body)
  "Main macro that wraps BODY in logic that reacts to change in `point'."
  (declare (indent 0))
  `(scroll-on-jump--impl nil
     ,@body))

;;;###autoload
(defmacro scroll-on-jump-interactive (fn)
  "Macro that wraps interactive call to function FN.

Use if you want to use `scroll-on-jump' for a single `key-binding',
without changing behavior anywhere else."
  `(lambda ()
     (interactive)
     (scroll-on-jump
       (call-interactively ,fn))))

;; Helper function (not public).
(defun scroll-on-jump-advice--wrapper (old-fn &rest args)
  "Internal function use to advise using `scroll-on-jump-advice-add'.

This calls (calling OLD-FN with ARGS)."
  (scroll-on-jump
    (apply old-fn args)))

;;;###autoload
(defmacro scroll-on-jump-advice-add (fn)
  "Add advice to FN, to instrument it with scrolling capabilities."
  (advice-add fn :around #'scroll-on-jump-advice--wrapper))

;;;###autoload
(defmacro scroll-on-jump-advice-remove (fn)
  "Remove advice on FN added by `scroll-on-jump-advice-add'."
  (advice-remove fn #'scroll-on-jump-advice--wrapper))

;; -----------
;; With-Scroll
;;
;; Use when wrapping actions that themselves scroll.

;;;###autoload
(defmacro scroll-on-jump-with-scroll (&rest body)
  "Main macro wrapping BODY, handling change `point' and vertical scroll."
  (declare (indent 0))
  `(scroll-on-jump--impl t
     ,@body))

;;;###autoload
(defmacro scroll-on-jump-with-scroll-interactive (fn)
  "Macro that wraps interactive call to function FN.

Use if you want to use `scroll-on-jump-with-scroll' for a single `key-binding',
without changing behavior anywhere else."
  `(lambda ()
     (interactive)
     (scroll-on-jump-with-scroll
       (call-interactively ,fn))))

;; Helper function (not public).
(defun scroll-on-jump-advice--with-scroll-wrapper (old-fn &rest args)
  "Internal function use to advise using `scroll-on-jump-advice-add'.

This calls OLD-FN with ARGS."
  (scroll-on-jump-with-scroll
    (apply old-fn args)))

;;;###autoload
(defmacro scroll-on-jump-with-scroll-advice-remove (fn)
  "Remove advice on FN added by `scroll-on-jump-with-scroll-advice-add'."
  (advice-remove fn #'scroll-on-jump-advice--with-scroll-wrapper))

;;;###autoload
(defmacro scroll-on-jump-with-scroll-advice-add (fn)
  "Add advice to FN, to instrument it with scrolling capabilities."
  (advice-add fn :around #'scroll-on-jump-advice--with-scroll-wrapper))

(provide 'scroll-on-jump)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; elisp-autofmt-format-quoted: nil
;; End:
;;; scroll-on-jump.el ends here
