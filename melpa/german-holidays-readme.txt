
Installation:

To use `german-holidays' exclusively

 (setq calendar-holidays holiday-german-holidays)

To use 'german-holidays' additionally

 (setq calendar-holidays (append calendar-holidays holiday-german-holidays))

If you'd like to show holidays for Rhineland Palatinate only, you can use

 (setq calendar-holidays holiday-german-RP-holidays)

This works for for all states:

 `holiday-german-BW-holidays'
 `holiday-german-HE-holidays'
 `holiday-german-HH-holidays'
 etc.

; Credits

inspired by https://github.com/abo-abo/netherlands-holidays
