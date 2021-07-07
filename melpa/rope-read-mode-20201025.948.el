;;; rope-read-mode.el --- Rearrange lines to read text smoothly -*- lexical-binding: t -*-

;; THIS FILE HAS BEEN GENERATED.



;; Copyright 2015-2019 Marco Wahl
;; 
;; Author: Marco Wahl <marcowahlsoft@gmail.com>
;; Maintainer: Marco Wahl <marcowahlsoft@gmail.com>
;; Created: 4 Jan 2015
;; Version: 0.4.3
;; Package-Version: 20201025.948
;; Package-Commit: 6f024d9409ba454b83a2a1ccd57d9a3ebba90a39
;; Keywords: reading, convenience, chill
;; URL: https://gitlab.com/marcowahl/rope-read-mode
;; Package-Requires: ((emacs "24"))
;; 
;; This file is not part of Emacs.
;; 
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; =rope-read-mode= can reverse every other line of a buffer or in a part
;; of a buffer.  With every other line reversed reading can be like
;; following a rope.

;; Turning it on and off
;; ---------------------

;; =M-x rope-read-mode= in a buffer activates rope-read.  No visible
;; change in the buffer is to be expected.  The buffer is set read-only.

;; Type =M-x rope-read-mode= or press 'q' to quit rope-read.  The buffer
;; writability gets restored.

;; Action
;; ------

;; When =rope-read-mode= is on you can press
;; - =C-g= to interrupt =rope-read-mode= anytime
;; - =q= to quit =rope-read-mode=
;; - =?= to open the help buffer
;; - =r= /redraw standard/ to go back to the representation of the buffer
;;   without reversed lines (keeping =rope-read-mode=)
;; - =p= /paragraph/ to reverse every other line starting with the line
;;   below the cursor up to the end of the paragraph (if visible) and
;;   move point there
;; - The next four commands are each followed by reversing every other
;;   line in the visible part.  The keys are taken the same as in
;;   =view-mode=:
;;   - =SPC= to scroll a screen down
;;   - =<backspace>= or =S-SPC= to scroll a screen up
;;   - =v= or =<return>= to scroll one line down
;;   - =V= or =y= to scroll one line up
;; - =g= /get the rope-read/ to trigger reversing every other line for
;;   the currently visible part of the buffer
;; - =d= /downwards/ to reverse every other line starting with the line
;;   below the cursor

;; Configuration
;; -------------

;; For convenience you can bind command =rope-read-mode= to a key.  For
;; example to activate or deactivate =rope-read-mode= by pressing scroll
;; lock two times use the line

