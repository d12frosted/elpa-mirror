;;; mexican-holidays.el --- Mexico holidays for Emacs calendar.

;; Copyright (C) 2016 Saúl Germán Gutiérrez-Calderón

;; Author: Saúl Gutiérrez <me@sggc.me>
;; URL: https://github.com/sggutier/mexican-holidays
;; Package-Version: 20210604.1421
;; Package-Commit: 8e28907ea69f2c0ed9aad9f3b99664ca147379d0
;; Version: 0.0.9
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
;; Remove default holidays, then append mexican calendar
;;
;; (customize-set-variable 'holiday-bahai-holidays nil)
;; (customize-set-variable 'holiday-hebrew-holidays nil)
;; (customize-set-variable 'holiday-islamic-holidays nil)
;; (setq calendar-holidays (append calendar-holidays holiday-mexican-holidays))
;;

(eval-when-compile
  (require 'calendar)
  (require 'holidays))

(defvar holiday-mexican--statutory-holidays
  '((holiday-fixed 1 1 "Año Nuevo")
    (holiday-fixed 2 5 "Día de la Constitución")
    (holiday-fixed 3 21 "Natalicio de Benito Juárez")
    (holiday-fixed 4 1 "Día del Trabajo")
    (holiday-fixed 9 16 "Día de la Independencia de México")
    (holiday-fixed 11 20 "Día de la Revolución Mexicana")
    (holiday-fixed 12 25 "Navidad")
    ))

(defvar holiday-mexican--civic-holidays
  '((holiday-fixed 2 19 "Día del Ejército")
    (holiday-fixed 2 24 "Día de la Bandera")
    (holiday-fixed 3 18 "Aniversario de la Expropiación petrolera")
    (holiday-fixed 4 21 "Heroica Defensa de Veracruz")
    (holiday-fixed 5 5 "Aniversario de la Batalla de Puebla")
    (holiday-fixed 6 1 "Día de la Marina")
    (holiday-fixed 9 13 "Día de los Niños Héroes")
    (holiday-fixed 9 15 "Grito de Dolores")
    (holiday-fixed 9 27 "Cnosumación de la Independencia de México")
    (holiday-fixed 10 12 "Descubrimiento de América")
    ))

(defvar holiday-mexican--festivities
  '((holiday-fixed 1 6 "Día de los Reyes Magos")
    (holiday-fixed 2 14 "Día de San Valentín")
    (holiday-fixed 4 30 "Día del Niño")
    (holiday-fixed 5 10 "Día de las Madres")
    (holiday-fixed 5 15 "Día del Docente")
    (holiday-fixed 5 23 "Día del estudiante")
    (holiday-float 6 0 3 "Día del Padre")
    (holiday-fixed 8 28 "Día del Abuelo")
    (holiday-fixed 10 31 "Halloween")
    (holiday-fixed 11 1 "Día de Todos los Santos")
    (holiday-fixed 11 2 "Día de Muertos")
    (holiday-fixed 12 24 "Nochebuena")
    (holiday-fixed 12 28 "Día de los Inocentes")
    (holiday-fixed 12 31 "Vispera de Año Nuevo")    
    ))

(defvar holiday-mexican--christian
  '(
    (holiday-fixed 2 2 "Día de la Candelaria")
    (holiday-fixed 12 12 "Día de la Virgen de Guadalupe")
    (holiday-easter-etc 0 "Día de Pascua")
    (holiday-easter-etc -46 "Miércoles de Ceniza")
    (holiday-easter-etc -7 "Domingo de Ramos")
    (holiday-easter-etc -1 "Sábado Santo")
    (holiday-easter-etc 39 "Día de la Ascención")
    (holiday-easter-etc 49 "Pentecostés")
    (holiday-easter-etc 60 "Corpus Christi")
    (holiday-fixed 8 15 "Día de la Asunción de María")
    ))

(defvar holiday-mexican-holidays
  (append holiday-mexican--statutory-holidays holiday-mexican--christian holiday-mexican--festivities holiday-mexican--civic-holidays)
)

(provide 'mexican-holidays)

;;; mexican-holidays.el ends here
