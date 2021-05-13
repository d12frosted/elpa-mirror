;;; zone-nyan.el --- Zone out with nyan cat

;; Copyright (C) 2015 Vasilij Schneidermann <mail@vasilij.de>

;; Author: Vasilij Schneidermann <mail@vasilij.de>
;; URL: https://depp.brause.cc/zone-nyan
;; Package-Version: 20210508.1642
;; Package-Commit: 38b6e9f1f5871e9166b00a1db44680caa56773be
;; Version: 0.2.2
;; Package-Requires: ((emacs "24.3") (esxml "0.3.1"))
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A zone program displaying the infamous nyan cat animation.  Best
;; viewed in a graphical Emacs instance with SVG support.

;; See the README for more info: https://depp.brause.cc/zone-nyan

;;; Code:

(require 'esxml)

(defgroup zone-nyan nil
  "Zone out with nyan cat"
  :group 'zone
  :prefix "zone-nyan-")


;;; palette

(defvar zone-nyan-palette
  '((black  :gui "#000000" :term "color-16"  :ascii "  ")
    (white  :gui "#ffffff" :term "color-231" :ascii "@@")
    (gray   :gui "#999999" :term "color-246" :ascii ";;")
    (indigo :gui "#003366" :term "color-18"  :ascii "::")

    (red    :gui "#ff0000" :term "color-196" :ascii "##")
    (orange :gui "#ff9900" :term "color-208" :ascii "==")
    (yellow :gui "#ffff00" :term "color-226" :ascii "--")
    (green  :gui "#33ff00" :term "color-82"  :ascii "++")
    (cyan   :gui "#0099ff" :term "color-33"  :ascii "~~")
    (violet :gui "#6633ff" :term "color-57"  :ascii "$$")

    (rose   :gui "#ff99ff" :term "color-213" :ascii "??")
    (pink   :gui "#ff3399" :term "color-198" :ascii "<>")
    (rouge  :gui "#ff9999" :term "color-210" :ascii "()")
    (bread  :gui "#ffcc99" :term "color-216" :ascii "##")
  "Palette for GUI, 256 color and ASCII display of nyan cat."))

(defcustom zone-nyan-gui-type
  (if (image-type-available-p 'svg) 'svg 'text)
  "Rendering type on graphical displays."
  :type '(choice (const :tag "SVG" svg)
                 (const :tag "Text" text))
  :group 'zone-nyan)

(defcustom zone-nyan-term-type 'color
  "Rendering type on textual displays."
  :type '(choice (const :tag "Color" color)
                 (const :tag "ASCII" ascii))
  :group 'zone-nyan)


;;; data

(defun zone-nyan-rainbow (flip)
  "Return a list of rectangles describing a rainbow.
If FLIP is non-nil, the rainbow is flipped horizontally."
  (if flip
      '([ 0  0 2 3 red]
        [ 2  1 8 3 red]
        [10  0 8 3 red]
        [18  1 8 3 red]

        [ 0  3 2 3 orange]
        [ 2  4 8 3 orange]
        [10  3 8 3 orange]
        [18  4 8 3 orange]

        [ 0  6 2 3 yellow]
        [ 2  7 8 3 yellow]
        [10  6 8 3 yellow]
        [18  7 8 3 yellow]

        [ 0  9 2 3 green]
        [ 2 10 8 3 green]
        [10  9 8 3 green]
        [18 10 8 3 green]

        [ 0 12 2 3 cyan]
        [ 2 13 8 3 cyan]
        [10 12 8 3 cyan]
        [18 13 8 3 cyan]

        [ 0 15 2 3 violet]
        [ 2 16 8 3 violet]
        [10 15 8 3 violet]
        [18 16 8 3 violet])
    '([ 0  1 3 3 red]
      [ 3  0 8 3 red]
      [11  1 8 3 red]
      [19  0 8 3 red]

      [ 0  4 3 3 orange]
      [ 3  3 8 3 orange]
      [11  4 8 3 orange]
      [19  3 8 3 orange]

      [ 0  7 3 3 yellow]
      [ 3  6 8 3 yellow]
      [11  7 8 3 yellow]
      [19  6 8 3 yellow]

      [ 0 10 3 3 green]
      [ 3  9 8 3 green]
      [11 10 8 3 green]
      [19  9 8 3 green]

      [ 0 13 3 3 cyan]
      [ 3 12 8 3 cyan]
      [11 13 8 3 cyan]
      [19 12 8 3 cyan]

      [ 0 16 3 3 violet]
      [ 3 15 8 3 violet]
      [11 16 8 3 violet]
      [19 15 8 3 violet])))

