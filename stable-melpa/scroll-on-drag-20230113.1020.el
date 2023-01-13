;;; scroll-on-drag.el --- Interactive scrolling -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2019  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-scroll-on-drag
;; Package-Version: 20230113.1020
;; Package-Commit: cf026998a81097a372f1af3ca48eeb6e7d658951
;; Version: 0.1
;; Package-Requires: ((emacs "26.2"))

;;; Commentary:

;; Interactive scrolling which can be canceled by pressing escape.

;;; Usage

;; (scroll-on-drag) ; Interactively scroll the current buffer
;;

;;; Code:

;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup scroll-on-drag nil
  "Configure smooth scrolling on drag."
  :group 'scrolling)

(defcustom scroll-on-drag-style 'line-by-pixel
  "The the method scrolling is calculated."
  :type '(choice (const :tag "Line" line) (const :tag "Line-By-Pixel" line-by-pixel)))

(defcustom scroll-on-drag-delay 0.01
  "Idle time between scroll updates (in seconds)."
  :type 'float)

(defcustom scroll-on-drag-motion-scale 0.25
  "Scroll speed multiplier."
  :type 'float)

(defcustom scroll-on-drag-motion-accelerate 0.3
  "Non-linear scroll power (0.0 for linear speed, 1.0 for very fast acceleration)."
  :type 'float)

(defcustom scroll-on-drag-smooth t
  "Use smooth (pixel) scrolling."
  :type 'boolean)

(defcustom scroll-on-drag-clamp nil
  "Prevent scrolling past the buffer end."
  :type 'boolean)

(defcustom scroll-on-drag-follow-mouse t
  "Scroll the window under the mouse cursor (instead of the current active window)."
  :type 'boolean)

(defcustom scroll-on-drag-pre-hook nil
  "List of functions to be called when `scroll-on-drag' starts."
  :type 'hook)

(defcustom scroll-on-drag-post-hook nil
  "List of functions to be called when `scroll-on-drag' finishes."
  :type 'hook)

(defcustom scroll-on-drag-redisplay-hook nil
  "List of functions to run on scroll redraw."
  :type 'hook)


;; ---------------------------------------------------------------------------
;; Internal Functions

;; Generic scrolling functions.
;;
;; It would be nice if this were part of a more general library.
;; Optionally also move the point is needed because _not_ doing this
;; makes the window constraint so the point stays within it.

;; Per-line Scroll.
;; return remainder of lines to scroll (matching forward-line).
(defun scroll-on-drag--scroll-by-lines (window lines also-move-point)
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
                          (goto-char (window-start))
                          (setq lines-remainder (forward-line lines))
                          (point))
                        t)
      (when also-move-point
        (unless (zerop lines-remainder)
          (forward-line (- lines-remainder)))))
    lines-remainder))

;; Per-pixel Scroll,
;; return remainder of lines to scroll (matching forward-line).
(defun scroll-on-drag--scroll-by-pixels (window char-height delta-px also-move-point)
  "Line based scroll that optionally move the point.
Argument WINDOW The window to scroll.
Argument CHAR-HEIGHT The result of `frame-char-height'.
Argument DELTA-PX The number of pixels to scroll (signed).
Argument ALSO-MOVE-POINT When non-nil, move the POINT as well."
  (cond
   ((< delta-px 0)
    (let* ((scroll-px-prev (- char-height (window-vscroll nil t))) ; flip.
           (scroll-px-next (+ scroll-px-prev (- delta-px))) ; flip.
           (lines (/ scroll-px-next char-height))
           (scroll-px (- scroll-px-next (* lines char-height)))
           (lines-remainder 0))
      (unless (zerop lines)
        ;; flip
        (setq lines-remainder
              (- (scroll-on-drag--scroll-by-lines window (- lines) also-move-point)))
        (unless (zerop lines-remainder)
          (setq scroll-px char-height)))
      (set-window-vscroll window (- char-height scroll-px) t)
      (- lines-remainder)))
   ((> delta-px 0)
    (let* ((scroll-px-prev (window-vscroll nil t))
           (scroll-px-next (+ scroll-px-prev delta-px))
           (lines (/ scroll-px-next char-height))
           (scroll-px (- scroll-px-next (* lines char-height)))
           (lines-remainder 0))
      (unless (zerop lines)
        (setq lines-remainder (scroll-on-drag--scroll-by-lines window lines also-move-point))
        (unless (zerop lines-remainder)
          (setq scroll-px char-height)))
      (set-window-vscroll window scroll-px t)
      lines-remainder))
   ;; no lines scrolled.
   (t
    0)))

;; End generic scrolling functions.

(defsubst scroll-on-drag--force-redisplay-with-hooks ()
  "Wrapper for `redisplay' to ignore `inhibit-redisplay'."
  (let ((inhibit-redisplay nil))
    (run-hooks 'scroll-on-drag-redisplay-hook)
    (redisplay)))

(defun scroll-on-drag--evil-visual-line-data ()
  "Return data associated with visual line mode or nil when none is found."
  ;; The checks are written so as not to require evil mode as a dependency.
  (when (and (fboundp 'evil-visual-state-p)
             (funcall #'evil-visual-state-p)
             (fboundp 'evil-visual-type)
             (eq (funcall #'evil-visual-type) 'line)
             (boundp 'evil-visual-point))
    (let ((mark (symbol-value 'evil-visual-point)))
      (when (markerp mark)
        mark))))

(defmacro scroll-on-drag--with-evil-visual-mode-hack (visual-line-data &rest body)
  "Execute BODY without evil-visual-mode line constraints.
Run when MARK is non-nil.
VISUAL-LINE-DATA is the result of `scroll-on-drag--evil-visual-line-data'."
  (declare (indent 1))
  `(unwind-protect
       (progn
         (goto-char (marker-position ,visual-line-data))
         ,@body)
     (set-marker ,visual-line-data (point))))


;; ---------------------------------------------------------------------------
;; Public Functions

(defun scroll-on-drag--impl ()
  "Interactively scroll (typically on click event).
Returns true when scrolling took place, otherwise nil."
  (let* ((scroll-timer nil)

         ; Don't run unnecessary logic when scrolling.
         (inhibit-point-motion-hooks t)
         ;; Only draw explicitly once all actions have been done.
         (inhibit-redisplay t)

         ;; Variables for re-use.
         (this-window (selected-window))
         (this-frame-char-height (frame-char-height))
         (this-frame-char-height-as-float (float this-frame-char-height))

         ;; Reset's when pressing Escape.
         (has-scrolled nil)
         ;; Doesn't reset (so we can detect clicks).
         (has-scrolled-real nil)

         ;; Cursor offset.
         (delta 0)
         (delta-prev 0)

         ;; Only for 'line-by-pixel' style.
         (delta-px-accum 0)

         ;; Restoration position.
         (restore-window-start (window-start))
         (restore-point (point))

         ;; Don't move past the buffer end.
         (point-clamp-max
          (cond
           (scroll-on-drag-clamp
            (cond
             ((eq (window-end) (point-max))
              (pos-bol))
             (t
              (save-excursion
                (goto-char (pos-bol))
                (let ((lines
                       (- (window-body-height)
                          ;; When the point is at the window top,
                          ;; account for it being clamped while scrolling.
                          (1+ (max scroll-margin
                                   (count-lines restore-window-start restore-point))))))
                  (goto-char (point-max))
                  (forward-line (- lines))
                  (point))))))
           (t
            nil)))

         ;; Restore indent (lost when scrolling).
         (restore-column (current-column))

         (mouse-y-fn
          (cond
           ((eq scroll-on-drag-style 'line)
            (lambda () (cdr (cdr (mouse-position)))))
           (t
            (lambda () (cdr (cdr (mouse-pixel-position)))))))

         ;; Reference to compare all mouse motion to.
         (y-init (funcall mouse-y-fn))

         (point-of-last-line
          (cond
           (scroll-on-drag-smooth
            (save-excursion
              (goto-char (point-max))
              (pos-bol)))
           (t
            0)))

         (mouse-y-delta-scale-fn
          ;; '(f * motion-scale) ^ power', then truncate to int.
          (lambda (delta)
            (let* ((f (/ (float delta) this-frame-char-height-as-float))
                   (f-abs (abs f)))
              (truncate
               (copysign
                ;; Clamp so converting to int won't fail.
                (min 1e+18
                     (* (expt
                         (* f-abs scroll-on-drag-motion-scale)
                         (+ 1.0 (* f-abs scroll-on-drag-motion-accelerate)))
                        this-frame-char-height-as-float))
                f)))))

         ;; Calls 'timer-update-fn'.
         (timer-start-fn
          (lambda (timer-update-fn)
            (setq scroll-timer
                  (run-with-timer
                   scroll-on-drag-delay nil
                   (lambda () (funcall timer-update-fn timer-update-fn))))))

         ;; Stops calling 'timer-update-fn'.
         (timer-stop-fn
          (lambda ()
            (when scroll-timer
              (cancel-timer scroll-timer)
              (setq scroll-timer nil))))

         (timer-update-fn
          (cond

           ((eq scroll-on-drag-style 'line)
            ;; -------------
            ;; Style: "line"

            (lambda (self-fn)
              (let ((lines delta))
                (unless (zerop lines)
                  (setq delta-px-accum (- delta-px-accum (* lines this-frame-char-height)))
                  (let ((lines-remainder (scroll-on-drag--scroll-by-lines this-window lines t)))
                    (unless (zerop (- lines lines-remainder))
                      (scroll-on-drag--force-redisplay-with-hooks)))))
              (funcall timer-start-fn self-fn)))

           ((eq scroll-on-drag-style 'line-by-pixel)
            ;; ----------------------
            ;; Style: "line-by-pixel"

            (lambda (self-fn)
              (let ((do-draw nil)
                    (delta-scaled (funcall mouse-y-delta-scale-fn delta)))

                (cond
                 ;; Smooth-Scrolling.
                 (scroll-on-drag-smooth
                  (scroll-on-drag--scroll-by-pixels
                   this-window
                   this-frame-char-height
                   delta-scaled
                   t)
                  (when (>= (point) point-of-last-line)
                    (set-window-vscroll this-window 0 t))
                  (setq do-draw t))

                 ;; Non-Smooth-Scrolling (snap to lines).
                 ;; Basically same logic as above, but only step over lines.
                 (t
                  (setq delta-px-accum (+ delta-scaled delta-px-accum))
                  (let ((lines (/ delta-px-accum this-frame-char-height)))

                    (unless (zerop lines)
                      (setq delta-px-accum (- delta-px-accum (* lines this-frame-char-height)))
                      (scroll-on-drag--scroll-by-lines this-window lines t)
                      (setq do-draw t)))))

                ;; Clamp the buffer inside the window.
                (when point-clamp-max
                  ;; Scrolling down.
                  (when (< 0 delta)
                    (let ((scroll-pt
                           (cond
                            ((eq restore-point (point))
                             (pos-bol))
                            (t
                             (point)))))
                      (cond
                       ((= point-clamp-max scroll-pt)
                        (set-window-vscroll this-window 0 t))

                       ((< point-clamp-max scroll-pt)
                        (let ((lines (count-lines scroll-pt point-clamp-max)))
                          (set-window-vscroll this-window 0 t)
                          (scroll-on-drag--scroll-by-lines this-window (- lines) t)))))))

                (when do-draw
                  (scroll-on-drag--force-redisplay-with-hooks)))
              (funcall timer-start-fn self-fn)))))

         ;; Apply pixel offset and snap to a line.
         (scroll-snap-smooth-to-line-fn
          (lambda ()
            (when scroll-on-drag-smooth
              (when (> (window-vscroll this-window t) (/ this-frame-char-height 2))
                (scroll-on-drag--scroll-by-lines this-window 1 nil))
              (set-window-vscroll this-window 0 t)
              (setq delta-px-accum 0)
              (scroll-on-drag--force-redisplay-with-hooks))))

         (scroll-reset-fn
          (lambda ()
            (funcall timer-stop-fn)
            (funcall scroll-snap-smooth-to-line-fn)
            (setq delta-prev 0)
            (setq y-init (funcall mouse-y-fn))))

         (scroll-restore-fn
          (lambda ()
            (goto-char restore-point)
            (set-window-start this-window restore-window-start t)))

         ;; Workaround for bad pixel scrolling performance
         ;; when the cursor is partially outside the view.
         (scroll-consrtain-point-below-window-start-fn
          (lambda ()
            (let ((lines-from-top (count-lines (window-start) (pos-bol))))
              (when (> scroll-margin lines-from-top)
                (forward-line (- scroll-margin lines-from-top))
                (scroll-on-drag--force-redisplay-with-hooks))))))

    ;; ---------------
    ;; Main Event Loop

    (track-mouse
      (while (let ((event (read-event)))
               (cond
                ;; Escape restores initial state, restarts scrolling.
                ((eq event 'escape)
                 (setq has-scrolled nil)
                 (funcall scroll-reset-fn)
                 (funcall scroll-restore-fn)
                 (scroll-on-drag--force-redisplay-with-hooks)
                 t)

                ;; Space keeps current position, restarts scrolling.
                ((eq event ?\s)
                 (funcall scroll-reset-fn)
                 t)
                ((mouse-movement-p event)
                 (setq delta (- (funcall mouse-y-fn) y-init))
                 (cond
                  ((zerop delta)
                   (funcall timer-stop-fn))
                  (t
                   (when (zerop delta-prev)
                     (unless has-scrolled
                       ;; Clamp point to scroll bounds on first scroll,
                       ;; allow pressing 'Esc' to use unclamped position.
                       (when scroll-on-drag-smooth
                         (funcall scroll-consrtain-point-below-window-start-fn))
                       (setq has-scrolled t))
                     (unless has-scrolled-real
                       (let ((inhibit-redisplay nil))
                         (run-hooks 'scroll-on-drag-pre-hook)))
                     (setq has-scrolled-real t)
                     (funcall timer-stop-fn)
                     (funcall timer-update-fn timer-update-fn))))

                 (setq delta-prev delta)
                 t)
                ;; Cancel...
                (t
                 nil)))))

    (funcall scroll-snap-smooth-to-line-fn)
    (funcall timer-stop-fn)

    ;; Restore state (the point may have been moved by constraining to the scroll margin).
    (when (eq restore-window-start (window-start))
      (funcall scroll-restore-fn)
      (setq has-scrolled nil))

    ;; Restore indent level if possible.
    (when (and has-scrolled (> restore-column 0))
      (move-to-column restore-column))

    (when has-scrolled-real
      (let ((inhibit-redisplay nil))
        (run-hooks 'scroll-on-drag-post-hook)
        (run-window-scroll-functions this-window)))

    has-scrolled-real))

(defun scroll-on-drag--impl-with-evil-mode-workaround ()
  "Workaround for evil mode visual line selection.
This requires a separate code path to run pre/post logic."
  (let ((visual-line-data (scroll-on-drag--evil-visual-line-data)))
    (cond
     (visual-line-data
      (let ((result nil)
            (result-point nil))
        (save-excursion
          (scroll-on-drag--with-evil-visual-mode-hack visual-line-data
            (when (setq result (scroll-on-drag--impl))
              (setq result-point (point)))))
        (when result
          (goto-char result-point))
        result))
     (t
      (scroll-on-drag--impl)))))

(defun scroll-on-drag--impl-with-window (scroll-win)
  "Scroll on drag function that takes an optional SCROLL-WIN."
  (cond
   (scroll-win
    (with-selected-window scroll-win
      (scroll-on-drag--impl-with-evil-mode-workaround)))
   (t
    (scroll-on-drag--impl-with-evil-mode-workaround))))

(defun scroll-on-drag (&optional event)
  "Main scroll on drag function.

EVENT is optionally used to find the active window
when `scroll-on-drag-follow-mouse' is non-nil."
  (interactive "e")
  (let ((scroll-win nil))
    (when scroll-on-drag-follow-mouse
      (setq scroll-win (posn-window (or (event-start event) last-input-event))))

    (scroll-on-drag--impl-with-window scroll-win)))


;;;###autoload
(defmacro scroll-on-drag-with-fallback (&rest body)
  "A macro to scroll and perform a different action on click.
Optional argument BODY Hello."
  `(lambda ()
     (interactive)
     (unless (scroll-on-drag)
       ,@body)))

(provide 'scroll-on-drag)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; scroll-on-drag.el ends here
