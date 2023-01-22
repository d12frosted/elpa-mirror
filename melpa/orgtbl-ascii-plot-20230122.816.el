;;; orgtbl-ascii-plot.el --- ascii-art bar plots in org-mode tables

;; Copyright (C) 2013-2023  Thierry Banel

;; Author: Thierry Banel  tbanelwebmin at free dot fr
;;         Michael Brand
;; Version: 1.1
;; Package-Version: 20230122.816
;; Package-Commit: 4160128045b271bc1aef3d14dbf0c5b53ae58bd2
;; Keywords: org, table, ascii, plot

;; orgtbl-ascii-plot is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; orgtbl-ascii-plot is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Notice! ----------------------------------
;; This package is now part of Org Mode.
;; It is no longer needed as a separate Melpa package.
;;
;; Standard key-binding is now `C-c " a`.
;; -------------------------------------------
;;
;;
;; Detailed documentation is here:
;; http://orgmode.org/worg/org-contrib/orgtbl-ascii-plot.html

;; Put the cursor in a column containing numerical values
;; of an Org-Mode table,
;; type C-c " a
;; A new column is added with a bar plot.
;; When the table is refreshed (C-u C-c *),
;; the plot is updated to reflect the new values.
;;
;; Example:
;; | ! |  x |    sin(x/4) |              |
;; |---+----+-------------+--------------|
;; | # |  0 |           0 | WWWWWW       |
;; | # |  1 |  0.32719470 | WWWWWWWW     |
;; | # |  2 |  0.61836980 | WWWWWWWWWh   |
;; | # |  3 |  0.84147098 | WWWWWWWWWWW  |
;; | # |  4 |  0.97193790 | WWWWWWWWWWWV |
;; | # |  5 |  0.99540796 | WWWWWWWWWWWW |
;; | # |  6 |  0.90929743 | WWWWWWWWWWWu |
;; | # |  7 |  0.72308588 | WWWWWWWWWW-  |
;; | # |  8 |  0.45727263 | WWWWWWWWh    |
;; | # |  9 |  0.14112001 | WWWWWWV      |
;; | # | 10 | -0.19056796 | WWWWH        |
;; | # | 11 | -0.50127705 | WWW          |
;; | # | 12 | -0.75680250 | Wu           |
;; | # | 13 | -0.92901450 | ;            |
;; | # | 14 | -0.99895492 |              |
;; | # | 15 | -0.95892427 | :            |
;; | # | 16 | -0.81332939 | W.           |
;; | # | 17 | -0.57819824 | WWu          |
;; | # | 18 | -0.27941550 | WWWW-        |
;; | # | 19 | 0.050127010 | WWWWWW-      |
;; | # | 20 |  0.37415123 | WWWWWWWW:    |
;; | # | 21 |  0.65698660 | WWWWWWWWWH   |
;; | # | 22 |  0.86749687 | WWWWWWWWWWW: |
;; | # | 23 |  0.98250779 | WWWWWWWWWWWH |
;; | # | 24 |  0.98935825 | WWWWWWWWWWWH |
;; | # | 25 |  0.88729411 | WWWWWWWWWWW- |
;; | # | 26 |  0.68755122 | WWWWWWWWWW.  |
;; | # | 27 |  0.41211849 | WWWWWWWWu    |
;; | # | 28 | 0.091317236 | WWWWWWu      |
;; | # | 29 | -0.23953677 | WWWWl        |
;; | # | 30 | -0.54402111 | WWh          |
;; | # | 31 | -0.78861628 | W-           |
;; #+TBLFM: $3=sin($x/3);R::$4='(orgtbl-ascii-draw $3 -1 1)

