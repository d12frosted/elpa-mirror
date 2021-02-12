A helm interface to chronos.

`helm-chronos-add-timer' is a replacement for `chronos-add-timer' that offers
two sources for predefined timers, or allows the entry of a new timer.

The format for predefined and entered timers is:

<expiry time specification>/<message>

See the chronos documentation for details of the expiry time specification,

Helm gets possible matches from two sources:

* Standard timers

There is a predefined list helm-chronos-standard-timers, empty by default,
which can be set in your init file like:

(setq helm-chronos-standard-timers
      '( "     4/Tea"
         "=16:20/Time for tea"))

In this example, two timers are offered as standard: one to go off in 4
minutes from when it is set, and another that will expire at 4:20pm today.

* Recent timers

As new timers are entered via helm-chronos, they are added to the recent
timers list in the same format as the standard timers.  This list is
persistent by being saved to helm-chronos-recent-timers-file.

Installation

Put this file somewhere Emacs can find it and (require 'helm-chronos)

For more information, see the info manual or website.
