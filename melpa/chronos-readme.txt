Chronos provides multiple countdown / countup timers, shown sorted by expiry
time in a special buffer *chronos*.

   Expiry      Elapsed      To go  Message
   [17:02]                         --now--
   [17:07]           9       4:51  Coffee

In this example, the time 'now' is 17:02. A five minute countdown
timer was set up 9 seconds ago.  It is expected to expire in 4 minutes
51 seconds at 17:07.

Installation

Put this file somewhere Emacs can find it and (require 'chronos).

`M-x chronos-add-timer' will start chronos and prompt you to add a timer.
When prompted for the time, enter an integer number of minutes for the timer
to count down from.  When prompted for the message, enter a short description
of the timer for display and notification.

For more details, including more sophisticated time specifications and
notification options, see the info manual or website.