(defun zone-nyan-star (x y frame)
  "Return a list of rectangles describing a star at X|Y.
FRAME is a number between 0 (inclusive) and 6 (exclusive) and
stands for its animation progress."
  (cond
   ((= frame 0)
    (list `[,(+ x 0) ,(+ y 0) 1 1 white]))
   ((= frame 1)
    (list `[,(+ x 1) ,(+ y 0) 1 1 white]
          `[,(+ x 0) ,(+ y 1) 1 1 white]
          `[,(+ x 2) ,(+ y 1) 1 1 white]
          `[,(+ x 1) ,(+ y 2) 1 1 white]))
   ((= frame 2)
    (list `[,(+ x 2) ,(+ y 0) 1 2 white]
          `[,(+ x 0) ,(+ y 2) 2 1 white]
          `[,(+ x 3) ,(+ y 2) 2 1 white]
          `[,(+ x 2) ,(+ y 3) 1 2 white]))
   ((= frame 3)
    (list `[,(+ x 3) ,(+ y 0) 1 2 white]
          `[,(+ x 0) ,(+ y 3) 2 1 white]
          `[,(+ x 3) ,(+ y 3) 1 1 white]
          `[,(+ x 5) ,(+ y 3) 2 1 white]
          `[,(+ x 3) ,(+ y 5) 1 2 white]))
   ((= frame 4)
    (list `[,(+ x 3) ,(+ y 0) 1 1 white]
          `[,(+ x 1) ,(+ y 1) 1 1 white]
          `[,(+ x 5) ,(+ y 1) 1 1 white]
          `[,(+ x 0) ,(+ y 3) 1 1 white]
          `[,(+ x 6) ,(+ y 3) 1 1 white]
          `[,(+ x 1) ,(+ y 5) 1 1 white]
          `[,(+ x 5) ,(+ y 5) 1 1 white]
          `[,(+ x 3) ,(+ y 6) 1 1 white]))
   ((= frame 5)
    (list `[,(+ x 3) ,(+ y 0) 1 1 white]
          `[,(+ x 0) ,(+ y 3) 1 1 white]
          `[,(+ x 6) ,(+ y 3) 1 1 white]
          `[,(+ x 3) ,(+ y 6) 1 1 white]))))

