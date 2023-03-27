;;; colors.el --- Color manipulation library -*- lexical-binding: t -*-

;; Author: Nicolas Martyanoff <nicolas@n16f.net>
;; URL: https://github.com/galdor/colors
;; Package-Version: 20230319.2026
;; Package-Commit: 173f3d2d3516d32b11b9a7d2f4e9bd17b5cd168e
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.1"))

;; Copyright 2023 Nicolas Martyanoff <nicolas@n16f.net>
;;
;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;; SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
;; IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

;;; Commentary:

;; This package provides utilities to manipulate colors. Compared to the
;; built-in color.el, colors.el uses provides a consistent interface, always
;; accepting and returning colors as lists. It also uses commonly used
;; representation for components: 8 bit values for RGB colors, 0-360 hue for
;; HSL colors.
;;
;; RGB colors are represented as lists of three elements for the red, green
;; and blue components. RGB components are represented as 8 bit integer.
;;
;; HSL colors are represented as lists of three elements for the hue,
;; saturation and lightness. Hue is represented as an integer in [0, 360].
;; Saturation and lightness are represented as floating point numbers in [0.0,
;; 1.0] rounded to two decimal places.

;;; Code:

(defun colors-parse-rgb (string)
  "Parse an hexadecimal RGB color string (e.g. \"#204080\").
Return the three RGB components as a list or NIL if STRING does
not represent an RGB color."
  (when (string-match "^#\\([0-9A-Za-z]\\{6\\}\\)$" string)
    (let* ((digits (match-string 1 string))
           (r (string-to-number (substring digits 0 2) 16))
           (g (string-to-number (substring digits 2 4) 16))
           (b (string-to-number (substring digits 4 6) 16)))
      (list r g b))))

(defun colors-format-rgb (color)
  "Return the hexadecimal representation of the RGB color COLOR."
  (let ((r (nth 0 color))
        (g (nth 1 color))
        (b (nth 2 color)))
    (format "#%02x%02x%02x" r g b)))

(defun colors-parse-hsl (string)
  "Parse a HSL color string (e.g. \"hsl(180, 20%, 40%)\").
Return the three HSL components as a list or NIL if STRING does
not represent a HSL color."
  (when (string-match
         "^hsl( *\\([0-9]+\\) *, *\\([0-9]+\\)% *, *\\([0-9]+\\)% *)$" string)
    (let* ((h (string-to-number (match-string 1 string)))
           (s (/ (string-to-number (match-string 2 string)) 100.0))
           (l (/ (string-to-number (match-string 3 string)) 100.0)))
      (when (and (<= 0 h 360)
                 (<= 0 s 1.0)
                 (<= 0 l 1.0))
        (list h s l)))))

(defun colors-format-hsl (color)
  "Return the string representation of HSL color COLOR."
  (let ((h (nth 0 color))
        (s (nth 1 color))
        (l (nth 2 color)))
    (format "hsl(%d, %.0f%%, %.0f%%)" h (* s 100.0) (* l 100.0))))

(defun colors-rgb-to-hsl (color)
  "Convert the HSL color COLOR to an RGB color."
  (let* ((r (nth 0 color))
         (g (nth 1 color))
         (b (nth 2 color))
         (rf (/ r 255.0))
         (gf (/ g 255.0))
         (bf (/ b 255.0))
         (cmin (min rf gf bf))
         (cmax (max rf gf bf))
         (delta (- cmax cmin))
         (l (/ (+ cmin cmax) 2)))
    (cond
     ((zerop delta)
      (list 0 0.0 (/ (round (* l 100.0)) 100.0)))
     (t
      (let ((h (cond
                ((= cmax rf)
                 (mod (/ (- gf bf) delta) 6))
                ((= cmax gf)
                 (+ (/ (- bf rf) delta) 2))
                ((= cmax bf)
                 (+ (/ (- rf gf) delta) 4))))
            (s (/ delta (- 1.0 (abs (- (* 2.0 l) 1.0))))))
        (list (round (* h 60.0))
              (/ (round (* s 100.0)) 100.0)
              (/ (round (* l 100.0)) 100.0)))))))

(defun colors-hsl-to-rgb (color)
  "Convert the RGB color COLOR to an HSL color."
  (let* ((h (nth 0 color))
         (s (nth 1 color))
         (l (nth 2 color))
         (c (* (- 1.0 (abs (- (* 2.0 l) 1.0))) s))
         (x (* c (- 1.0 (abs (- (mod (/ h 60.0) 2.0) 1.0)))))
         (m (- l (/ c 2.0)))
         (rgb (cond
               ((<=   0 h 59)
                (list c x 0.0))
               ((<=  60 h 119)
                (list x c 0.0))
               ((<= 120 h 179)
                (list 0.0 c x))
               ((<= 180 h 239)
                (list 0.0 x c))
               ((<= 240 h 299)
                (list x 0.0 c))
               ((<= 300 h 359)
                (list c 0.0 x)))))
    (mapcar (lambda (v) (round (* (+ v m) 255.0))) rgb)))

(provide 'colors)

;;; colors.el ends here
