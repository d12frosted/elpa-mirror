;;; contrast-color.el --- Pick best contrast color for you -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Yuta Yamada

;; Author: Yuta Yamada <cokesboy[at]gmail.com>
;; URL: https://github.com/yuutayamada/contrast-color-el
;; Package-Version: 20160903.1807
;; Package-Commit: c5fb77a211ebbef3185ada37bea7420534c33f94
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5"))
;; Keywords: color, convenience

;;; The MIT License (MIT)

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; This package only provide a single function that return a contrast
;; color using CIEDE2000 algorithm.
;;
;;
;; Usage:
;;
;;   (contrast-color "#ff00ff") ; -> "#1b5e20"
;;
;;                  or
;;
;;   (contrast-color "Brightmagenta") ; -> "#1b5e20"
;;
;;
;; Note that as default color candidates, this package uses
;; ‘contrast-color-material-colors’ variable, which is defined based
;; on Google’s material design, but if you want to change this color
;; definition you can do like this:
;;
;;    (contrast-color-set '("black" "white"))
;;
;; But keep in mind that providing many colors may increase calculation time.
;;
;;; Code:

(require 'color)
(require 'cl-lib)

(defgroup contrast-color nil "contrast-color group"
  :group 'convenience)

(defcustom contrast-color-candidates nil ; initial value is set in end of this file
  "List of colors.  One of those colors is used as the contrast color.
As the default value, ‘contrast-color-material-colors’ is used.
You can change this variable via ‘contrast-color-set’."
  :group 'contrast-color
  :type '(repeat :tag "list of colors" string))

;; TODO: make this variable saves when users exit Emacs, so don’t need
;; same calculation again.
(defcustom contrast-color-cache nil
  "Alist of specified base color and contrast color."
  :group 'contrast-color
  :type '(choice
          (const :tag "Initial value" nil)
          (repeat :tag "Cons sell of specified color and contrast color"
                  (cons string string))))

(defcustom contrast-color-use-hex-name t
  "If non-nil, returned color name will be hex value."
  :group 'contrast-color
  :type 'bool)

(defvar contrast-color-predicate-function 'contrast-color-predicate-default
  "Predicate function, which takes two arguments.
First argument is base color’s category and second argument is
candidate color’s category.")

(defvar contrast-color--lab-cache nil
  "Internal cache.")

(defvar contrast-color-debug nil)

;;;;;;;;;;;;;;;;
;; Functions

(defun contrast-color--get-lab (color)
  "Get CIE l*a*b from COLOR."
  (apply 'color-srgb-to-lab (color-name-to-rgb color)))

(defun contrast-color--compute-core (base-color)
  "Return alist of (color-of-candidate . ciede2000).
As the reference BASE-COLOR will be used to compare on the process."
  (let* ((candidates contrast-color-candidates)
         (b-lab (contrast-color--get-lab base-color))
         (colors-&-labs
          (or contrast-color--lab-cache
              (setq contrast-color--lab-cache
                    (contrast-color--convert-lab candidates)))))
    (let ((result (contrast-color--filter b-lab colors-&-labs)))
      (cl-loop for (c-name . c-lab) in result
               collect (contrast-color--examine b-lab c-lab c-name)))))

(defun contrast-color--filter (base-lab colors-&-labs)
  (cl-loop with rank0 = '()
           with rank1 = '()
           with rank2 = '()
           with rank3 = '()
           with b-category = (contrast-color--categorize base-lab)
           for (c-name . data) in colors-&-labs
           for c-category = (cdar data)
           for c-lab = (cl-cdadr data)
           if (funcall contrast-color-predicate-function b-category c-category)
           do (cl-case it
                (0 (push (cons c-name c-lab) rank0))
                (1 (push (cons c-name c-lab) rank1))
                (2 (push (cons c-name c-lab) rank2))
                (3 (push (cons c-name c-lab) rank3)))
           finally return (prog1 (or rank3 rank2 rank1 rank0)
                            (contrast-color--debug-print rank0 rank1 rank2 rank3))))

(defun contrast-color--convert-lab (color-candidates)
  "Convert COLOR-CANDIDATES to l*a*b style."
  (cl-loop for c in color-candidates
           for lab = (contrast-color--get-lab c)
           collect (cons c `((category . ,(contrast-color--categorize lab))
                             (lab . ,lab)))))

(defun contrast-color--categorize (lab)
  "Categorize LAB."
  ;; ΔL* lightness and darkness (+ = lighter, - = darker)
  ;; Δa* red and green (+ = redder, - = greener)
  ;; Δb* yellow and blue (+ = yellower, - = bluer)
  ;; http://www.colourphil.co.uk/lab_lch_colour_space.shtml
  (cl-loop for order in '(L a b)
           collect (contrast-color--categoraize-1 order lab)))

(defun contrast-color--categoraize-1 (key lab)
  "Classify LAB’s containing rate."
  (setq lab (nth (cl-case key (L 0) (a 1) (b 2)) lab))
  (cl-case key
    (L     ; range 0 ~ 100
     (cond
      ((and (<=  0.0 lab) (<  lab  20.0)) 'lab-0-20)
      ((and (<= 20.0 lab) (<  lab  40.0)) 'lab-20-40)
      ((and (<= 40.0 lab) (<  lab  60.0)) 'lab-40-60)
      ((and (<= 60.0 lab) (<  lab  80.0)) 'lab-60-80)
      ((and (<= 80.0 lab) (<= lab 100.0)) 'lab-80-100)
      (t (error "Can not happen (L) %f" lab))))
    ((a b) ; range -128 ~ +127
     (cond
      ((and (<= -128.0 lab) (<  lab -77.0)) 'lab-0-20)
      ((and (<=  -77.0 lab) (<  lab -26.0)) 'lab-20-40)
      ((and (<=  -26.0 lab) (<  lab  25.0)) 'lab-40-60)
      ((and (<=   25.0 lab) (<  lab  76.0)) 'lab-60-80)
      ((and (<=   76.0 lab) (<= lab 127.0)) 'lab-80-100)
      (t (error "Can not happen (%s) %f" key lab))))))

(defun contrast-color-predicate-default (base contrast)
  "Default predicate function.
Return non-nil if BASE and CONTRAST’s category doesn't match.
You can return 0 to 3.  3 is checked first and 0 is last."
  (cl-destructuring-bind (b-l b-a b-b c-l c-a c-b) (append base contrast)
    (cl-loop for (b-lab . c-lab) in `((,b-l . ,c-l) (,b-a . ,c-a) (,b-b . ,c-b))
             collect (contrast-color--filter-Lab b-lab c-lab) into list-of-t
             ;; Count number of t; 3 is most high rank
             finally return (length (delq nil list-of-t)))))

(defun contrast-color--filter-Lab (b-rate c-rate)
  (cl-case b-rate
    ((lab-0-20 lab-20-40)   (memq c-rate '(lab-60-80 lab-80-100)))
    (lab-40-60              (memq c-rate '(lab-0-20  lab-80-100)))
    ((lab-60-80 lab-80-100) (memq c-rate '(lab-0-20  lab-20-40)))))

;; TODO: add an advice to debug distance
(defun contrast-color--examine (color1 color2 color2-name)
  "Examine distance of COLOR1 and COLOR2.
Return pair of (color-distance . COLOR2-NAME)."
  (cons (color-cie-de2000 color1 color2) color2-name))

(defun contrast-color--compute (color)
  "Return contrast color against COLOR."
  (cl-loop
   with cie-and-colors = (contrast-color--compute-core color)
   for (cie . c) in cie-and-colors
   for best = (cons cie c) then (if (< (car best) cie) (cons cie c) best)
   finally return (cdr best)))

;;;###autoload
(defun contrast-color (color)
  "Return most contrasted color against COLOR.
The return color picked from ‘contrast-color-candidates’.
The algorithm is used CIEDE2000. See also ‘color-cie-de2000’ function."
  (let* ((base-color (downcase color))
         (cached-color (assoc-default base-color contrast-color-cache)))
    (if cached-color
        cached-color
      (let ((c (contrast-color--format (contrast-color--compute base-color))))
        (add-to-list 'contrast-color-cache (cons base-color c))
        c))))

(defun contrast-color--format (color)
  "Format color name.
If ‘contrast-color-use-hex-name’ is non-nil, convert COLOR name to hex form."
  (downcase
   (if (and contrast-color-use-hex-name
            (not (eq ?# (string-to-char color))))
       (apply 'color-rgb-to-hex (color-name-to-rgb color))
     color)))

;;;###autoload
(defun contrast-color-set (colors)
  "Set list of COLORS to ‘contrast-color-candidates’."
  (setq contrast-color-candidates colors
        contrast-color--lab-cache nil))

(defun contrast-color--debug-print (&rest args)
  (when contrast-color-debug
    (cl-loop for i from 0 to (length args)
             do (message "rank%d: %d" i (nth i args)))))

;; https://material.google.com/style/color.html
;; license: http://zavoloklom.github.io/material-design-color-palette/license.html
(defconst contrast-color-material-colors
  '(; reds
    "#FFEBEE" "#FFCDD2" "#EF9A9A" "#E57373" "#EF5350" "#F44336" "#E53935"
    "#D32F2F" "#C62828" "#B71C1C" "#FF8A80" "#FF5252" "#FF1744" "#D50000"
    ;; pinks
    "#FCE4EC" "#F8BBD0" "#F48FB1" "#F06292" "#EC407A" "#E91E63" "#D81B60"
    "#C2185B" "#AD1457" "#880E4F" "#FF80AB" "#FF4081" "#F50057" "#C51162"
    ;; purples
    "#F3E5F5" "#E1BEE7" "#CE93D8" "#BA68C8" "#AB47BC" "#9C27B0" "#8E24AA"
    "#7B1FA2" "#6A1B9A" "#4A148C" "#EA80FC" "#E040FB" "#D500F9" "#AA00FF"
    ;; deep purple
    "#EDE7F6" "#D1C4E9" "#B39DDB" "#9575CD" "#7E57C2" "#673AB7" "#5E35B1"
    "#512DA8" "#4527A0" "#311B92" "#B388FF" "#7C4DFF" "#651FFF" "#6200EA"
    ;; indigo
    "#E8EAF6" "#C5CAE9" "#9FA8DA" "#7986CB" "#5C6BC0" "#3F51B5" "#3949AB"
    "#303F9F" "#283593" "#1A237E" "#8C9EFF" "#536DFE" "#3D5AFE" "#304FFE"
    ;; blue
    "#E3F2FD" "#BBDEFB" "#90CAF9" "#64B5F6" "#42A5F5" "#2196F3" "#1E88E5"
    "#1976D2" "#1565C0" "#0D47A1" "#82B1FF" "#448AFF" "#2979FF" "#2962FF"
    ;; light blue
    "#E1F5FE" "#B3E5FC" "#81D4fA" "#4fC3F7" "#29B6FC" "#03A9F4" "#039BE5"
    "#0288D1" "#0277BD" "#01579B" "#80D8FF" "#40C4FF" "#00B0FF" "#0091EA"
    ;; cyan
    "#E0F7FA" "#B2EBF2" "#80DEEA" "#4DD0E1" "#26C6DA" "#00BCD4" "#00ACC1"
    "#0097A7" "#00838F" "#006064" "#84FFFF" "#18FFFF" "#00E5FF" "#00B8D4"
    ;; teal
    "#E0F2F1" "#B2DFDB" "#80CBC4" "#4DB6AC" "#26A69A" "#009688" "#00897B"
    "#00796B" "#00695C" "#004D40" "#A7FFEB" "#64FFDA" "#1DE9B6" "#00BFA5"
    ;; green
    "#E8F5E9" "#C8E6C9" "#A5D6A7" "#81C784" "#66BB6A" "#4CAF50" "#43A047"
    "#388E3C" "#2E7D32" "#1B5E20" "#B9F6CA" "#69F0AE" "#00E676" "#00C853"
    ;; light green
    "#F1F8E9" "#DCEDC8" "#C5E1A5" "#AED581" "#9CCC65" "#8BC34A" "#7CB342"
    "#689F38" "#558B2F" "#33691E" "#CCFF90" "#B2FF59" "#76FF03" "#64DD17"
    ;; lime
    "#F9FBE7" "#F0F4C3" "#E6EE9C" "#DCE775" "#D4E157" "#CDDC39" "#C0CA33"
    "#A4B42B" "#9E9D24" "#827717" "#F4FF81" "#EEFF41" "#C6FF00" "#AEEA00"
    ;; yellow
    "#FFFDE7" "#FFF9C4" "#FFF590" "#FFF176" "#FFEE58" "#FFEB3B" "#FDD835"
    "#FBC02D" "#F9A825" "#F57F17" "#FFFF82" "#FFFF00" "#FFEA00" "#FFD600"
    ;; amber
    "#FFF8E1" "#FFECB3" "#FFE082" "#FFD54F" "#FFCA28" "#FFC107" "#FFB300"
    "#FFA000" "#FF8F00" "#FF6F00" "#FFE57F" "#FFD740" "#FFC400" "#FFAB00"
    ;; orange
    "#FFF3E0" "#FFE0B2" "#FFCC80" "#FFB74D" "#FFA726" "#FF9800" "#FB8C00"
    "#F57C00" "#EF6C00" "#E65100" "#FFD180" "#FFAB40" "#FF9100" "#FF6D00"
    ;; deep orange
    "#FBE9A7" "#FFCCBC" "#FFAB91" "#FF8A65" "#FF7043" "#FF5722" "#F4511E"
    "#E64A19" "#D84315" "#BF360C" "#FF9E80" "#FF6E40" "#FF3D00" "#DD2600"
    ;; brown
    "#EFEBE9" "#D7CCC8" "#BCAAA4" "#A1887F" "#8D6E63" "#795548" "#6D4C41"
    "#5D4037" "#4E342E" "#3E2723"
    ;; grey
    "#FAFAFA" "#F5F5F5" "#EEEEEE" "#E0E0E0" "#BDBDBD" "#9E9E9E" "#757575"
    "#616161" "#424242" "#212121"
    ;; blue grey
    "#ECEFF1" "#CFD8DC" "#B0BBC5" "#90A4AE" "#78909C" "#607D8B" "#546E7A"
    "#455A64" "#37474F" "#263238"
    ;; Black and white
    "#000000" "#ffffff"))

(unless contrast-color-candidates
  (setq contrast-color-candidates contrast-color-material-colors))

(provide 'contrast-color)
;;; contrast-color.el ends here
