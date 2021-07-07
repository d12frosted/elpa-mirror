;;; sparkline.el --- Make sparkline images from a list of numbers

;; Copyright (C) 2013, 2014 Willem Rein Oudshoorn

;; Author: Willem Rein Oudshoorn <woudshoo@xs4all.nl>
;; Created: July 2013
;; Version: 1.0.2
;; Package-Version: 20150101.1319
;; Package-Commit: a2b5d817d272d6363b67ed8f8cc75499a19fa8d2
;; Keywords: extensions
;; Package-Requires: ((cl-lib "0.3"))

;; This file is not part of GNU Emacs
;; Standard GPL v3 or higher license applies.

;;; Commentary:

;; This package provides a function to create a sparkline graph.
;; 
;; Sparkline graphs were introduced by Edward Tufte see
;; 
;; http://en.wikipedia.org/wiki/Sparkline
;; 
;; They are charts containing a single line without any labels or
;; indication of scale.
;;
;; They are meant to be used inline in text, without changing the line
;; height and provide a quick overview of the trend and pattern of the
;; underlying data.
;;
;; Creating sparkline graphs is done by the function `sparkline-make-sparkline',
;; for example:
;;
;;   (sparkline-make-sparkline 80 11 '(10 20 4 23.3 22.1 3.3 4.5 6.7))
;;
;; which creates an image which can be inserted in a buffer with the
;; standard image functions such as:
;;
;;   (insert-image
;;      (sparkline-make-sparkline 80 11 '(10 20 4 23.3 22.1 3.3 4.5 6.7)))
;;
;;
;; GENERAL DRAWING FEATURES
;;
;; Besides creating sparklines this package also allows creating and
;; drawing into bitmaps in a limited way.
;;
;; The supported features are:
;;
;; - Creating a monochrome bitmap of arbitrary size with `sparkline-make-image'
;; - Coloring a pixel in the foreground or backaground color with `sparkline-set-pixel'
;; - Drawing straight lines with `sparkline-draw-line'.
;; 
;;; Code:
(require 'cl-lib)

(defun sparkline--image-data (image)
  "Return the underlying `bool-vector' containing the bitmap data of IMAGE."
  (plist-get (cdr image) :data))

(defun sparkline--image-index (image x y)
  "Return the index in the bitmap vector of IMAGE for location (X Y).
Returns nil if the coordinates are outside the image."
  (let ((width (plist-get (cdr image) :width))
		(height (plist-get (cdr image) :height)))
    (when (and (>= x 0)
			   (>= y 0)
			   (> width x)
			   (> height y))
      (+ x (* (plist-get (cdr image) :width) y)))))

(defun sparkline-set-pixel (image x y value)
  "Set the pixel in IMAGE at location (X Y) to VALUE.
Value should be either nil or t, where t means foreground and nil
indicates the background.

This updates the image in place.

Note that if the coordinates are outside the image the image is
not updated and no error is throw."
  (let ((index (sparkline--image-index image x y)))
    (when index
      (aset (sparkline--image-data image) index value))))


(defun sparkline-make-image (width height &optional foreground background)
  "Create a bitmap image of given `WIDTH' and `HEIGHT'.
The optional `FOREGROUND' and `BACKGROUND' parameters indicate
the colors for the foreground (t) and background (nil) pixels."
  (let ((data (make-bool-vector (* width height) nil)))
    `(image :type xbm
			:data
			,data
			:height ,height
			:width ,width
			:foreground ,foreground
			:background ,background
			:ascent 100)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Line drawing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  The standard Bresenham line drawing algorithm can only draw lines
;;;  in one octant, in our case octant 1 (see numbering below).
;;;  So for the general case we need to do a
;;;  coordinate transformation such that the desired line lies in octant 1
;;;  and do the inverse transformation when actually coloring the points in
;;;  the image.
;;;
;;;  Octant numbering:
;;;
;;;
;;;
;;;                 \   |   /           |
;;;                  \6 | 7/            |
;;;                   \ | /             | y increasing
;;;               5    \|/   8          |
;;;           ----------+---------      |
;;;               4    /|\   1          |
;;;                   / | \             |
;;;                  /  |  \            |
;;;                 / 3 | 2 \           v
;;;
;;;       ------ x increasing --------->
;;;

(defun sparkline--draw-case (dx dy)
  "Return the quadrant for the directional vector (DX DY).
The return value is one of :1, ..., :8.

If the vector is on a quadrant boundary it is undefined which quadrant is returned."
  (cond
   ((and (>= dx 0)
		 (>= dy 0)
		 (>= dx dy)) :1)
   ((and (>= dx 0)
		 (>= dy 0)
		 (< dx dy)) :2)
   ((and (>= dx 0)
		 (< dy 0)
		 (>= dx (- dy))) :8)
   ((and (>= dx 0)
		 (< dy 0)
		 (< dx (- dy))) :7)
   ((and (< dx 0)
		 (>= dy 0)
		 (>= (- dx) dy)) :4)
   ((and (< dx 0)
		 (>= dy 0)
		 (< (- dx) dy)) :3)
   ((and (< dx 0)
		 (< dy 0)
		 (>= (- dx) (- dy))) :5)
   ((and (< dx 0)
		 (< dy 0)
		 (< (- dx) (- dy))) :6)
   (t (error "SHOULD NOT HAPPEN, IMPOSSIBLE OCTANT"))))



(defun sparkline--transformed-coordinates (x0 y0 x1 y1 octant)
  "Helper function for `sparkline-draw-line'.
This transforms the coordinates for (X0 Y0) (X1 Y1) in such a way that the
resulting directional vector is in quadrant :1 if the original
directional vector is in octant OCTANT.

This is useful for drawing algorithms because it can be used
to ensure that the line from (X0 Y0) to (X1 Y1) have increasing x values
and increasing y values, where the total increase in y is less or equal than
the total increase in x.

For example the Bresenham line drawing algorithm needs this.

To be able to draw the points afterwards in the correct location,
use `sparkline--draw-pixel-case' which will undo the transformation
before drawing the pixel."
  (cond
   ((eq octant :1) (list x0 y0 x1 y1))
   ((eq octant :2) (list y0 x0 y1 x1))
   ((eq octant :3) (list y0 (- x0) y1 (- x1)))
   ((eq octant :4) (list (- x0) y0 (- x1) y1))
   ((eq octant :5) (list x1 y1 x0 y0))
   ((eq octant :6) (list y1 x1 y0 x0))
   ((eq octant :7) (list (- y0) x0 (- y1) x1))
   ((eq octant :8) (list x0 (- y0) x1 (- y1)))))

(defun sparkline--draw-pixel-case (image x y value octant)
  "Helper function for `sparkline-draw-line'.
Draws in IMAGE at location X Y a point with VALUE.  However X and
Y are not used directly but transformed into another octant
depending on OCTANT.  This inverts the transformation used in
`sparkline--transformed-coordinates'.

The parameter OCTANT indicates the transformation.  It will
transform a point in octant 1 to the octant OCTANT."
  (cond
   ((eq octant :1) (sparkline-set-pixel image x y value))
   ((eq octant :2) (sparkline-set-pixel image y x value))
   ((eq octant :3) (sparkline-set-pixel image (- y) x value))
   ((eq octant :4) (sparkline-set-pixel image (- x) y value))
   ((eq octant :5) (sparkline-set-pixel image x y value))
   ((eq octant :6) (sparkline-set-pixel image y x value))
   ((eq octant :7) (sparkline-set-pixel image y (- x) value))
   ((eq octant :8) (sparkline-set-pixel image x (- y) value))))




(defun sparkline-draw-line (image x0 y0 x1 y1 value)
  "Draw a line in the IMAGE from (X0 Y0) to (X1 Y1).
The color of the line is indicated by VALUE which should be either
nil or t."
  (let* ((octant (sparkline--draw-case (- x1 x0) (- y1 y0)))
		 (transformed (sparkline--transformed-coordinates x0 y0 x1 y1 octant))
		 (x0* (nth 0 transformed))
		 (y0* (nth 1 transformed))
		 (x1* (nth 2 transformed))
		 (y1* (nth 3 transformed)))
    (let* ((dx (- x1* x0*))
		   (dy (- y1* y0*))
		   (D (- (* 2 dy) dx)))
      (sparkline--draw-pixel-case image x0* y0* value octant)
      (while (and
			  (cl-incf x0*)
			  (<= x0* x1*))
		(if (> D 0)
			(progn
			  (cl-incf y0*)
			  (sparkline--draw-pixel-case image x0* y0* value octant)
			  (cl-incf D (- (* 2 dy) (* 2 dx))))
		  (progn
			(sparkline--draw-pixel-case image x0* y0* value octant)
			(cl-incf D (* 2 dy)))))))
  image)



(defun sparkline-make-sparkline (width height data)
  "Create a bitmap of size WIDTH x HEIGHT containing a sparkline chart of DATA."
  (let* ((min (apply 'min data))
		 (max (apply 'max data))
		 (length (length data))
		 (index 0)
		 (image (sparkline-make-image width height (when (= min max) "gray")))
		 prev-x prev-y)
    (when (= min max)
      (cl-decf min)
      (cl-incf max))
    (dolist (value data)
      (let ((x (/ (* (- width 1) index) (- length 1)))
			(y (floor (/ (* (- height 1) (- max value)) (- max min)))))
		(when (and prev-x prev-y)
		  (sparkline-draw-line image prev-x prev-y x y t))
		(setq prev-x x)
		(setq prev-y y)
		(cl-incf index)))
    image))


(provide 'sparkline)

;;; sparkline.el ends here
