;;; tzc.el --- Converts time between different time zones  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Homepage: https://github.com/md-arif-shaikh/tzc
;; Version: 0.0.1
;; Package-Version: 20220513.434
;; Package-Commit: f4e2273b65ace1ea56c9824c3bdb97925c98c8ba
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
;; (setq tzc-favourite-time-zones-alist '(("Asia/Kolkata" "Kolkata") ("America/New_York" "New York") ("Europe/Berlin" "Berlin")))

;;; Code:
(require 'timezone)
(require 'subr-x)

(defvar tzc-color--time-zone-label "#98C379"
  "Color to indicate a time zone label.")
(defvar tzc-color--time-string "#56B6C2"
  "Color to indicate a time string.")
(defvar tzc-color--date-string "#C678DD"
  "Color to indicate a date string.")
(defvar tzc-color--offset-string "#E5C07B"
  "Color to indicate a offset string.")

(defface tzc-face-time-zone-label
  `((t :foreground ,tzc-color--time-zone-label
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for time zone label."
  :group 'tzc-face)

(defface tzc-face-time-string
  `((t :foreground ,tzc-color--time-string
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for time string."
  :group 'tzc-face)

(defface tzc-face-date-string
  `((t :foreground ,tzc-color--date-string
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for date string."
  :group 'tzc-face)

(defface tzc-face-offset-string
  `((t :foreground ,tzc-color--offset-string
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for offset string."
  :group 'tzc-face)

(defcustom tzc-use-date-in-world-clock t
  "Whether to use full date in world clock buffer."
  :type 'boolean
  :group 'tzc)

(defcustom tzc-use-offset-in-world-clock t
  "Whether to display offset in world clock buffer."
  :type 'boolean
  :group 'tzc)

(defcustom tzc-use-date-in-convert-time nil
  "Whether to use full date in when converting time."
  :type 'boolean
  :group 'tzc)

(defcustom tzc-favourite-time-zones-alist '(("Asia/Kolkata" "Kolkata")
					    ("UTC+0000" "UTC")
					    ("America/New_York" "New_York")
					    ("Europe/London" "London")
					    ("Europe/Berlin" "Berlin")
					    ("Asia/Shanghai" "Shanghai")
					    ("Asia/Tokyo" "Tokyo"))
  "Alist for favourite time zones containing timezone and label."
  :type '(repeat (list string string))
  :group 'tzc)

(defun tzc--favourite-time-zones ()
  "Get the list of favourite time zones."
  (mapcar #'car tzc-favourite-time-zones-alist))

(defun tzc--get-time-zone-label (time-zone)
  "Get the label for the TIME-ZONE."
  (cond ((member time-zone (tzc--favourite-time-zones))
	 (nth 1 (assoc time-zone tzc-favourite-time-zones-alist)))
	((string-match-p "/" time-zone)
	 (nth 1 (split-string time-zone "/")))
	(t time-zone)))

(defcustom tzc-main-dir (cond ((string-equal system-type "darwin") "/usr/share/zoneinfo.default/")
			      ((string-equal system-type "gnu/linux") "/usr/share/zoneinfo/"))
  "Main directory to look for the zoneinfo data on your system."
  :type 'string
  :group 'tzc)

(defcustom tzc-areas '("Africa" "America" "Antarctica" "Arctic" "Asia" "Atlantic" "Australia" "Brazil" "Canada" "Chile" "Europe" "Indian" "Mexico" "Pacific" "US")
  "Areas to look for the timezone info."
  :type 'list
  :group 'tzc)

(defun tzc--get-time-zones ()
  "Get list of time zones from system."
  (let* ((zones '()))
    (dolist (area tzc-areas)
      (setq zones (append zones (mapcar (lambda (zone) (concat area "/" zone)) (directory-files (concat tzc-main-dir area) nil directory-files-no-dot-files-regexp)))))
    zones))

(defcustom tzc-time-zones (delete-dups (append (tzc--favourite-time-zones) (tzc--get-time-zones)))
  "List of time zones."
  :type 'list
  :group 'tzc)

(defcustom tzc-world-clock-buffer-name "*tzc-wclock*"
  "Name of the `tzc-world-clock' buffer."
  :type 'string
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
	 (to-zone-day 0))
    (cond ((< to-zone-minute 0) (setq to-zone-minute (+ to-zone-minute 60)
				      to-zone-hour (1- to-zone-hour)))
	  ((>= to-zone-minute 60) (setq to-zone-minute (- to-zone-minute 60)
					to-zone-hour (1+ to-zone-hour))))
    (cond ((< to-zone-hour 0) (setq to-zone-hour (+ to-zone-hour 24)
				    to-zone-day (1- to-zone-day)))
	  ((>= to-zone-hour 24) (setq to-zone-hour (- to-zone-hour 24)
				      to-zone-day (1+ to-zone-day))))
    (list to-zone-minute to-zone-hour to-zone-day)))

(defun tzc--get-converted-time-string (time-string from-zone to-zone &optional use-date use-offset)
  "Convert a given time as given in TIME-STRING from FROM-ZONE to TO-ZONE.
If USE-DATE is non-nil then the full date and day is shown,
otherwise only relative information is shown. If USE-OFFSET is non-nil
then offset will be displayed."
  (unless (string-match-p ":" time-string)
    (user-error "Seems like the time is not specified in HH:MM format.  This might lead to
erroneous calculation.  Please use correct format for time!"))
  (let* ((to-zone-list (tzc--get-converted-time time-string from-zone to-zone))
	 (minute (nth 0 to-zone-list))
	 (hour (nth 1 to-zone-list))
	 (day (nth 2 to-zone-list))
	 (to-time-string (format "%02d:%02d" hour minute))
	 (to-day-string "")
	 (offset-string ""))
    (if use-date
	(setq to-day-string (format-time-string " %a %d %B %Y" (time-add (current-time) (days-to-time day))))
      (setq to-day-string (cond
			   ((= day 0) "")
			   ((> day 0) (format " +%sD" day))
			   ((< day 0) (format " %sD" day)))))
    (when use-offset
      (setq offset-string (format " %s" (tzc--get-offset to-zone))))
    (concat (propertize to-time-string 'face 'tzc-face-time-string)
	    (propertize to-day-string 'face 'tzc-face-date-string)
	    (propertize offset-string 'face 'tzc-face-offset-string))))

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
  (message (concat (propertize time-string 'face 'tzc-face-time-string) " "
		   (propertize (tzc--get-time-zone-label from-zone) 'face 'tzc-face-time-zone-label) " = "
		   (tzc--get-converted-time-string time-string from-zone to-zone tzc-use-date-in-convert-time) " "
		   (propertize (tzc--get-time-zone-label to-zone) 'face 'tzc-face-time-zone-label))))

(defun tzc-convert-current-time (to-zone)
  "Convert current local time to TO-ZONE."
  (interactive (list (completing-read "Enter To Zone: " tzc-time-zones)))
  (let ((time-now (format-time-string "%H:%M")))
    (message (concat "Local Time " time-now " = "  (tzc--get-converted-time-string time-now nil to-zone tzc-use-date-in-convert-time) " " (tzc--get-time-zone-label to-zone)))))

(defun tzc-convert-time-to-favourite-time-zones (time-string from-zone)
  "Convert time in TIME-STRING from FROM-ZONE to `(tzc--favourite-time-zones)`."
  (interactive
   (let* ((from-zone (completing-read "Enter From Zone: " tzc-time-zones))
	  (time-string (completing-read "Enter time to covert: " (tzc--time-list from-zone))))
   (list time-string from-zone)))
  (with-current-buffer (generate-new-buffer "*tzc-times*")
    (insert time-string " " (tzc--get-time-zone-label from-zone))
    (dolist (to-zone (tzc--favourite-time-zones))
      (unless (string-equal to-zone from-zone)
	(insert " = " (tzc--get-converted-time-string time-string from-zone to-zone) " " (tzc--get-time-zone-label to-zone) "\n")))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
    (switch-to-buffer-other-window "*tzc-times*")))

(defun tzc-convert-current-time-to-favourite-time-zones ()
  "Convert current local time to `(tzc--favourite-time-zones)`."
  (interactive)
  (with-current-buffer (generate-new-buffer tzc-world-clock-buffer-name)
    (dolist (to-zone (tzc--favourite-time-zones))
      (unless (string-equal to-zone nil)
	(insert (tzc--get-converted-time-string (format-time-string "%H:%M") nil to-zone) " " (tzc--get-time-zone-label to-zone) "\n")))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
    (switch-to-buffer-other-window tzc-world-clock-buffer-name)))

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

(define-derived-mode tzc-world-clock-mode special-mode "tzc world clock"
  "Major mode for buffer that displays times in various time zones.
See `tzc-world-clock'."
  :interactive nil
  (setq-local revert-buffer-function #'tzc-world-clock-update)
  (setq show-trailing-whitespace nil))

(defun tzc-world-clock-update (&optional _arg _noconfirm)
  "Update the `tzc-world-clock' buffer."
  (when (get-buffer tzc-world-clock-buffer-name)
    (with-current-buffer (get-buffer tzc-world-clock-buffer-name)
      (let ((inhibit-read-only t)
	    (op (point)))
        (erase-buffer)
        (dolist (to-zone (tzc--favourite-time-zones))
	  (unless (string-equal to-zone nil)
	    (insert (propertize (tzc--get-time-zone-label to-zone) 'face 'tzc-face-time-zone-label) " " (tzc--get-converted-time-string (format-time-string "%H:%M") nil to-zone tzc-use-date-in-world-clock tzc-use-offset-in-world-clock) "\n")))
	(align-regexp (point-min) (point-max) "\\(\\s-*\\) ")
        (goto-char op)))))

;;;###autoload
(defun tzc-world-clock-previous-or-next (previous-or-next)
    "Get the `tzc-world-clock' buffer for PREVIOUS-OR-NEXT hour."
  (when (get-buffer tzc-world-clock-buffer-name)
    (with-current-buffer (get-buffer tzc-world-clock-buffer-name)
      (let* ((inhibit-read-only t)
	     (op (point))
	     (first-line)
	     (time-zone-list)
	     (time)
	     (hour-now)
	     (min-now)
	     (hour-previous-or-next)
	     (zone))
	(goto-char (point-min))
	(setq first-line (thing-at-point 'line))
	(setq time-zone-list (split-string first-line))
	(setq time (nth 1 time-zone-list))
	(setq hour-now (string-to-number (substring time 0 2)))
	(setq min-now (string-to-number (substring time 3 5)))
	(setq hour-previous-or-next (if (string-equal previous-or-next "previous")
					(if (> min-now 0)
					    hour-now
					  (1- hour-now))
				      (1+ hour-now)))
	(cond ((>= hour-previous-or-next 24) (setq hour-previous-or-next (- hour-previous-or-next 24)))
	      ((< hour-previous-or-next 0) (setq hour-previous-or-next (+ hour-previous-or-next 24))))
	(setq zone (car (car tzc-favourite-time-zones-alist)))
        (erase-buffer)
        (dolist (to-zone (tzc--favourite-time-zones))
	  (unless (string-equal to-zone nil)
	    (insert  (propertize (tzc--get-time-zone-label to-zone) 'face 'tzc-face-time-zone-label) " " (tzc--get-converted-time-string (format "%s:00" hour-previous-or-next) zone to-zone tzc-use-date-in-world-clock tzc-use-offset-in-world-clock) "\n")))
	(align-regexp (point-min) (point-max) "\\(\\s-*\\) ")
	(goto-char op)))))

;;;###autoload
(defun tzc-world-clock-previous ()
  "Get the `tzc-world-clock` for the previous hour."
  (interactive)
  (tzc-world-clock-previous-or-next "previous"))

;;;###autoload
(defun tzc-world-clock-next ()
  "Get the `tzc-world-clock` for the next hour."
  (interactive)
  (tzc-world-clock-previous-or-next "next"))

;;;###autoload
(defvar tzc-world-clock-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" #'tzc-world-clock-next)
    (define-key map "p" #'tzc-world-clock-previous)
    map))

;;;###autoload
(defun tzc-world-clock ()
  "Display a world clock buffer for time zones in `tzc-favourite-time-zones-alist`."
  (interactive)
  (if-let ((buffer (get-buffer tzc-world-clock-buffer-name)))
      (pop-to-buffer buffer)
    (pop-to-buffer tzc-world-clock-buffer-name)
    (dolist (to-zone (tzc--favourite-time-zones))
      (unless (string-equal to-zone nil)
	(insert (propertize (tzc--get-time-zone-label to-zone) 'face 'tzc-face-time-zone-label) " " (tzc--get-converted-time-string (format-time-string "%H:%M") nil to-zone tzc-use-date-in-world-clock tzc-use-offset-in-world-clock) "\n")))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\) "))
  (tzc-world-clock-mode))

(defun tzc-check-time-zone (time-zone)
  "Check info for TIME-ZONE."
  (interactive "sEnter Time Zone: ")
  (if (member time-zone (tzc--get-time-zones))
      (progn
	(let* ((name (tzc--get-time-zone-label time-zone))
	       (offset (tzc--get-offset time-zone)))
	  (message "%s %s" name offset)))
    (message "%s is not a recognized time zone name." time-zone)))

(provide 'tzc)
;;; tzc.el ends here