;; #+BEGIN_EXAMPLE
;; (global-set-key (kbd "<Scroll_Lock> <Scroll_Lock>") 'rope-read-mode)
;; #+END_EXAMPLE

;; You can control the flipping via customization.  See M-x
;; customize-apropos rope-read.  Shortcut: With point after the next
;; closing parenthesis do C-xe (customize-apropos "rope-read").


;;; Code:


;; Variables for customization

(defcustom rope-read-flip-line-horizontally t
  "When not nil the line in rope-read-mode gets flipped upside
  down.  When nil no upside down flip occurs."
  :group 'rope-read
  :type 'boolean)

(defcustom rope-read-flip-line-vertically t
  "When not nil the line in rope-read-mode gets flipped left
  right.  When nil no left right flip occurs."
  :group 'rope-read
  :type 'boolean)

(defcustom rope-read-mode-lighter
  " ⇌"
  "Text in the mode line to indicate that the mode is on."
  :group 'rope-read
  :type 'string)


;; Variables

(defvar rope-read-overlays nil
  "List of rope-read-overlays.")

(defvar rope-read-olimid-next-unused 0
  "Overlay-image-id that has not been used yet.

  The program must reset this variable reasonably when an id gets
  used.")

(defvar rope-read-image-overlay-path
  (concat user-emacs-directory "rope-read-mode/")
  "Path where the overlay images get stored.")

(defvar rope-read-image-overlay-filename-format-string
  (concat (file-name-directory rope-read-image-overlay-path) "%d.png")
  "Template for the filenames to be written to disk.")

(defvar rope-read-mode nil)
(make-variable-buffer-local 'rope-read-mode)

(defvar rope-read-old-buffer-read-only)
(make-variable-buffer-local 'rope-read-old-buffer-read-only)

(defvar rope-read-transform-fun
  ;; #'rope-read-reol-in-visible-buffer-part-with-images
  #'rope-read-reol
  "The function which transforms a screen for rope-reading.

This indirection is for the comfort of any coder to try
out something new.")

(defvar rope-read-mode-hook nil)


;; Keys

(defvar rope-read-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map " " #'rope-read-next-page)
    (define-key map [?\S-\ ] #'rope-read-prev-page)
    (define-key map (kbd "<backspace>") #'rope-read-prev-page)
    (define-key map (kbd "<return>") #'rope-read-scroll-up-line)
    (define-key map "v" #'rope-read-scroll-up-line)
    (define-key map "y" #'rope-read-scroll-down-line)
    (define-key map "V" #'rope-read-scroll-down-line)
    (define-key map "g" #'rope-read-refresh)
    (define-key map "d" #'rope-read-reol)
    (define-key map "p" #'rope-read-next-paragraph)
    (define-key map "r" #'rope-read-delete-overlays)
    (define-key map "q" #'rope-read-quit)
    (define-key map "?" #'describe-mode)
    map)
  "Keymap for `rope-read-mode'.")


;; The mode

;;;###autoload
(define-minor-mode rope-read-mode
  "Rope Reading mode.

In rope-read-mode every other line gets reversed.  rope-read-mode is a
view only mode.

\\{rope-read-mode-map}

This mode can help to save eye movements.

By reversing every other line the reader often just can dip the
gaze at the end of a line to read on instead of doing the
annoying search for the next line at the other side of the text."
  :lighter rope-read-mode-lighter :keymap rope-read-mode-map
  (if rope-read-mode (rope-read-mode-enable) (rope-read-mode-disable)))

(defun rope-read-mode-enable ()
  (unless (file-exists-p rope-read-image-overlay-path)
    (make-directory rope-read-image-overlay-path))
  (setq rope-read-old-buffer-read-only buffer-read-only
        buffer-read-only t)
  (run-hooks 'rope-read-mode-hook))

(defun rope-read-mode-disable ()
  (rope-read-delete-overlays)
  (setq buffer-read-only rope-read-old-buffer-read-only))


;; Commands

(defun rope-read-delete-overlays ()
  "Delete all overlays currently used with the rope-read-feature."
  (interactive)
  (mapc #'delete-overlay rope-read-overlays)
  (setq rope-read-overlays nil))

(defun rope-read-next-page ()
  "Scroll up one page.
If point is at the bottom bring the line with the cursor to the
top.  This is supposed to ease reading."
  (interactive)
  (rope-read-delete-overlays)
  (if (rope-read-point-at-bottom-p)
      (recenter 0)                      ;
    (scroll-up-command))
  (redisplay t)
  (move-to-window-line 0)
  (funcall rope-read-transform-fun))

(defun rope-read-prev-page ()
  (interactive)
  (rope-read-delete-overlays)
  (scroll-down-command)
  (redisplay t)
  (move-to-window-line 0)
  (funcall rope-read-transform-fun))

(defun rope-read-scroll-line (n)
  "Scroll the buffer N lines and reverse every other visible line."
  (rope-read-delete-overlays)
  (scroll-up-line n)
  (redisplay t)
  (move-to-window-line 0)
  (funcall rope-read-transform-fun))

(defun rope-read-scroll-up-line (n)
  "Scroll the buffer up N lines and reverse every other visible line.

  E.g.  for N = 1 the second-line becomes first."
  (interactive "p")
  (unless n (setq n 1))
  (rope-read-scroll-line n))

(defun rope-read-scroll-down-line (n)
  "Scroll the buffer down N lines and reverse every other line.

  E.g.  for N = 1 the first-line becomes second."
  (interactive "p")
  (unless n (setq n 1))
  (rope-read-scroll-line (- n)))

(defun rope-read-refresh ()
  "Refresh the rope-read-representation for the given window."
  (interactive)
  (rope-read-delete-overlays)
  (redisplay t)
  (move-to-window-line 0)
  (funcall rope-read-transform-fun))

(defun rope-read-quit ()
  (interactive)
  (when rope-read-mode (rope-read-mode 'toggle)))


;; Coordinates calculation

(defun rope-read-y-info-of-line ()
  "Return the top coordinate and the height of the line that contains `(point)'.
This function typically takes a while."
  (let* ((beg (progn (beginning-of-visual-line) (point)))
         (posn-at-point
          (progn
            (posn-at-point (point))))
         (y-top (cdr (posn-x-y posn-at-point)))
         (height (cdr (nth 9 posn-at-point)))
         (end (progn (end-of-visual-line) (point))))
    (goto-char beg)
    (while (and (< (point) (point-max))
                (progn (forward-char)
                       (< (point) end)))
      (setq
       posn-at-point (posn-at-point (point))
       height (max height (cdr (nth 9 posn-at-point)))
       y-top (min y-top (cdr (posn-x-y posn-at-point)))))
    (cons y-top height)))

(defun rope-read-line-height ()
  "Height of the current line."
  (let* ((beg (progn (beginning-of-visual-line) (point)))
         (height (cdr (nth 9 (posn-at-point beg))))
         (end (progn (end-of-visual-line) (point))))
    (goto-char beg)
    (forward-char)
    (while (progn (< (point) end))
      (setq height (max height (cdr (nth 9 (posn-at-point (point))))))
      (forward-char))
    height))

(defun rope-read-line-width ()
  "Width of the current line."
  (end-of-visual-line)
  (car (posn-x-y (posn-at-point (point)))))

(defun rope-read-line-top ()
  "Top coordinate of the current line."
  (end-of-visual-line)
  (cdr (posn-x-y (posn-at-point (point)))))

(defun rope-read-line-widths-and-tops ()
  "Line widths and tops of the window."
  (let ((max-line-number (move-to-window-line -1))
        (line 0)
        widths tops)
    (while (<= line max-line-number)
      (move-to-window-line line)
      (setq tops (cons (rope-read-line-top) tops)
            widths (cons (rope-read-line-width) widths))
      (incf line))
    (cons (vconcat (nreverse widths)) (vconcat (nreverse tops)))))


;; Reverse those lines

(defun rope-read-reol-in-visible-buffer-part-with-images ()
  "Reverse every other line in the visible buffer part."
  (move-to-window-line 0)
  (rope-read-reol))

(defun rope-read-advance-one-visual-line ()
  (beginning-of-visual-line 2))

(defun rope-read-reol ()
  "Reverse every other line in the visible part starting with line after point."
  (interactive)
   (let ((point-at-start (point))
         (last-line
          (progn (move-to-window-line -1)
                 (point))))
     (goto-char point-at-start)
     (beginning-of-visual-line)
     (rope-read-advance-one-visual-line)
     (while (and (< (point) last-line) ; todo: handle case of last line
                 (< (save-excursion (end-of-visual-line) (point))
                    (point-max)))  ; todo: try to handle also the very
                                        ; last line.  the last line is
                                        ; special because it is
                                        ; special for the
                                        ; beginning-of-visual-line
                                        ; command.  no further
                                        ; iteration!
       (rope-read-snap-visual-line-under-olimid-filename)
       (let* ((l-beg   (save-excursion (beginning-of-visual-line) (point)))
              (l-end   (save-excursion (end-of-visual-line) (point)))
              (l-next  (save-excursion
                         (goto-char l-beg) (beginning-of-visual-line 2) (point)))
                                        ; try to use for identify truncation of the line
              (olimid-current (1- rope-read-olimid-next-unused)))
         (push (make-overlay l-beg l-end) rope-read-overlays)
         (overlay-put
          (car rope-read-overlays) 'display
          (create-image
           (expand-file-name
            (format
             rope-read-image-overlay-filename-format-string
             olimid-current))
           nil nil
           :scale 1.0
           :ascent 'center
           ;; TODO: try to refine.  hint: try
           ;; understand.  is this a font-dependent
           ;; thing?  e.g. :ascent 83 is possible.
           ;; there are further attributes...
           ))
         (when (= l-end l-next)
           (overlay-put (car rope-read-overlays) 'after-string "\n")
           ;; this newline makes the images appear in some cases.
           ;; todo: at least think about doing something similar in
           ;; the analog case of 'before'.
           )
         (goto-char l-next)
         (redisplay t)
         (rope-read-advance-one-visual-line)))
     (forward-line -1)
     (beginning-of-visual-line)))


;; Line snapper

(defun rope-read-snap-visual-line-under-olimid-filename ()
  "Snapshot the visual line with `(point)' flipflopped.

Also consider the line above the line containing `(point)'.  If
the line above is longer then extend the snapshot to use the
length of the line above.  This often eases continuation of
reading for short lines.

The file name for the snapshot contains the number
`rope-read-olimid-next-unused' as index.  Use the source for all
detail."
  (interactive "P")
  (save-excursion
    (let* ((beg (progn (beginning-of-visual-line) (point)))
           (end (progn (end-of-visual-line) (point)))
           (end-above (save-excursion (goto-char beg) (end-of-visual-line 0) (point)))
           (beg-next (progn  (goto-char beg) (beginning-of-visual-line 2) ))
           (width (if (or (= end beg-next) (= end-above beg))
                      (- (nth 2 (window-inside-pixel-edges))
                         (nth 0 (window-inside-pixel-edges)))
                    (- (max (car (posn-x-y (posn-at-point end)))
                            (car (posn-x-y (posn-at-point end-above))))
                       (car (posn-x-y (posn-at-point beg))))))
           (y-info-getter #'rope-read-y-info-of-line)
           (y-top-height (progn (goto-char beg)
                                (funcall y-info-getter)))
           (y-pos-line (car y-top-height))
           (height (cdr y-top-height))
           (x-win-left (nth 0 (window-inside-pixel-edges)))
           (y-win-top (nth 1 (window-inside-pixel-edges)))
           (x-anchor (+ x-win-left))
           (y-anchor (+ y-win-top y-pos-line)))
      (call-process
       "convert" nil nil nil
       (format "x:%s[%dx%d+%d+%d]"
               (frame-parameter nil 'window-id)
               width height x-anchor y-anchor)
       (if rope-read-flip-line-horizontally "-flip" "")
       (if rope-read-flip-line-vertically "-flop" "")
       (expand-file-name
        (format
         rope-read-image-overlay-filename-format-string
         (1-(setq
             rope-read-olimid-next-unused
             (1+ rope-read-olimid-next-unused)))))))))


;; Paragraph wise rope read
(defun rope-read-reol-in-region (start end)
  "Reverse every other line starting with line with pos START.
Do this at most up to pos END."
  (interactive "r")
  (rope-read-delete-overlays)
  (let ((transient-mark-mode-before transient-mark-mode))
    (unwind-protect
        (let* ((point-at-start start)
             (point-at-last-window-line (progn (move-to-window-line -1) (point)))
             (point-at-end (min end point-at-last-window-line)))
        (transient-mark-mode -1)
        (goto-char point-at-start)
        (beginning-of-visual-line)
        (rope-read-advance-one-visual-line)
        (while (and (< (point) point-at-end) ; todo: handle case of last line
                    (< (save-excursion (end-of-visual-line) (point))
                       (min point-at-end (point-max)))) ; todo: try to handle also the very
                                        ; last line.  the last line is
                                        ; special because it is
                                        ; special for the
                                        ; beginning-of-visual-line
                                        ; command.  no further
                                        ; iteration!
          (rope-read-snap-visual-line-under-olimid-filename)
          (let* ((l-beg   (save-excursion (beginning-of-visual-line) (point)))
                 (l-end   (save-excursion (end-of-visual-line) (point)))
                 (l-next  (save-excursion
                            (goto-char l-beg) (beginning-of-visual-line 2) (point)))
                                        ; try to use for identify truncation of the line
                 (olimid-current (1- rope-read-olimid-next-unused)))
            (push (make-overlay l-beg l-end) rope-read-overlays)
            (overlay-put
             (car rope-read-overlays) 'display
             (create-image
              (expand-file-name
               (format
                rope-read-image-overlay-filename-format-string
                olimid-current))
              nil nil
              :scale 1.0
              :ascent 'center
              ;; TODO: try to refine.  hint: try
              ;; understand.  is this a font-dependent
              ;; thing?  e.g. :ascent 83 is possible.
              ;; there are further attributes...
              ))
            (when (= l-end l-next)
              (overlay-put (car rope-read-overlays) 'after-string "\n")
              ;; this newline makes the images appear in some cases.
              ;; todo: at least think about doing something similar in
              ;; the analog case of 'before'.
              )
            (goto-char l-next)
            (redisplay t)
            (rope-read-advance-one-visual-line)))
        (when ( <= point-at-last-window-line (point))
          (beginning-of-line 0)))
    (transient-mark-mode transient-mark-mode-before))))

(defun rope-read-point-at-bottom-p ()
  "Return T if point is in one of the last two lines at bottom."
  (let* ((point-before (point)))
    (save-excursion
      (if (< point-before
             (progn
               (move-to-window-line -2)
               (point)))
          nil t))))

(defun rope-read-next-paragraph ()
  "Apply rope read up to the end of the paragraph and move point there.
If point is in one of the two bottom lines recenter the line with
point to the top."
  (interactive)
  (skip-chars-forward " \t\n\r")
  (when (rope-read-point-at-bottom-p)
    (recenter 0)
    (redisplay))
  (let ((beg (point))
        (end (save-excursion
               (let ((point-in-bottom-line
                      (save-excursion
                        (move-to-window-line -1)
                        (point))))
                 (forward-paragraph)
                 (min (point) point-in-bottom-line)))))
    (rope-read-reol-in-region beg end)))


(provide 'rope-read-mode)


;;; rope-read-mode.el ends here
