;;; dynamic-ruler.el --- Displays a dynamic ruler at point.

;; Copyright (C) 2015, 2016 Francesc Rocher

;; Author: Francesc Rocher <francesc.rocher@gmail.com>
;; URL: http://rocher.github.io/dynamic-ruler
;; Package-Version: 20160602.808
;; Package-Commit: c9c0de6fe5721f06b50e01d9b4684b519c71b367
;; Version: 0.1.4
;; Keywords: ruler tools convenience
;; Maintainer: Francesc Rocher <francesc.rocher@gmail.com>

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Displays a dynamic ruler at point that can be freely moved around
;; the buffer, for measuring and positioning text.

;; (load "dynamic-ruler") and see the help strings for
;; `dynamic-ruler' and `dynamic-ruler-vertical'

;; This ruler is based on the popup-ruler by Rick Bielawski, which in
;; turn was inspired by the one in fortran-mode but code-wise bears no
;; resemblance.

;;; Installation:

;; Put dynamic-ruler.el on your load path, add a load command to .emacs and
;; map the main routines to convenient keystrokes. For example:

;; (require 'dynamic-ruler)
;; (global-set-key [f9]    'dynamic-ruler)
;; (global-set-key [S-f9]  'dynamic-ruler-vertical)

;; Please report any bugs!

;;; TODO:

;; Optimize code.

;; New function to interactively switch between horizontal and
;; vertical rulers.

;;; History:

;; 2015-08-22 FRM Initial packaged release.

;; This file is *NOT* part of GNU Emacs.

;;; Code:

(defgroup dynamic-ruler nil
  "Displays a dynamic ruler at point that can be freely moved
around the buffer, for measuring and positioning text."
  :group 'convenience)

(defface dynamic-ruler-positive-face
  '((t (:background "gold"
                    :foreground "gray16"
                    :slant normal
                    :weight normal
                    :height 1.0)))
  "Default face to display positive numbers in dynamic rulers.")

(defface dynamic-ruler-negative-face
  '((t (:background "gray16"
                    :foreground "gold"
                    :slant normal
                    :weight normal
                    :height 1.0)))
  "Default face to display negative numbers in dynamic rulers.")

