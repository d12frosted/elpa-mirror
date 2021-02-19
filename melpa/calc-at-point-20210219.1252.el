;;; calc-at-point.el --- Perform calculations at point or over selection -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/calc-at-point
;; Package-Version: 20210219.1252
;; Package-Commit: 0c1a9e94b519b0edb0abcbacdf6101eea2f2a524
;; Version: 1.0
;; Package-Requires: ((emacs "26") (dash "2.18.0"))
;; Keywords: convenience

;; calc-at-point is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; calc-at-point is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with calc-at-point.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package allows for calculations to be run at point or
;; over a selection.
;; It supports repeating last calculation using `calc-at-point-repeat-last'

;;; Code:
(require 'dash)
(require 'calc)
(require 'thingatpt)

(defvar calc-at-point-last-calculation
  "The last calculation.  Can be repeated using `calc-at-point-repeat-last'.")

;; * Calculate
(defun calc-at-point-calculate (func thing &optional bounds)
  "The main function used to apply calculations to buffer contents.
FUNC is the calculation to be performed and should only accept one argument,
that argument will be the number at point.
THING is a function with zero arguments returning a cons cell with the bounds
of the thing at point.
BOUNDS allows you to supply the bounds of where the number is located.
This is used to increase performance while running this function over all
numbers in selection."
  (let ((pt (point)))
    (save-excursion
      (let* ((num-bounds (or bounds (funcall thing)))
	     (num (string-to-number (buffer-substring-no-properties (car num-bounds) (cdr num-bounds))))
	     (result (funcall func num)))
	(unless (eq num result)
	  (delete-region (car num-bounds) (cdr num-bounds))
	  (goto-char (car num-bounds))
	  (insert (number-to-string result)))))
    (goto-char pt)))