;;; Requires:
(require 'org)
(require 'org-table)
(require 'easymenu)

;;; Code:

(defun orgtbl-ascii-draw (value min max &optional width characters)
  "Draws an ascii bar in a table.
    VALUE is a the value to plot, the width of the bar to draw.
    A value equal to MIN will be displayed as empty (zero width bar).
    A value equal to MAX will draw a bar filling all the WIDTH.
    WIDTH is the expected width in characters of the column.
    CHARACTERS is a string of characters that will compose the bar,
    with shades of grey from pure white to pure black.
    It defaults to a 10 characters string of regular ascii characters.
    "
  (unless characters (setq characters " .:;c!lhVHW"))
  (unless width (setq width 12))
  (if (stringp value)
      (setq value (string-to-number value)))
  (setq value (* (/ (- (+ value 0.0) min) (- max min)) width))
  (cond
   ((< value     0) "too small")
   ((> value width) "too large")
   (t
    (let ((len (1- (length characters))))
      (concat
       (make-string (floor value) (elt characters len))
       (string (elt characters
		    (floor (* (- value (floor value)) len)))))))))
  
;;;###autoload
(defun orgtbl-ascii-plot (&optional ask)
  "Draws an ascii bars plot in a column, out of values found in another column.
  A numeric prefix may be given to override the default 12 characters wide plot.
    "
  (interactive "P")
  (let ((col (org-table-current-column))
	(min  1e999)
	(max -1e999)
	(length 12)
	(table (org-table-to-lisp)))
    (cond ((consp ask)
	   (setq length
		 (or
		  (read-string "Length of column [12] " nil nil 12)
		  12)))
	  ((numberp ask)
	   (setq length ask)))
    (mapc
     (lambda (x)
       (when (consp x)
	 (setq x (nth (1- col) x))
	 (when (string-match
		"^[-+]?\\([0-9]*[.]\\)?[0-9]*\\([eE][+-]?[0-9]+\\)?$"
		x)
	   (setq x (string-to-number x))
	   (if (> min x) (setq min x))
	   (if (< max x) (setq max x)))))
     (or (memq 'hline table) table)) ;; skip table header if any
    (org-table-insert-column)
    (org-table-move-column-right)
    (org-table-store-formulas
     (cons
      (cons
       (concat "$" (number-to-string (1+ col)))
       (format "'(%s $%s %s %s %s)"
	       "orgtbl-ascii-draw" col min max length))
      (org-table-get-stored-formulas)))
    (org-table-recalculate t)))

;;;###autoload
(defun orgtbl-ascii-plot-bindings ()
  (org-defkey org-mode-map "\C-c\"a"  'orgtbl-ascii-plot)
  (org-defkey org-mode-map "\C-c\"g"  'org-plot/gnuplot)
  (easy-menu-add-item
   org-tbl-menu '("Column")
   ["Ascii plot" orgtbl-ascii-plot t]))

;;;###autoload
(if (functionp 'org-defkey)
    (orgtbl-ascii-plot-bindings) ;; org-mode already loaded
  (setq org-load-hook            ;; org-mode will be loaded later
	(cons 'orgtbl-ascii-plot-bindings
	      (if (boundp 'org-load-hook)
		  org-load-hook))))

;; Example of extension: unicode characters
;; Here are two examples of different styles.

;; Unicode block characters are used to give a smooth effect.
;; See http://en.wikipedia.org/wiki/Block_Elements
;; Use one of those drawing functions
;; - orgtbl-ascii-draw   (the default ascii)
;; - orgtbl-uc-draw-grid (unicode with a grid effect)
;; - orgtbl-uc-draw-cont (smooth unicode)

;; This is best viewed with the "DejaVu Sans Mono" font
;; (use M-x set-default-font).

;; Be aware that unicode support is not available everywhere.
;; For instance, LaTex export will not work.
;; If you plan to export your Org document,
;; either draw pure ascii plots,
;; or use ascii plots only for quick and throwable visualization.

(defun orgtbl-uc-draw-grid (value min max &optional width)
  "Draws an ascii bar in a table.
    It is a variant of orgtbl-ascii-draw with Unicode block characters,
    for a smooth display.
    Bars appear as grids (to the extend the font allows).
    "
  ;; http://en.wikipedia.org/wiki/Block_Elements
  ;; best viewed with the "DejaVu Sans Mono" font
  (orgtbl-ascii-draw value min max width " \u258F\u258E\u258D\u258C\u258B\u258A\u2589"))
  
(defun orgtbl-uc-draw-cont (value min max &optional width)
  "Draws an ascii bar in a table.
    It is a variant of orgtbl-ascii-draw with Unicode block characters,
    for a smooth display.
    Bars are solid (to the extend the font allows).
    "
  (orgtbl-ascii-draw value min max width " \u258F\u258E\u258D\u258C\u258B\u258A\u2589\u2588"))

(provide 'orgtbl-ascii-plot)
;;; orgtbl-ascii-plot.el ends here
