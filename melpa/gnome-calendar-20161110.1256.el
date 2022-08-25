;;; gnome-calendar.el --- Integration with the GNOME Shell calendar

;; Copyright (C) 2013-2016 Nicolas Petton
;;
;; Author: Nicolas Petton <nicolas@petton.fr>
;; Keywords: gnome calendar
;; Package-Version: 20161110.1256
;; Package-Commit: 668591bec95c23934c5e1ef100cec4824e7cb25d
;; Package: gnome-calendar

;; Version: 0.3

;; gnome-calendar is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.
;;
;; gnome-calendar.el is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;;; Commentary:
;;; GNOME Shell calendar integration with Emacs.

;;; Code:

(require 'dbus)
(require 'time-date)

(defvar gsc-gnome-calendar-dbus-object nil)

(defvar gsc-get-items-function nil
  "Function to be called to retrieve items.")

(defun gnome-shell-calendar-register-service (function)
  "Register to the GnomeShell calendar service.
FUNCTION is called to fill the Gnome calendar with items."
  (setq gsc-get-items-function function)
  (dbus-register-service :session
                         "org.gnome.Shell.CalendarServer"
                         :replace-existing)
  (setq gsc-gnome-calendar-dbus-object
        (dbus-register-method :session
                              "org.gnome.Shell.CalendarServer"
                              "/org/gnome/Shell/CalendarServer"
                              "org.gnome.Shell.CalendarServer"
                              "GetEvents"
                              'gsc-select-items)))

(defun gnome-shell-calendar-unregister-service ()
  "Unregister from the DBus service."
  (when gsc-gnome-calendar-dbus-object
    (dbus-unregister-object gsc-gnome-calendar-dbus-object)
    (dbus-unregister-service :session "org.gnome.Shell.CalendarServer")
    (setq gsc-gnome-calendar-dbus-object nil)))

(defun gsc-select-items (since until force-reload)
  "Return a list of calendar events.
The events are filtered between SINCE and UNTIL dates.
When FORCE-RELOAD is non-nil, reload all events."
  (let ((day-since (floor (time-to-number-of-days (seconds-to-time since))))
        (day-until (floor (time-to-number-of-days (seconds-to-time until))))
        (items (funcall gsc-get-items-function))
        selected-items)
    (dolist (item items)
      (let ((day (floor (time-to-number-of-days (cdr item)))))
        (when (and (>= day day-since)
                   (<= day day-until))
          (add-to-list 'selected-items item))))
    (list :array (gsc-items-to-dbus-entries selected-items))))

(defun gsc-items-to-dbus-entries (items)
  "Return a list of D-BUS entries built from ITEMS.
ITEMS are retieved wth `gsc-get-items-function'."
  (mapcar (lambda (item)
            (list :struct
                  ""
                  (car item)
                  ""
                  :boolean (not (gsc-item-has-time-p item))
                  :int64 (floor (time-to-seconds (cdr item)))
                  :int64 (+ 1 (floor (time-to-seconds (cdr item))))
                  (list :array :signature "{sv}")))
          items))

(defun gsc-item-has-time-p (item)
  "Return non-nil if ITEM has a time value as cdr."
  (let ((time (decode-time (cdr item))))
    (or (not (= 0 (nth 0 time)))
        (not (= 0 (nth 1 time)))
        (not (= 0 (nth 2 time))))))

(provide 'gnome-calendar)
;;; gnome-calendar.el ends here