;; ** Range
(defun calc-at-point-calculate-range (func beg end thing thing-regex)
  "A wrapper to apply `calc-at-point-calculate' at every line in range.
FUNC is the calculation to be performed and should only accept one argument,
that argument will be the number at point.
BEG and END specifies in what region this function will run.
THING is a function with zero arguments returning a cons cell with the bounds
of the thing at point. THING-REGEX is a regex of what the THING looks like,
used to quickly collect the bounds of all THINGs in the buffer."
  (mapc (apply-partially #'calc-at-point-calculate func thing)
	(calc-at-point-get-all-things beg end #'calc-at-point-get-number thing-regex)))

(defun calc-at-point-get-all-things (beg end thing thing-regex)
  "Gets the bounds of all things specified by THING-REGEX in region BEG END.
BEG and END specifies in what region this function will run.
THING-REGEX is a regex of what the THING looks like,
used to quickly collect the bounds of all THINGs in the buffer.
THING is a function with zero arguments returning a cons cell with the bounds
of the thing at point."
  (save-excursion
    (let* ((numbers '())
	   (largest (max beg end))
	   (smallest (min beg end)))
      (goto-char smallest)
      (while (and
	      (search-forward-regexp thing-regex nil t)
	      ;; Add 1 so that numbers just inside selection box are also included
	      (< (point) (+ 1 largest)))
	(push (funcall thing) numbers)
	(goto-char (cdr (car numbers))))
      numbers)))

;; ** Wrappers
(defun calc-at-point-run (thing thing-regex &optional func beg end)
  "Run FUNC at THING at point.
Or if selection is active, run it on every THING between within selection.
FUNC is the calculation to be performed and should only accept one argument,
that argument will be the number at point.
BEG and END specifies in what region this function will run.
THING is a function that returns the bounds of the thing to apply the
calculate operation on, by default `calc-at-point-get-number' is used.
THING-REGEX is a regex of what the THING looks like,
it's used to quickly collect the bounds of all THINGs in the buffer."
  (when func
    (setq calc-at-point-last-calculation func))

  (let ((func-final (or func calc-at-point-last-calculation)))
    (unless func-final
      (error "Error: Can't repeat last calculation as no calculations have been performed yet"))

    (if (and beg end)
	(calc-at-point-calculate-range func-final beg end thing thing-regex)
      (if mark-active
	  (calc-at-point-calculate-range func-final (point) (mark) thing thing-regex)
	(calc-at-point-calculate func-final thing nil)))))

(defun calc-at-point-run-input (thing thing-regex prompt func &optional beg end)
  "Ask the user for a number then apply that number to FUNC.
PROMPT is the prompt text to use for `completing-read'.
FUNC is the calculation to be performed and should only accept two arguments,
the first one is the user input, the second one is the number at point in
the buffer.
BEG and END specifies in what region this function will run.
THING is a function that returns the bounds of the thing to apply the
calculate operation on, by default `calc-at-point-get-number' is used.
THING-REGEX is a regex of what the THING looks like,
it's used to quickly collect the bounds of all THINGs in the buffer."
  (let* ((input-raw (completing-read prompt nil))
	 (input (string-to-number input-raw)))
    (if (string= input-raw "")
	(calc-at-point-repeat-last)
      (calc-at-point-run thing thing-regex (apply-partially func input) beg end))))

;; * Default get number function
(defvar calc-at-point-get-number-regex "-?[0-9]+\\.?[0-9]*")

(defun calc-at-point-get-number ()
  "Return the bounds of the number at point."
  (let ((thing (thing-at-point-looking-at calc-at-point-get-number-regex 500)))
    (when thing
      (let ((beginning (match-beginning 0))
	    (end (match-end 0)))
	(cons beginning end)))))

;; * Operators
;; ** Misc
;;;###autoload
(defun calc-at-point-repeat-last (&optional beg end)
  "Repeats the last calculation.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex nil beg end))

;;;###autoload
(defun calc-at-point-quick-calc (&optional beg end)
  "Run number at point through `quick-calc'.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex
		     (lambda (a) (car (calc-do-alg-entry (number-to-string a)))) beg end))

;; ** 2 arg
;;;###autoload
(defun calc-at-point-add (&optional beg end)
  "Run addition on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "+ " '+ beg end))

;;;###autoload
(defun calc-at-point-sub (&optional beg end flip)
  "Run subtraction on number at point.
BEG and END specifies in what region this function will run.
FLIP flips the order the operation is made in."
  (interactive)
  (if flip
      (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "(flip) - " '- beg end)
    (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "- " (-flip '-) beg end)))

;;;###autoload
(defun calc-at-point-mult (&optional beg end)
  "Run multiplication on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "* " '* beg end))

;;;###autoload
(defun calc-at-point-div (&optional beg end flip)
  "Run division on number at point.
BEG and END specifies in what region this function will run.
FLIP flips the order the operation is made in."
  (interactive)
  (if flip
      (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "/ " '/ beg end)
    (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "(flip) / " (-flip '/) beg end)))

;;;###autoload
(defun calc-at-point-mod (&optional beg end flip)
  "Run modulus on number at point.
BEG and END specifies in what region this function will run.
FLIP flips the order the operation is made in."
  (interactive)
  (if flip
      (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "(flip) % " 'mod beg end)
    (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "% " (-flip 'mod) beg end)))

;;;###autoload
(defun calc-at-point-exp (&optional beg end flip)
  "Set exponent on number at point.
BEG and END specifies in what region this function will run.
FLIP flips the order the operation is made in."
  (interactive)
  (if flip
      (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "(flip) ^ " 'expt beg end)
    (calc-at-point-run-input #'calc-at-point-get-number calc-at-point-get-number-regex "^ " (-flip 'expt) beg end)))

(defalias 'calc-at-point-raise #'calc-at-point-exp)

;; ** 1 arg
;;;###autoload
(defun calc-at-point-add-1 (&optional beg end)
  "Increase number at point by 1.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex (apply-partially '+ 1) beg end))

;;;###autoload
(defun calc-at-point-sub-1 (&optional beg end)
  "Decrease number at point by 1.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex (apply-partially (-flip '-) 1) beg end))

;;;###autoload
(defun calc-at-point-sqrt (&optional beg end)
  "Run square root on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'sqrt beg end))

;;;###autoload
(defun calc-at-point-abs (&optional beg end)
  "Run absolute on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'abs beg end))

;;;###autoload
(defun calc-at-point-round (&optional beg end)
  "Round number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'round beg end))

;;;###autoload
(defun calc-at-point-floor (&optional beg end)
  "Floor number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'floor beg end))

;;;###autoload
(defun calc-at-point-cos (&optional beg end)
  "Run cos on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'cos beg end))

;;;###autoload
(defun calc-at-point-sin (&optional beg end)
  "Run sin on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'sin beg end))

;;;###autoload
(defun calc-at-point-tan (&optional beg end)
  "Run sin on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'tan beg end))

;;;###autoload
(defun calc-at-point-acos (&optional beg end)
  "Run acos on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'acos beg end))

;;;###autoload
(defun calc-at-point-asin (&optional beg end)
  "Run asin on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'asin beg end))

;;;###autoload
(defun calc-at-point-atan (&optional beg end)
  "Run atan on number at point.
BEG and END specifies in what region this function will run."
  (interactive)
  (calc-at-point-run #'calc-at-point-get-number calc-at-point-get-number-regex 'atan beg end))

(provide 'calc-at-point)

;;; calc-at-point.el ends here
