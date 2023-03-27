;;; latvian-holidays.el --- Latvian holidays for the calendar

;; Copyright (C) 2023 Alexander Shumilov

;; Author: Alexander Shumilov <alexander.shumilov@me.com>
;; URL: https://github.com/ashumilov/latvian-holidays
;; Package-Version: 20230326.2030
;; Package-Commit: 6b82f3bd9682c97f19a65b7d359ce7a02ec9cfec
;; Version: 1.0.0
;; Keywords: calendar

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
;; The list of public Latvian holidays (day offs) and commemoration days.
;;
;; Informational sources:
;; https://likumi.lv/doc.php?id=72608
;; https://lv.wikipedia.org/wiki/Vispārējie_latviešu_Dziesmu_un_Deju_svētki
;;
;;; Installation:
;;
;; Replace holidays:
;;
;; (setq calendar-holidays latvian-holidays)
;;
;; Or append holidays:
;;
;; (setq calendar-holidays (append calendar-holidays latvian-holidays))
;;
;; You could also append commemoration and celebration days:
;;
;; (setq calendar-holidays (append latvian-holidays latvian-holidays-commemoration-days)
;;
;; or:
;;
;; (setq calendar-holidays (append calendar-holidays latvian-holidays latvian-holidays-commemoration-days))

;;; Code:


(require 'calendar)

(defvar displayed-year)

(defvar latvian-holidays-public-holidays
  '((holiday-fixed 1 1 "Jaunais Gads")
    (holiday-easter-etc -2 "Lielā Piektdiena")
    (holiday-easter-etc 0 "Pirmās Lieldienas")
    (holiday-easter-etc 1 "Otrās Lieldienas")
    (holiday-fixed 5 1 "Darba svētki")
    (latvian-holidays--fixed-with-day-off 5 4 "Latvijas Republikas Neatkarības atjaunošanas diena")
    (holiday-float 5 0 2 "Mātes diena")
    (holiday-easter-etc 49 "Vasarsvētki")
    (holiday-fixed 6 23 "Līgo diena")
    (holiday-fixed 6 24 "Jāņi")
    (latvian-holidays--fixed-with-day-off 11 18 "Latvijas Republikas proklamēšanas diena")
    (holiday-fixed 12 24 "Ziemassvētku vakars")
    (holiday-fixed 12 25 "Ziemassvētki")
    (holiday-fixed 12 26 "Otrie Ziemassvētki")
    (holiday-fixed 12 31 "Vecgada vakars"))
  "Latvian holidays.")

(defvar latvian-holidays-commemoration-days
  '((holiday-fixed 1 20 "1991. gada barikāžu aizstāvju atceres diena")
    (holiday-fixed 1 26 "Latvijas Republikas starptautiskās (de jure) atzīšanas diena")
    (holiday-fixed 3 8 "Starptautisko sieviešu diena")
    (holiday-fixed 3 25 "Komunistiskā genocīda upuru piemiņas diena")
    (holiday-fixed 4 27 "Latgales kongresa diena")
    (holiday-fixed 5 8 "Nacisma sagrāves diena un Otrā pasaules kara upuru piemiņas diena")
    (holiday-fixed 5 9 "Eiropas diena")
    (holiday-fixed 5 15 "Starptautisko ģimenes diena")
    (holiday-fixed 5 17 "Ugunsdzēsēju un glābēju diena")
    (holiday-fixed 6 1 "Starptautisko bērnu aizsardzības diena")
    (holiday-fixed 6 14 "Komunistiskā genocīda upuru piemiņas diena")
    (holiday-fixed 6 17 "Latvijas Republikas okupācijas diena")
    (holiday-float 6 0 3 "Medicīnas darbinieku diena")
    (holiday-fixed 6 22 "Varoņu piemiņas diena (Cēsu kaujas atceres diena)")
    (holiday-fixed 7 4 "Ebreju tautas genocīda upuru piemiņas diena")
    (holiday-float 7 6 2 "Jūras svētku diena")
    (holiday-fixed 8 11 "Latvijas brīvības cīnītāju piemiņas diena")
    (holiday-fixed 8 21 "Konstitucionālā likuma “Par Latvijas Republikas valstisko statusu” pieņemšanas diena")
    (holiday-fixed 8 23 "staļinisma un nacisma upuru atceres diena")
    (holiday-fixed 9 1 "Zinību diena")
    (holiday-float 9 0 2 "Tēva diena")
    (holiday-fixed 9 22 "Baltu vienības diena")
    (holiday-fixed 10 1 "Starptautisko senioru diena")
    (holiday-float 10 0 1 "Skolotāju diena")
    (holiday-fixed 11 7 "Robežsargu diena")
    (holiday-fixed 11 11 "Lāčplēša diena")
    (holiday-fixed 12 5 "Policijas darbinieku diena"))
  "Latvian commemoration and celebration days.")

(defvar latvian-holidays-song-and-dance-celebrations
  (let ((string "Vispārējo latviešu Dziesmu un deju svētku noslēguma diena"))
    `((latvian-holidays--fixed-with-day-off-once 6 29 1873 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 20 1880 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 21 1888 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 18 1895 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 21 1910 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 22 1926 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 22 1931 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 19 1933 ,string)
      (latvian-holidays--fixed-with-day-off-once 6 19 1938 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 22 1948 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 23 1950 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 22 1955 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 24 1960 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 18 1965 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 20 1970 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 22 1973 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 24 1977 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 13 1980 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 21 1985 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 8 1990 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 4 1993 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 5 1998 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 6 2003 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 12 2008 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 7 2013 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 8 2018 ,string)
      (latvian-holidays--fixed-with-day-off-once 7 9 2023 ,string)))
  "Final Day of the Nationwide Latvian Song and Dance Celebration.")

(defun latvian-holidays--fixed-with-day-off-once (month day year string)
  "Holiday (MONTH, DAY, YEAR, STRING) with optional day-off.
If holiday falls on weekend (Saturday or Sunday),
the following working day (Monday) is day off."
  (let* ((holiday-date (list month day year))
         (holiday (if (calendar-date-is-visible-p holiday-date)
                      (list holiday-date string)))
         (day-of-week (calendar-day-of-week holiday-date))
         (is-weekend (or (eq day-of-week 6) (eq day-of-week 0)))
         (day-off-date (if is-weekend        ; calculate nearest (in future) Monday
                           (calendar-gregorian-from-absolute
                            (+ (calendar-absolute-from-gregorian holiday-date)
                               (% (1+ (- 7 day-of-week)) 7)))))
         (day-off (if (and day-off-date (calendar-date-is-visible-p day-off-date))
                      (list day-off-date (concat string " (pārceltā brīvdiena)")))))
    (remove nil (list holiday day-off))))

(defun latvian-holidays--fixed-with-day-off (month day string)
  "Holiday (MONTH, DAY, STRING) with optional day-off.
If holiday falls on weekend (Saturday or Sunday),
the following working day (Monday) is day off."
  (latvian-holidays--fixed-with-day-off-once month day displayed-year string))

(defvar latvian-holidays (append latvian-holidays-public-holidays latvian-holidays-song-and-dance-celebrations))

(provide 'latvian-holidays)

;;; latvian-holidays.el ends here
