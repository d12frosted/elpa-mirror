;;; celestial-mode-line.el --- Show lunar phase and sunrise/-set time in modeline -*-coding: utf-8; lexical-binding: t; -*-

;; Copyright (C) 2017 craven@gmx.net

;; Author: Peter <craven@gmx.net>
;; URL: https://github.com/ecraven/celestial-mode-line
;; Package-Commit: 3f5794aca99b977f1592cf1ab4516ae7922196a1
;; Package-Version: 20180518.822
;; Package-X-Original-Version: 20180518
;; Package-Requires: ((emacs "24"))
;; Version: 0.1.2
;; Keywords: extensions
;; Created: 2017-12-05

;;; License:

;; Licensed under the GPLv3.

;;; Commentary:

;; Do something like the following to set this up:
;; 
;; (setq calendar-longitude 25.5)
;; (setq calendar-latitude 17.5)
;; (setq calendar-location-name "Some place")
;; (use-package celestial-mode-line
;;   :config
;;   (setq global-mode-string '("" celestial-mode-line-string display-time-string))
;;   (celestial-mode-line-start-timer))
;; 
;; The default icons are:
;; (defvar celestial-mode-line-phase-representation-alist '((0 . "○") (1 . "☽") (2 . "●") (3 . "☾")))
;; (defvar celestial-mode-line-sunrise-sunset-alist '((sunrise . "☀↑") (sunset . "☀↓")))
;;
;; You can get text-only icons as follows:
;; (defvar celestial-mode-line-phase-representation-alist '((0 . "( )") (1 . "|)") (2 . "(o)") (3 . "|)")))
;; (defvar celestial-mode-line-sunrise-sunset-alist '((sunrise . "*^") (sunset . "*v")))
;;
;;; Code:
(require 'calendar)
(require 'lunar)
(require 'solar)
(require 'cl-lib)

(defvar celestial-mode-line-phase-representation-alist '((0 . "○") (1 . "☽") (2 . "●") (3 . "☾")))
(defvar celestial-mode-line-sunrise-sunset-alist '((sunrise . "☀↑") (sunset . "☀↓")))

(defvar celestial-mode-line-string ""
  "Buffered mode-line string.")
(put 'celestial-mode-line-string 'risky-local-variable t) ;; for mode-line face

(defvar celestial-mode-line--timer nil
  "Interval timer object.")

(defgroup celestial-mode-line nil
  "Show lunar phase and sunrise/sunset in the mode-line."
  :group 'convenience
  :prefix "celestial-mode-line-")

(defcustom celestial-mode-line-prefix " "
  "Text to display before the lunar phase in the mode-line."
  :type 'string
  :group 'celestial-mode-line)

(defcustom celestial-mode-line-suffix ""
  "Text to display after the sunrise/sunset time in the mode-line."
  :type 'string
  :group 'celestial-mode-line)

(defcustom celestial-mode-line-update-interval 60
  "*Seconds between updates of lunar phase in the mode line."
  :type 'integer
  :group 'celestial-mode-line)

(defun celestial-mode-line--next-phase (&optional date)
  "Return the next phase of moon data after DATE or the current day."
  (let* ((d (list (or date (calendar-current-date))))
	 (month (calendar-extract-month (car d)))
	 (year (calendar-extract-year (car d)))
         (dummy (calendar-increment-month month year -1))
	 (phase-list (lunar-phase-list month year))
	 (cur-phase (car phase-list)))
    (ignore dummy)
    (while (calendar-date-compare cur-phase d)
      (setq cur-phase (car phase-list))
      (setq phase-list (cdr phase-list)))
    cur-phase))

(defun celestial-mode-line--relevant-data (&optional date)
  "Return a list of (phase, days, date and time) of the next event after DATE."
  (let* ((date (or date (calendar-current-date)))
         (next-phase (celestial-mode-line--next-phase date))
         (d (car next-phase))
         (time (cadr next-phase))
         (phase (caddr next-phase))
         (days (- (calendar-absolute-from-gregorian d)
                  (calendar-absolute-from-gregorian date))))
    (list phase days d time)))

(defun celestial-mode-line--phase-representation (phase-index)
  "Return the representation of PHASE-INDEX.
See `celestial-mode-line-phase-representation-alist'."
  (assoc-default phase-index celestial-mode-line-phase-representation-alist))

(defun celestial-mode-line--sunrise-sunset (date time &optional extra-time)
  "Return the next sunrise or sunset data after DATE TIME, adding EXTRA-TIME to the duration."
  (cl-destructuring-bind (sunrise sunset day-length)
      (solar-sunrise-sunset date)
    (ignore day-length)
    (cl-destructuring-bind (sec min hr . rest)
        time
      (let ((now (+ hr (/ min 60.0) (/ sec 60.0 60.0))))
        (cond ((> (car sunrise) now)
               (list 'sunrise (car sunrise) (+ (- (car sunrise) now) (or extra-time 0))))
              ((> (car sunset) now)
               (list 'sunset (car sunset) (+ (- (car sunset) now) (or extra-time 0))))
              (t
               (celestial-mode-line--sunrise-sunset (calendar-gregorian-from-absolute
                                                     (1+ (calendar-absolute-from-gregorian date)))
                                                    (list 0 0 0)
                                                    (- 24 now))))))))

(defun celestial-mode-line--sunrise-sunset-representation (date)
  "Return a text representation of the next sunrise or sunset after DATE."
  (cl-destructuring-bind (sun-type sun-time sun-until-duration)
      (celestial-mode-line--sunrise-sunset date (decode-time))
    (ignore sun-until-duration)
    (let* ((h (truncate sun-time))
           (m (truncate (* 60 (- sun-time h)))))
      (concat (assoc-default sun-type celestial-mode-line-sunrise-sunset-alist)
              (format "%d:%02d" h m)))))

(defun celestial-mode-line-update (&optional date)
  "Update `celestial-mode-line-string' for DATE."
  (let ((date (or date (calendar-current-date))))
    (cl-destructuring-bind (next-phase days moon-date time)
        (celestial-mode-line--relevant-data date)
      (ignore time)
      (setq celestial-mode-line-string
            (propertize (concat
                         celestial-mode-line-prefix
                         (if (zerop days) "" (number-to-string days))
                         (celestial-mode-line--phase-representation next-phase)
                         " "
                         (celestial-mode-line--sunrise-sunset-representation date)
                         celestial-mode-line-suffix)
                        'help-echo (celestial-mode-line--text-description date)))
      celestial-mode-line-string)))

(defun celestial-mode-line--text-description (&optional date)
  "Return a text description of the current lunar phase after DATE."
  (cl-destructuring-bind (next-phase days moon-date time)
      (celestial-mode-line--relevant-data date)
    (concat (lunar-phase-name next-phase)
            (if (zerop days)
                " today"
              (concat
               " in " (number-to-string days)
               " day" (if (> days 1) "s" "")))
            " on " (calendar-date-string moon-date)
            " at " time)))

;;;###autoload
(defun celestial-mode-line-start-timer ()
  "Start the timer for updating the celestial mode-line data.

See `celestial-mode-line-update-interval'."
  (when celestial-mode-line--timer
    (cancel-timer celestial-mode-line--timer))
  (setq celestial-mode-line--timer (run-at-time nil celestial-mode-line-update-interval
                                          'celestial-mode-line--update-handler))
  (celestial-mode-line-update))

(defun celestial-mode-line--update-handler ()
  "Handle the celestial mode-line update."
  (celestial-mode-line-update))

(provide 'celestial-mode-line)
;;; celestial-mode-line.el ends here
