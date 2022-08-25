;;; speeddating.el --- Increase date and time at point  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/emacs-speeddating
;; Package-Requires: ((emacs "25"))
;; Package-Version: 20180319.723
;; Package-Commit: eeaf90cd10e376bff5a295590a3d5f7fd1402523
;; Compatibility: GNU Emacs 25
;; Keywords: date time
;; Created: Thu, 15 Mar 2018 15:17:39 +0800
;; Version: 0

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

;; Increase date and time at point

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'seq)
(require 'pcase)
(require 'rx)
(require 'thingatpt)                    ; `thing-at-point-looking-at'

;;;; Custom options

(defgroup speeddating nil
  "Increase date and time at point."
  :group 'convenience)

;; (info "(elisp) Time Parsing")
(defcustom speeddating-formats
  '("%a, %d %b %Y %H:%M:%S %z" ; Sun, 18 Mar 2018 01:20:20 +0800  Email, date --rfc-email
    "%a %b %d %H:%M:%S %Y %z"  ; Sun Mar 18 00:57:15 2018 +0800   Git log
    "%Y-%m-%dT%H:%M:%S%:z"     ; 2018-03-18T02:54:38+08:00        ISO 8601, date --iso-8601=seconds
    "%a %b %_d %H:%M:%S %Z %Y" ; Sun Mar 18 03:40:23 CST 2018     date
    "%a %b %-d %H:%M:%S %Y %Z" ; Mon Mar 19 00:53:56 2018 CST     Reddit
    "%-d %B %Y, at %H:%M"      ; 19 March 2018, at 01:02          Wikipedia
    ;; TODO Mar 19, 2018, 12:41 AM GMT+8 GitHub
    ;; TODO 2018-03-18T16:41:48Z
    "%Y-%m-%d %H:%M:%S"        ; 2018-03-18 20:17:19
    "%Y-%m-%d %H:%M"           ; 2018-03-18 20:17
    "%A, %B %d, %Y"            ; Sunday, March 18, 2018
    "%d %B %Y"                 ; 18 March 2018
    "%d %b %Y"                 ; 18 Mar 2018
    "%B %-d, %Y"               ; April 9, 2018
    "%Y-%m-%d"                 ; 2018-03-18
    "%Y/%m/%d"                 ; 2018/03/18
    "%H:%M:%S"
    "%Y"
    "%A")
  "Date and time formats.
The format uses the same syntax as `format-time-string'."
  :type '(repeat (choice string))
  :group 'speeddating)

;;;; Utility functions

;; The built-in `alist-get' allows only `eq' for testing key before 26.1
(defun speeddating--alist-get (key alist)
  (cdr (assoc key alist)))

(defvar speeddating--log-buffer "*Debug Speeddating Log*")
;; (get-buffer-create speeddating--log-buffer)

(defun speeddating--log (format-string &rest args)
  (let ((buffer (get-buffer speeddating--log-buffer)))
    (when buffer
      (with-current-buffer buffer
        (goto-char (point-max))
        (insert
         (format "%s %s\n"
                 (propertize (format-time-string "%H:%M:%S") 'face 'font-lock-string-face)
                 (apply #'format (cons format-string args))))))))

;;;; Internal variables and functions

(defvar speeddating--abbrev-weekdays
  '("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"))

(defvar speeddating--full-weekdays
  '("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"))

(defvar speeddating--abbrev-months
  '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))

(defvar speeddating--full-months
  '("January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December"))

;; (SEC MINUTE HOUR DAY MONTH YEAR DOW DST UTCOFF)
;;   0    1     2    3    4    5    6   7     8

;; TODO: Use `time-add' instead ?
(defun speeddating--time-inc-sec    (time inc) (cl-incf (nth 0 time) inc))
(defun speeddating--time-inc-minute (time inc) (cl-incf (nth 1 time) inc))
(defun speeddating--time-inc-hour   (time inc) (cl-incf (nth 2 time) inc))
(defun speeddating--time-inc-day    (time inc) (cl-incf (nth 3 time) inc))
(defun speeddating--time-inc-month  (time inc) (cl-incf (nth 4 time) inc))
(defun speeddating--time-inc-year   (time inc) (cl-incf (nth 5 time) inc))

(defmacro speeddating--time-set-sec    (val) `(lambda (time string) (setf (nth 0 time) ,val)))
(defmacro speeddating--time-set-minute (val) `(lambda (time string) (setf (nth 1 time) ,val)))
(defmacro speeddating--time-set-hour   (val) `(lambda (time string) (setf (nth 2 time) ,val)))
(defmacro speeddating--time-set-day    (val) `(lambda (time string) (setf (nth 3 time) ,val)))
(defmacro speeddating--time-set-month  (val) `(lambda (time string) (setf (nth 4 time) ,val)))
(defmacro speeddating--time-set-year   (val) `(lambda (time string) (setf (nth 5 time) ,val)))
(defmacro speeddating--time-set-dow    (val) `(lambda (time string) (setf (nth 6 time) ,val)))

;; (info "(elisp) Time Parsing")
(defvar speeddating--format-spec
  (list
   (list "%a"
         :reg (regexp-opt speeddating--abbrev-weekdays t)
         :len 3
         :set (speeddating--time-set-dow (1+ (seq-position speeddating--abbrev-weekdays string)))
         :inc #'speeddating--time-inc-day)
   (list "%A"
         :reg (regexp-opt speeddating--full-weekdays t)
         :len 9
         :set (speeddating--time-set-dow (1+ (seq-position speeddating--full-weekdays string)))
         :inc #'speeddating--time-inc-day)
   (list "%b"
         :reg (regexp-opt speeddating--abbrev-months t)
         :len 3
         :set (speeddating--time-set-month (1+ (seq-position speeddating--abbrev-months string)))
         :inc #'speeddating--time-inc-month)
   (list "%B"
         :reg (regexp-opt speeddating--full-months t)
         :len 9
         :set (speeddating--time-set-month (1+ (seq-position speeddating--full-months string)))
         :inc #'speeddating--time-inc-month)
   (list "%Y"
         :reg (rx (group (repeat 4 digit)))
         :len 4
         :set (speeddating--time-set-year (string-to-number string))
         :inc #'speeddating--time-inc-year)
   (list "%m"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-month (string-to-number string))
         :inc #'speeddating--time-inc-month)
   (list "%_m"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-month (string-to-number string))
         :inc #'speeddating--time-inc-month)
   (list "%d"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-day (string-to-number string))
         :inc #'speeddating--time-inc-day)
   (list "%_d"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-day (string-to-number string))
         :inc #'speeddating--time-inc-day)
   (list "%-d"
         :reg (rx (group (repeat 1 2 digit)))
         :len 2
         :set (speeddating--time-set-day (string-to-number string))
         :inc #'speeddating--time-inc-day)
   (list "%H"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-hour (string-to-number string))
         :inc #'speeddating--time-inc-hour)
   (list "%M"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-minute (string-to-number string))
         :inc #'speeddating--time-inc-minute)
   (list "%S"
         :reg (rx (group (repeat 2 digit)))
         :len 2
         :set (speeddating--time-set-sec (string-to-number string))
         :inc #'speeddating--time-inc-sec)
   (list "%z"
         :reg (rx (group (or "-" "+") (repeat 4 digit)))
         :len 5
         :set (lambda (time string)
                (let ((sign (intern (substring string 0 1)))
                      (hour (string-to-number (substring string 1 3)))
                      (minute (string-to-number (substring string 3))))
                  (setf (nth 8 time) (funcall sign (+ (* hour 60 60) (* minute 60))))))
         :inc (lambda (_time _inc)
                (user-error
                 "Increasing or decreasing time zone is not yet supported")))
   (list "%:z"
         :reg (rx (group (or "-" "+") (repeat 2 digit) ":" (repeat 2 digit)))
         :len (length "+08:00")
         :set (lambda (time string)
                (let ((sign (intern (substring string 0 1)))
                      (hour (string-to-number (substring string 1 3)))
                      (minute (string-to-number (substring string 4))))
                  (setf (nth 8 time) (funcall sign (+ (* hour 60 60) (* minute 60))))))
         :inc (lambda (_time _inc)
                (user-error
                 "Increasing or decreasing time zone is not yet supported")))
   (list "%::z"
         :reg (rx (group (or "-" "+") (repeat 2 digit) ":" (repeat 2 digit) ":" (repeat 2 digit)))
         :len (length "+08:00:00")
         :set (lambda (time string)
                (let ((sign (intern (substring string 0 1)))
                      (hour (string-to-number (substring string 1 3)))
                      (minute (string-to-number (substring string 4 6)))
                      (second (string-to-number (substring string 6))))
                  (setf (nth 8 time) (funcall sign (+ (* hour 60 60) (* minute 60) second)))))
         :inc (lambda (_time _inc)
                (user-error
                 "Increasing or decreasing time zone is not yet supported")))
   (list "%:::z"
         :reg (rx (group (or "-" "+") (repeat 2 digit)))
         :len (length "+08")
         :set (lambda (time string)
                (let ((sign (intern (substring string 0 1)))
                      (hour (string-to-number (substring string 1 3))))
                  (setf (nth 8 time) (funcall sign (* hour 60 60)))))
         :inc (lambda (_time _inc)
                (user-error
                 "Increasing or decreasing time zone is not yet supported")))
   (list "%Z"
         :reg (rx (group (repeat 2 5 (in "A-Z"))))
         :len 5
         :set (lambda (time string)
                (cond ((string= string "UTC")
                       (setf (nth 8 time) 0))
                      ((equal string (cadr (current-time-zone)))
                       (setf (nth 8 time) (car (current-time-zone))))
                      (t (user-error "Unsupported time zone abbreviation %s" string))))
         :inc (lambda (_time _inc)
                (user-error
                 "Increasing or decreasing time zone is not yet supported"))))
  "List of (%-spec regexp length set inc).")

(defun speeddating--format-split (string)
  (let ((%-specs (mapcar #'car speeddating--format-spec))
        (list ()))
    (while (> (length string) 0)
      (if (string-prefix-p "%" string)
          (let ((%-spec (seq-find
                         (lambda (prefix) (string-prefix-p prefix string))
                         %-specs)))
            (cond (%-spec
                   (push %-spec list)
                   (setq string (substring string (length %-spec))))
                  ((string-prefix-p "%%" string)
                   (push "%" list)
                   (push "%" list)
                   (setq string (substring string (length "%%"))))
                  ((string-prefix-p "%t" string)
                   (push "%" list)
                   (push "t" list)
                   (setq string (substring string (length "%t"))))
                  (t (error "Unsupported format %s" string))))
        (push (substring string 0 1) list)
        (setq string (substring string 1))))
    (nreverse list)))

;; (speeddating--format-split "%Y-%m-%d")
;;      => ("%Y" "-" "%m" "-" "%d")

(defun speeddating--format-to-regexp (string)
  (mapconcat
   (lambda (x)
     (if (= (length x) 1)
         (regexp-quote x)
       (let ((plist (speeddating--alist-get x speeddating--format-spec)))
         (if plist (plist-get plist :reg) (error "Unsupported format %s" x)))))
   (speeddating--format-split string) ""))

;; (speeddating--format-to-regexp "%Y-%m-%d")
;;      => "\\([[:digit:]]\\{4\\}\\)-\\([[:digit:]]\\{2\\}\\)-\\([[:digit:]]\\{2\\}\\)"

(defun speeddating--format-length (string)
  (apply
   #'+
   (mapcar
    (lambda (x)
      (if (= (length x) 1)
          1
        (let ((plist (speeddating--alist-get x speeddating--format-spec)))
          (if plist (plist-get plist :len) (error "Unsupported format %s" x)))))
    (speeddating--format-split string))))

;; (speeddating--format-length "%Y-%m-%d")
;;      => 10

(defun speeddating--format-to-list (string)
  (seq-filter
   (lambda (x)
     (when (> (length x) 1)
       (if (speeddating--alist-get x speeddating--format-spec)
           t
         (error "Unsupported %s" x))))
   (speeddating--format-split string)))

;; (speeddating--format-to-list "%Y-%m-%d")
;;      => ("%Y" "%m" "%d")

(defun speeddating--looking-at (format-string)
  (thing-at-point-looking-at
   (speeddating--format-to-regexp format-string)
   (1- (speeddating--format-length format-string))))

(defun speeddating--time-normalize (time)
  (pcase-let ((`(,_sec0 ,_minute0 ,_hour0 ,day0 ,month0 ,year0 ,dow0 ,_dst0 ,utcoff0) (decode-time))
              (`(,sec ,minute ,hour ,day ,month ,year ,dow ,dst ,utcoff) time))
    (setq sec (or sec 0)
          minute (or minute 0)
          hour (or hour 0)
          utcoff (or utcoff utcoff0))
    (setq month (or month month0)
          year (or year year0))
    (if (null dow)
        (setq day (or day day0))
      (setq day (or day (+ day0 (- dow dow0)))))
    (list sec minute hour day month year dow dst utcoff)))

(defun speeddating--time-at-point-1 (format-string)
  (when (speeddating--looking-at format-string)
    (speeddating--log "1. '%s' =~ '%s'" (match-string 0) format-string)
    (let ((time (list nil nil nil nil nil nil nil nil nil)))
      ;; `seq-do-indexed' is not available in Emacs 25
      (cl-loop for x in (speeddating--format-to-list format-string)
               for index from 1
               do (let ((plist (speeddating--alist-get x speeddating--format-spec)))
                    (funcall (plist-get plist :set) time (match-string index))))
      (speeddating--log "2. %s" time)
      ;; Normalize time
      (setq time (speeddating--time-normalize time))
      (speeddating--log "3. %s" time)
      time)))

(defun speeddating-time-at-point ()
  (seq-some
   (lambda (format-string)
     (let ((time (speeddating--time-at-point-1 format-string)))
       (when time
         (list format-string time))))
   speeddating-formats))

(defun speeddating--on-subexp-p (num)
  (and (>= (point) (match-beginning num))
       (<  (point) (match-end num))))

(defun speeddating--replace (format-string time)
  (let ((new (format-time-string format-string (apply #'encode-time time) (nth 8 time)))
        (old-point (point)))
    (speeddating--log "4. '%s' => '%s'\n%c" (match-string 0) new 12)
    (delete-region (match-beginning 0) (match-end 0))
    (insert new)
    (goto-char old-point)))

(defun speeddating--increase-1 (format-string time inc)
  (let ((list (speeddating--format-to-list format-string))
        (group 1)
        (found nil))
    (while (and list (null found))
      (when (speeddating--on-subexp-p group)
        (setq found (car list)))
      (pop list)
      (cl-incf group))
    (if found
        (let ((plist (speeddating--alist-get found speeddating--format-spec)))
          (funcall (plist-get plist :inc) time inc)
          (speeddating--replace format-string time))
      (user-error "Don't know which field to increase or decrease, try to move point"))))

;;;; User commands

;;;###autoload
(defun speeddating-increase (inc)
  "Increase date and time at point by INC."
  (interactive "*p")
  (let ((format-string-and-time (speeddating-time-at-point)))
    (if format-string-and-time
        (apply #'speeddating--increase-1 `(,@format-string-and-time ,inc))
      (user-error
       "No date and time at point or speeddating doesn't yet understand its format"))))

;;;###autoload
(defun speeddating-decrease (dec)
  "Decrease date and time at point by DEC."
  (interactive "*p")
  (speeddating-increase (- dec)))

(defun speeddating-parse-time-string (string)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (speeddating-time-at-point)))

(provide 'speeddating)
;;; speeddating.el ends here
