;;; ct.el --- Color Tools - a color api -*- coding: utf-8; lexical-binding: t -*-

;; Copyright (c) 2020 neeasade
;; SPDX-License-Identifier: MIT
;;
;; Version: 0.1
;; Package-Version: 20210219.1344
;; Package-Commit: c302ee94feee0c5efc511e8f9fd8cb2f6dfe3490
;; Author: neeasade
;; Keywords: convenience color theming rgb hsv hsl cie-lab background
;; URL: https://github.com/neeasade/ct.el
;; Package-Requires: ((emacs "26.1") (dash "2.18.0") (hsluv "1.0.0"))

;;; Commentary:
;; neeasade's color tools for Emacs.

;;; Code:

;; There are 3 sections to this file (IE, you may use these bullets as search text):
;; - helpers to build color space functions
;; - color space functions
;; - other color functions

;; conventions:
;; setting the wrap convention for docstrings at ~100 chars.
;; TODO: .editorconfig: spaces, 2 space indent

(require 'color)
(require 'seq)

(require 'hsluv)
(require 'dash)

;; customization:

(defgroup ct nil
  "Utilities for editing individual colors."
  :group 'ct
  :prefix "ct-")

(defcustom ct-always-shorten t
  "Whether results of color functions should ensure format #HHHHHH rather than #HHHHHHHHHHHH."
  :type 'boolean
  :group 'ct)

;;;
;;; helpers to build color space functions
;;;

(defun ct--range (one &optional two step)
  "Create a range from ONE to TWO with step STEP."
  (let* ((start (if two one 0))
          (end (if two two one))
          (step (or step (if (> end start) 1 -1))))
    (cond
      ((= end start) (list start))
      ((> end start)
        (number-sequence start end step))
      ((< end start)
        (number-sequence start end step)))))

(defun ct-clamp (value min max)
  "Make sure VALUE is a number between MIN and MAX inclusive."
  (min max (max min value)))

(defun ct-shorten (c)
  "Optionally transform C #HHHHHHHHHHHH to #HHHHHH."
  (if (= (length c) 7)
    c
    (--> c
      (color-name-to-rgb it)
      `(color-rgb-to-hex ,@ it 2)
      (eval it))))

(defun ct-maybe-shorten (c)
  "Internal function for optionally shortening color C -- see variable 'ct-always-shorten'."
  (if ct-always-shorten
    (ct-shorten c)
    c))

(defun ct-name-to-lab (name &optional white-point)
  "Transform NAME into LAB colorspace with optional lighting assumption WHITE-POINT."
  (--> name
    (color-name-to-rgb it)
    (apply #'color-srgb-to-xyz it)
    (append it (list (or white-point color-d65-xyz)))
    (apply #'color-xyz-to-lab it)))

(defun ct-lab-to-name (lab &optional white-point)
  "Convert LAB color to #HHHHHH with optional lighting assumption WHITE-POINT."
  (->>
    (-snoc lab (or white-point color-d65-xyz))
    (apply #'color-lab-to-xyz)
    (apply #'color-xyz-to-srgb)
    ;; when pulling it out we might die (srgb is not big enough to hold all possible values)
    (-map #'color-clamp)
    (apply #'color-rgb-to-hex)
    (ct-maybe-shorten)))

(defun ct-hsv-to-rgb (H S V)
  "Convert HSV to RGB. Expected values: H: radian, S,V: 0 to 1."
  ;; cf https://peteroupc.github.io/colorgen.html#HSV
  (let* ((pi2 (* pi 2))
          (H (cond
               ((< H 0) (- pi2 (mod (- H) pi2)))
               ((>= H pi2) (mod H pi2))
               (t H)))
          (hue60 (/ (* H 3) pi))
          (hi (floor hue60))
          (f (- hue60 hi))
          (c (* V (- 1 S)))
          (a (* V (- 1 (* S f))))
          (e (* V (- 1 (* S (- 1 f))))))
    (cond
      ((= hi 0) (list V e c))
      ((= hi 1) (list a V c))
      ((= hi 2) (list c V e))
      ((= hi 3) (list c a V))
      ((= hi 4) (list e c V))
      (t (list V c a)))))

;;;
;;; color space functions
;;;

(defun ct-transform-rgb (c transform)
  "Work with a color C in the RGB space using function TRANSFORM. Ranges for RGB are all 0-100."
  (->> c
    (color-name-to-rgb)
    (-map (lambda (p) (* p 100.0)))
    (apply transform)
    (-map (lambda (p) (/ p 100.0)))
    (-map #'color-clamp)
    (apply #'color-rgb-to-hex)
    (ct-maybe-shorten)))

(defun ct-transform-lab (c transform)
  "Work with a color C in the LAB space using function TRANSFORM.
Ranges for LAB are {0-100,-100-100,-100-100}."
  (->> c
    (ct-name-to-lab)
    (apply transform)
    (apply (lambda (L A B)
             (list
               (ct-clamp L 0 100)
               (ct-clamp A -100 100)
               (ct-clamp B -100 100))))
    (ct-lab-to-name)))

(defun ct-transform-lch (c transform)
  "Work with a color C in the LCH space using function TRANSFORM.
Ranges for LCH are {0-100,0-100,0-360}."
  (ct-transform-lab c
    (lambda (&rest lab)
      (->> lab
        (apply #'color-lab-to-lch)
        (apply (lambda (L C H) (list L C (radians-to-degrees H))))
        (apply transform)
        (apply (lambda (L C H) (list L C (degrees-to-radians (mod H 360)))))
        (apply #'color-lch-to-lab)))))

(defun ct-transform-hsl (c transform)
  "Work with a color C in the HSL space using function TRANSFORM.
Ranges for HSL are {0-360,0-100,0-100}."
  (->> c
    (color-name-to-rgb)
    (apply #'color-rgb-to-hsl)
    (apply (lambda (H S L) (list (* 360.0 H) (* 100.0 S) (* 100.0 L))))
    (apply transform)
    (apply (lambda (H S L) (list (/ (mod H 360) 360.0) (/ S 100.0) (/ L 100.0))))
    (apply #'color-hsl-to-rgb)
    (-map #'color-clamp)
    (apply #'color-rgb-to-hex)
    (ct-maybe-shorten)))

(defun ct-transform-hsv (c transform)
  "Work with a color C in the HSV space using function TRANSFORM.
Ranges for HSV are {0-360,0-100,0-100}."
  (->> (color-name-to-rgb c)
    (apply #'color-rgb-to-hsv)
    (funcall (lambda (hsv)
               (apply transform
                 (list
                   (radians-to-degrees (-first-item hsv))
                   (* 100.0 (-second-item hsv))
                   (* 100.0 (-third-item hsv))))))
    ;; from transformed to what our function expects
    (funcall (lambda (hsv)
               (list
                 (degrees-to-radians (-first-item hsv))
                 (color-clamp (/ (-second-item hsv) 100.0))
                 (color-clamp (/ (-third-item hsv) 100.0)))))
    (apply #'ct-hsv-to-rgb)
    (apply #'color-rgb-to-hex)
    (ct-maybe-shorten)))

(defun ct-transform-hpluv (c transform)
  "Work with a color C in the HPLUV space using function TRANSFORM.
Ranges for HPLUV are {0-360,0-100,0-100}."
  (ct-maybe-shorten
    (apply #'color-rgb-to-hex
      (-map #'color-clamp
        (hsluv-hpluv-to-rgb
          (let ((result (apply transform (-> c ct-shorten hsluv-hex-to-hpluv))))
            (list
              (mod (-first-item result) 360.0)
              (ct-clamp (-second-item result) 0 100)
              (ct-clamp (-third-item result) 0 100))))))))

(defun ct-transform-hsluv (c transform)
  "Work with a color C in the HSLUV space using function TRANSFORM.
Ranges for HSLUV are {0-360,0-100,0-100}."
  (ct-maybe-shorten
    (apply #'color-rgb-to-hex
      (-map #'color-clamp
        (hsluv-hsluv-to-rgb
          (let ((result (apply transform (-> c ct-shorten hsluv-hex-to-hsluv))))
            (list
              (mod (-first-item result) 360.0)
              (ct-clamp (-second-item result) 0 100)
              (ct-clamp (-third-item result) 0 100))))))))

;; individual property tweaks:
(defmacro ct--transform-prop (transform index)
  "Internal function for making a TRANSFORM function on property INDEX of a color property list."
  `(,transform c
     (lambda (&rest args)
       (-replace-at ,index
         (if (functionp func-or-val)
           (funcall func-or-val (nth ,index args))
           func-or-val)
         args))))

(defun ct-transform-rgb-r (c func-or-val) "Transform property rgb-r of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-rgb 0))
(defun ct-transform-rgb-g (c func-or-val) "Transform property rgb-g of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-rgb 1))
(defun ct-transform-rgb-b (c func-or-val) "Transform property rgb-b of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-rgb 2))

(defun ct-transform-hsl-h (c func-or-val) "Transform property hsl-h of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsl 0))
(defun ct-transform-hsl-s (c func-or-val) "Transform property hsl-s of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsl 1))
(defun ct-transform-hsl-l (c func-or-val) "Transform property hsl-l of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsl 2))

(defun ct-transform-hsv-h (c func-or-val) "Transform property hsv-h of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsv 0))
(defun ct-transform-hsv-s (c func-or-val) "Transform property hsv-s of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsv 1))
(defun ct-transform-hsv-v (c func-or-val) "Transform property hsv-v of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsv 2))

(defun ct-transform-hsluv-h (c func-or-val) "Transform property hsluv-h of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsluv 0))
(defun ct-transform-hsluv-s (c func-or-val) "Transform property hsluv-s of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsluv 1))
(defun ct-transform-hsluv-l (c func-or-val) "Transform property hsluv-l of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hsluv 2))

(defun ct-transform-hpluv-h (c func-or-val) "Transform property hpluv-h of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hpluv 0))
(defun ct-transform-hpluv-p (c func-or-val) "Transform property hpluv-p of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hpluv 1))
(defun ct-transform-hpluv-l (c func-or-val) "Transform property hpluv-l of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-hpluv 2))

(defun ct-transform-lab-l (c func-or-val) "Transform property lab-l of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lab 0))
(defun ct-transform-lab-a (c func-or-val) "Transform property lab-a of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lab 1))
(defun ct-transform-lab-b (c func-or-val) "Transform property lab-b of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lab 2))

(defun ct-transform-lch-l (c func-or-val) "Transform property lch-l of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lch 0))
(defun ct-transform-lch-c (c func-or-val) "Transform property lch-c of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lch 1))
(defun ct-transform-lch-h (c func-or-val) "Transform property lch-h of C using FUNC-OR-VAL." (ct--transform-prop ct-transform-lch 2))

(defun ct--getter (c transform getter)
  "Internal function for making a GETTER of C using a TRANSFORM function."
  (let ((return))
    (apply transform
      (list c
        (lambda (&rest props)
          (setq return (funcall getter props))
          props)))
    return))

(defun ct-get-rgb (c) "Get rgb representation of color C." (ct--getter c #'ct-transform-rgb #'identity))
(defun ct-get-rgb-r (c) "Get rgb-r representation of color C." (ct--getter c #'ct-transform-rgb #'-first-item))
(defun ct-get-rgb-g (c) "Get rgb-g representation of color C." (ct--getter c #'ct-transform-rgb #'-second-item))
(defun ct-get-rgb-b (c) "Get rgb-b representation of color C." (ct--getter c #'ct-transform-rgb #'-third-item))

(defun ct-get-hsl (c) "Get hsl representation of color C." (ct--getter c #'ct-transform-hsl #'identity))
(defun ct-get-hsl-h (c) "Get hsl-h representation of color C." (ct--getter c #'ct-transform-hsl #'-first-item))
(defun ct-get-hsl-s (c) "Get hsl-s representation of color C." (ct--getter c #'ct-transform-hsl #'-second-item))
(defun ct-get-hsl-l (c) "Get hsl-l representation of color C." (ct--getter c #'ct-transform-hsl #'-third-item))

(defun ct-get-hsv (c) "Get hsv representation of color C." (ct--getter c #'ct-transform-hsv #'identity))
(defun ct-get-hsv-h (c) "Get hsv-h representation of color C." (ct--getter c #'ct-transform-hsv #'-first-item))
(defun ct-get-hsv-s (c) "Get hsv-s representation of color C." (ct--getter c #'ct-transform-hsv #'-second-item))
(defun ct-get-hsv-v (c) "Get hsv-v representation of color C." (ct--getter c #'ct-transform-hsv #'-third-item))

(defun ct-get-hsluv (c) "Get hsluv representation of color C." (ct--getter c #'ct-transform-hsluv #'identity))
(defun ct-get-hsluv-h (c) "Get hsluv-h representation of color C." (ct--getter c #'ct-transform-hsluv #'-first-item))
(defun ct-get-hsluv-s (c) "Get hsluv-s representation of color C." (ct--getter c #'ct-transform-hsluv #'-second-item))
(defun ct-get-hsluv-l (c) "Get hsluv-l representation of color C." (ct--getter c #'ct-transform-hsluv #'-third-item))

(defun ct-get-hpluv (c) "Get hpluv representation of color C." (ct--getter c #'ct-transform-hpluv #'identity))
(defun ct-get-hpluv-h (c) "Get hpluv-h representation of color C." (ct--getter c #'ct-transform-hpluv #'-first-item))
(defun ct-get-hpluv-s (c) "Get hpluv-s representation of color C." (ct--getter c #'ct-transform-hpluv #'-second-item))
(defun ct-get-hpluv-l (c) "Get hpluv-l representation of color C." (ct--getter c #'ct-transform-hpluv #'-third-item))

(defun ct-get-lab (c) "Get lab representation of color C." (ct--getter c #'ct-transform-lab #'identity))
(defun ct-get-lab-l (c) "Get lab-l representation of color C." (ct--getter c #'ct-transform-lab #'-first-item))
(defun ct-get-lab-a (c) "Get lab-a representation of color C." (ct--getter c #'ct-transform-lab #'-second-item))
(defun ct-get-lab-b (c) "Get lab-b representation of color C." (ct--getter c #'ct-transform-lab #'-third-item))

(defun ct-get-lch (c) "Get lch representation of color C." (ct--getter c #'ct-transform-lch #'identity))
(defun ct-get-lch-l (c) "Get lch-l representation of color C." (ct--getter c #'ct-transform-lch #'-first-item))
(defun ct-get-lch-c (c) "Get lch-c representation of color C." (ct--getter c #'ct-transform-lch #'-second-item))
(defun ct-get-lch-h (c) "Get lch-h representation of color C." (ct--getter c #'ct-transform-lch #'-third-item))

;; make colors within our normalized transform functions:
(defun ct--make-color-meta (transform properties)
  "Internal function for creating a color using TRANSFORM function forcing PROPERTIES."
  (funcall transform "#cccccc" (lambda (&rest _) properties)))

(defun ct-make-rgb (R G B) "Make a color using R*G*B properties." (ct--make-color-meta 'ct-transform-rgb (list R G B)))
(defun ct-make-hsl (H S L) "Make a color using H*S*L properties." (ct--make-color-meta 'ct-transform-hsl (list H S L)))
(defun ct-make-hsv (H S V) "Make a color using H*S*V properties." (ct--make-color-meta 'ct-transform-hsv (list H S V)))
(defun ct-make-hsluv (H S L) "Make a color using H*S*L*uv properties." (ct--make-color-meta 'ct-transform-hsluv (list H S L)))
(defun ct-make-hpluv (H P L) "Make a color using H*P*L*uv properties." (ct--make-color-meta 'ct-transform-hpluv (list H P L)))
(defun ct-make-lab (L A B) "Make a color using L*A*B properties." (ct--make-color-meta 'ct-transform-lab (list L A B)))
(defun ct-make-lch (L C H) "Make a color using L*C*H properties." (ct--make-color-meta 'ct-transform-lch (list L C H)))

(defun ct--rotation-meta (transform c interval)
  "Internal function for managing hue rotation in TRANSFORM starting at C by degree count INTERVAL."
  (-map (lambda (offset) (funcall transform c (-partial '+ offset)))
    (if (< 0 interval)
      (number-sequence 0 359 interval)
      (number-sequence 360 1 interval))))

(defun ct-rotation-hsl (c interval) "Perform a hue rotation in HSL space starting with color C by INTERVAL degrees." (ct--rotation-meta 'ct-transform-hsl-h c interval))
(defun ct-rotation-hsv (c interval) "Perform a hue rotation in HSV space starting with color C by INTERVAL degrees." (ct--rotation-meta 'ct-transform-hsv-h c interval))
(defun ct-rotation-hsluv (c interval) "Perform a hue rotation in HSLuv space starting with color C by INTERVAL degrees." (ct--rotation-meta 'ct-transform-hsluv-h c interval))
(defun ct-rotation-hpluv (c interval) "Perform a hue rotation in HPLUV space starting with color C by INTERVAL degrees." (ct--rotation-meta 'ct-transform-hpluv-h c interval))
(defun ct-rotation-lch (c interval) "Perform a hue rotation in LCH space starting with color C by INTERVAL degrees." (ct--rotation-meta 'ct-transform-lch-h c interval))

;;;
;;; other color functions
;;;

;; sRGB <-> linear RGB convertion
;; https://en.wikipedia.org/wiki/SRGB#The_forward_transformation_(CIE_XYZ_to_sRGB)
;; TODO: compare to 'ct-luminance-srgb' -- the comparison value is different though.
(defun ct--linearize (comp)
  "Convert a color COMPonent value from sRGB to linear RGB.
Component value in 0-100 range."
  (let ((c (/ comp 100.0)))
    (* 100
      (if (<= c 0.04045)
        (/ c 12.92)
        (expt (/ (+ c 0.055) 1.055) 2.4)))))

(defun ct--delinearize (comp)
  "Convert a color COMPonent value from linear RGB to sRGB.
Component value in 0-100 range."
  (let ((c (/ comp 100.0)))
    (* 100
       (if (<= c 0.0031308)
           (* c 12.92)
         (- (* 1.055 (expt c (/ 1 2.4))) 0.055)))))

(defun ct-srgb-to-rgb (c)
  "Convert color C from sRGB color space to linear RGB.
Ranges for sRGB color are all 0-100."
  (ct-transform-rgb c
    (lambda (&rest comps)
      (-map 'ct--linearize comps))))

(defun ct-rgb-to-srgb (c)
  "Convert linear color C to sRGB color space.
Ranges for RGB color are all 0-100."
  (ct-transform-rgb c
    (lambda (&rest comps)
      (-map 'ct--delinearize comps))))

(defun ct-lab-lighten (c &optional value)
  "Lighten color C by VALUE in the lab space. Value defaults to a very small amount."
  ;; note: lightening colors is a little more sensitive than darkening them
  ;; the increased default value here reflects that -- so we don't get false
  ;; stops in color iteration
  (ct-transform-lab-l c (-partial '+ (or value 0.7))))

(defun ct-lab-darken (c &optional value)
  "Darken color C by VALUE in the lab space. Value defaults to a very small amount."
  (ct-transform-lab-l c (-rpartial '- (or value 0.5))))

(defun ct-pastel (c &optional Smod Vmod)
  "Make a color C more 'pastel' in the hsluv space -- optionally change the rate of change with SMOD and VMOD."
  ;; cf https://en.wikipedia.org/wiki/Pastel_(color)
  ;; pastel colors belong to a pale family of colors, which, when described in the HSV color space,
  ;; have high value and low saturation.
  (ct-transform-hsv c
    (lambda (H S L)
      (list
        H
        (- S (or Smod 5))
        (+ L (or Vmod 5))))))

(defun ct-luminance-srgb (c)
  "Get the srgb luminance value of C."
  ;; cf https://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
  (let ((rgb (-map
               (lambda (part)
                 (if (<= part 0.03928)
                   (/ part 12.92)
                   (expt (/ (+ 0.055 part) 1.055) 2.4)))
               (color-name-to-rgb c))))
    (+
      (* (nth 0 rgb) 0.2126)
      (* (nth 1 rgb) 0.7152)
      (* (nth 2 rgb) 0.0722))))

(defun ct-contrast-ratio (c1 c2)
  "Get the contrast ratio between C1 and C2."
  ;; cf https://peteroupc.github.io/colorgen.html#Contrast_Between_Two_Colors
  (let ((rl1 (ct-luminance-srgb c1))
         (rl2 (ct-luminance-srgb c2)))
    (/ (+ 0.05 (max rl1 rl2))
      (+ 0.05 (min rl1 rl2)))))

(defun ct-lab-change-whitepoint (c w1 w2)
  "Convert a color C wrt white points W1 and W2 through the lab colorspace."
  (ct-lab-to-name (ct-name-to-lab c w1) w2))

(defun ct-name-distance (c1 c2)
  "Get cie-DE2000 distance between C1 and C2 -- value is 0-100."
  ;; note: there are 3 additional optional params to cie-de2000: compensation for
  ;; {lightness,chroma,hue} (all 0.0-1.0)
  ;; https://en.wikipedia.org/wiki/Color_difference#CIEDE2000
  (apply #'color-cie-de2000 (-map 'ct-name-to-lab (list c1 c2))))

(defun ct-is-light-p (c &optional scale)
  "Determine if C is a light color with lightness in the LAB space.
Optionally override SCALE comparison value."
  (> (-first-item (ct-name-to-lab c)) (or scale 65)))

(defun ct-greaten (c &optional percent)
  "Make a light color C lighter, a dark color C darker (by PERCENT)."
  (ct-shorten
    (if (ct-is-light-p c)
      (color-lighten-name c percent)
      (color-darken-name c percent))))

(defun ct-lessen (c &optional percent)
  "Make a light color C darker, a dark color C lighter (by PERCENT)."
  (ct-shorten
    (if (ct-is-light-p c)
      (color-darken-name c percent)
      (color-lighten-name c percent))))

(defun ct-iterations (start op condition)
  "Do OP on START color until CONDITION is met or op has no effect - return all intermediate steps."
  (let ((colors (list start))
         (iterations 0))
    (while (and (not (funcall condition (-last-item colors)))
             (not (string= (funcall op (-last-item colors)) (-last-item colors)))
             (< iterations 10000))
      (setq iterations (+ iterations 1))
      (setq colors (-snoc colors (funcall op (-last-item colors)))))
    colors))

(defun ct-iterate (start op condition)
  "Do OP on START color until CONDITION is met or op has no effect."
  (-last-item (ct-iterations start op condition)))

(defun ct-tint-ratio (c against ratio)
  "Tint a foreground color C against background color AGAINST until contrast RATIO minimum is reached."
  (ct-iterate c
    (if (ct-is-light-p against)
      'ct-lab-darken
      'ct-lab-lighten)
    (lambda (step) (> (ct-contrast-ratio step against) ratio))))

(defun ct-format-rbga (C &optional opacity)
  "RGBA formatting:
Pass in C and OPACITY 0-100, get a string
representation of C as follows: 'rgba(R, G, B, OPACITY)', where
values RGB are 0-255, and OPACITY is 0-1.0 (default 1.0)."
  (->>
    (ct-get-rgb C)
    (-map (-partial '* (/ 255.0 100)))
    (-map #'round)
    (funcall (lambda (coll) (-snoc coll
                              (/
                                (ct-clamp (or opacity 100) 0 100)
                                100.0))))
    (apply (-partial 'format "rgba(%s, %s, %s, %s)"))))

(defun ct-format-argb (C &optional opacity end)
  "Argb formatting:
Pass in C and OPACITY 0-100, get a string representation of C
as follows: '#AAFFFFFF', where AA is a hex pair for the alpha,
followed by FF times 3 hex pairs for red, green, blue. If END is
truthy, then format will be '#FFFFFFAA'."
  (->>
    (ct-clamp (or opacity 100) 0 100)
    (* (/ 255.0 100))
    (round)
    (format "%02x")
    (funcall (lambda (A)
               (if end
                 (format "#%s%s" (-> C ct-shorten (substring 1)) A)
                 (format "#%s%s" A (-> C ct-shorten (substring 1))))))))

(defun ct-mix-opacity (top bottom opacity)
  "Get resulting color of TOP color with OPACITY overlayed against BOTTOM. Opacity is expected to be 0.0-1.0."
  ;; cf https://stackoverflow.com/questions/12228548/finding-equivalent-color-with-opacity
  (seq-let (r1 g1 b1 r2 g2 b2)
    (append (ct-get-rgb top) (ct-get-rgb bottom))
    (ct-make-rgb
      (+ r2 (* (- r1 r2) opacity))
      (+ g2 (* (- g1 g2) opacity))
      (+ b2 (* (- b1 b2) opacity)))))

(defun ct--colorspace-map (label)
  "Map a LABEL to plist'd utility functions associated with a space. LABEL is one of: rgb hsl hsluv hpluv lch lab hsv."
  (->>
    `(:transform "ct-transform-%s"
       :make "ct-make-%s"
       :get "ct-get-%s"
       :get-1 ,(concat "ct-get-%s-" (string (elt label 0)))
       :get-2 ,(concat  "ct-get-%s-" (string (elt label 1)))
       :get-3 ,(concat "ct-get-%s-" (string (elt label 2))))
    (-partition 2)
    (-map (lambda (parts)
            (list
              (car parts)
              (intern (format (cadr parts) label)))))
    (-flatten)))

(defun ct-gradient (step start end &optional with-ends space)
  "Create a gradient from color START to color END with STEP steps.
Optionally include START and END in results using
WITH-ENDS. Optionally choose a colorspace with SPACE (see
'ct--colorspace-map'). Hue-inclusive colorspaces may see mixed
results."
  ;; NB: this might not go the right direction WRT hue properties
  ;; TODO: account for hue step direction via closeness to 360 or 0.
  (let* ((op-map (ct--colorspace-map (or space "rgb")))
          (step (if with-ends (- step 2) step))
          (get-offsets
            (lambda (start end)
              ;; tolerance
              (if (<= (abs (- end start)) 0.1)
                (-repeat (+ step 2) start)
                (append
                  (ct--range start end (/ (- end start) (float step)))
                  (list end))))))
    (->>
      (-zip-lists
        (funcall (plist-get op-map :get) start)
        (funcall (plist-get op-map :get) end))

      (-map (-applify get-offsets))

      ;; TODO: this is a hack -- sometimes get-offsets is short one -- pad out by the end goal prop.
      (-map
        (lambda (parts)
          (if (< (length parts) step)
            (append parts (-repeat (- step (length parts)) (-last-item parts)))
            parts)))

      (apply #'-zip-lists)
      (-map (-applify (plist-get op-map :make)))
      (funcall
        (lambda (result)
          (if with-ends
            result
            (cdr (-drop-last 1 result))))))))

(defun ct-average-color (space colors)
  "Compute the average color from COLORS in space SPACE. See also: 'ct--colorspace-map'."
  (apply (plist-get (ct--colorspace-map space) :make)
    (-reduce-from
      (lambda (acc new)
        (seq-let (p1 p2 p3 P1 P2 P3)
          (append acc
            (funcall (plist-get (ct--colorspace-map space) :get) new))
          (list
            (/ (+ P1 p1) 2.0)
            (/ (+ P2 p2) 2.0)
            (/ (+ P3 p3) 2.0))))
      (funcall (plist-get (ct--colorspace-map space) :get)
        (-first-item colors))
      (cdr colors))))

(provide 'ct)
;;; ct.el ends here
