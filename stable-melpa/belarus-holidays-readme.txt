Provide Belarus holidays with working day transfers for calendar.el

To highlight non-working days in calendar buffer u can use this code:

(defadvice calendar-generate-month
(after highlight-weekend-days (month year indent) activate)
"Highlight weekend days.
If STRING contains `\(нерабочы\)' day is non-working.
If STRING contains `\(рабочы\)' day is working."
(dotimes (i 31)
 (let ((date (list month (1+ i) year)) (working nil) (non-working nil)
(hlist nil))
    (setq hlist (calendar-check-holidays date))
       (dolist (cursor hlist)
          (if (string-match-p "\(рабочы\)" cursor)
        (setq working t))
           (if (string-match-p "\(нерабочы\)" cursor)
        (setq non-working t)))
       (if (and (not working)
              (or (= (calendar-day-of-week date) 0)
                  (= (calendar-day-of-week date) 6)
           non-working))
    (calendar-mark-visible-date date 'holiday)))))

And with `use-package` try so:

(use-package belarus-holidays
 :ensure t
 :config
 (setq calendar-holidays belarus-holidays)
 (defadvice calendar-generate-month
   (after highlight-weekend-days (month year indent) activate)
 "Highlight weekend days. If STRING contains `\(нерабочы\)' day is non-working. If STRING contain `\(рабочы\)' day is working."
(dotimes (i 31)
 (let ((date (list month (1+ i) year)) (working nil) (non-working nil) (hlist nil))
   (setq hlist (calendar-check-holidays date))
   (dolist (cursor hlist)
     (if (string-match-p "\(рабочы\)" cursor)
  (setq working t))
     (if (string-match-p "\(нерабочы\)" cursor)
  (setq non-working t)))
   (if (and (not working)
     (or (= (calendar-day-of-week date) 0)
	 (= (calendar-day-of-week date) 6)
	 non-working))
(calendar-mark-visible-date date 'holiday))))))
