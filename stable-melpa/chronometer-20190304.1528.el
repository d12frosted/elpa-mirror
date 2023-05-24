;;; chronometer.el --- a [not so] simple chronometer -*- lexical-binding: t; -*-

;; Copyright  (C)  2004-2019  Marcelo Toledo

;; Author: Marcelo Toledo <marcelo@marcelotoledo.com>
;; Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
;; Created: 21 Jul 2004
;; Package-Requires: ((emacs "24"))
;; Package-Version: 20190304.1528
;; Package-Commit: 8457b296ef87be339cbe47730b922757d60bdcd5
;; Version: 2.0
;; Keywords: tools, convenience
;; URL: https://github.com/marcelotoledo/chronometer

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;; Code:


;;; Commentary:

;; This is a major mode to help you keep track of time.

;; Chronometer opens in a very discrete buffer, you can set an alarm to whenever you want and you will be alerted accordingly. For your convinience you can hide it to concentrate and you'll still be alerted.

;;; Code:

(defconst chronometer-default-buffer "*chronometer*"
  "The default working buffer.")

(defconst chronometer-buffer-size -4
  "The height of `chronometer-default-buffer'.")

(defconst chronometer-prompt "Chronometer=> "
  "The prompt that will be displayed in the chronometer buffer.")

(defconst chronometer-prompt-space "    "
  "The space between chronometer and important messages.")

(defconst chronometer-prompt-paused "Paused"
  "Message when Paused.")

(defconst chronometer-prompt-alarm "Beep! - Press s to stop beeping!"
  "Message when beeping.")

(defvar chronometer-start-time nil
  "Chronometer start time. If it's paused this value will be incremented.")

(defvar chronometer-alarm nil
  "Minute you want to be alerted.")

(defvar chronometer-alarm-ringing nil
  "If the alarm is ringing.")

(defvar chronometer-timer nil
  "Timer object.")

(defvar chronometer-paused nil
  "If the chronometer is paused this variable will be t, otherwise nil.")

(defconst chronometer-interval 1
  "The chronometer buffer is updated every `chronometer-interval' second(s).")

(defconst chronometer-running nil
  "If chronometer is running this variable will be true, otherwise false.")

