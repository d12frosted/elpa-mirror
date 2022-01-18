;;; tzc.el --- Converts time between different time zones  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Homepage: https://github.com/md-arif-shaikh/tzc
;; Version: 0.0.1
;; Package-Version: 20220118.557
;; Package-Commit: d1f08fff5d4f9c2584a3b405464c6a92000f62b3
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience

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

;; Convert time between different time zones.
;;
;; `tzc-convert-time` to convert a given time from one time-zone to another
;; `tzc-convert-time-to-favourite-time-zones` to convert a given time from one
;; time-zone to a list of favourite time-zones.
;;
;; A list of favourite time zones could be set using like following
;; (setq tzc-favourite-time-zones '("Asia/Kolkata" "America/New_York" "Europe/Berlin"))

;;; Code:
(require 'timezone)

(defcustom tzc-favourite-time-zones '("UTC+0000"
				      "Asia/Kolkata"
				      "America/New_York"
				      "UK/London"
				      "Europe/Berlin"
				      "Asia/Shanghai"
				      "Asia/Tokyo")
  "List of favourite time zones."
  :type 'list
  :group 'tzc)

(defcustom tzc-main-dir (cond ((string-equal system-type "darwin") "/usr/share/zoneinfo.default/")
			      ((string-equal system-type "gnu/linux") "/usr/share/zoneinfo/"))
  "Main directory to look for the zoneinfo data on your system"
  :type 'string
  :group 'tzc)

(defcustom tzc-areas '("Africa" "America" "Antarctica" "Arctic" "Asia" "Atlantic" "Australia" "Brazil" "Canada" "Chile" "Europe" "Indian" "Mexico" "Pacific" "US")
  "Areas to look for the timezone info"
  :type 'list
  :group 'tzc)

(defun tzc--get-time-zones ()
  "Get list of time zones from system."
  (let* ((zones '()))
    (dolist (area tzc-areas)
      (setq zones (append zones (mapcar (lambda (zone) (concat area "/" zone)) (directory-files (concat tzc-main-dir area) nil directory-files-no-dot-files-regexp)))))
    zones))

(defcustom tzc-time-zones (delete-dups (append tzc-favourite-time-zones (tzc--get-time-zones)))
  "List of time zones."
  :type 'list
  :group 'tzc)

(defun tzc--+-p (timeshift)
  "Check if the TIMESHIFT in contain +- string."
  (when (stringp timeshift)
   (or (string-match-p "+" timeshift) (string-match-p "-" timeshift))))

(defun tzc--+-position (timeshift)
  "Position of +- in a TIMESHIFT string."
  (or (string-match "+" timeshift) (string-match "-" timeshift)))

(defun tzc--format-time-shift (timeshift)
  "Convert a TIMESHIFT to proper format of +-HHMM."
  (let ((timeshiftstring (substring timeshift (tzc--+-position timeshift))))
    (cond ((= (length timeshiftstring) 3) (concat timeshiftstring "00"))
	  ((= (length timeshiftstring) 4) (concat timeshiftstring "0"))
	  (t timeshiftstring))))

(defun tzc--get-offset (time-zone)
  "Get the time offset for TIME-ZONE."
  (if (tzc--+-p time-zone)
      (tzc--format-time-shift time-zone)
    (format-time-string "%z" nil time-zone)))

(defun tzc--get-time-shift-between-zones (from-zone to-zone)
  "Get the shift in time between FROM-ZONE and TO-ZONE."
  (let* ((from-zone-offset (tzc--get-offset from-zone))
	 (to-zone-offset (tzc--get-offset to-zone)))
    (- (timezone-zone-to-minute to-zone-offset) (timezone-zone-to-minute from-zone-offset))))

(defun tzc--get-hour (time-string)
  "Get the hour from TIME-STRING."
  (let* ((hour (decoded-time-hour (parse-time-string time-string))))
    (if (string-match-p "PM" (upcase time-string))
	(+ hour 12)
      hour)))

(defun tzc--get-hour-shift (from-zone to-zone)
  "Get the shift in hour between FROM-ZONE and TO-ZONE."
  (/ (tzc--get-time-shift-between-zones from-zone to-zone) 60))

(defun tzc--get-minute-shift (from-zone to-zone)
  "Get the shift in minute between FROM-ZONE and TO-ZONE."
  (% (tzc--get-time-shift-between-zones from-zone to-zone) 60))

(defun tzc--get-converted-time (time-string from-zone to-zone)
  "Convert a given time as given in TIME-STRING from FROM-ZONE to TO-ZONE.
Returns a list of the form `(min hour day)`."
  (let* ((from-zone-hour (tzc--get-hour time-string))
	 (from-zone-minute (decoded-time-minute (parse-time-string time-string)))
	 (hour-shift (tzc--get-hour-shift from-zone to-zone))
	 (minute-shift (tzc--get-minute-shift from-zone to-zone))
	 (to-zone-hour (+ from-zone-hour hour-shift))
	 (to-zone-minute (+ from-zone-minute minute-shift))
	 (to-zone-day "+0d"))
    (cond ((< to-zone-minute 0) (setq to-zone-minute (+ to-zone-minute 60)
				      to-zone-hour (1- to-zone-hour)))
	  ((>= to-zone-minute 60) (setq to-zone-minute (- to-zone-minute 60)
					to-zone-hour (1+ to-zone-hour))))
    (cond ((< to-zone-hour 0) (setq to-zone-hour (+ to-zone-hour 24)
				    to-zone-day "-1d"))
	  ((>= to-zone-hour 24) (setq to-zone-hour (- to-zone-hour 24)
				      to-zone-day "+1d")))
    (list to-zone-minute to-zone-hour to-zone-day)))

(defun tzc--get-converted-time-string (time-string from-zone to-zone)
  "Convert a given time as given in TIME-STRING from FROM-ZONE to TO-ZONE."
  (unless (string-match-p ":" time-string)
    (user-error "Seems like the time is not specified in HH:MM format.  This might lead to
erroneous calculation.  Please use correct format for time!"))
  (let* ((to-zone-list (tzc--get-converted-time time-string from-zone to-zone))
	 (minute (nth 0 to-zone-list))
	 (hour (nth 1 to-zone-list))
	 (day (nth 2 to-zone-list))
	 (to-time-string (format "%02d:%02d" hour minute))
	 (to-day-string))
    (unless (string-equal day "+0d")
      (setq to-day-string (format " %s" day)))
    (concat to-time-string to-day-string " " to-zone)))

(defun tzc--time-list (time-zone)
  "A list of times to display for completion based on TIME-ZONE."
  (let* ((time-now (format-time-string "%H:%M" nil time-zone))
	 (hour-now (string-to-number (format-time-string "%H" nil time-zone)))
	 (time-list-after (cl-loop for time in (number-sequence (1+ hour-now) 23)
				   collect (format "%02d:00" time)))
	 (time-list-before (cl-loop for time in (number-sequence 0 (1- hour-now))
				   collect (format "%02d:00" time))))
    (append (cons time-now time-list-after) time-list-before)))

(defun tzc-convert-time (time-string from-zone to-zone)
  "Convert a given time as given in TIME-STRING from FROM-ZONE to TO-ZONE."
  (interactive
   (let* ((from-zone (completing-read "Enter From Zone: " tzc-time-zones))
	  (to-zone (completing-read (format "Convert time from %s to: " from-zone) tzc-time-zones))
	  (time-string (completing-read (format "Enter time to covert from %s to %s: " from-zone to-zone) (tzc--time-list from-zone))))
   (list time-string from-zone to-zone)))
  (message (concat time-string " " from-zone " = "  (tzc--get-converted-time-string time-string from-zone to-zone))))

(defun tzc-convert-current-time (to-zone)
  "Convert current local time to TO-ZONE."
  (interactive (list (completing-read "Enter To Zone: " tzc-time-zones)))
  (let ((time-now (format-time-string "%H:%M")))
    (message (concat "Local Time " time-now " = "  (tzc--get-converted-time-string time-now nil to-zone)))))

(defun tzc-convert-time-to-favourite-time-zones (time-string from-zone)
  "Convert time in TIME-STRING from FROM-ZONE to `tzc-favourite-time-zones`."
  (interactive
   (let* ((from-zone (completing-read "Enter From Zone: " tzc-time-zones))
	  (time-string (completing-read "Enter time to covert: " (tzc--time-list from-zone))))
   (list time-string from-zone)))
  (with-current-buffer (generate-new-buffer "*tzc-times*")
    (insert time-string " " from-zone)
    (dolist (to-zone tzc-favourite-time-zones)
      (unless (string-equal to-zone from-zone)
	(insert " = " (tzc--get-converted-time-string time-string from-zone to-zone) "\n")))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
    (switch-to-buffer-other-window "*tzc-times*")))

(defun tzc-convert-current-time-to-favourite-time-zones ()
  "Convert current local time to `tzc-favourite-time-zones`."
  (interactive)
  (with-current-buffer (generate-new-buffer "*tzc-times*")
    (insert "Local Time " (format-time-string "%H:%M"))
    (dolist (to-zone tzc-favourite-time-zones)
      (unless (string-equal to-zone nil)
	(insert " = " (tzc--get-converted-time-string (format-time-string "%H:%M") nil to-zone) "\n")))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
    (switch-to-buffer-other-window "*tzc-times*")))

(defun tzc--get-zoneinfo-from-time-stamp (timestamp)
  "Get the zoneinfo Area/City from TIMESTAMP."
  (string-match "[a-z]+[/][a-z]+" timestamp)
  (match-string 0 timestamp))

(defun tzc-convert-time-at-mark (to-zone)
  "Convert time at the marked region to TO-ZONE."
  (interactive
   (list (completing-read "Enter To Zone:  " (tzc--get-time-zones))))
  (let* ((timestamp (buffer-substring-no-properties (mark) (point)))
	 (from-zone)
	 (hour)
	 (minute))
    (if (not (string-match-p ":" timestamp))
	(user-error "Seems like the time is not specified in HH:MM format.  This might lead to
erroneous calculation.  Please use correct format for time!")
      (setq hour (tzc--get-hour timestamp))
      (setq minute (decoded-time-minute (parse-time-string timestamp))))
    (cond ((tzc--+-p timestamp)
	   (setq from-zone (tzc--format-time-shift timestamp)))
	  (t (setq from-zone (tzc--get-zoneinfo-from-time-stamp timestamp))))
    (tzc-convert-time (format "%02d:%02d" hour minute) from-zone to-zone)))

(defun tzc-convert-and-replace-time-at-mark (to-zone)
  "Convert time at the marked region to TO-ZONE."
  (interactive
   (list (completing-read "Enter To Zone:  " (tzc--get-time-zones))))
  (let* ((converted-time-strings (split-string (tzc-convert-time-at-mark to-zone) " = "))
	 (converted-time (nth 1 converted-time-strings)))
    (kill-region (mark) (point))
    (insert converted-time)))

(provide 'tzc)
;;; tzc.el ends here