(defun zone-nyan-stars (frame)
  "Return a list of rectangles describing a star constellation at X|Y.
FRAME is a number between 0 (inclusive) and 12 (exclusive) and
stands for its animation progress."
  (cond
   ((= frame 0)
    (append (zone-nyan-star 41 0 1)
            (zone-nyan-star 65 12 3)
            (zone-nyan-star  0 21 1)
            (zone-nyan-star  8 41 5)
            (zone-nyan-star 69 56 0)
            (zone-nyan-star 36 64 2)))
   ((= frame 1)
    (append (zone-nyan-star 34 -1 2)
            (zone-nyan-star 57  7 4)
            (zone-nyan-star  5 44 0)
            (zone-nyan-star 66 56 0)
            (zone-nyan-star 27 63 3)))
   ((= frame 2)
    (append (zone-nyan-star 25 -2 3)
            (zone-nyan-star 49  7 5)
            (zone-nyan-star 66 19 3)
            (zone-nyan-star  0 43 1)
            (zone-nyan-star 57 53 5)
            (zone-nyan-star 18 63 4)))
   ((= frame 3)
    (append (zone-nyan-star 16 -2 4)
            (zone-nyan-star 46 10 0)
            (zone-nyan-star 58 19 4)
            (zone-nyan-star 48 53 4)
            (zone-nyan-star  9 63 5)))
   ((= frame 4)
    (append (zone-nyan-star  7 -2 5)
            (zone-nyan-star 41  9 1)
            (zone-nyan-star 50 19 5)
            (zone-nyan-star 39 53 3)
            (zone-nyan-star  6 66 0)))
   ((= frame 5)
    (append (zone-nyan-star  4  1 0)
            (zone-nyan-star 34  8 2)
            (zone-nyan-star 47 22 0)
            (zone-nyan-star 66 41 3)
            (zone-nyan-star 32 54 2)
            (zone-nyan-star  1 65 1)))
   ((= frame 6)
    (append (zone-nyan-star -1  0 1)
            (zone-nyan-star 25  7 3)
            (zone-nyan-star 42 21 1)
            (zone-nyan-star 58 41 4)
            (zone-nyan-star 27 55 1)))
   ((= frame 7)
    (append (zone-nyan-star 16  7 4)
            (zone-nyan-star 35 20 2)
            (zone-nyan-star 50 41 5)
            (zone-nyan-star 24 56 0)
            (zone-nyan-star 67 63 3)))
   ((= frame 8)
    (append (zone-nyan-star 65 -2 3)
            (zone-nyan-star  7  7 5)
            (zone-nyan-star 26 19 3)
            (zone-nyan-star 44 44 0)
            (zone-nyan-star 15 53 5)
            (zone-nyan-star 59 63 4)))
   ((= frame 9)
    (append (zone-nyan-star 57 -2 4)
            (zone-nyan-star  4 10 0)
            (zone-nyan-star 17 19 4)
            (zone-nyan-star 35 42 2)
            (zone-nyan-star  7 53 4)
            (zone-nyan-star 51 63 5)))
   ((= frame 10)
    (append (zone-nyan-star 49 -2 5)
            (zone-nyan-star -1  9 1)
            (zone-nyan-star  8 19 5)
            (zone-nyan-star 26 41 3)
            (zone-nyan-star -1 53 3)
            (zone-nyan-star 48 66 0)))
   ((= frame 11)
    (append (zone-nyan-star 46  1 0)
            (zone-nyan-star  5 22 0)
            (zone-nyan-star 17 41 4)
            (zone-nyan-star -4 53 4)
            (zone-nyan-star 43 65 1)))))

(defun zone-nyan-tail (frame)
  "Return a list of rectangles describing a tail.
FRAME is a number between 0 (inclusive) and 6 (exclusive) and
stands for its animation progress."
  (cond
   ((= frame 0)
    '([ 0 0 4 3 black]
      [ 1 1 4 3 black]
      [ 2 2 4 3 black]
      [ 3 3 3 3 black]
      [ 5 6 1 1 black]

      [ 1 1 2 1 gray]
      [ 2 2 2 1 gray]
      [ 3 3 2 1 gray]
      [ 4 4 2 1 gray]))
   ((= frame 1)
    '([ 1 1 2 4 black]
      [ 0 2 4 2 black]
      [ 2 3 4 3 black]
      [ 4 6 2 1 black]

      [ 1 2 2 2 gray]
      [ 2 4 2 1 gray]
      [ 4 4 2 2 gray]))
   ((= frame 2)
    '([ 5 4 1 1 black]
      [ 2 5 4 1 black]
      [ 0 6 6 2 black]
      [ 1 8 4 1 black]

      [ 2 6 4 1 gray]
      [ 1 7 3 1 gray]))
   ((= frame 3)
    '([ 4 4 2 1 black]
      [ 2 5 4 3 black]
      [ 1 6 2 4 black]
      [ 0 7 4 2 black]

      [ 4 5 2 2 gray]
      [ 2 6 2 1 gray]
      [ 1 7 2 2 gray]))
   ((= frame 4)
    '([ 0 2 4 1 black]
      [-1 3 7 2 black]
      [ 1 5 5 1 black]
      [ 4 6 2 1 black]

      [ 0 3 3 1 gray]
      [ 1 4 4 1 gray]
      [ 5 5 1 1 gray]))
   ((= frame 5)
    '([ 1 1 2 4 black]
      [ 0 2 4 2 black]
      [ 2 3 4 3 black]
      [ 4 6 2 1 black]

      [ 1 2 2 2 gray]
      [ 2 4 2 1 gray]
      [ 4 4 2 2 gray]))))

