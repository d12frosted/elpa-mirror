;;; battery-notifier.el --- Notify when battery capacity is low

;; This file is not part of Emacs

;; Copyright (C) 2021 by Jason Johnson
;; Package-Requires: ((alert "1.3"))
;; Package-Version: 20210521.1238
;; Package-Commit: ae2043db954e131d9de7347ab1a6107fd07e8893
;; Author:          Jason Johnson (jason@fullsteamlabs.com)
;; Maintainer:      Jason Johnson (jason@fullsteamlabs.com)
;; Created:         May 15, 2021
;; Keywords:        hardware, battery
;; URL: https://github.com/jasonmj/battery-notifier
;; Version: 0.2.2

;; COPYRIGHT NOTICE

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; version 3.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;  Simple package to notify when battery capacity is low and take action via
;;  hooks when battery capacity is critically low.  Allows for configuration
;;  of notification capacity threshold, action hook capacity threshold,
;;  notification function, critical capacity hooks, and check interval.
;;  This is a global minor mode.

;;; Usage:

;;  M-x `battery-notifer-mode'
;;      Toggles battery-notifier-mode on & off.  Optional arg turns
;;      battery-notifier-mode on if arg is a positive integer.

;;; Comments:

;;  Any comments, suggestions, bug reports or upgrade requests are
;;  welcome.  Please create issues or send pull requests via Github at
;;  https://github.com/jasonmj/battery-notifier.

;;; Change Log:

;;  See https://github.com/jasonmj/battery-notifer/commits/main

;;; Code:

;;; **************************************************************************
;;; ***** require
;;; **************************************************************************

(require 'alert)
(require 'battery)

;;; **************************************************************************
;;; ***** define group
;;; **************************************************************************

(defgroup battery-notifier nil
  "Sends notifications or run actions when battery capacity is low."
  :prefix "battery-notifier-"
  :group 'battery)

;;; **************************************************************************
;;; ***** define customization options
;;; **************************************************************************

(defcustom battery-notifier-notification-function 'battery-notifier-alert
  "The function to use when displaying low battery notifications."
  :type 'function
  :group 'battery-notifier)

(defcustom battery-notifier-capacity-low-threshold 15
  "The threshold below which low battery notifications should be sent."
  :type '(choice
          (integer :tag "Specify notification threshold")
          (const :tag "Do nothing" nil))
  :group 'battery-notifier)

(defcustom battery-notifier-capacity-critical-threshold 5
  "The threshold below which the 'battery-notifier-capacity-critical-hook' will run."
  :type '(choice
          (integer :tag "Specify critical capacity threshold")
          (const :tag "Do nothing" nil))
  :group 'battery-notifier)

(defcustom battery-notifier-timer-interval 30
  "The interval at which the battery status should be checked."
  :type 'integer
  :group 'battery-notifier)

(defcustom battery-notifier-capacity-critical-hook nil
  "Hooks run when battery capacity is critically low."
  :type 'hook
  :group 'battery-notifier)

(defvar battery-notifier-timer nil
  "A variable for keeping track of the battery notifier timer.")

;;; **************************************************************************
;;; ***** utility functions
;;; **************************************************************************

(defun battery-notifier-alert (message)
  "A simple wrapper to display the MESSAGE via alert with title and severity."
  (alert message :title "Battery Notifier" :severity 'high))

(defun battery-notifier-get-device-capacity ()
  "Check the current capacity of the battery."
  (string-to-number (battery-format "%p" (funcall battery-status-function))))

(defun battery-notifier-get-device-status ()
  "Check the current status of the battery."
  (battery-format "%B" (funcall battery-status-function)))

(defun battery-notifier-check ()
  "Get the current state of the battery and either notify or run hooks if low."
  (let ((battery-capacity (battery-notifier-get-device-capacity))
        (battery-status (battery-notifier-get-device-status)))
    (when (equal battery-status "Discharging")
      (when (and battery-notifier-capacity-low-threshold
                 (< battery-capacity battery-notifier-capacity-low-threshold))
        (funcall battery-notifier-notification-function
                 (concat "Low Battery: " (number-to-string battery-capacity) "%")))
      (when (and battery-notifier-capacity-critical-threshold
                 (< battery-capacity battery-notifier-capacity-critical-threshold))
        (run-hooks 'battery-notifier-capacity-critical-hook)))))

(defun battery-notifier-watch ()
  "Start the 'battery-notifier-timer'."
  (setq battery-notifier-timer
        (run-with-timer 2 battery-notifier-timer-interval 'battery-notifier-check)))

;;; **************************************************************************
;;; ***** mode definition
;;; **************************************************************************

;;;###autoload
(define-minor-mode battery-notifier-mode
  "Toggle use of 'battery-notifier-mode'.
This global minor mode sends notifications when battery capacity is low
and runs action hooks when battery capacity is critically low."
  :lighter " enabled"
  :init-value nil
  :keymap nil
  :global t
  :group 'battery-notifier

  (if battery-notifier-mode
      (battery-notifier-watch)
    (cancel-timer battery-notifier-timer)))

(provide 'battery-notifier)

;;; battery-notifier.el ends here
