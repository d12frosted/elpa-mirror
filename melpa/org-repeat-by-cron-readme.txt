An Org mode task repeater based on Cron expressions

Modified from https://github.com/Raemi/org-reschedule-by-rule.

Key Differences:
- Uses a cron parser implemented in pure Elisp, with
  no dependency on the Python croniter package.
- Replaces the INTERVAL property with a DAY_AND property.
- Supports toggling between SCHEDULED and DEADLINE timestamps.
- Fully compatible with org-habit.

org-repeat-by-cron.el is a lightweight extension for Emacs Org
mode that allows you to repeat tasks using the power of Cron expressions.
Standard Org mode repeaters (like +1d , ++1w ) are relative to
the current SCHEDULED or DEADLINE timestamp. In contrast, this
tool provides repetition based on absolute time rules. You can
easily set a task to repeat "on the last Friday of every month"
or "on the first Monday of each quarter" without manual date
calculations.

A core advantage is its pure Elisp implementation, ensuring it
works out-of-the-box in any Emacs environment without external
dependencies.

Installation
Install via Melpa :
#+begin_src elisp
(use-package org-repeat-by-cron
  :ensure t
  :config
  (global-org-repeat-by-cron-mode))
#+end_src

Usage

To make an Org task repeat according to a Cron rule,
simply add the =REPEAT_CRON= property to its =PROPERTIES= drawer.

Tip: You do not need to wrap the =REPEAT_CRON= value in quotes.

Example

Suppose we have a weekly course:

#+begin_src org
,* TODO Weekend Course
:PROPERTIES:
:REPEAT_CRON: * * SAT,SUN
:END:
#+end_src

When marked as =DONE=, it will automatically be rescheduled
to the next matching date. For example, if today is Dec 9, 2025,
it will be scheduled for the coming Saturday (Dec 13, 2025):

#+begin_src org
,* TODO Weekend Course
SCHEDULED: <2025-12-13 Sat>
:PROPERTIES:
:REPEAT_CRON: * * SAT,SUN
:REPEAT_ANCHOR: 2025-12-13 Sat
:END:
#+end_src

Marking it =DONE= again will calculate the next point based
on the =REPEAT_ANCHOR= and the current time:

#+begin_src org
,* TODO Weekend Course
SCHEDULED: <2025-12-14 Sun>
:PROPERTIES:
:REPEAT_CRON: * * SAT,SUN
:REPEAT_ANCHOR: 2025-12-14 Sun
:END:
#+end_src

Tip1: If you do not want to specify a specific hour/minute,
use the *3-field shorthand* (discussed below).
Tip2: If you use org-repeat-by-cron with the built-in Org repeater
cookie (e.g., +1w) on the same task, the build-in cookie will
be taken over and preserved, so you can use this package with
org-habit.

Check README for more usage: https://github.com/TomoeMami/org-repeat-by-cron.el