(defun zone-nyan-legs (frame)
  "Return a list of rectangles describing a set of legs.
FRAME is a number between 0 (inclusive) and 6 (exclusive) and
stands for its animation progress."
  (cond
   ((= frame 0)
    '([ 1 0 2 1 black]
      [ 1 1 3 1 gray]
      [ 0 1 1 3 black]
      [ 1 3 3 1 black]
      [ 3 2 2 1 black]
      [ 1 2 2 1 gray]

      [ 6 2 4 1 black]
      [ 6 3 3 1 black]
      [ 7 2 2 1 gray]

      [15 2 4 1 black]
      [16 3 3 1 black]
      [16 2 2 1 gray]

      [20 2 4 1 black]
      [21 3 2 1 black]
      [21 2 2 1 gray]))
   ((= frame 1)
    '([ 2 0 3 3 black]
      [ 1 1 3 3 black]
      [ 2 1 2 2 gray]

      [ 6 2 1 1 black]
      [ 7 2 3 2 black]
      [ 7 2 2 1 gray]

      [16 2 1 1 black]
      [17 2 3 2 black]
      [17 2 2 1 gray]

      [21 2 1 1 black]
      [22 2 3 2 black]
      [22 2 2 1 gray]))
   ((= frame 2)
    '([ 2 1 3 4 black]
      [ 5 3 1 1 black]
      [ 3 2 2 2 gray]

      [ 7 3 1 1 black]
      [ 8 3 3 2 black]
      [ 8 3 2 1 gray]

      [17 3 1 1 black]
      [18 3 3 2 black]
      [18 3 2 1 gray]

      [22 3 1 1 black]
      [23 3 3 2 black]
      [23 3 2 1 gray]))
   ((= frame 3)
    '([ 2 1 3 3 black]
      [ 1 2 3 3 black]
      [ 2 2 2 2 gray]

      [ 6 3 1 1 black]
      [ 7 3 3 2 black]
      [ 7 3 2 1 gray]

      [16 3 1 1 black]
      [17 3 3 2 black]
      [17 3 2 1 gray]

      [21 3 1 1 black]
      [22 3 3 2 black]
      [22 3 2 1 gray]))
   ((= frame 4)
    '([ 1 0 3 3 black]
      [ 0 1 3 3 black]
      [-1 2 3 3 black]
      [ 0 2 2 2 gray]
      [ 2 2 1 1 gray]

      [ 4 3 1 1 black]
      [ 5 3 3 2 black]
      [ 5 3 2 1 gray]

      [14 3 1 1 black]
      [15 3 3 2 black]
      [15 3 2 1 gray]

      [19 3 1 1 black]
      [20 3 3 2 black]
      [20 3 2 1 gray]))
   ((= frame 5)
    '([ 1 0 3 3 black]
      [ 0 1 3 3 black]
      [-1 2 3 3 black]
      [ 0 2 2 2 gray]
      [ 1 1 1 1 gray]
      [ 2 2 1 1 gray]

      [ 4 3 3 2 black]
      [ 5 3 2 1 gray]
      [ 7 3 1 1 black]

      [14 3 3 2 black]
      [15 3 2 1 gray]
      [17 3 1 1 black]

      [19 3 1 1 black]
      [20 2 3 3 black]
      [21 2 1 1 gray]
      [20 3 2 1 gray]))))

(defun zone-nyan-pop-tart ()
  "Return a list of rectangles describing a pop tart."
  '([ 2  0 17 18 black]
    [ 1  1 19 16 black]
    [ 0  2 21 14 black]

    [ 2  1 17 16 bread]
    [ 1  2 19 14 bread]

    [ 4  2 13 14 rose]
    [ 3  3 15 12 rose]
    [ 2  4 17 10 rose]

    [ 9  3  1  1 pink]
    [12  3  1  1 pink]
    [ 4  4  1  1 pink]
    [16  5  1  1 pink]
    [ 8  7  1  1 pink]
    [ 5  9  1  1 pink]
    [ 9 10  1  1 pink]
    [ 3 11  1  1 pink]
    [ 7 13  1  1 pink]
    [ 4 14  1  1 pink]))

