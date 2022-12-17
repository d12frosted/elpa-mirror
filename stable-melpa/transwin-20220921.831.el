;;; transwin.el --- Make window/frame transparent  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2022  Shen, Jen-Chieh
;; Created date 2020-06-25 01:42:34

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/transwin
;; Package-Version: 20220921.831
;; Package-Commit: ed0156a98b6fce94da9045bdffe369f390b70c0c
;; Version: 0.1.4
;; Package-Requires: ((emacs "24.3"))
;; Keywords: frames window transparent

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

(defcustom transwin-parameter-alpha 'alpha
  "Frame parameter symbol."
  :type 'symbol
  :group 'transwin)

(defvar transwin--current-alpha 100
  "Current alpha level.")

(defvar transwin--record-toggle-frame-transparency 85
  "Record toggle frame transparency.")

;;; Util

(defun transwin--to-reverse (val)
  "Reverse value VAL."
  (- 0 val))

(defun transwin--to-positive (val)
  "Convert VAL to positive value."
  (when (and val (< val 0))
    (setq val (transwin--to-reverse val)))
  val)

(defun transwin--to-negative (val)
  "Convert VAL to negative value."
  (when (and val (> val 0))
    (setq val (transwin--to-reverse val)))
  val)

(defun transwin--clamp-integer (val min max)
  "Make sure the VAL is between MIN and MAX."
  (cond ((<= val min) min)
        ((>= val max) max)
        (t val)))

(defun transwin--log (fmt &rest args)
  "Log message like function `message' with same argument FMT and ARGS."
  (let (message-log-max) (apply 'message fmt args)))

;;; Core

(defun transwin--set-transparency (alpha-level)
  "Set the frame transparency by ALPHA-LEVEL."
  (set-frame-parameter nil transwin-parameter-alpha alpha-level)
  (transwin--log "[INFO] Frame alpha level is %d" (frame-parameter nil transwin-parameter-alpha))
  (setq transwin--current-alpha alpha-level)
  (unless (= alpha-level 100)
    (setq transwin--record-toggle-frame-transparency alpha-level)))

(defun transwin--delta-frame-transparent (del-trans)
  "Delta change the frame transparency by a certain percentage, DEL-TRANS."
  (let ((alpha (or (frame-parameter nil transwin-parameter-alpha) 100))
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
(defun transwin-inc (&optional del-trans)
  "Increment the frame transparency by a certain percentage, DEL-TRANS."
  (interactive)
  (transwin--delta-frame-transparent (transwin--to-positive (or del-trans transwin-delta-alpha))))

;;;###autoload
(defun transwin-dec (&optional del-trans)
  "Decrement the frame transparency by a certain percentage, DEL-TRANS."
  (interactive)
  (transwin--delta-frame-transparent (transwin--to-negative (or del-trans transwin-delta-alpha))))

;;;###autoload
(defun transwin-ask (alpha-level)
  "Set the frame transparency by ALPHA-LEVEL."
  (interactive "p")
  (let ((alpha-level (if (< alpha-level 2)
                         (read-number "Opacity percentage: " transwin--record-toggle-frame-transparency)
                       alpha-level)))
    (transwin--set-transparency alpha-level)))

;;;###autoload
(defun transwin-toggle ()
  "Toggle frame's transparency between `recorded'% and 100%."
  (interactive)
  (if (= transwin--current-alpha 100)
      (transwin--set-transparency transwin--record-toggle-frame-transparency)
    (transwin--set-transparency 100)))

;;; Obsolete

(define-obsolete-function-alias
  'transwin-increment-frame-transparent
  'transwin-inc "0.1.4")

(define-obsolete-function-alias
  'transwin-decrement-frame-transparent
  'transwin-dec "0.1.4")

(define-obsolete-function-alias
  'transwin-ask-set-transparency
  'transwin-ask "0.1.4")

(define-obsolete-function-alias
  'transwin-toggle-transparent-frame
  'transwin-toggle "0.1.4")

(provide 'transwin)
;;; transwin.el ends here
