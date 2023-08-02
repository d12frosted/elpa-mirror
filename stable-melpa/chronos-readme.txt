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

you can fill in the `chronos-standard-timers' variable to use the
`chronos-select-timer' command to quickly select a chrono.
ex:
(setq chronos-standard-timers
      '("Green Tea (Short)            2/Green Tea: Remove tea bag"
        "Green Tea (Medium)      0:2:30/Green Tea: Remove tea bag"
        "Green Tea (Long)             3/Green Tea: Remove tea bag"
        "Black Tea (Medium)           4/Black Tea: Remove tea bag"
        "Black Tea (Long)             5/Black Tea: Remove tea bag"
        "Herbal Tea                  10/Herbal Tea: Remove tea bag"
        "Timebox                     25/Finish and Reflect + 5/Back to it"
        "Break                       30/Back to it"
        "Charge Phone                30/Unplug Phone"
        "Charge Tablet               60/Unplug Tablet"
        "Charge Headphones           15/Unplug Headphones"
        "Charge Battery             120/Unplug Battery"
        "Class: Very Short            1/End"
        "Class: Short                 5/End"
        "Class: Medium               10/End"
        "Class: Long                 15/End"))

For more details, including more sophisticated time specifications and
notification options, see the info manual or website.
