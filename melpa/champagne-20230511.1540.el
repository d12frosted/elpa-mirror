;;; champagne.el --- Graphical countdowns  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Positron Solutions

;; Author:  Psionik K <73710933+psionic-k@users.noreply.github.com>
;; Keywords: games
;; Package-Version: 20230511.1540
;; Package-Commit: 069452fa162d6aefc693c8d0546a84d967218289
;; Version: 0.2.0
;; Package-Requires: ((emacs "28.1") (posframe "1.4.2"))
;; Homepage: http://github.com/positron-solutions/champagne

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

;; Now you can count down important events with friends & family from within
;; Emacs!  Subscriptions?  Yuck!  Stop paying $10 a month for "turn-key"
;; solutions to animate your countdowns.  They don't even have integration hooks
;; or customizations!

;;; Usage:

;; For a quick manual coundown, M-x champagne will just ask you for a number of
;; seconds.

;; For a basic countdown, starting right now:
;; (champagne 5)
;;
;; Count down to some point in the future:
;; (champagne nil "Sun Jan 23 00:00:00 2023")
;;
;; Count down and call a function at the beginning of the countdown
;; (champagne nil nil #'parrot-start-animation)
;;
;; Count down and call a function at the end of the countdown
;; (champagne nil nil nil #'snow)
;;
;; Count down with all behaviors
;; (champagne 60 "Sun Jan 23 00:00:00 2023" #'parrot-start-animation #'snow)

;;; Code:

(require 'posframe)

;; macros only
(eval-when-compile (require 'cl-lib))

(defgroup champagne nil "Count down." :prefix 'champagne :group 'champagne)

(defcustom champagne-default-seconds 10
  "Default seconds to count down."
  :group 'champagne
  :type 'integer)

(defcustom champagne-frame-time 0.02
  "How much time for each frame during animation."
  :group 'champagne
  :type 'float)

(defcustom champagne-buffer-name " *champagne*"
  "Buffer where countdown is rendered."
  :group 'champagne
  :type 'string)

(defun champagne--read-N+ ()
  "Read a positive integer."
  (save-match-data
    (cl-block nil
      (while t
        (let ((str (read-from-minibuffer
                    "Countdown duration (integer seconds): "
                    (number-to-string champagne-default-seconds) nil nil nil)))
          (when (string-match-p "\\`[1-9][0-9]*\\'" str)
            (cl-return (string-to-number str))))
        (message "Please enter a positive integer.")
        (sit-for 1)))))

(defun champagne--start (goal-time start-fun end-fun digits)
  "Count down to GOAL-TIME.
Call START-FUN and then start the animation, which will call
END-FUN when it's done.  DIGITS is determined from duration when
calling `champagne'."
  (when start-fun (funcall start-fun))
  (let ((animation-timer (timer-create)))
    (timer-set-function
     animation-timer
     #'champagne--animate (list goal-time end-fun animation-timer digits))
    (timer-set-time animation-timer (current-time) champagne-frame-time)
    (timer-activate animation-timer)))

(defun champagne--animate (goal-time end-fun animation-timer digits)
  "Animate a countdown until GOAL-TIME.
Call END-FUN when countdown finishes.  ANIMATION-TIMER is
cancelled when GOAL-TIME is reached.  DIGITS is used to make
display behavior consistent."
  (if (time-less-p goal-time (current-time))
      (progn (cancel-timer animation-timer)
             (posframe-delete champagne-buffer-name)
             (when end-fun (funcall end-fun)))
    (let* ((diff (time-subtract goal-time (current-time)))
           (diff-seconds (+ 1(nth 1 diff)))
           (digits-remaining (length (number-to-string diff-seconds)))
           (diff-micros (nth 2 diff))
           (fraction (/ diff-micros 1000000.0))
           (buffer (get-buffer-create champagne-buffer-name))
           ;; You can customize the animation easing function and counter scale if
           ;; you add support here.
           (height-max-frac 0.8)
           (height-min-frac 0.1)
           (eased-frac (expt fraction 0.6))
           (height-cur-frac (+ (* eased-frac (- height-max-frac height-min-frac))
                               height-min-frac))
           (height-margin-frac (- height-max-frac height-cur-frac))
           (font-scale  (* (float (frame-height)) height-cur-frac)))

      (set-buffer buffer)
      (face-remap-set-base 'default :height font-scale)

      (unless (string=
               (buffer-substring-no-properties
                (max (- (point-max) digits-remaining) 1)
                (point-max))
               (number-to-string diff-seconds))
        (erase-buffer)
        ;; Make any leading spaces half width so that shorter numbers are
        ;; slightly shifted left.
        (let* ((padding (propertize (make-string (- digits digits-remaining) ?\40)
                                    'display '(space-width 0.5))))
          (insert (format " %s%d" padding diff-seconds))))

      ;; Customize the color in animation if you want full party mode
      ;; (put-text-property 2 (point-max) 'face '(:foreground "#ff00ff"))

      ;; Note to any hackers, anything you do that affects the child frame size
      ;; in animation will slow your display down too much for smooth visuals.
      ;; This includes borders, child borders, and refreshing the posframe.

      ;; expand the space character we appended at the front as the current
      ;; fraction goes down.  Horizontally, this scales by digits.
      (put-text-property
       1 2
       'display `(space-width
                  ,(* digits (/ height-margin-frac height-cur-frac 2.0))))

      ;; add a subscript translation that scales up as current fraction goes
      ;; down.
      (put-text-property
       (- (point-max) digits-remaining) (point-max)
       'display `(raise ,(- (/ height-margin-frac height-cur-frac 2.0))))

      ;; posframe show is run only after contents are available so that the
      ;; handler will do most of the work.
      (unless (posframe--find-existing-posframe buffer)
        (posframe-show
         buffer
         ;; Border will use child-frame-border color by default
         ;; :border-width 10
         ;; :border-color (face-attribute 'internal-border :background)

         ;; Use of timeout or refresh calels leads to considerable slowness
         ;; probably because it causes child frame resize.

         ;; Only supported on GTK?
         ;; https://www.reddit.com/r/emacs/comments/v72tu6/new_emacs_frame_parameter_for_transparency/
         ;; :override-parameters '((alpha-background 0.0))

         :poshandler 'posframe-poshandler-frame-center)))))

;;;###autoload
(defun champagne (&optional duration goal-time start-fun end-fun)
  "Count down.
DURATION is the number of seconds that will be counted down,
reaching GOAL-TIME.  If GOAL-TIME is nil, the countdown will
start immediately.  START-FUN will be called when the countdown
begins.  END-FUN will be called with the countdown finishes."
  (interactive (list (champagne--read-N+)))
  (let* ((duration (or duration champagne-default-seconds))
         (digits (length (number-to-string duration)))
         (goal-time (cond ((stringp goal-time)
                           (append (encode-time (parse-time-string goal-time)
                                                '(0 0))))
                          ((consp goal-time) goal-time)
                          (t (time-add (current-time) `(0 ,duration 0 0)))))
         (start-time (time-subtract goal-time `(0 ,duration 0 0))))
    (run-at-time start-time nil #'champagne--start
                 goal-time start-fun end-fun digits)))

(provide 'champagne)
;;; champagne.el ends here
