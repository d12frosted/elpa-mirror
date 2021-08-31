;;; streak.el --- Track a daily streak in your Mode Line -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Colin Woodbury
;;
;; Author: Colin Woodbury <https://www.fosskers.ca>
;; Maintainer: Colin Woodbury <colin@fosskers.ca>
;; Created: June 18, 2021
;; Modified: August 29, 2021
;; Version: 2.0.0
;; Package-Version: 20210831.1609
;; Package-Commit: bcc2ac219c5840f850ffda75a86a456d2f146eef
;; Keywords: calendar
;; Homepage: https://github.com/fosskers/streak
;; Package-Requires: ((emacs "27.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;; `streak-mode' is a minor mode for tracking some daily streak.
;; Exercising? Learning a language? Track your success in your mode line!
;;
;; If you've broken your streak, it can be reset with `streak-reset'. Don't
;; worry, you'll do better next time!
;;
;;; Code:

(require 'xdg)

(defvar streak--streak-message nil
  "String representation of the current streak.")

;;;###autoload
(define-minor-mode streak-mode
  "Display the number of days of a successful streak in the mode line."
  :init-value nil
  :global t
  :group 'streak
  :lighter " Streak"
  (if streak-mode
      (progn
        (unless streak--streak-message
          (streak-update))
        (add-to-list 'global-mode-string '(t streak--streak-message)))
    (setq global-mode-string (delete '(t streak--streak-message) global-mode-string))))

;; TODO Use `file-name-concat' once Emacs 28 is the lowest supported version.
(defcustom streak-file (expand-file-name "streak" (xdg-cache-home))
  "The location to save the start of the current streak."
  :group 'streak
  :type 'file)

(defcustom streak-hour-pattern " %dh "
  "A format string for displaying the successful hours of the current streak."
  :group 'streak
  :type 'string)

(defcustom streak-day-pattern " %dd "
  "A format string for displaying the successful days of the current streak."
  :group 'streak
  :type 'string)

(defun streak--seconds-since-unix-epoch ()
  "The number of seconds since the Unix Epoch."
  (time-convert nil 'integer))

(defun streak--current ()
  "Read the streak file for the current streak."
  (streak--render (streak--current-int)))

(defun streak--current-int ()
  "Read the streak file for the current streak."
  (if (not (file-exists-p streak-file))
      (streak--init)
    (when-let ((buffer (find-file-noselect streak-file)))
      (string-to-number (streak--buffer-first-line buffer)))))

(defun streak--render (start)
  "Give a human-friendly presentation of the streak, given its START."
  (let* ((now (streak--seconds-since-unix-epoch))
         (seconds-per-hour 3600)
         (seconds-per-day 86400)
         (delta (/ (- now start) seconds-per-day)) ;; int
         (hours (/ (- now start) seconds-per-hour))) ;; int
    (cond ((= 0 delta) (format streak-hour-pattern hours))
          (t (format streak-day-pattern delta)))))

(defun streak--buffer-first-line (buffer)
  "Yield the first line of a BUFFER as a string."
  (with-current-buffer buffer
    (goto-char (point-min))
    (buffer-substring-no-properties (line-beginning-position) (line-end-position))))

(defun streak--init ()
  "Initialize the streak file but don't set the mode line.
Returns the time that was set."
  (let ((now (streak--seconds-since-unix-epoch)))
    (message "Streak: Setting your streak start to the current time.")
    (streak--set now)
    now))

;;;###autoload
(defun streak-reset ()
  "Mark the current time as the start of a new streak."
  (interactive)
  (let ((now (streak--init)))
    (setq streak--streak-message (streak--render now))))

(defun streak--set (seconds)
  "Set the streak in the streak file, given SECONDS since the Unix epoch."
  (when-let ((buffer (find-file-noselect streak-file))
             (date (format-time-string "%Y-%m-%d %H:%M" seconds (current-time-zone))))
    (with-current-buffer buffer
      (goto-char (point-min))
      (insert (format "%d ;; %s\n" seconds date))
      (save-buffer))))

;;;###autoload
(defun streak-increment ()
  "Move the streak start back by 1 day, increasing the overall streak days."
  (interactive)
  (let* ((start (streak--current-int))
         (seconds-per-day 86400)
         (new (- start seconds-per-day)))
    (streak--set new)
    (setq streak--streak-message (streak--render new))))

;;;###autoload
(defun streak-decrement ()
  "Move the streak start up by 1 day, decreasing the overall streak days."
  (interactive)
  (let* ((start (streak--current-int))
         (seconds-per-day 86400)
         (new (+ start seconds-per-day)))
    (streak--set new)
    (setq streak--streak-message (streak--render new))))

;;;###autoload
(defun streak-update ()
  "Reread the streak file and update the mode line."
  (interactive)
  (setq streak--streak-message (streak--current)))

(provide 'streak)
;;; streak.el ends here
