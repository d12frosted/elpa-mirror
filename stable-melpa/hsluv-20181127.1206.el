;;; hsluv.el --- hsluv color space conversions -*- coding: utf-8; lexical-binding: t -*-

;; Copyright (c) 2017 Geert Vermeiren
;;
;; Version: 1.0.0
;; Package-Version: 20181127.1206
;; Package-Commit: c3bc5228e30d66e7dee9ff1a0694c2b976862fc0
;; Author: Geert Vermeiren
;; Keywords: color hsluv
;; URL: https://github.com/hsluv/hsluv-emacs
;; Package-Requires: ((seq "2.20"))

;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is furnished to do
;; so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
;; THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package provides an elisp implementation of the HSLUV colorspace
;; conversions as created by Alexei Boronine, and documented on
;; http://www.hsluv.org/

;; HSLuv is a human-friendly alternative to HSL.

;; CIELUV is a color space designed for perceptual uniformity based on human
;; experiments. When accessed by polar coordinates, it becomes functionally
;; similar to HSL with a single problem: its chroma component doesn't fit into
;; a specific range.

;; HSLuv extends CIELUV with a new saturation component that allows you to span
;; all the available chroma as a neat percentage.

;; The reference implementation is written in Haxe and released under
;; the MIT license. It can be found at https://github.com/hsluv/hsluv
;; The math is available under the public domain.

;; The following functions provide the conversions
;; from RGB to/from HSLUV and HPLUV:

;;   (hsluv-hsluv-to-rgb (list H S Luv))
;;   (hsluv-hpluv-to-rgb (list H P Luv))
;;   (hsluv-rgb-to-hsluv (list R G B))
;;   (hsluv-rgb-to-hpluv (list R G B))

;;; Changelog

;; 2017/04/15 v1.0  First version
;; 2018/08/07       Split off testing
;; 2018/10/13       Cleanup for package release in the wild

;;; Code:

(require 'seq)

(defconst hsluv--m
  '((3.240969941904521 -1.537383177570093 -0.498610760293)
    (-0.96924363628087 1.87596750150772 0.041555057407175)
    (0.055630079696993 -0.20397695888897 1.056971514242878)))

(defconst hsluv--minv
  '((0.41239079926595 0.35758433938387 0.18048078840183)
    (0.21263900587151 0.71516867876775 0.072192315360733)
    (0.019330818715591 0.11919477979462 0.95053215224966)))

(defconst hsluv--refY 1.0)
(defconst hsluv--refU 0.19783000664283)
(defconst hsluv--refV 0.46831999493879)

;; CIE LUV constants

(defconst hsluv--kappa 903.2962962)
(defconst hsluv--epsilon 0.0088564516)

