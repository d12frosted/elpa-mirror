;;; wwg.el --- Writer word goals  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Andrea

;; Author: Andrea andrea-dev@hotmail.com>
;; Version: 0.0.1
;; Package-Version: 20210314.2101
;; Package-Commit: d62ece22ab7c8c46d874f5ae61712aa517b25ce2
;; Package-Requires: ((emacs "25.1"))
;; Keywords: wp
;; Homepage: https://github.com/ag91/writer-word-goals

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:

;; A mode that gives you focus in achieving your writing goals.
;;
;; This mode allows you to set a writing goal and achieve it. The main
;; feature is to let you define a number of words and the mode
;; periodically prizes your efforts by printing encouragement messages
;; in the console. The messages shows only when your cursor is in the
;; buffer in which you set a writing goal. This mode also allows you
;; to set multiple goals in different buffers, although it is not
;; advised because distracting.
;;
;; The aim of this mode is to give a structure in your writing. The
;; idea is to write everyday N (ideally 1k) words. The next day you
;; should edit what you wrote, and write some more.
;;
;; Other utilities provide similar functionality:
;; - count-words: Emacs built-in to count the words in the buffer
;; - org-wc: this counts words in Org-Mode buffers
;; - wc-goal-mode and wc-mode: these keep track of how many words you wrote in the modeline
;;
;; This mode differs from the above because encourages you
;; periodically to not surrender your writing dreams.
;;
;; See documentation on https://github.com/ag91/writer-word-goals

;;; Code:

(defgroup wwg nil
  "Options specific to wwg."
  :tag "wwg"
  :group 'wwg)

(defvar wwg-active-timer-alist
  nil
  "Alist of (buffer . timer) bindings to cleanup achieved targets.")

(defvar wwg-monitor-function
  'wwg-check-count-and-beep-with-message-if-finished
  "The function to monitor the target was reached in buffer.
It takes two arguments: a number (target) and the buffer.
   It should return any value when it finds the target satisfied for cleanup purposes.")

(defcustom wwg-monitor-period
  15
  "How many seconds before checking if a writer has reached the words target.
Defaults to a minute."
  :group 'wwg
  :type 'string)

(defcustom wwg-number-of-words
  1000
  "The number of words your aim to write in a session."
  :group 'wwg
  :type 'number)


(defun wwg-choose-message (remaining-words)
  "Produce a message according to the delta between TARGET-COUNT and REMAINING-WORDS."
  (cond
   ((< remaining-words 50) "Fabulous, so close!")
   ((< remaining-words 200) "You are quite done, awesome!")
   ((< remaining-words 500) "Okay, doing good effort there!")
   ((< remaining-words 800) "Not bad!")
   ('otherwise "Okay!")))

(defun wwg-check-count-and-beep-with-message-if-finished (target-count buffer)
  "Beep if TARGET-COUNT was reached in BUFFER."
  (let* ((total-so-far
          (with-current-buffer buffer
            (count-words (point-min) (point-max))))
         (remaining-words (- target-count total-so-far)))
    (if (<= remaining-words 0)
        (progn
          (beep)
          (message
           "Well done! You wrote %s words, and %s extra words of what you planned!!"
           target-count
           (abs remaining-words))
          'finished)
      (message
       "%s %s words left."
       (wwg-choose-message remaining-words)
       remaining-words)
      nil)))

(defun wwg-run-monitor (target-number buffer)
  "Call `wwg-monitor-function' with TARGET-NUMBER and BUFFER and cleanup timer if completed."
  (when (and
         (eq buffer (current-buffer))
         (funcall wwg-monitor-function target-number buffer))
    (cancel-timer
     (car (alist-get buffer wwg-active-timer-alist)))))

(defun wwg-monitor-word-count-for-buffer (target-number buffer)
  "Monitor every `wwg-monitor-period' seconds if the writer reached the TARGET-NUMBER in BUFFER."
  (add-to-list
   'wwg-active-timer-alist
   (list
    buffer
    (run-with-timer
     wwg-monitor-period
     wwg-monitor-period
     `(lambda () (wwg-run-monitor ,target-number ,buffer))))))

(define-minor-mode wwg-mode
  "Toggle writer goal mode for writing some number of words."
  :group 'wwg
  (if (not wwg-mode)
      (cancel-timer (car (alist-get (current-buffer) wwg-active-timer-alist)))
    (let* ((current (count-words (point-min) (point-max)))
           (target (read-number "How many words do you want to write? " 1000)))
      (wwg-monitor-word-count-for-buffer (+ current target) (current-buffer)))))

(provide 'wwg)
;;; wwg.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\?[ \t]+1.%02y%02m%02d\\?\n"
;; End:
