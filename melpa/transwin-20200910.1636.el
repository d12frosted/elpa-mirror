;;; transwin.el --- Make window/frame transparent  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-06-25 01:42:34

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Make window/frame transparent.
;; Keyword: window transparent frame
;; Version: 0.1.3
;; Package-Version: 20200910.1636
;; Package-Commit: a31c7aae9d48edfcd10ccefc7b513214d6ddfb29
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/jcs-elpa/transwin

;; This file is NOT part of GNU Emacs.

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
;;
;; Make window/frame transparent.
;;

;;; Code:

(defgroup transwin nil
  "Make window/frame transparent."
  :prefix "transwin-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/transwin"))

(defcustom transwin-delta-alpha 5
  "Delta value increament/decreament transparency value."
  :type 'integer
  :group 'transwin)

(defvar transwin--current-alpha 100
  "Current alpha level.")

(defvar transwin--record-toggle-frame-transparency 85
  "Record toggle frame transparency.")

;;; Util

(defun transwin--to-reverse (in-val)
  "Reverse value IN-VAL."
  (- 0 in-val))

(defun transwin--to-positive (in-val)
  "Convert IN-VAL to positive value."
  (when (and in-val
             (< in-val 0))
    (setq in-val (transwin--to-reverse in-val)))
  in-val)

(defun transwin--to-negative (in-val)
  "Convert IN-VAL to negative value."
  (when (and in-val
             (> in-val 0))
    (setq in-val (transwin--to-reverse in-val)))
  in-val)

(defun transwin--clamp-integer (in-val in-min in-max)
  "Make sure the IN-VAL is between IN-MIN and IN-MAX."
  (let ((out-result in-val))
    (cond ((<= in-val in-min) (progn (setq out-result in-min)))
          ((>= in-val in-max) (progn (setq out-result in-max))))
    out-result))

(defun transwin--log (fmt &rest args)
  "Log message like function `message' with same argument FMT and ARGS."
  (let ((message-log-max nil)) (apply 'message fmt args)))

;;; Core

(defun transwin--set-transparency (alpha-level)
  "Set the frame transparency by ALPHA-LEVEL."
  (set-frame-parameter nil 'alpha alpha-level)
  (transwin--log "[INFO] Frame alpha level is %d" (frame-parameter nil 'alpha))
  (setq transwin--current-alpha alpha-level)
  (unless (= alpha-level 100)
    (setq transwin--record-toggle-frame-transparency alpha-level)))

(defun transwin--delta-frame-transparent (del-trans)
  "Delta change the frame transparency by a certain percentage, DEL-TRANS."
  (let ((alpha (frame-parameter nil 'alpha))
        (current-transparency transwin-delta-alpha))

    (setq current-transparency
          (cond ((numberp alpha) alpha)
                ((numberp (cdr alpha)) (cdr alpha))
                ;; Also handle undocumented (<active> <inactive>) form.
                ((numberp (cadr alpha)) (cadr alpha))))

    (setq current-transparency (+ current-transparency del-trans))
    (setq current-transparency (transwin--clamp-integer current-transparency 5 100))

    ;; Apply the value to frame.
    (transwin--set-transparency current-transparency)))

;;;###autoload
(defun transwin-increment-frame-transparent (&optional del-trans)
  "Increment the frame transparency by a certain percentage, DEL-TRANS."
  (interactive)
  (unless del-trans
    (setq del-trans (transwin--to-positive transwin-delta-alpha)))
  (transwin--delta-frame-transparent del-trans))

;;;###autoload
(defun transwin-decrement-frame-transparent (&optional del-trans)
  "Decrement the frame transparency by a certain percentage, DEL-TRANS."
  (interactive)
  (unless del-trans
    (setq del-trans (transwin--to-negative transwin-delta-alpha)))
  (transwin--delta-frame-transparent del-trans))

;;;###autoload
(defun transwin-ask-set-transparency (alpha-level)
  "Set the frame transparency by ALPHA-LEVEL."
  (interactive "p")
  (let ((alpha-level (if (< alpha-level 2)
                         (read-number "Opacity percentage: " transwin--record-toggle-frame-transparency)
                       alpha-level)))
    (transwin--set-transparency alpha-level)))

;;;###autoload
(defun transwin-toggle-transparent-frame ()
  "Toggle frame's transparency between `recorded'% and 100%."
  (interactive)
  (if (= transwin--current-alpha 100)
      (transwin--set-transparency transwin--record-toggle-frame-transparency)
    (transwin--set-transparency 100)))

(provide 'transwin)
;;; transwin.el ends here
