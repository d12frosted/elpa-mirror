* Description
This package adds Polish holidays to the Emacs calendar.

If you have ~org-agenda-include-diary~ set to ~t~,
these will be also listed in the ~org-agenda~ view.

* Installation

Replace holidays:
    (setq calendar-holidays polish-holidays)

Or append holidays:
    (setq calendar-holidays (append calendar-holidays polish-holidays))

Note that this must be called *before* Emacs calendar is loaded.


You can also do the same with functions:
After loading the package, in your =init.el= add a call to:
    (polish-holidays-set) ;;
to enable Polish calendar and disable other calendars,
or add a call to:
    (polish-holidays-append)
to append Polish calendar to the current list of calendars
additionally, you can set below variable
    (setq polish-holidays-use-all-p t)
to use all the holidays (i.e. include catholic holidays)

* Example configuration:
    (use-package polish-holidays
      :ensure t
      :after holidays
      :config
      (setq polish-holidays-use-all-p nil)  ; 'notable' holidays
      ;; (setq polish-holidays-use-all-p t) ; include catholic holidays
      (polish-holidays-set))
