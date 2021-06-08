;;; calendar-norway.el --- Norwegian calendar

;; Copyright (C) 2012-2021 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.9.5
;; Package-Commit: 4dd8c38ef30ad45931c8ae7bcdfd720c3fcffffc
;; Package-Version: 20210608.1136
;; Package-X-Original-Version: 0.9.5
;; Keywords: calendar norwegian localization

;; Based on http://bigwalter.net/daniel/elisp/sv-kalender.el v.1.8
;; Copyright (C) 2002,2003,2004,2007,2009 Daniel Jensen
;; Author: Daniel Jensen <daniel@bigwalter.net>

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Norwegian calendar localization.

;; Example usage:
;;  ;; Localises date format, weekdays, months, lunar/solar names:
;; (require 'calendar-norway)
;; ;; Set what holidays you want in your calendar:
;; (setq calendar-holidays
;;    (append
;;     ;; Include days where you don't have to work:
;;     calendar-norway-raude-dagar
;;     ;; Include other days that people celebrate:
;;     calendar-norway-andre-merkedagar
;;     ;; Include daylight savings time:
;;     calendar-norway-dst
;;     ;; And then you can add some non-Norwegian holidays etc. if you like:
;;     '((holiday-fixed 3 17 "St. Patricksdag")
;;       (holiday-fixed 10 31 "Hallowe'en")
;;       (holiday-float 11 4 4 "Thanksgiving")
;;       (solar-equinoxes-solstices))))

