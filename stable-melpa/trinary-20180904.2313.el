;;; trinary.el --- Trinary logic. -*- lexical-binding: t -*-

;; Copyright (C) 2018 Matúš Goljer

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20180904.2313
;; Package-Commit: 886232c6d7e92a8e9fe573eef46754ebe321f90d
;; Created: 25th August 2018
;; Package-requires: ((emacs "24"))
;; Keywords: languages
;; Homepage: https://github.com/Fuco1/trinary-logic

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Trinary logic.

;;; Code:

(defconst trinary--true 1)
(defconst trinary--maybe 0)
(defconst trinary--false -1)

(cl-defstruct (trinary
               (:print-function 'trinary-print)
               (:constructor nil)
               (:constructor trinary-true (&aux (value trinary--true)))
               (:constructor trinary-maybe (&aux (value trinary--maybe)))
               (:constructor trinary-false (&aux (value trinary--false))))
  value)

(defun trinary-print (value)
  "Print trinary VALUE."
  (let ((x (trinary-value value)))
    (cond
     ((= x trinary--false) "F")
     ((= x trinary--maybe) "?")
     ((= x trinary--true) "T"))))

(defun trinary--int-to-value (x)
  "Convert X to `trinary' value."
  (cond
   ((eq x trinary--true) (trinary-true))
   ((eq x trinary--maybe) (trinary-maybe))
   ((eq x trinary--false) (trinary-false))
   (t (error "Can not convert %d to trinary value" x))))

(defun trinary-true-p (value)
  "Return non-nil if VALUE is true₃."
  (= trinary--true (trinary-value value)))

(defun trinary-maybe-p (value)
  "Return non-nil if VALUE is maybe₃."
  (= trinary--maybe (trinary-value value)))

(defun trinary-false-p (value)
  "Return non-nil if VALUE is false₃."
  (= trinary--false (trinary-value value)))

(defun trinary-possible-p (value)
  "Return non-nil if it is possible that VALUE is true₂."
  (or (trinary-true-p value) (trinary-maybe-p value)))

(defun trinary-necessary-p (value)
  "Return non-nil if it is necessary that VALUE is true₂."
  (trinary-true-p value))

(defun trinary-not (a)
  "Negate the VALUE.

Truth table:

  | A | ¬A |
  |---+----|
  | T | F  |
  | ? | ?  |
  | F | T  |"
  (trinary--int-to-value (- (trinary-value a))))

(defun trinary-and (left right)
  "And LEFT and RIGHT.

Truth table:

  | A | B | A ∧ B |
  |---+---+-------|
  | T | T | T     |
  | T | ? | ?     |
  | T | F | F     |
  | ? | T | ?     |
  | ? | ? | ?     |
  | ? | F | F     |
  | F | T | F     |
  | F | ? | F     |
  | F | F | F     |"
  (trinary--int-to-value
   (min (trinary-value left) (trinary-value right))))

(defun trinary-or (left right)
  "Or LEFT and RIGHT.

Truth table:

  | A | B | A ∨ B |
  |---+---+-------|
  | T | T | T     |
  | T | ? | T     |
  | T | F | T     |
  | ? | T | T     |
  | ? | ? | ?     |
  | ? | F | ?     |
  | F | T | T     |
  | F | ? | ?     |
  | F | F | F     |"
  (trinary--int-to-value
   (max (trinary-value left) (trinary-value right))))

;; TODO: make better name for this
(defun trinary-happened (left right)
  "Could an event happen based on the observation of LEFT and RIGHT?

Truth table:

  | A | B | A  B |
  |---+---+-------|
  | T | T | T     |
  | T | ? | ?     |
  | T | F | ?     |
  | ? | T | ?     |
  | ? | ? | ?     |
  | ? | F | ?     |
  | F | T | ?     |
  | F | ? | ?     |
  | F | F | F     |

The motivation here is branch analysis: we need to know if an
event occurred surely or surely not, that is either on both
branches or on neither.  In all other cases we don't know because
we always only pick one branch but it is unknown which one will
be the right one at the actual time of observation."
  (cond
   ((and (trinary-true-p left)
         (trinary-true-p right))
    (trinary-true))
   ((and (trinary-false-p left)
         (trinary-false-p right))
    (trinary-false))
   (t (trinary-maybe))))

(defun trinary-add-maybe (value)
  "Add maybe to VALUE."
  (trinary-or value (trinary-maybe)))

(provide 'trinary)
;;; trinary.el ends here
