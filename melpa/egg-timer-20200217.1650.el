;;; egg-timer.el --- Commonly used intervals for setting timers while working -*- lexical-binding: t -*-

;; Author: William Carroll <wpcarro@gmail.com>
;; URL: https://github.com/wpcarro/egg-timer.el
;; Package-Version: 20200217.1650
;; Package-Commit: e3542aeb80905956b94373a222a9cbac04e6497e
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;; The MIT License (MIT)
;;
;; Copyright (c) 2016 Al Scott
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;; Select common timer intervals and use `notifications-notify' to display a
;; message when the timer completes.  Since this depends on
;; `notifications-notify', ensure that your Emacs is compiled with dbus
;; support.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dependencies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'notifications)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Library
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup egg-timer nil
  "Use timers to help focus on a task."
  :group 'emacs)

(defcustom egg-timer-intervals
  '(("1 minute" . 1)
    ("2 minutes" . 2)
    ("3 minutes" . 3)
    ("4 minutes" . 4)
    ("5 minutes" . 5)
    ("10 minutes" . 10)
    ("15 minutes" . 15)
    ("20 minutes" . 20)
    ("30 minutes" . 30)
    ("45 minutes" . 45)
    ("1 hour" . 60)
    ("2 hours" . 120))
  "Commonly used intervals for timer amounts in minutes."
  :type '(alist :key-type string :value-type integer)
  :group 'egg-timer)

(defun egg-timer-do-schedule (minutes &optional label)
  "Schedule a timer to go off in MINUTES.
Provide LABEL to change the notifications, which defaults to \"MINUTES
minutes\"."
  (interactive)
  (unless label (setq label (format "%s minutes" minutes)))
  (run-at-time
   (format "%s minutes" minutes)
   nil
   (lambda ()
     (notifications-notify
      :title "egg-timer.el"
      :body (format "%s timer complete." label))))
  (message "%s timer scheduled." label))

(defun egg-timer-schedule ()
  "Select and schedule a timer for a given set of time intervals."
  (interactive)
  (let* ((key (completing-read "Set timer for: " egg-timer-intervals))
         (val (alist-get key egg-timer-intervals nil nil #'string=)))
    (egg-timer-do-schedule val key)))

(provide 'egg-timer)
;;; egg-timer.el ends here
