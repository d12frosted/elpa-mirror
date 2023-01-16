;;; orgtbl-fit.el --- Regression-fit a column in an Org Mode table  -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2023  Thierry Banel

;; Author: Thierry Banel tbanelwebmin at free dot fr
;; Contributors:
;; Version: 1.0
;; Package-Version: 20230110.1544
;; Package-Commit: 5bde4902187b2578dc39ee3a02cd7c84c4470b8a
;; Package-Requires: ((emacs "24.4"))
;; Keywords: data, extensions
;; URL: https://github.com/tbanel/orgtblfit/blob/master/README.org

;; orgtbl-fit is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; orgtbl-fit is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Regression fitting predicts numerical values of a column based on
;; other columns.  The closer the predicted values to the observed values,
;; the better the fit is.
;; Full documentation here:
;;  https://github.com/tbanel/orgtblfit/blob/master/README.org

;;; Requires:
(require 'org-table)
(require 'calc-ext)
(eval-when-compile (require 'cl-lib))
(require 'rx)
(cl-proclaim '(optimize (speed 3) (safety 0)))

;;; Code:

(defun orgtbl-fit--extract-variables (model)
  "MODEL is a Calc expression.
This recursive function looks through MODEL and
extracts variables.
Those variables should fall in just two categories:
- names of columns in the Org Mode table
- names of placeholder variables in the MODEL"
  (if (listp model)
      (if (eq (car model) 'var)
          (list model)
        (mapcan #'orgtbl-fit--extract-variables model))))

(defun orgtbl-fit--replace-col-dollar (model header)
  "Replace column names by $ forms.
MODEL is the user-provided MODEL with placeholder
variables replaced by actual numerical values by Calc.
This recursive function looks through MODEL,
destructively replacing variables that match column names
as listed in HEADER by their equivalent $ form."
  (if (listp model)
      (if (eq (car model) 'var)
          (let ((pos (cl-position (cadr model) header)))
            (if pos
                (setcar (cdr model)
                        (intern (format "$%d" (1+ pos))))))
        (cl-loop for f in model
                 do (orgtbl-fit--replace-col-dollar f header)))))

(defun orgtbl-fit--make-acceptable-calc-variable (var i)
  "Change an arbitrary column name to a Calc variable.
Remove non alphanumeric characters from VAR.
If this is not enough or not possible,
then fall back to the $ form using I.
For instance if I=3, the name of the third column is $3.
Note that a dollar variable name like $3 is not a suitable
Calc name.  It will be presented to the user as $3, then
replaced by DOLLAR3 for Calc to use it."
  (setq var (replace-regexp-in-string "[^a-zA-Z0-9$]" "" var))
  (if (= (length var) 0)
      (setq var (format "$%d" i)))
  (intern var))

(defvar org-ts-regexp0) ;; found in org.el

(defun orgtbl-fit--read-calc-expr (expr)
  "Interpret EXPR as either an Org Mode date or as a Calc expression."
  (cond
   ;; nil happens when a table is malformed,
   ;; some columns are missing in some rows
   ((not expr) nil)
   ;; Empty cell returned as nil,
   ;; to be processed later depending on modifier flags.
   ((equal expr "") nil)
   ;; The purely numerical cell case arises very often.
   ;; Short-circuiting general functions boosts performance (a lot).
   ((and (string-match
          (rx bos
              (? (any "+-")) (* (any "0-9"))
              (? "." (* (any "0-9")))
              (? "e" (? (any "+-")) (+ (any "0-9")))
              eos)
          expr)
         (not (string-match (rx bos (* (any "+-.")) "e") expr)))
    (math-read-number expr))
   ;; Convert an Org-mode date to Calc internal representation.
   ((string-match org-ts-regexp0 expr)
    (calcFunc-date
     (math-parse-date
      (replace-regexp-in-string " *[a-z]+[.]? *" " " expr))))
   ;; Convert a duration into a number of seconds.
   ((string-match
     (rx bos
         (group (any "0-9") (any "0-9"))
         ":"
         (group (any "0-9") (any "0-9"))
         (? ":" (group (any "0-9") (any "0-9")))
         eos)
     expr)
    (+ (* 3600 (string-to-number (match-string 1 expr)))
       (*   60 (string-to-number (match-string 2 expr)))
       (if (match-string 3 expr)
           (string-to-number (match-string 3 expr))
         0)))
   ;; Generic case: symbolic Calc expression.
   (t
    (math-simplify
     (calcFunc-expand
      (math-read-expr expr))))))

(defun orgtbl-fit--read-table-as-header+data ()
  "Read table from Org Mode file.
Split it in header + data.
If table has no header, create one with ($1 $2 $3 ...)."
  (let ((table (org-table-to-lisp))
        (header)
        (header-p 1))

    ;; Remove leading lines if any.
    (while (not (listp (car table)))
      (setq table (cdr table))
      (setq header-p (1+ header-p)))
    
    (if (memq 'hline table)
        ;; `table' has a header, put it in the `header' variable.
        (progn
          (setq header
                (cl-loop for x in (car table)
                         for i from 1
                         collect
                         (orgtbl-fit--make-acceptable-calc-variable x i)))
          ;; Leave `table' without a header.
          (setq table (cdr (memq 'hline table))))
          
      ;; No header in `table', create one with ($1 $2 $3 ...).
      (setq header
            (cl-loop for i from 1 to (length (car table))
                     collect
                     (orgtbl-fit--make-acceptable-calc-variable "" i)))
      (setq header-p nil))
    
    (list header table header-p)))

(defun orgtbl-fit--ask-user-for-model (table header col)
  "Ask user which regression model to use.
A default linear-plus-constant model is proposed,
taking into account all numerical columns in TABLE.
It has a form like this one:
? +?*col1 +?*col2 +?*col3 +…
HEADER is the list of column names.
COL is the target column which must be ignored."
  ;; Find purely numeric columns.
  (let ((numeric (make-vector (length header) t)))
    (cl-loop for row in table
             do
             (cl-loop for x in row
                      for n from 0
                      unless (string-match-p
                              (rx (? (any "+-"))
                                  (+ (any "0-9"))
                                  (? "." (* (any "0-9")))
                                  (? (any "eE")
                                     (? (any "+-"))
                                     (+ (any "0-9"))))
                              x)
                      do (aset numeric n nil)))

    ;; Create a default linear model with constant.
    ;; Only numeric columns are considered.
    ;; Result look like that:
    ;; ? + ?*col1 + ?*col2 + ?*col3 + …
    (let ((model
           (concat "?"
                   (cl-loop for h in header
                            for n from 0
                            if (and (aref numeric n)
                                    (not (equal n (1- col))))
                            concat (format " +?*%s" h)))))

      ;; Ask user which model should be used,
      ;; defaulting to the previously defined linear model.
      (read-string "Model: "
                   model
                   nil))))

(defun orgtbl-fit--replace-question-marks-with-vars (model)
  "Replace question-marks in MODEL by actual variables.
Their names are orgtblfit0, orgtblfit1, orgtblfit2…
Return the modified MODEL and the list of new variables."
  (let ((placeholders)
        (n 0))
    (setq model
          (replace-regexp-in-string
           "\\?"
           (lambda (_txt)
             (setq n (1+ n))
             (let ((p (format "orgtblfit%d" n)))
               (setq placeholders (cons (intern p) placeholders))
               p))
           model))
    (list model placeholders)))

(defun orgtbl-fit--replace-$-by-dollar (header)
  "Destructively replace $ forms by dollar ones in HEADER.
For instance, $3 becomes DOLLAR3."
  (cl-loop for v on header
           if (string-match-p (rx bol "$") (symbol-name (car v)))
           do (setcar
               v
               (orgtbl-fit--make-acceptable-calc-variable
                (replace-regexp-in-string
                 (rx "$" (group (+ (any "0-9"))))
                 "DOLLAR\\1"
                 (symbol-name (car v)))
                0))))

(defun orgtbl-fit--replace-$-by-variable-in-header (model header)
  "In MODEL, replace $ forms by corresponding variables found in HEADER."
  (replace-regexp-in-string
   (rx "$" (+ (any "0-9")))
   (lambda (txt)
     (let ((n (1- (string-to-number (substring txt 1)))))
       (unless (< n (length header))
         (user-error "Column %s is out of bounds" txt))
       (symbol-name (nth n header))))
   model))


(defun orgtbl-fit--collect-variables-in-cols-params
    (model header placeholders cols params)
  "Collect all variables in MODEL.
Dispatch them either in COLS if they appear in HEADER,
or in PARAMS if they appear in PLACEHOLDERS.
A sanity check is done if a variable does not fall in any."
  (cl-loop for x in (orgtbl-fit--extract-variables model)
           do
           (cond ((memq (cadr x) header)
                  (nconc cols (list x)))
                 ((memq (cadr x) placeholders)
                  (nconc params (list x)))
                 (t
                  (user-error "Unknown variable: %s" (cadr x)))))
  (delete-dups cols)
  (delete-dups params))

(defun orgtbl-fit--extract-data-from-table (table header cols col)
  "Extract data from TABLE and put it in Calc format.
The result is a Calc vector of columns.
Columns are in the same order as in COLS,
which is not necessarily the order as in the Org table.
HEADER is used to locate a column from its name.
A last column is added, for the target column COL."
  (cons 'vec
        (cl-loop for c in
                 (append (cdr cols)
                         (list (list 'var (nth (1- col) header))))
                 collect
                 (cons 'vec
                       (cl-loop for row in table
                                if (listp row)
                                collect
                                (orgtbl-fit--read-calc-expr
                                 (nth (cl-position (cadr c) header)
                                      row)))))))

(defun orgtbl-fit--add-formula-to-spreadsheet (model header col)
  "Add regression fit MODEL to the table spreadsheet.
It will be applied to the before-last column.
Also add a formula to compute difference between observed and
predicted values.  It will be applied on the last column.
HEADER is used to locate the two new columns.
COL is the target columns which hold observations."
  (org-table-store-formulas
   (cons (cons (format "$%d" (1+ (length header)))
               (math-format-value model))
         (cons (cons (format "$%d" (+ 2 (length header)))
                     (format "$%d-$%d"
                             (1+ (length header))
                             col))
               (org-table-get-stored-formulas)))))

;;;###autoload
(defun orgtbl-fit (&optional model)
  "Add a column to an Org Mode table which fits the current column.
A user-supplied MODEL is applied to columns mentioned in the MODEL
in order to match as close as possible the column where the cursor is on.
A new column is added, with values computed with the MODEL.
Usually, no exact fit can be found.  Another column is added showing
differences between actual values and fitted values.
A default linear-with-constant MODEL is proposed as a default.
It mentions only columns containing numerical values."
  (interactive)
  (let* ((col (org-table-current-column))
         (header)
         (table)
         (header-p) ;; nil or row number of header
         (cols   (list 'vec))
         (params (list 'vec))
         (placeholders))

    ;; Read table and split header + data
    (cl-multiple-value-setq (header table header-p)
      (orgtbl-fit--read-table-as-header+data))
         
    ;; If MODEL is not given, then ask for it,
    ;; with a linear-plus-constant default.
    (unless model
      (setq model (orgtbl-fit--ask-user-for-model table header col)))

    ;; Replace question marks by actual variables
    ;; like orgtblfit0, orgtblfit1, orgtblfit2…
    ;; Keep orgtblfit0, orgtblfit1, … in `placeholders'.
    (cl-multiple-value-setq (model placeholders)
      (orgtbl-fit--replace-question-marks-with-vars model))

    ;; In the `header', destructively replace $ forms by dollar ones.
    ;; For instance, $3 becomes DOLLAR3
    (orgtbl-fit--replace-$-by-dollar header)

    ;; In the MODEL, replace $ forms
    ;; by corresponding variables found in `header'.
    (setq model
          (orgtbl-fit--replace-$-by-variable-in-header model header))

    ;; Convert MODEL from its textual form
    ;; to its Calc representation.
    (setq model (math-simplify (math-read-expr model)))

    ;; Collect all variables in MODEL and split them
    ;; either in `cols' if they appear in `header',
    ;; or in `params' if they appear in `placeholders'.
    ;; A sanity check is done if a variable does not fall in any.
    (orgtbl-fit--collect-variables-in-cols-params
     model
     header
     placeholders
     cols
     params)

    ;; Extract data from `table' and put it in Calc format.
    ;; Not all columns are kept, and their ordering may differ.
    (setq table
          (orgtbl-fit--extract-data-from-table table header cols col))

    ;; Here is the heart of this package:
    ;; call Calc to fit the target column against the MODEL
    ;; by doing a regression.
    ;; The resulting is the MODEL with
    ;; question marks `?' replaced by numerical computed values.
    (setq model
          (calcFunc-fit model  ;; orgtblfit0 + orgtblfit1*c1 + orgtblfit2*c2…
                        cols   ;;     c1, c2, c3…
                        params ;; orgtblfit0, orgtblfit1, orgtblfit2…
                        table))

    ;; Replace variables by $ forms using the `header'.
    ;; For example, if `header' is (a b c d ...),
    ;; replace variable `c' by `$3' because
    ;; c is in 3th position in `header'.
    (orgtbl-fit--replace-col-dollar model header)

    ;; Note: there is no need to add two new columns at the end of table.
    ;; They will be implicitly added.

    ;; Set column titles if table has a header.
    (when header-p
      (org-table-put 1 (+ (length header) 1) "Best Fit")
      (org-table-put 1 (+ (length header) 2) "Fit Diff"))

    ;; Add the MODEL computed by Calc,
    ;; something like: 1.41 +5.34*$1 -0.33*$2 +2.97*$3 +…
    ;; as a spreadsheet formula in the new column.
    ;; Then add the difference between computed and target values
    ;; in the other column.
    (orgtbl-fit--add-formula-to-spreadsheet model header col)
  
    ;; Restore cursor position where it was.
    (org-table-goto-column col)
    
    ;; The two new formulas need to be computed to fill-in
    ;; the new columns
    (org-table-recalculate t)))

(provide 'orgtbl-fit)
;;; orgtbl-fit.el ends here