(defvar chronometer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "s") #'chronometer-stop-alarm)
    (define-key map (kbd "a") #'chronometer-set-alarm)
    (define-key map (kbd "q") #'chronometer-quit)
    (define-key map (kbd "p") #'chronometer-toggle-pause)
    (define-key map (kbd "?") #'chronometer-help)
    (define-key map (kbd "r") #'chronometer-restart)
    (define-key map (kbd "h") #'chronometer-hide)
    map)
  "Chronometer mode map.")



(defun chronometer-toggle-pause ()
  "Toggle pause."
  (interactive)
  (setq chronometer-paused (not chronometer-paused)))

(defun chronometer-set-alarm ()
  "Set alarm to the minute you would like to alerted."
  (interactive)
  (setq chronometer-alarm (read-from-minibuffer "Set alarm to what minute? ")))

(defun chronometer-stop-alarm ()
  "Unset alarm."
  (interactive)
  (setq chronometer-alarm nil
        chronometer-alarm-ringing nil))

(defun chronometer-restart ()
  "Start chronometer from zero."
  (interactive)
  (setq chronometer-start-time (current-time)))

(defun chronometer-hide ()
  "Hide Chronometer buffer."
  (interactive)
  (when (get-buffer-window chronometer-default-buffer)
    (delete-window (get-buffer-window chronometer-default-buffer))))

(defun chronometer-quit ()
  "Quit Chronometer."
  (interactive)
  (when (get-buffer-window chronometer-default-buffer)
    (delete-window (get-buffer-window chronometer-default-buffer))
    (setq chronometer-running nil)
    (kill-buffer chronometer-default-buffer)
    (chronometer-cancel-timer)
    (message "Bye")))

(defun chronometer-help ()
  "Quick reference:

* \\[chronometer-set-alarm] - Set alarm
* \\[chronometer-stop-alarm] - Stop alarm
* \\[chronometer-toggle-pause] - Toggle pause
* \\[chronometer-restart] - Restart Chronometer
* \\[chronometer-hide] - Hide
* \\[chronometer-quit] - Exit
* \\[chronometer-help] - Help"
  (interactive)
  (save-window-excursion
    (with-output-to-temp-buffer "*Help*"
      (princ (documentation 'chronometer-help)))
    (message "Type any key to continue.")
    (sit-for 10)))



(defun chronometer-prompt-alarm-set (minutes)
  "Format prompt string with MINUTES to be used when alart is set."
  (format "Alarm set to %s minute(s)" minutes))

(defun chronometer-first-run ()
  "Prepare chronometer for first run."
  (unless chronometer-running
    (chronometer-stop-alarm)
    (when chronometer-paused (chronometer-toggle-pause))
    (chronometer-restart)
    (get-buffer-create chronometer-default-buffer)
    (setq chronometer-timer (run-with-timer 1 chronometer-interval 'chronometer-loop)
          chronometer-running t)))

(defun chronometer-show-buffer ()
  "Show chronometer buffer."
  (cond ((not (get-buffer-window chronometer-default-buffer))
         (let ((split-window-keep-point nil)
               (window-min-height 2))
           (select-window (split-window-vertically chronometer-buffer-size))
           (switch-to-buffer chronometer-default-buffer)))
        ((not (eq (current-buffer) chronometer-default-buffer))
         (select-window (get-buffer-window chronometer-default-buffer)))))

(defun chronometer-increment-start-time ()
  "Add one second in 'chronometer-start-time'."
  (setf (cadr chronometer-start-time) (+ (cadr chronometer-start-time) 1)))

(defun chronometer-cancel-timer ()
  "Cancel the chronometer timer."
  (cancel-timer chronometer-timer))

(defun chronometer-alarm-alert ()
  "Invert the modeline colors."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil #'invert-face 'mode-line))

(defun chronometer-minutes-elapsed ()
  "Calculate the number of minutes elapsed."
  (let ((hours (string-to-number (format-time-string "%H" (time-subtract (current-time) chronometer-start-time) t)))
        (minutes (string-to-number (format-time-string "%M" (time-subtract (current-time) chronometer-start-time) t))))
    (+ (* hours 60) minutes)))

(defun chronometer-loop ()
  "This function run every 'chronometer-interval' second(s) and display data in the buffer."
  (with-current-buffer chronometer-default-buffer
    (when chronometer-paused
        (chronometer-increment-start-time))
    (let ((time-elapsed (format-time-string "%H:%M:%S" (time-subtract (current-time) chronometer-start-time) t))
          (minutes-elapsed (chronometer-minutes-elapsed))
          (inhibit-read-only t))
      (erase-buffer)
      (goto-char (point-min))
      (insert chronometer-prompt time-elapsed)
      (when chronometer-paused
        (insert chronometer-prompt-space chronometer-prompt-paused))
      (if chronometer-alarm-ringing
          (progn
            (insert chronometer-prompt-space chronometer-prompt-alarm)
            (chronometer-alarm-alert))
        (when chronometer-alarm
          (insert chronometer-prompt-space (chronometer-prompt-alarm-set chronometer-alarm))
          (when (and (>= minutes-elapsed (string-to-number chronometer-alarm))
                     (null chronometer-alarm-ringing))
            (setq chronometer-alarm-ringing t)
            (chronometer)))))))

(define-derived-mode chronometer-mode special-mode "Chronometer"
  "Major mode for controlling Chronometer, use `M-x ‘chronometer’
  RET' to start it and the following commands to interact with
  it:

\\{chronometer-mode-map}")

;;;###autoload
(defun chronometer ()
  "A [not so] simple chronometer.

Use this function to start, it will automatically start from zero
and will keep incrementing every second. Use the following
commands to interact with it:

\\{chronometer-mode-map}"
  (interactive)
  (chronometer-first-run)
  (chronometer-show-buffer)
  (chronometer-mode))

(provide 'chronometer)

;;; chronometer.el ends here