(defun zone-nyan-face ()
  "Return a list of rectangles describing a face."
  '([ 2  0  2  1 black]
    [ 1  1  4  2 black]
    [ 5  2  1  1 black]

    [12  0  2  1 black]
    [11  1  4  2 black]
    [10  2  1  1 black]

    [ 0  5 16  5 black]
    [ 1  3 14  8 black]
    [ 2  3 12  9 black]
    [ 3  3 10 10 black]

    [ 2  1  2  3 gray]
    [ 4  2  1  2 gray]
    [ 5  3  1  1 gray]

    [12  1  2  3 gray]
    [11  2  1  2 gray]
    [10  3  1  1 gray]

    [ 2  4 12  7 gray]
    [ 1  5 14  5 gray]
    [ 3 11 10  1 gray]

    [ 2  8  2  2 rouge]
    [13  8  2  2 rouge]

    [ 4  6  2  2 black]
    [ 4  6  1  1 white]

    [11  6  2  2 black]
    [11  6  1  1 white]

    [ 5 10  7  1 black]
    [ 5  9  1  1 black]
    [ 8  9  1  1 black]
    [11  9  1  1 black]

    [ 9  7  1  1 black]))


;;; SVG

(defvar zone-nyan-svg-size 70
  "Virtual SVG canvas size.")

(defun zone-nyan-svg-scale (width height)
  "Calculate the maximum scaling factor given WIDTH and HEIGHT.
The result describes how large a tile in a grid with
`zone-nyan-svg-size' as size can be."
  (/ (min width height) zone-nyan-svg-size))

(defun zone-nyan-svg-root (width height scale x-offset y-offset body)
  "Wrap BODY in a SVG root element and return the appropriate SXML.
WIDTH and HEIGHT designate the dimensions in pixels, SCALE,
X-OFFSET and Y-OFFSET transform the virtual canvas to a pixel art
grid.  Additionally to that, clipping of the virtual canvas is
ensured."
  `(svg (@ (xmlns "http://www.w3.org/2000/svg")
           (width ,(number-to-string width))
           (height ,(number-to-string height)))
        (defs
          (clipPath (@ (id "clip-path"))
                    (rect (@ (x "0") (y "0")
                             (width ,(number-to-string zone-nyan-svg-size))
                             (height ,(number-to-string zone-nyan-svg-size))))))
        (g (@ (style "clip-path: url(#clip-path);")
              (transform ,(format "translate(%s,%s) scale(%s)"
                                  x-offset y-offset scale)))
           ,@body)))

(defun zone-nyan-svg-group (x y body)
  "Wrap BODY in a SVG group element at X and Y and return the appropriate SXML.
X and Y are interpreted as grid coordinates."
  `(g (@ (transform ,(format "translate(%s,%s)" x y)))
      ,@body))

(defun zone-nyan-svg-rect (x y width height fill)
  "Returns a SVG rect element as SXML.
X and Y are interpreted as grid coordinates, WIDTH and HEIGHT are
interpreted as grid units, FILL is a hex code string."
  `(rect (@ (x ,(number-to-string x))
            (y ,(number-to-string y))
            (width ,(number-to-string width))
            (height ,(number-to-string height))
            (fill ,fill))))

