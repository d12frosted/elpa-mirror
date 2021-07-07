;;; macro-math.el --- in-buffer mathematical operations
;;
;; Copyright (C) 2007, 2009 Nikolaj Schumacher
;;
;; Author: Nikolaj Schumacher <bugs * nschum de>
;; Version: 1.0
;; Package-Version: 20130328.1604
;; Package-Commit: 216e59371e9ee39c34117ba79b9acd78bb415750
;; Keywords: convenience
;; URL: http://nschum.de/src/emacs/macro-math/
;; Compatibility: GNU Emacs 21.x, GNU Emacs 22.x, GNU Emacs 23.x
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Add the following to your .emacs file:
;;
;; (require 'macro-math)
;; (global-set-key "\C-x~" 'macro-math-eval-and-round-region)
;; (global-set-key "\C-x=" 'macro-math-eval-region)
;;
;; At any time, especially during macros, add an expression to the buffer and
;; mark it.  Then call `macro-math-eval-region' to get the result.
;;
;; A few example expressions:
;; 5 + 3
;; (2 + 3) * 5
;; 1/2 * pi
;;
;; For example, use it to increase all numbers in a buffer by one.
;; Call `kmacro-start-macro', move the point behind the next number, type "+ 1",
;; mark the number and + 1, call `macro-math-eval-region'.  Finish the macro
;; with `kmacro-end-macro', then call it repeatedly.
;;
;;; Change Log ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; 2009-03-09 (1.0)
;;    Symbols names (like pi or e) can now be evaluated.
;;    `macro-math-eval-region' accepts a numeric prefix now.
;;    Changed back-end to `calc-eval'.
;;
;; 2007-04-10 (0.9)
;;    Initial release.
;;
;;; Code:

(add-to-list 'debug-ignored-errors "^Unknown value '.*'$")

(defgroup macro-math nil
  "In-buffer mathematical operations"
  :group 'convenience)

(defcustom macro-math-rounding-precision 3
  "*Number of decimal places macro-math will round to by default."
  :type 'number
  :group 'macro-math)

;;;###autoload
(defun macro-math-eval-region (beg end &optional copy-to-kill-ring digits)
  "Evaluate the marked mathematical expression and replace it with the result.
With arg COPY-TO-KILL-RING or prefix arg, don't replace the region, but
save the result to the kill-ring.  When DIGITS is non-nil, or a numeric
prefix arg is given, it determines the number of decimal digits to round
to."
  (interactive (list (region-beginning)
                     (region-end)
                     (consp current-prefix-arg)
                     (when (numberp current-prefix-arg) current-prefix-arg)))
  (let* ((calc-multiplication-has-precedence nil)
         (result (macro-math-eval (buffer-substring-no-properties beg end)))
         (rounded (if digits
                      (macro-math-round result digits)
                    (number-to-string result))))
    (if (or buffer-read-only copy-to-kill-ring)
        (progn (deactivate-mark)
               (kill-new rounded)
               (message "Saved %s in kill-ring" rounded))
      (delete-region beg end)
      (insert rounded))))

;;;###autoload
(defun macro-math-eval-and-round-region (beg end &optional digits)
  "Call `macro-math-eval-region' and round the number to DIGITS places.
If DIGITS is nil, `macro-math-rounding-precision' will be used."
  (interactive "r\nP")
  (macro-math-eval-region
   beg end nil (or digits macro-math-rounding-precision)))

;;; Internal ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsubst macro-math-symbol-value (symbol)
  (let* ((symbol (intern symbol))
         (value (when (boundp symbol)
                  (symbol-value symbol))))
    ;; Add parentheses, so two numbers aren't accidentally concatenated.
    (if (numberp value)
        (concat "(" (number-to-string value) ")")
      (error "Unknown value '%s'" symbol))))

(defun macro-math-eval (expression)
  ;; Replace variables with their values.
  (setq expression
        (replace-regexp-in-string "\\<\\([-a-zA-Z]+\\)\\>"
                                  'macro-math-symbol-value expression))
  (string-to-number (calc-eval expression)))

(defun macro-math-round (number digits)
  "Return a string representation of NUMBER rounded to DIGITS places."
  (if (<= digits 0)
      (number-to-string (round number))
    (format
     (format "%%.%df" digits) number)))

(provide 'macro-math)
;;; macro-math.el ends here
