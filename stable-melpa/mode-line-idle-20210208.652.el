;;; mode-line-idle.el --- Evaluate mode line content when idle -*- lexical-binding:t -*-

;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-mode-line-idle
;; Package-Version: 20210208.652
;; Package-Commit: 4995d75cdabe2f4e8a41a56d041f8e3b24e3ea10
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Simple delayed text evaluation for the mode-line.

;;; Usage

;; (defvar my-word '(:eval (count-words (point-min) (point-max))))
;; (setq-default mode-line-format (list "Word Count " '(:eval (mode-line-idle 1.0 my-word "?"))))
;;

;;; Code:


;; ---------------------------------------------------------------------------
;; Generic Utility Functions

(defun mode-line-idle--tree-to-string (tree)
  "Convert TREE recursively to a string.
TREE can be one of the following:
- lists with `car' `:eval'
  - The `cdr' is evaluated and the result
    is passed to `mode-line-idle--tree-to-string'
- Lists with `car' `:propertize'
  - The `caar' is passed to `mode-line-idle--tree-to-string'.
  - The `cddr' is passed to as properties to `propertize'.
- Other lists: element-wise processed with `mode-line-idle--tree-to-string'
- A symbol, it's value will be passed to `mode-line-idle--tree-to-string'.
- Any other element is converted into a string using `prin1-to-string'."
  (cond
    ((null tree)
      "")
    ((symbolp tree)
      ;; Support non-string symbols, allows numbers etc to be included.
      (mode-line-idle--tree-to-string (symbol-value tree)))
    ((listp tree)
      (let ((tree-type (car-safe tree)))
        (cond
          ((eq tree-type :eval)
            (mode-line-idle--tree-to-string (eval (cons 'progn (cdr tree)) t)))
          ((eq tree-type :propertize)
            (pcase-let ((`(,item . ,rest) (cdr tree)))
              (apply 'propertize (cons (mode-line-idle--tree-to-string item) rest))))
          (t
            (mapconcat #'mode-line-idle--tree-to-string tree "")))))
    (t
      (prin1-to-string tree t))))


;; ---------------------------------------------------------------------------
;; Internal Variables

;; One off timers.
(defvar-local mode-line-idle--timers nil)
;; Cache evaluated expressions.
(defvar-local mode-line-idle--values nil)
;; Prevent timer creation when running the timer callback.
(defconst mode-line-idle--timer-lock nil)


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun mode-line-idle--timer-callback (buf item)
  "Calculate all values in BUF for the times associated with ITEM."
  ;; It's possible the buffer was removed since the timer started.
  ;; In this case there is nothing to do as the timer only runs once
  ;; and the variables are local.
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((found nil))
        (dolist (content (cdr item))
          ;; Replace the previous value, if it exists.
          (assq-delete-all content mode-line-idle--values)
          (push (cons content (mode-line-idle--tree-to-string content)) mode-line-idle--values)
          (setq found t))

        ;; Remove this item.
        (setq mode-line-idle--timers (delq item mode-line-idle--timers))

        (when found
          (force-mode-line-update)
          ;; Prevent `mode-line-idle' from starting new idle timers
          ;; since it can cause continuous updates.
          (let ((mode-line-idle--timer-lock t))
            (redisplay t)))))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun mode-line-idle (delay-in-seconds content default-text)
  "Delayed evaluation of CONTENT, delayed by DELAY-IN-SECONDS."

  ;; Check if this is running within `mode-line-idle--timer-callback'.
  (unless mode-line-idle--timer-lock
    (let ((item (assoc delay-in-seconds mode-line-idle--timers)))
      (unless item
        ;; Use a float so `equal' comparisons can be used when the input is an int.
        (unless (floatp delay-in-seconds)
          (setq delay-in-seconds (float delay-in-seconds)))
        (setq item (cons delay-in-seconds (list)))
        ;; Since this is a one-off timer, no need to manage, fire and forget.
        (run-with-idle-timer
          delay-in-seconds
          nil
          #'mode-line-idle--timer-callback
          (current-buffer)
          item)
        (push item mode-line-idle--timers))

      ;; Add the symbol to the timer list.
      (let ((content-list (cdr item)))
        ;; Paranoid check we don't add twice.
        (setq content-list (delq content content-list))
        (push content content-list)
        (setcdr item content-list))))

  ;; Return the cached value.
  (let ((value (cdr (assq content mode-line-idle--values))))
    (or value default-text)))

(provide 'mode-line-idle)
;;; mode-line-idle.el ends here
