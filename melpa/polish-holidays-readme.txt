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
    (holiday-polish-holidays-set) ;;
to enable Polish calendar and disable other calendars,
or add a call to:
    (holiday-polish-holidays-append)
to append Polish calendar to the current list of calendars