;;; Code:
(require 'calendar)
(require 'holidays)
(require 'solar)

;; Alter some calendar settings:
(setq calendar-week-start-day 1)        ; måndag som første dag i veka
(calendar-set-date-style 'european)     ; day/month/year
(setq calendar-date-display-form        ; «ons. 2. mai 2012»
      '((if dayname
            (concat dayname ", "))
        day ". " monthname " " year))
(setq calendar-time-display-form        ; 24-timars, ingen tidssone
      '(24-hours ":" minutes))
(setq calendar-day-name-array
      ["søndag" "måndag" "tysdag" "onsdag" "torsdag" "fredag" "laurdag"])
(setq calendar-day-header-array
      ["sø" "må" "ty" "on" "to" "fr" "la"])
(setq calendar-month-name-array
      ["januar" "februar" "mars"     "april"   "mai"      "juni"
       "juli"    "august"   "september" "oktober" "november" "desember"])


(setq solar-n-hemi-seasons
      '("Vårjamdøgn" "Sommarsolkverv"
        "Haustjamdøgn" "Vintersolkverv"))

(defadvice lunar-phase-name (around sv-lunar-phase-name activate)
  "Månefasenamn på norsk."
  (setq ad-return-value
        (let ((phase (ad-get-arg 0)))
          (cond ((= 0 phase) "Nymåne")
                ((= 1 phase) "Månen i ny")
                ((= 2 phase) "Fullmåne")
                ((= 3 phase) "Månen i ne")))))

(defadvice solar-sunrise-sunset-string (around sv-solar-sunrise-sunset-string
                                               activate)
  "Soloppgang og solnedgang på norsk."
  (setq ad-return-value
        (let ((l (solar-sunrise-sunset date)))
          (format
           "%s, %s ved %s (%s timar dagslys)"
           (if (car l)
               (concat "Sol opp " (apply 'solar-time-string (car l)))
             "Ingen soloppgang")
           (if (car (cdr l))
               (concat "ned " (apply 'solar-time-string (car (cdr l))))
             "ingen solnedgang")
           (eval calendar-location-name)
           (car (cdr (cdr l)))))))


;; Helper:
(defun calendar-norway-calculate-easter (year)
  "Calculate the date for Easter in YEAR."
  (let* ((century (1+ (/ year 100)))
         (shifted-epact (% (+ 14 (* 11 (% year 19))
                              (- (/ (* 3 century) 4))
                              (/ (+ 5 (* 8 century)) 25)
                              (* 30 century))
                           30))
         (adjusted-epact (if (or (= shifted-epact 0)
                                 (and (= shifted-epact 1)
                                      (< 10 (% year 19))))
                             (1+ shifted-epact)
                           shifted-epact))
         (paschal-moon (- (calendar-absolute-from-gregorian
                           (list 4 19 year))
                          adjusted-epact)))
    (calendar-dayname-on-or-before 0 (+ paschal-moon 7))))

;; Helgdagar
(defvar calendar-norway-raude-dagar
      '((holiday-fixed 1 1 "Nyttårsdag")

        ;; Jul
        (holiday-fixed 12 25 "Førstedag jul")
        (holiday-fixed 12 26 "Annandag jul")

        ;; Påske og pinse
        (holiday-filter-visible-calendar
         (mapcar
          (lambda (dag)
            (list (calendar-gregorian-from-absolute
                   (+ (calendar-norway-calculate-easter displayed-year) (car dag)))
                  (cadr dag)))
          '((  -3 "Skjærtorsdag")
            (  -2 "Langfredag")
            (  -1 "Påskeaftan")
            (   0 "Påskedagen")
            (  +1 "Annandag påske")
            ( +39 "Kristi himmelferdsdag")
            ( +49 "Førstedag pinse")
            ( +50 "Annandag pinse"))))

        (holiday-fixed 5 1 "Internasjonal arbeidardag")
        (holiday-fixed 5 17 "Grunnlovsdagen"))
      "Raude kalenderdagar i Noreg.")

(defvar calendar-norway-andre-merkedagar
      '(;; Meir påske
        (holiday-filter-visible-calendar
         (mapcar
          (lambda (dag)
            (list (calendar-gregorian-from-absolute
                   (+ (calendar-norway-calculate-easter displayed-year) (car dag)))
                  (cadr dag)))
          '(( -3 "Skjærtorsdag"))))

        (holiday-fixed 12 31 "Nyttårsaftan")
        (holiday-fixed 2 14 "Valentinsdag")
        (holiday-fixed 3 8 "Internasjonale kvinnedagen")
        (holiday-fixed 4 1 "Første april")

        (holiday-float 2 0 2 "Morsdag")
        (holiday-float 11 0 2 "Farsdag")

        (holiday-fixed 5 8 "Frigjeringsdagen")

        (holiday-fixed 6 23 "Sankthansaftan (jonsokaftan)")
        (holiday-fixed 7 29 "Olsok")

        (holiday-fixed 10 24 "FN-dagen")

        (holiday-fixed 12 13 "Luciadagen")
        (holiday-fixed 12 24 "Julaftan")

        (let ((midsommar-d (calendar-dayname-on-or-before
                            6 (calendar-absolute-from-gregorian
                               (list 6 26 displayed-year)))))
          ;; Midsommar
          (holiday-filter-visible-calendar
          (list
           (list
            (calendar-gregorian-from-absolute (1- midsommar-d))
            "Midtsommaraftan")
           (list
            (calendar-gregorian-from-absolute midsommar-d)
            "Midtsommardagen"))))
        )
      "Høgtider som ikkje er raude kalenderdagar i Noreg.")

(defvar calendar-norway-dst
  '((when (and (require 'cal-dst nil 'noerror)
               (require 'solar nil 'noerror))
      (funcall 'holiday-sexp
               calendar-daylight-savings-starts
               '(format "Sommartid byrjar %s"
                        (if (fboundp 'atan)
                            (solar-time-string (/ calendar-daylight-savings-starts-time
                                                  (float 60))
                                               calendar-standard-time-zone-name)
                          "")))
      (funcall 'holiday-sexp
               calendar-daylight-savings-ends
               '(format "Vintertid byrjar %s"
                        (if (fboundp 'atan)
                            (solar-time-string (/ calendar-daylight-savings-ends-time
                                                  (float 60))
                                               calendar-daylight-time-zone-name)
                          "")))))
  "Solar equinoxes and Daylight Saving Time localised to Norwegian.")



(provide 'calendar-norway)
;;; calendar-norway.el ends here