(defcustom dynamic-ruler-vertical-interval 1
  "Puts numbers on a vertical ruler only at this interval.
1 is the default which means every line.  5 would mean every N mod 5 line.
Line number 1 is always marked explicitly regardless of this value."
  :group 'dynamic-ruler)

;;;###autoload
(defun dynamic-ruler ()
  "Temporarily display a horizontal ruler at `point'.
Press up and down, or `n' and `p', keys to move it around the
buffer.  Left and right, or `f' and `b', will change the origin
of the numbered scale.  Keys `a', `e' and `c' will change also
the origin of the numbered scale to the beginning, end and
center, respectively.  Numbers 0 to 9 will change the step
interval.  Press `q' to quit."
  (interactive)
  (let ((key nil)
        (key-type (if (>= emacs-major-version 25) 'cons 'vector))
        (offset (current-column))
        (offset-inc 1)
        (offset-line 1))
    (while (not key)
      (discard-input)
      (setq key
            (momentary-string-display
             (let* ((left-len offset)
                    (right-len (- (+ (window-hscroll)(window-width)) 0 left-len))
                    (left (dynamic-ruler-r-l left-len))
                    (right (dynamic-ruler-l-r right-len)))
               (concat (cadr left) (cadr right) "\n"
                       (car left) (car right) "\n"))
             (line-beginning-position offset-line)
             32
             (if (display-graphic-p)
                 "[cursor]: move; a,c,e: begin/center/end of line; 0-9: inc; q: quit"
               "f,b,n,p: move; a,c,e: begin/center/end of line; 0-9: inc; q: quit")))
      (if (eq (type-of key) key-type)
          (let ((k (elt key 0)))
            (if (or (eq k ?f) (eq k 'right)) (setq offset (+ offset offset-inc)))
            (if (or (eq k ?b) (eq k 'left)) (setq offset (- offset offset-inc)))
            (if (eq (type-of k) 'integer)
                (progn
                  (if (eq k ?0) (setq offset-inc 10))
                  (if (and (<= ?1 k) (<= k ?9)) (setq offset-inc (- k ?0)))))
            (if (or (< offset 0) (eq k ?a)) (setq offset 0))
            (if (or (>= offset (window-width))
                    (eq k ?e))
                (setq offset (- (window-width) 0)))
            (if (and (or (eq k ?p) (eq k 'up))
                     (< (window-start) (line-beginning-position offset-line)))
                (setq offset-line (1- offset-line)))
            (if (and (or (eq k ?n) (eq k 'down))
                     (< (line-beginning-position (1+ offset-line)) (window-end)))
                (setq offset-line (1+ offset-line)))
            (if (eq k ?c)
                (setq offset (/ (window-width) 2)))
            (if (eq k ?q)
                (setq key t)
              (setq key nil))))))
  (discard-input)
  (sit-for 0)
  (message nil))

;;;###autoload
(defun dynamic-ruler-vertical ()
  "Temporarily display a vertical ruler in the `current-column'.
Press left and right, or `f' and `b', keys to move it around the
buffer.  Up and down, or `n' and `p', will change the origin of
the numbered scale.  Keys `a', `e' and `c' will change also the
origin of the numbered scale to the beginning, end and center,
respectively.  Numbers 0 to 9 will change the numbered scale and
the step interval.  Press `q' to quit."
  (interactive)
  (let ((key nil)
        (column (current-column))
        (window-line (count-lines (window-start) (if (bolp) (1+ (point)) (point))))
        (offset-inc 1))
    (while (not key)
      (save-excursion
        (setq key
              (dynamic-ruler-momentary-column
               (dynamic-ruler-strings window-line)
               column))
        (let ((k (elt key 0)))
          (if (and (or (eq k ?f) (eq k 'right))
                   (< column (- (window-width) 8)))
              (setq column (1+ column)))
          (if (and (or (eq k ?b) (eq k 'left))
                   (>= column 1))
              (setq column (1- column)))
          (if (or (eq k ?p) (eq k 'up)) (setq window-line (- window-line offset-inc)))
          (if (or (< window-line 1) (eq k ?a)) (setq window-line 1))
          (if (or (eq k ?n) (eq k 'down)) (setq window-line (+ window-line offset-inc)))
          (if (or (> window-line (+ 0 (window-height))) (eq k ?e)) (setq window-line (+ 0 (window-height))))
          (if (eq k ?c) (setq window-line (1+ (/ (window-height) 2))))
          (if (eq (type-of k) 'integer)
              (progn
                (if (eq k ?0) (setq offset-inc 10))
                (if (and (<= ?1 k) (<= k ?9))
                    (setq offset-inc (- k ?0)))
                (setq dynamic-ruler-vertical-interval offset-inc)))
          (if (eq k ?q) (setq key t) (setq key nil)))))
    (discard-input)
    (sit-for 0)
    (message nil)))

(defun dynamic-ruler-r-l (len)
  "Return right to left running ruler of length LEN.
Result is a list of 2 strings, markers and counters."
  (let* ((iterations (/ (1- (abs len)) 10))
         (short (- (* 10 (1+ iterations)) (abs len)))
         (result1 "|....|....")
         (result2 "10   5    ")
         (inc1    "|....|....")
         (inc2    "%d0         ")
         (i 1))
    (while  (<= i iterations)
      (setq i (1+ i))
      (setq result1 (concat inc1 result1))
      (setq result2 (concat (substring (format inc2 i) 0 10) result2)))
    (list
     (propertize (substring result1 short) 'face 'dynamic-ruler-negative-face)
     (propertize (substring result2 short) 'face 'dynamic-ruler-negative-face))))

(defun dynamic-ruler-l-r (len)
  "Return left to right running ruler of length LEN.
Result is a list of 2 strings; markers and counters."
  (let* ((iterations (/ (1- (abs len)) 10))
         (result1 "....|....|")
         (result2 "    5   10")
         (inc1    "....|....|")
         (inc2    "        %d0")
         (i 1))
    (while  (<= i iterations)
      (setq i (1+ i))
      (setq result1 (concat result1 inc1))
      (setq result2 (concat result2 (substring (format inc2 i) -10))))
    (list
     (propertize (substring result1 0 len) 'face 'dynamic-ruler-positive-face)
     (propertize (substring result2 0 len) 'face 'dynamic-ruler-positive-face))))

(defun dynamic-ruler-window-position (window-line)
  "Return the cons (screen-line . screen-column) of point starting at WINDOW-LINE."
  (if (eq (current-buffer) (window-buffer))
      (if (or truncate-lines (/= 0 (window-hscroll)))
          ;; Lines never wrap when horizontal scrolling is in effect.
          (let ((window-column (- (current-column)(window-hscroll))))
            (cond
             ((= 0 (current-column))
              (cons window-line 0))
             ((<= (current-column) (window-hscroll))
              (cons (1- window-line) 0))
             (t (cons (1- window-line) window-column))))
        ;; When lines are not being truncated we deal with wrapping
        (let ((window-column (% (current-column)(window-width)))
              (old-window-line (count-screen-lines (window-start) (point))))
          (if (= 0 window-column)
              (cons window-line window-column)
            (cons (1- window-line) window-column))))))

(defun dynamic-ruler-strings (window-line)
  "Return a list of strings that form a vertical ruler starting at WINDOW-LINE.
The ruler is intended to run from the top of the screen to the
bottom so there are (window-height) strings."
  (if (or truncate-lines (/= 0 (window-hscroll)))
      (let* ((position (dynamic-ruler-window-position window-line))
             (row (car position))
             (col (cdr position))
             (start 1)
             (mid (if (bolp) (1- row) row))
             (end (- (window-height) mid))
             (width (length (number-to-string (max start end mid))))
             ruler-list)
        (message (format "window-line=%d, mid=%d, end=%d" window-line mid end))
        (append
         (if (>= mid 1)
             (dynamic-ruler-make-strings
              mid 1
              dynamic-ruler-vertical-interval width 'dynamic-ruler-negative-face)
           nil)
         (dynamic-ruler-make-strings
          1 end dynamic-ruler-vertical-interval width 'dynamic-ruler-positive-face)))
    (error "Unsupported window configuration")))

(defun dynamic-ruler-make-strings (start end interval width face)
  "Return a list of strings that form a vertical ruler.
Numbering of the strings runs from START to END where strings not
a multiple of INTERVAL do not contain numbers.  The exception
being that a string numbered 1 is always numbered.  The strings
have total length WIDTH and property FACE."
  (let* ((fmt (concat "─  %" (number-to-string width) "d  ─"))
         (spacer (concat "─  " (make-string width ? ) "  ─"))
         (increment (if (> start end) -1 1))
         (done nil)
         ruler-list)
    (while (not done)
      (if (or (= start 1) (= 0 (% start interval)))
          (push (propertize (format fmt start) 'face face) ruler-list)
        (push (propertize spacer 'face face) ruler-list))
      (setq done (= start end))
      (setq start (+ increment start)))
    (reverse ruler-list)))

(defun dynamic-ruler-momentary-column (string-list col)
  "Momentarily display STRING-LIST in the current buffer at COL.

The strings in STRING-LIST cannot contain \\n.  They are
displayed in `dynamic' face, which is customizable.

Starting at the top of the display each string in the list is displayed
on subsequent lines at column COL until one of the following is reached:
the last string in STRING-LIST, the bottom of the display, the last line
in the buffer."
  (let ((count (window-height))
        (loc (count-lines (window-start) (point)))
        overlay-list
        this-overlay
        buffer-file-name
        key)
    (goto-char (window-start))
    ;; although we now use overlays, dynamic-ruler-temporary-invisible-change is still
    ;; needed because move-to-column can insert spaces into the buffer.
    (dynamic-ruler-temporary-invisible-change
     (unwind-protect
         (progn
           (while (and string-list (> count 0))
             (move-to-column col t)
             (setq this-overlay (make-overlay (point) (point) nil t))
             (setq overlay-list (cons this-overlay overlay-list))
             (overlay-put this-overlay 'before-string (pop string-list))
             (forward-line)
             (if (< (point)(point-max))
                 (setq count (1- count))
               (setq count -1)))
           (goto-char (window-start))
           (if (= col 0)
               (forward-line loc)
             (forward-line (1- loc))
             (move-to-column col))
           (setq key (read-key-sequence-vector
                      (if (display-graphic-p)
                          "[cursor]: move; a,c,e: begin/center/end of column; 0-9: inc; q: quit"
                        "f,b,n,p: move; a,c,e: begin/center/end of column; 0-9: inc; q: quit"
                        )))
           (while overlay-list
             (delete-overlay (prog1 (car overlay-list)
                               (setq overlay-list (cdr overlay-list))))))))
    key))

;;;###autoload
(defmacro dynamic-ruler-temporary-invisible-change (&rest forms)
  "Execute FORMS with a temporary `buffer-undo-list', undoing on return.
The changes you make within FORMS are undone before returning.
But more importantly, the buffer's `buffer-undo-list' is not affected.
This macro allows you to temporarily modify read-only buffers too.
Always return nil"
`(let* ((buffer-undo-list)
          (modified (buffer-modified-p))
          (inhibit-read-only t))
     (save-excursion
       (unwind-protect
           (progn ,@forms)
         (primitive-undo (length buffer-undo-list) buffer-undo-list)
         (set-buffer-modified-p modified))) ()))

(provide 'dynamic-ruler)

;;; dynamic-ruler.el ends here
