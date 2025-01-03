
2025  (updated 03/01/25)

What:
- Russian holidays
- International holidays: Valentine's Day, April Fools' Day, Halloween
- Key Orthodox Christian Holidays
- Old Slavic Fests
- Open source conferences: Emacs, FSF, GNU, FOSDEM
- AI and Russian IT conferences: PyTorh, NeurIPS, IEEE CAI, WAIC,
  AI Journey dec + TAdviser SummIT nov + CNews Forum nov
- common colendar configuration

Why? Because the dates will be updated per year at least.

Not included: regional holidays.

Features:
- Support arbitrary number of years at once
- fix for behavior of `list-holidays' function included
- this package is example of how to set holidays per year
;
Usage:
(require 'russian-calendar)
(setopt calendar-holidays (append russian-calendar-holidays
                                  ;; - enable if you need:
                                  ;; russian-calendar-general-holidays
                                  ;; russian-calendar-orthodox-christian-holidays
                                  ;; russian-calendar-old-slavic-fests
                                  ;; russian-calendar-open-source-confs
                                  ;; russian-calendar-ai-confs
                                  ;; russian-calendar-russian-it-confs
                                  ))
;; optional:
(russian-calendar-localize)
(russian-calendar-set-location-to-moscow)
(russian-calendar-show-diary-holidays-in-calendar)
(russian-calendar-enhance-calendar-movement)
(russian-calendar-fix-list-holidays)
(russian-calendar-check-year-not-obsolate)

Other packages:
