;;; chroma.el --- Color manipulation library -*- lexical-binding: t -*-

;; Author: Nicolas Martyanoff <nicolas@n16f.net>
;; SPDX-License-Identifier: ISC
;; URL: https://github.com/galdor/chroma
;; Package-Version: 20230503.1210
;; Package-Commit: e6ebe08ce439b0dd8cfd2a0a78abf34f195feb3c
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
;; built-in color.el, chroma.el uses provides a consistent interface, always
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

(defvar chroma-rgb-regexp "#\\([0-9A-Za-z]\\{6\\}\\)"
  "The regular expression used to match hexadecimal RGB colors.")

(defvar chroma-hsl-regexp
  "hsl( *\\([0-9]+\\) *, *\\([0-9]+\\)% *, *\\([0-9]+\\)% *)"
  "The regular expression used to match HSL colors.")

(defun chroma-parse-rgb (string)
  "Parse an hexadecimal RGB color string (e.g. \"#204080\").
Return the three RGB components as a list or NIL if STRING does
not represent an RGB color."
  (if (string-match (chroma--anchored-regexp chroma-rgb-regexp) string)
      (let* ((digits (match-string 1 string))
             (r (string-to-number (substring digits 0 2) 16))
             (g (string-to-number (substring digits 2 4) 16))
             (b (string-to-number (substring digits 4 6) 16)))
        (list r g b))
    (error "Invalid RGB color %S" string)))

(defun chroma-format-rgb (color)
  "Return the hexadecimal representation of an RGB color."
  (let ((r (nth 0 color))
        (g (nth 1 color))
        (b (nth 2 color)))
    (format "#%02x%02x%02x" r g b)))

(defun chroma-parse-hsl (string)
  "Parse a HSL color string (e.g. \"hsl(180, 20%, 40%)\").
Return the three HSL components as a list or NIL if STRING does
not represent a HSL color."
  (if (string-match (chroma--anchored-regexp chroma-hsl-regexp) string)
      (let* ((h (string-to-number (match-string 1 string)))
             (s (/ (string-to-number (match-string 2 string)) 100.0))
             (l (/ (string-to-number (match-string 3 string)) 100.0)))
        (if (and (<= 0 h 360)
                 (<= 0 s 1.0)
                 (<= 0 l 1.0))
            (list h s l)
          (error "Invalid HSL color components %S" (list h s l))))
    (error "Invalid HSL color %S" string)))

(defun chroma-format-hsl (color)
  "Return the string representation of an HSL color."
  (let ((h (nth 0 color))
        (s (nth 1 color))
        (l (nth 2 color)))
    (format "hsl(%d, %.0f%%, %.0f%%)" h (* s 100.0) (* l 100.0))))

(defun chroma-rgb-to-hsl (color)
  "Convert an HSL color to an RGB color."
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

(defun chroma-rgb-string-to-hsl-string (string)
  "Convert an HSL color string to an RGB color string."
  (chroma-format-hsl
   (chroma-rgb-to-hsl
    (chroma-parse-rgb string))))

(defun chroma-hsl-to-rgb (color)
  "Convert an RGB color to an HSL color."
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

(defun chroma-hsl-string-to-rgb-string (string)
  "Convert an RGB color string to an HSL color string."
  (chroma-format-rgb
   (chroma-hsl-to-rgb
    (chroma-parse-hsl string))))

(defun chroma--color-string-at-point-function (regexp)
  (lambda (point)
    (save-excursion
      (goto-char point)
      (let ((line-start (line-beginning-position))
            (line-end (line-end-position)))
        (goto-char line-start)
        (catch 'color
          (while (re-search-forward regexp line-end t)
            (let ((match-start (match-beginning 0))
                  (match-end (match-end 0)))
              (when (<= match-start point match-end)
                (let ((color-string (buffer-substring-no-properties
                                     match-start match-end)))
                  (throw 'color
                         (list color-string match-start match-end)))))))))))

(defun chroma--color-at-point-function (regexp parsing-fn)
  (lambda (point)
    (cl-multiple-value-bind (string start end)
        (funcall (chroma--color-string-at-point-function regexp) point)
      (list (funcall parsing-fn string) start end))))

(defalias 'chroma-rgb-color-at-point
  (chroma--color-at-point-function chroma-rgb-regexp 'chroma-parse-rgb)
  "Return a list containing the value, start and end of the RGB
color at POINT or NIL if POINT is not positioned on a RGB color.")

(defalias 'chroma-rgb-color-string-at-point
  (chroma--color-string-at-point-function chroma-rgb-regexp)
  "Return a list containing the string, start and end of the RGB
color at POINT or NIL if POINT is not positioned on a RGB color.")

(defalias 'chroma-hsl-color-at-point
  (chroma--color-at-point-function chroma-hsl-regexp 'chroma-parse-hsl)
  "Return a list containing the value, start and end of the HSL
color at POINT or NIL if POINT is not positioned on a HSL color.")

(defalias 'chroma-hsl-color-string-at-point
  (chroma--color-string-at-point-function chroma-hsl-regexp)
  "Return a list containing the string, start and end of the HSL
color at POINT or NIL if POINT is not positioned on a HSL color.")

(defun chroma--color-conversion-dwim-function (regexp color-string-at-point-fn
                                                      color-conversion-fn)
  (lambda (start end)
    (interactive "r")
    (chroma--with-undo-amalgamate
     (cond
      ((use-region-p)
       (save-restriction
         (narrow-to-region start end)
         (goto-char (point-min))
         (while (re-search-forward regexp (point-max) t)
           (let ((match-start (match-beginning 0))
                 (match-end (match-end 0))
                 (color-string (match-string-no-properties 0)))
             (replace-region-contents (match-beginning 0) (match-end 0)
                                      (lambda ()
                                        (funcall color-conversion-fn
                                                 color-string)))))))
      (t
       (cl-multiple-value-bind (color-string start end)
           (funcall color-string-at-point-fn (point))
         (replace-region-contents start end
                                  (lambda ()
                                    (funcall color-conversion-fn
                                             color-string)))))))))

(defalias 'chroma-hsl-to-rgb-dwim
  (chroma--color-conversion-dwim-function chroma-hsl-regexp
                                          'chroma-hsl-color-string-at-point
                                          'chroma-hsl-string-to-rgb-string)
  "Convert HSL colors to RGB colors either in the current region if
it is active or undeer the point if it is not.")

(defalias 'chroma-rgb-to-hsl-dwim
  (chroma--color-conversion-dwim-function chroma-rgb-regexp
                                          'chroma-rgb-color-string-at-point
                                          'chroma-rgb-string-to-hsl-string)
  "Convert RGB colors to HSL colors either in the current region if
it is active or undeer the point if it is not.")

(defun chroma--anchored-regexp (regexp)
  "Return a the fully anchored version of REGEXP."
  (concat "^" regexp "$"))

(defmacro chroma--with-undo-amalgamate (&rest body)
  "Evaluate BODY as a single undo group. To be replaced by
`with-undo-amalgamate' once Emacs 29 is released."
  (let ((handle (make-symbol "--handle--")))
    `(let ((,handle (prepare-change-group))
           (undo-outer-limit nil)
           (undo-limit most-positive-fixnum)
           (undo-strong-limit most-positive-fixnum))
       (unwind-protect
           (progn
             (activate-change-group ,handle)
             ,@body)
         (accept-change-group ,handle)
         (undo-amalgamate-change-group ,handle)))))

(provide 'chroma)

;;; chroma.el ends here
