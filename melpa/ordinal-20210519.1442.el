;;; ordinal.el --- Convert number to ordinal number notation  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 4 Jan 2019
;; Version: 1.0.0
;; Package-Version: 20210519.1442
;; Package-Commit: a7f378306290b6807fb6b87cee3ef79b31cec711
;; Package-Requires: ((emacs "24.3"))
;; Keywords: lisp
;; Homepage: https://github.com/zonuexe/ordinal.el
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package simply provides conversion to English ordinal numbers.
;; (ex.  1st, 2nd, 3rd, 4th... Nth)
;;
;; It is worth noting that this function accepts "0th" for compatibility with function `nth'.
;; If you do not like it you can control it with the ordinal-number-accept-0 variable.
;;
;; (ordinal-format 0) ;; => "0th"
;;
;; You can prohibit "0th" for correct English.
;;
;; (let ((ordinal-number-accept-0 nil))
;;   (ordinal-format 0))
;; ;; =>  Assertion failed: (>= n 1)
;;
;; This variable works with dynamic scope.  Do not use `setq' for `ordinal-number-accept-0'.

;;; Code:
(eval-when-compile
  (require 'cl-lib))

(defvar ordinal-number-accept-0 t
  "If this variable is not NIL, it will not accept 0 for ordinal numbers.")

(defconst ordinal--english-suffixes '(nil "st" "nd" "rd"))

(defun ordinal-suffix (n)
  "Return suffix string of `N' in English."
  (cl-check-type n integer)
  (let ((last-1-digit (% n 10))
        (last-2-digit (% n 100)))
    (if (memq last-2-digit '(11 12 13))
        "th"
      (or (nth last-1-digit ordinal--english-suffixes)
          "th"))))

(defun ordinal-format (n)
  "Return string with an English ordinal appended to an integer `N'.

NOTE: \"0th\" is not a strictly correct English expression.
But Lisp's function `n-th' is 0 origin."
  ;; This is optimizable, but it is described redundantly due to the visibility of assertion error.
  (if ordinal-number-accept-0
      (cl-assert (>= n 0))
    (cl-assert (>= n 1)))
  (format "%d%s" n (ordinal-suffix n)))

(provide 'ordinal)
;;; ordinal.el ends here
