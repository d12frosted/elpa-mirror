;;; orthodox-christian-new-calendar-holidays.el --- Feasts (NS)

;;; Copyright (c) 2021 Carson Chittom

;;; Author: Carson Chittom <carson@wistly.net>
;;; URL: https://github.com/cmchittom/orthodox-christian-new-calendar-holidays
;; Package-Version: 20210830.1657
;; Package-Commit: 6869024ecd45eefd0ec648979c6a59d7c79770e0
;;; Version: 1.3.2
;;; Keywords: calendar

;;; This file is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3, or (at your option)
;;; any later version.

;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.

;;; For a full copy of the GNU General Public License
;;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; Although the Orthodox Churches of Jerusalem, Russia, Serbia,
;;; Ukraine, and Georgia continue to use the Julian calendar both for
;;; the Paschal cycle and for fixed feasts, the other Orthodox
;;; Churches follow the Revised Julian calendar for fixed feasts but
;;; use the original Julian Paschalion. So *strictly* speaking, using
;;; holiday-fixed is incorrect, but since the Revised Julian is
;;; exactly the same as the Gregorian until 2800 AD (when a difference
;;; in the leap year rule will make them diverge) I think that's a
;;; problem for someone else on another day.
;;;
;;; This is all fairly trivial, but putting it in a separate file gets
;;; it out of my ~/.emacs and makes it available if anyone else finds
;;; it useful.

;;; Usage:
;;;
;;; (setq holiday-bahai-holidays nil
;;;       holiday-christian-holidays nil
;;;       holiday-islamic-holidays nil)
;;; ;; Or whatever else you don't want included--see holidays.el for details
;;;
;;; (setq calendar-holidays
;;;       (append calendar-holidays orthodox-christian-new-calendar-holidays))


;;; Code:

(eval-when-compile
  (require 'calendar)
  (require 'holidays))

(defvar orthodox-christian-new-calendar-holidays--fixed-great-feasts
  '((holiday-fixed  9  8 "Nativity of the Theotokos")
    (holiday-fixed  9 14 "Exaltation of the Cross")
    (holiday-fixed 11 21 "Presentation of the Theotokos")
    (holiday-fixed 12 25 "Nativity of Christ")
    (holiday-fixed  1  6 "Theophany")
    (holiday-fixed  2  2 "Presentation of Jesus at the Temple")
    (holiday-fixed  3 25 "Annunciation")
    (holiday-fixed  8  6 "Transfiguration")
    (holiday-fixed  8 15 "Dormition of the Theotokos")))

(defvar orthodox-christian-new-calendar-holidays--paschal-cycle
  '((holiday-greek-orthodox-easter -77 "Zacchaeus Sunday")
    (holiday-greek-orthodox-easter -70 "Sunday of the Publican and the Pharisee")
    (holiday-greek-orthodox-easter -63 "Sunday of the Prodigal Son")
    (holiday-greek-orthodox-easter -56 "Sunday of the Last Judgement")
    (holiday-greek-orthodox-easter -49 "Forgiveness Sunday")
    (holiday-greek-orthodox-easter  -8 "Lazarus Saturday")
    (holiday-greek-orthodox-easter  -7 "Palm Sunday")
    (holiday-greek-orthodox-easter   0 "PASCHA")
    (holiday-greek-orthodox-easter  39 "Ascension")
    (holiday-greek-orthodox-easter  49 "Pentecost")))

(defvar orthodox-christian-new-calendar-holidays--fasts
  '((holiday-greek-orthodox-easter -48 "Great Lent begins")
    (holiday-greek-orthodox-easter  -9 "Great Lent ends")
    (holiday-fixed 11 15 "Nativity Fast begins")
    (holiday-fixed 12 24 "Nativity Fast ends")
    (holiday-greek-orthodox-easter 57 "Apostles' Fast begins")
    (holiday-fixed  6 28 "Apostles' Fast ends")
    (holiday-fixed  8  1 "Dormition Fast begins")
    (holiday-fixed  8 14 "Dormition Fast ends")))


(defvar orthodox-christian-new-calendar-holidays
  (append orthodox-christian-new-calendar-holidays--fixed-great-feasts
	  orthodox-christian-new-calendar-holidays--paschal-cycle
	  orthodox-christian-new-calendar-holidays--fasts))

(provide 'orthodox-christian-new-calendar-holidays)

;;; orthodox-christian-new-calendar-holidays.el ends here