(defun zone-nyan-svg-to-sxml (width height scale x y &rest body)
  "Return a SXML representation of BODY.
WIDTH and HEIGHT correspond to the size, SCALE, X and Y are used
to magnify and translate BODY.  BODY itself is a list where every
three items are the X offset, Y offset and a list of rectangles.
Each rectangle is represented as a vector with a X and Y
component, width, height and fill color which is looked up in
`zone-nyan-palette'."
  (let (groups)
    (while body
      (let* ((x-offset (pop body))
             (y-offset (pop body))
             (rects (pop body))
             group)
        (dolist (rect rects)
          (let* ((x (aref rect 0))
                 (y (aref rect 1))
                 (width (aref rect 2))
                 (height (aref rect 3))
                 (color (aref rect 4))
                 (fill (plist-get (cdr (assoc color zone-nyan-palette)) :gui)))
            (push (zone-nyan-svg-rect x y width height fill)
                  group)))
        (push (zone-nyan-svg-group x-offset y-offset (nreverse group))
              groups)))
    (zone-nyan-svg-root width height scale x y (nreverse groups))))

(defun zone-nyan-svg-image (time)
  "Return a SVG string for a point in TIME."
  (let* ((edges (window-inside-pixel-edges))
         (width (- (nth 2 edges) (car edges)))
         (height (- (nth 3 edges) (cadr edges)))
         (scale (zone-nyan-svg-scale width height))
         (x-offset (floor (/ (- width (* zone-nyan-svg-size scale)) 2.0)))
         (y-offset (floor (/ (- height (* zone-nyan-svg-size scale)) 2.0))))
    (when (> scale 0)
      (let* ((frame (mod time 6))
             (star-frame (mod time 12))
             (rainbow-flipped (not (zerop (mod (/ time 2) 2))))
             (pop-tart-offset (if (< frame 2) 0 1))
             (face-x-offset (if (or (zerop frame) (> frame 3)) 0 1))
             (face-y-offset (if (or (< frame 2) (> frame 4)) 0 1)))
        (sxml-to-xml
         (zone-nyan-svg-to-sxml
          width height scale x-offset y-offset
          0 0 (list (vector 0 0 zone-nyan-svg-size zone-nyan-svg-size 'indigo))
          0 26 (zone-nyan-rainbow rainbow-flipped)
          0 0 (zone-nyan-stars star-frame)
          19 32 (zone-nyan-tail frame)
          23 41 (zone-nyan-legs frame)
          25 (+ 25 pop-tart-offset) (zone-nyan-pop-tart)
          (+ 35 face-x-offset) (+ 30 face-y-offset) (zone-nyan-face)))))))


;;; text

(defvar zone-nyan-text-size 40
  "Virtual canvas size.")

(defun zone-nyan-text-canvas (init)
  "Returns an empty text canvas to paint rectangles on.
INIT is the initial color to fill it with."
  (let ((canvas (make-vector zone-nyan-text-size nil)))
    (dotimes (i zone-nyan-text-size)
      (aset canvas i (make-vector zone-nyan-text-size init)))
    canvas))

(defun zone-nyan-text-in-bounds (x y)
  "Non-nil if X|Y is a coordinate not out of bounds."
  (and (>= x 0) (< x zone-nyan-text-size)
       (>= y 0) (< y zone-nyan-text-size)))

(defun zone-nyan-text-pixel (canvas x y fill)
  "Paint a pixel on CANVAS at X|Y with FILL."
  (when (zone-nyan-text-in-bounds x y)
    (aset (aref canvas y) x fill)))

(defun zone-nyan-text-rect (canvas x y width height fill)
  "Paint a rectangle on CANVAS at X|Y with FILL.
WIDTH and HEIGHT are its dimensions."
  (dotimes (i height)
    (dotimes (j width)
      (zone-nyan-text-pixel canvas (+ x j) (+ y i) fill))))

(defun zone-nyan-text-paint-canvas (canvas &rest body)
  "Paint groups of rectangles to CANVAS.
BODY is a list where every three items are the X offset, Y offset
and a list of rectangles.  Each rectangle is represented as a
vector with a X and Y component, width, height and fill color."
  (while body
    (let* ((x-offset (pop body))
           (y-offset (pop body))
           (rects (pop body)))
      (dolist (rect rects)
        (let* ((x (aref rect 0))
               (y (aref rect 1))
               (width (aref rect 2))
               (height (aref rect 3))
               (fill (aref rect 4)))
          (zone-nyan-text-rect canvas (+ x-offset x) (+ y-offset y)
                               width height fill))))))

(defun zone-nyan-text-to-string (canvas)
  "Return a textual representation of CANVAS."
  (with-temp-buffer
    (dotimes (i (length canvas))
      (dotimes (j (length (aref canvas 0)))
        (let* ((color (aref (aref canvas i) j))
               (mappings (cdr (assoc color zone-nyan-palette))))
          (cond
           ((eq zone-nyan-gui-type 'text)
            (let ((fill (plist-get mappings :gui)))
              (insert (propertize "  " 'face `(:background ,fill)))))
           ((eq zone-nyan-term-type 'color)
            (let ((fill (plist-get mappings :term)))
              (insert (propertize "  " 'face `(:background ,fill)))))
           ((eq zone-nyan-term-type 'ascii)
            (insert (plist-get mappings :ascii))))))
      (insert "\n"))
    (buffer-string)))

