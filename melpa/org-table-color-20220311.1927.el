;;; org-table-color.el --- Add color to your org-mode table cells -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Colin Woodbury
;;
;; Author: Colin Woodbury <colin@fosskers.ca>
;; Maintainer: Colin Woodbury <colin@fosskers.ca>
;; Created: March 10, 2022
;; Modified: March 10, 2022
;; Version: 1.0.0
;; Package-Version: 20220311.1927
;; Package-Commit: 2022f301ef323953c3a0e087a1b601da85e06da1
;; Keywords: data faces lisp
;; Homepage: https://github.com/fosskers/org-table-color
;; Package-Requires: ((emacs "26.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Add color to your org-mode table cells.
;;
;;  The principal function is `org-table-color', which can be passed a function
;;  that produces a face for each table cell. See
;;  `org-table-color--color-by-correlation' for an example.
;;
;;  Or call a built-in styling function like
;;  `org-table-color-correlation-matrix' if you're not concerned with
;;  customisation.
;;
;;  See the Github README for full instructions.
;;
;;; Code:

(require 'org-table)

;;;###autoload
(defun org-table-color (get-face)
  "Color the 'org-mode' table at 'point', given a GET-FACE function.

GET-FACE must accept a single numerical argument (the value of
the cell) and return either a plist representing a face or nil.
When nil, no styling of that cell will occur. Further, no styling
will occur if the cell value is not a number.

See `org-table-color--color-by-correlation' for an example."
  (let* ((lisp (org-table-to-lisp))
         (rows (length lisp))
         (cols (length (car lisp))))
    (save-excursion
      (mapc (lambda (x) (mapc (lambda (y) (org-table-color--color-cell get-face x y))
                              (number-sequence 2 rows)))
            (number-sequence 2 cols)))))

;;;###autoload
(defun org-table-color-correlation-matrix ()
  "Color the 'org-mode' table at 'point' that represents a Correlation Matrix."
  (interactive)
  (org-table-color #'org-table-color--color-by-correlation))

(defun org-table-color--color-cell (get-face x y)
  "Color the cell via a GET-FACE function at the given X and Y coordinates."
  (org-table-goto-line y)
  (org-table-goto-column x)
  (when-let* ((cell (org-table-get y x))
              (nmbr (string-to-number cell))
              (face (funcall get-face nmbr))
              (over (make-overlay (point)
                                  (progn (org-table-end-of-field 1)
                                         (point)))))
    (overlay-put over 'face face)))

(defun org-table-color--color-by-correlation (num)
  "Color a table cell NUM value assuming it's from a correlation matrix.
Yields a plist that represents a face."
  (cond ((>= num 0.5) '(:foreground "black" :background "green"))
        ((>= num 0.3) '(:foreground "black" :background "#90EE90"))
        ((<= num -0.5) '(:foreground "black" :background "red"))
        ((<= num -0.3) '(:foreground "black" :background "orange"))))

(provide 'org-table-color)
;;; org-table-color.el ends here
