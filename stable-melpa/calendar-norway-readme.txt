Norwegian calendar localization.

Example usage:
 ;; Localises date format, weekdays, months, lunar/solar names:
(require 'calendar-norway)
;; Set what holidays you want in your calendar:
(setq calendar-holidays
   (append
    ;; Include days where you don't have to work:
    calendar-norway-raude-dagar
    ;; Include other days that people celebrate:
    calendar-norway-andre-merkedagar
    ;; Include daylight savings time:
    calendar-norway-dst
    ;; And then you can add some non-Norwegian holidays etc. if you like:
    '((holiday-fixed 3 17 "St. Patricksdag")
      (holiday-fixed 10 31 "Hallowe'en")
      (holiday-float 11 4 4 "Thanksgiving")
      (solar-equinoxes-solstices))))