(defun hsluv--get-bounds (l)
  "Return CIELUV bounds for a given lightness L.
For a given lightness L, return a list of 6 lines
in slope-intercept form that represent the bounds in CIELUV, stepping
over which will push a value out of the RGB gamut."
  (let* ((L (float l))
         (sub1 (/ (expt (+ L 16) 3) 1560896))
         (sub2 (if (> sub1 hsluv--epsilon)
                   sub1
                 (/ L hsluv--kappa)))
         (bounds '()))
    (reverse
     (dotimes (c 3 bounds)
       (let ((m1 (elt (elt hsluv--m c) 0))
             (m2 (elt (elt hsluv--m c) 1))
             (m3 (elt (elt hsluv--m c) 2)))
         (dotimes (T 2)
           (let ((bottom (+ (* sub2
                               (- (* 632260 m3)
                                  (* 126452 m2)))
                            (* 126452 T)))
                 (top1 (* sub2 (- (* 284517 m1)
                                  (* 94839 m3))))
                 (top2 (- (* L sub2 (+ (* 838422 m3)
                                       (* 769860 m2)
                                       (* 731718 m1)))
                          (* 769860 T L))))
             (setq bounds (cons (list (/ top1 bottom) (/ top2 bottom))
                                bounds)))))))))

(defun hsluv--intersect-line-line (line-a line-b)
  (/ (- (elt line-a 1)
        (elt line-b 1))
     (- (elt line-b 0)
        (elt line-a 0))))

(defun hsluv--distance-from-pole (point)
  (sqrt (apply #'+ (mapcar (lambda (x) (expt x 2)) point))))


(defun hsluv--length-of-ray-until-intersect (theta line)
  (/ (elt line 1)
     (- (sin theta)
        (* (elt line 0)
           (cos theta)))))

(defun hsluv--max-safe-chroma-for-l (L)
  "For given lightness L, return the maximum chroma.
Keeping the chroma value below this number will ensure
that for any hue, the color is within the RGB gamut."
  (let ((bounds (hsluv--get-bounds L))
        (minimum 1.0e+INF))
    (dotimes (i 2 minimum)
      (let* ((m1 (elt (elt bounds i) 0))
             (b1 (elt (elt bounds i) 1))
             (line (list m1 b1))
             (x (hsluv--intersect-line-line line (list (/ -1.0 m1) 0)))
             (length (hsluv--distance-from-pole (list x (+ b1 (* x m1))))))
        (setq minimum (min minimum length))))))

(defun hsluv--max-chroma-for-l-h (L H)
  (let ((hrad (* (/ H 360.0) float-pi 2))
        (bounds (hsluv--get-bounds L))
        (minimum 1.0e+INF))
    (dolist (bound bounds minimum)
      (let ((length (hsluv--length-of-ray-until-intersect hrad bound)))
        (when (> length 0)
          (setq minimum (min minimum length)))))))

(defun hsluv--dot-product (a b)
  "Calculate the dot product of the sequences A and B."
  (apply #'+ (seq-mapn #'* a b)))

;; used for rgb conversions
(defun hsluv--from-linear (c)
  (if (<= c 0.0031308)
      (* 12.92 c)
    (- (* 1.055 (expt c (/ 1 2.4))) 0.055)))

(defun hsluv--to-linear (n)
  (let ((c (float n)))
    (if (> c 0.04045)
        (expt (/ (+ c 0.055) (+ 1 0.055)) 2.4)
      (/ c 12.92))))

(defun hsluv-xyz-to-rgb (tuple)
  "Convert TUPLE from XYZ to RGB color space.
XYZ coordinates are ranging in [0;1] and RGB coordinates in [0;1] range.
TUPLE is a list containing the color's X,Y and Z values.
Returns a list containing the resulting color's red, green and blue."
  (mapcar #'hsluv--from-linear (mapcar (lambda (t2) (hsluv--dot-product t2 tuple)) hsluv--m)))

(defun hsluv-rgb-to-xyz (tuple)
  "Convert TUPLE from RGB to XYZ color space.
RGB coordinates are ranging in [0;1] and XYZ coordinates in [0;1] range.
TUPLE is a list containing the color's R,G and B values.
Returns a list containing the resulting color's XYZ coordinates."
  (let ((rgbl (mapcar #'hsluv--to-linear tuple)))
    (mapcar (lambda (tuple) (hsluv--dot-product tuple rgbl)) hsluv--minv)))

(defun hsluv--y-to-l (Y)
  "Convert Y to L.
http://en.wikipedia.org/wiki/CIELUV
In these formulas, Yn refers to the reference white point. We are using
illuminant D65, so Yn (see refY in Maxima file) equals 1. The formula is
simplified accordingly."
  (if (<= Y hsluv--epsilon)
      (* (/ Y hsluv--refY) hsluv--kappa)
    (- (* 116
          (expt (/ Y hsluv--refY)
                (/ 1.0 3.0)))
       16)))

(defun hsluv--l-to-y (L)
  "Convert L to Y."
  (if (<= L 8)
      (/ (* L hsluv--refY)
         hsluv--kappa)
    (* hsluv--refY
       (expt (/ (+ L 16) 116) 3))))

(defun hsluv-xyz-to-luv (tuple)
  "Convert a TUPLE from XYZ to LUV color space."
  (let* ((X (float (elt tuple 0)))
         (Y (float (elt tuple 1)))
         (Z (float (elt tuple 2)))
         (varU (if (= X 0) 0  (/ (* 4 X)
                                 (+ X
                                    (* 15 Y)
                                    (* 3 Z)))))
         (varV (if (= Y 0) 0 (/ (* 9 Y)
                                (+ X
                                   (* 15 Y)
                                   (* 3 Z)))))
         (L (hsluv--y-to-l Y))
         (U (* 13
               L
               (- varU hsluv--refU)))
         (V (* 13
               L
               (- varV hsluv--refV))))
    (list L U V)))


(defun hsluv-luv-to-xyz (tuple)
  "Convert a TUPLE from LUV to XYZ color space."
  (let ((L (float (elt tuple 0)))
        (U (float (elt tuple 1)))
        (V (float (elt tuple 2))))
    (if (= L 0)
        (list 0 0 0)
      (let* ((varU (+ (/ U (* 13 L)) hsluv--refU))
             (varV (+ (/ V (* 13 L)) hsluv--refV))
             (Y (hsluv--l-to-y L))
             (X (- 0 (/ (* 9 Y varU)
                        (* -4 varV))))
             (Z (- (/ (* 9 Y)
                      (* 3 varV))
                   (* 5 Y)
                   (/ X 3))))
        (list X Y Z)))))

(defun hsluv-luv-to-lch (tuple)
  "Convert a TUPLE from LUV to LCH color space."
  (let* ((L (float (elt tuple 0)))
         (U (float (elt tuple 1)))
         (V (float (elt tuple 2)))
         (C (sqrt (+ (* U U) (* V V))))
         (H 0))
    (when (>= C 0.00000001)
      (setq H (radians-to-degrees (atan V U)))
      (when (< H 0) (setq H (+ H 360.0))))
    (list L C H)))

(defun hsluv-lch-to-luv (tuple)
  "Convert a TUPLE from LCH to LUV color space."
  (let* ((L (float (elt tuple 0)))
         (C (float (elt tuple 1)))
         (H (float (elt tuple 2)))
         (Hrad (degrees-to-radians H))
         (U (* C (cos Hrad)))
         (V (* C (sin Hrad))))
    (list L U V)))

(defun hsluv-hsluv-to-lch (tuple)
  "Convert a TUPLE from HSLuv to LCH color space."
  (let ((H (float (elt tuple 0)))
        (S (float (elt tuple 1)))
        (L (float (elt tuple 2))))
    (cond ((> L 99.9999999)
           (list 100.0 0.0 H))
          ((< L 0.00000001)
           (list 0.0 0.0 H))
          (t
           (list L (* (/ (hsluv--max-chroma-for-l-h L H) 100.0) S) H)))))

(defun hsluv-lch-to-hsluv (tuple)
  "Convert a TUPLE from LCH to HSLuv color space."
  (let ((L (float (elt tuple 0)))
        (C (float (elt tuple 1)))
        (H (float (elt tuple 2))))
    (cond ((> L 99.9999999)
           (list H 0.0 100.0))
          ((< L 0.00000001)
           (list H 0.0 0.0))
          (t
           (list H (* 100.0 (/ C (hsluv--max-chroma-for-l-h L H))) L)))))

(defun hsluv-hpluv-to-lch (tuple)
  "Convert a TUPLE from HPLuv to LCH color space."
  (let ((H (float (elt tuple 0)))
        (S (float (elt tuple 1)))
        (L (float (elt tuple 2))))
    (cond ((> L 99.9999999)
           (list 100.0 0.0 H))
          ((< L 0.00000001)
           (list 0.0 0.0 H))
          (t
           (list L (* (/ (hsluv--max-safe-chroma-for-l L) 100.0) S) H)))))

(defun hsluv-lch-to-hpluv (tuple)
  "Convert a TUPLE from LCH to HPLuv color space."
  (let ((L (float (elt tuple 0)))
        (C (float (elt tuple 1)))
        (H (float (elt tuple 2))))
    (cond ((> L 99.9999999)
           (list H 0.0 100.0))
          ((< L 0.00000001)
           (list H 0.0 0.0))
          (t
           (list H (* 100.0 (/ C (hsluv--max-safe-chroma-for-l L))) L)))))

(defun hsluv-rgb-to-hex (tuple)
  "Convert an RGB TUPLE to a hexadecimal color ('#rrggbb') string."
  (concat "#" (mapconcat (lambda (num) (format "%02x" (* 255 num))) tuple "")))

(defun hsluv-hex-to-rgb (color)
  "Convert a COLOR in hexadecimal notation ('#rrggbb') to float RGB tuple."
  (list (/ (string-to-number (substring color 1 3) 16) 255.0)
        (/ (string-to-number (substring color 3 5) 16) 255.0)
        (/ (string-to-number (substring color 5) 16) 255.0)))

(defun hsluv-lch-to-rgb (tuple)
  "Convert a TUPLE from LCH to RGB color space."
  (hsluv-xyz-to-rgb (hsluv-luv-to-xyz (hsluv-lch-to-luv tuple))))

(defun hsluv-rgb-to-lch (tuple)
  "Convert a TUPLE from RGB to LCH color space."
  (hsluv-luv-to-lch (hsluv-xyz-to-luv (hsluv-rgb-to-xyz tuple))))

(defun hsluv-hsluv-to-rgb (tuple)
  "Convert a TUPLE from HSLuv to RGB color space."
  (hsluv-lch-to-rgb (hsluv-hsluv-to-lch tuple)))

(defun hsluv-hpluv-to-rgb (tuple)
  "Convert a TUPLE from HPLuv to RGB color space."
  (hsluv-lch-to-rgb (hsluv-hpluv-to-lch tuple)))

(defun hsluv-rgb-to-hsluv (tuple)
  "Convert a TUPLE from RGB to HSLuv color space."
  (hsluv-lch-to-hsluv (hsluv-rgb-to-lch tuple)))

(defun hsluv-rgb-to-hpluv (tuple)
  "Convert a TUPLE from RGB to HPLuv color space."
  (hsluv-lch-to-hpluv (hsluv-rgb-to-lch tuple)))

(defun hsluv-hsluv-to-hex (tuple)
  "Convert a TUPLE from HSLuv to RGB hexadecimal notation ('#rrggbb') color space."
  (hsluv-rgb-to-hex (hsluv-hsluv-to-rgb tuple)))

(defun hsluv-hpluv-to-hex (tuple)
  "Convert a TUPLE from HPLuv to RGB hexadecimal notation ('#rrggbb') color space."
  (hsluv-rgb-to-hex (hsluv-hpluv-to-rgb tuple)))

(defun hsluv-hex-to-hsluv (tuple)
  "Convert a TUPLE from RGB hexadecimal notation ('#rrggbb') to HSLuv color space."
  (hsluv-rgb-to-hsluv (hsluv-hex-to-rgb tuple)))

(defun hsluv-hex-to-hpluv (tuple)
  "Convert a TUPLE from RGB hexadecimal notation ('#rrggbb') to HPLuv color space."
  (hsluv-rgb-to-hpluv (hsluv-hex-to-rgb tuple)))

(provide 'hsluv)
;;; hsluv.el ends here
