;;; german-holidays.el --- German holidays for Emacs calendar

;; Author: Sebastian Christ <rudolfo.christ@gmail.com>
;; URL: https://github.com/rudolfochrist/german-holidays
;; Package-Version: 20181213.644
;; Package-Commit: a8462dffccaf2b665f2032e646b5370e993a386a
;; Version: 0.2.1

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Installation:
;;
;; To use `german-holidays' exclusively
;;
;;  (setq calendar-holidays holiday-german-holidays)
;;
;; To use 'german-holidays' additionally
;;
;;  (setq calendar-holidays (append calendar-holidays holiday-german-holidays))
;;
;; If you'd like to show holidays for Rhineland Palatinate only, you can use
;;
;;  (setq calendar-holidays holiday-german-RP-holidays)
;;
;; This works for for all states:
;;
;;  `holiday-german-BW-holidays'
;;  `holiday-german-HE-holidays'
;;  `holiday-german-HH-holidays'
;;  etc.
;;
;;; Credits
;;
;; inspired by https://github.com/abo-abo/netherlands-holidays

;;; Code:
(eval-when-compile
  (require 'calendar)
  (require 'holidays))

(defvar holiday-german--national-holidays
  '((holiday-fixed 1 1 "Neujahr")
    (holiday-easter-etc -2 "Karfreitag")
    (holiday-easter-etc 1 "Ostermontag")
    (holiday-fixed 5 1 "Tag der Arbeit")
    (holiday-easter-etc 39 "Christi Himmelfahrt")
    (holiday-easter-etc 50 "Pfingstmontag")
    (holiday-fixed 10 3 "Tag der Deutschen Einheit")
    (holiday-fixed 12 25 "1. Weihnachtstag")
    (holiday-fixed 12 26 "2. Weihnachtstag"))
  "Holidays valid in all German states, called 'bundeseinheitlich'.")

(defvar holiday-german--holiday-alist
  '((epiphany (holiday-fixed 1 6 "Heilige Drei Könige"))
    (easter (holiday-easter-etc 0 "Ostersonntag"))
    (whit-sunday (holiday-easter-etc 49 "Pfingstsonntag"))
    (corpus-christi (holiday-easter-etc 60 "Fronleichnam"))
    (assumption-day (holiday-fixed 8 15 "Mariä Himmelfahrt"))
    (reformation-day (holiday-fixed 10 31 "Reformationstag"))
    (all-saints-day (holiday-fixed 11 1 "Allerheiligen"))
    (penance-day (holiday-float 11 3 -1 "Buß- und Bettag" 22)))
  "Alist of German holidays with state-specific validity.")

(defun holiday-german--state-holidays (includes)
  "Constructs a state-specific list of holidays.

INCLUDES are holidays added to the `holiday-german--national-holidays'."
  (append holiday-german--national-holidays
          (mapcar (lambda (key)
                    (cadr (assoc key holiday-german--holiday-alist)))
                  includes)))

(defvar holiday-german-BW-holidays
  (holiday-german--state-holidays '(epiphany corpus-christi all-saints-day))
  "Holidays for Baden Wuerttemberg.")

(defvar holiday-german-BY-holidays
  (holiday-german--state-holidays
   '(epiphany corpus-christi assumption-day all-saints-day))
  "Holidays for Bavaria.")

(defvar holiday-german-BE-holidays holiday-german--national-holidays
  "Holidays for Berlin.")

(defvar holiday-german-BB-holidays
  (holiday-german--state-holidays '(easter whit-sunday reformation-day))
  "Holidays for Brandenburg.")

(defvar holiday-german-HB-holidays holiday-german--national-holidays
  "Holidays for Bremen.")

(defvar holiday-german-HH-holidays holiday-german--national-holidays
  "Holidays for Hamburg.")

(defvar holiday-german-HE-holidays
  (holiday-german--state-holidays '(corpus-christi))
  "Holidays for Hesse.")

(defvar holiday-german-MV-holidays
  (holiday-german--state-holidays '(reformation-day))
  "Holidays for Mecklenburg West Pomerania.")

(defvar holiday-german-NI-holidays
  (holiday-german--state-holidays '(reformation-day))
  "Holidays for Lower Saxony.")

(defvar holiday-german-NW-holidays
  (holiday-german--state-holidays '(corpus-christi all-saints-day))
  "Holidays for Northrhine Westphalia.")

(defvar holiday-german-RP-holidays
  (holiday-german--state-holidays '(corpus-christi all-saints-day))
  "Holidays for Rhineland Palatinate.")

(defvar holiday-german-SL-holidays
  (holiday-german--state-holidays
   '(corpus-christi assumption-day all-saints-day))
  "Holidays for Saarland.")

(defvar holiday-german-SN-holidays
  (holiday-german--state-holidays '(reformation-day penance-day))
  "Holidays for Saxony.")

(defvar holiday-german-ST-holidays
  (holiday-german--state-holidays '(epiphany reformation-day))
  "Holidays for Saxony Anhalt.")

(defvar holiday-german-SH-holidays holiday-german--national-holidays
  "Holidays for Schleswig Holstein.")

(defvar holiday-german-TH-holidays
  (holiday-german--state-holidays '(reformation-day))
  "Holidays for Thuringia.")

(defvar holiday-german-holidays
  (holiday-german--state-holidays
   (mapcar #'car holiday-german--holiday-alist))
  "All legal holidays in Germany.")

(provide 'german-holidays)

;;; german-holidays.el ends here
