Get notifications, when there is something to do.
Sometimes, you need a reminder a few days before a deadline, e.g. to buy a
present for a birthday, and then another notification one hour before to
have enough time to choose the right clothes.
For other events, e.g. rolling the dustbin to the roadside once per week,
you probably need another kind of notification strategy.
This package tries to satisfy the various needs.

In order to activate this package, you must add the following code
into your .emacs:

  (require 'org-notify)
  (org-notify-start)

Example setup:

(org-notify-add 'appt
                '(:time "-1s" :period "20s" :duration 10
                  :actions (-message -ding))
                '(:time "15m" :period "2m" :duration 100
                  :actions -notify)
                '(:time "2h" :period "5m" :actions -message)
                '(:time "3d" :actions -email))

This means for todo-items with `notify' property set to `appt': 3 days
before deadline, send a reminder-email, 2 hours before deadline, start to
send messages every 5 minutes, then 15 minutes before deadline, start to
pop up notification windows every 2 minutes.  The timeout of the window is
set to 100 seconds.  Finally, when deadline is overdue, send messages and
make noise."

Take also a look at the function `org-notify-add'.