(defun zone-nyan-text-image (time)
  "Return a buffer string for a point in TIME."
  (let ((width (window-body-width))
        (height (window-body-height)))
    (if (or (< width 80) (< height 40))
        (format "zone-nyan requires a 80x40 canvas\ncurrent dimensions: %dx%d"
                width height)
      (let* ((canvas (zone-nyan-text-canvas 'indigo))
             (frame (mod time 6))
             (star-frame (mod time 12))
             (rainbow-flipped (not (zerop (mod (/ time 2) 2))))
             (pop-tart-offset (if (< frame 2) 0 1))
             (face-x-offset (if (or (zerop frame) (> frame 3)) 0 1))
             (face-y-offset (if (or (< frame 2) (> frame 4)) 0 1)))
        (zone-nyan-text-paint-canvas
         canvas
         -15 11 (zone-nyan-rainbow rainbow-flipped)
         -15 -15 (zone-nyan-stars star-frame)
         4 17 (zone-nyan-tail frame)
         8 26 (zone-nyan-legs frame)
         10 (+ 10 pop-tart-offset) (zone-nyan-pop-tart)
         (+ 20 face-x-offset) (+ 15 face-y-offset) (zone-nyan-face))
        (zone-nyan-text-to-string canvas)))))


;;; frontend

(defun zone-nyan-image (time)
  "Create an image of nyan cat at TIME."
  (if (display-graphic-p)
      (cond
       ((eq zone-nyan-gui-type 'svg)
        (propertize " " 'display
                    (create-image (zone-nyan-svg-image time) 'svg t)))
       ((eq zone-nyan-gui-type 'text)
        (zone-nyan-text-image time))
       (t (user-error "Invalid value for `zone-nyan-gui-type'")))
    (if (memq zone-nyan-term-type '(color ascii))
        (zone-nyan-text-image time)
       (user-error "Invalid value for `zone-nyan-term-type'"))))

(defcustom zone-nyan-interval 0.07
  "Amount of time to wait until displaying the next frame."
  :type 'float
  :group 'zone-nyan)

(defcustom zone-nyan-bg-music-program nil
  "Program to call for playing background music."
  :type '(choice (const :tag "None" nil)
                 string)
  :group 'zone-nyan)

(defcustom zone-nyan-bg-music-args nil
  "Optional list of arguments for `zone-nyan-bg-music-program'."
  :type '(repeat string)
  :group 'zone-nyan)

(defcustom zone-nyan-hide-progress nil
  "Won't report progress information if set."
  :type 'boolean
  :group 'zone-nyan)

(defvar zone-nyan-bg-music-process nil
  "Current BG music process.")

(defvar zone-nyan-progress-timer nil
  "Timer for displaying the progress.
It fires every 100ms.")

(defvar zone-nyan-progress 0
  "Holds the current progress of the timer.")

(defun zone-nyan-report-progress ()
  "Report current nyan progress."
  (message "You've nyaned for %.1f seconds"
           (/ zone-nyan-progress 10.0)))

(defun zone-nyan-progress ()
  "Progress function.
It informs the user just how many seconds they've wasted on
watching nyan cat run."
  (unless zone-nyan-hide-progress
    (zone-nyan-report-progress))
  (setq zone-nyan-progress (1+ zone-nyan-progress)))

;;;###autoload
(defun zone-nyan ()
  "Zone out with nyan cat!"
  (delete-other-windows)
  (internal-show-cursor nil nil)
  (let ((time 0)
        ;; HACK zone aborts on read-only buffers
        (inhibit-read-only t))
    (unwind-protect
        (progn
          (when zone-nyan-bg-music-program
            (condition-case nil
                (setq zone-nyan-bg-music-process
                      (apply 'start-process "zone nyan" nil
                             zone-nyan-bg-music-program
                             zone-nyan-bg-music-args))
              (error
               (message "Couldn't start background music")
               (sit-for 5))))
          (setq zone-nyan-progress 0
                zone-nyan-progress-timer
                (run-at-time 0 0.1 'zone-nyan-progress))
          (while (not (input-pending-p))
            (erase-buffer)
            (insert (zone-nyan-image time))
            (goto-char (point-min))
            (sit-for zone-nyan-interval)
            (setq time (1+ time))))
      (internal-show-cursor nil t)
      (when zone-nyan-bg-music-process
        (delete-process zone-nyan-bg-music-process))
      (when zone-nyan-progress-timer
        (cancel-timer zone-nyan-progress-timer)
        (when zone-nyan-hide-progress
            (zone-nyan-report-progress))))))

;;;###autoload
(defun zone-nyan-preview ()
  "Preview the `zone-nyan' zone program."
  (interactive)
  (let ((zone-programs [zone-nyan]))
    (zone)))

(provide 'zone-nyan)

;;; zone-nyan.el ends here
