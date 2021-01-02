
Remove default holidays, then append mexican calendar

(customize-set-variable 'holiday-bahai-holidays nil)
(customize-set-variable 'holiday-hebrew-holidays nil)
(customize-set-variable 'holiday-islamic-holidays nil)
(setq calendar-holidays (append calendar-holidays holiday-mexican-holidays))
