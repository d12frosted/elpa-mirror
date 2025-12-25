An Org mode task repeater based on Cron expressions
Modified from https://github.com/Raemi/org-reschedule-by-rule.
Key Differences:
- Uses a cron parser implemented in pure Elisp, with
  no dependency on the Python croniter package.
- Replaces the INTERVAL property with a DAY_AND property.
- Supports toggling between SCHEDULED and DEADLINE timestamps.

org-repeat-by-cron.el is a lightweight extension for Emacs Org
mode that allows you to repeat tasks based on powerful Cron expressions.
Standard Org mode repeaters (like +1d , ++1w ) are based on
the current SCHEDULED or DEADLINE timestamp. In contrast, this
tool provides a repetition method based on absolute time rules.
You can easily set a task to repeat \"on the last Friday of
every month\" or \"on the first Monday of each quarter\"
without manual date calculations.
A core advantage of this tool is its pure Elisp implementation,
which does not rely on any external programs (like Python's
croniter library), ensuring it works out-of-the-box in Emacs environment.

Installation
Install via Melpa :
#+begin_src elisp
(use-package org-repeat-by-cron
  :ensure t  ; If the file is already in your load-path
  :config
  (global-org-repeat-by-cron-mode))
#+end_src

Usage

To make an Org task repeat according to a Cron rule,
simply add the =REPEAT_CRON= property to its =PROPERTIES= drawer.

Example

Suppose we have a weekly course:

#+begin_src org
,* TODO Weekend Course
:PROPERTIES:
:REPEAT_CRON: "* * SAT,SUN"
:END:
#+end_src

When it is marked as done, it will automatically be scheduled to
a date that meets the conditions. Taking today (December 9, 2025)
as an example, it will be scheduled for this Saturday
(December 13, 2025):

#+begin_src org
,* TODO Weekend Course
SCHEDULED: <2025-12-13 Sat>
:PROPERTIES:
:REPEAT_CRON: "* * SAT,SUN"
:REPEAT_ANCHOR: 2025-12-13 Sat
:END:
#+end_src

Then, if it is marked as done again, it will calculate the next qualifying
time point based on the =REPEAT_ANCHOR= and the current time, and schedule
it accordingly:

#+begin_src org
,* TODO Weekend Course
SCHEDULED: <2025-12-14 Sun>
:PROPERTIES:
:REPEAT_CRON: "* * SAT,SUN"
:REPEAT_ANCHOR: 2025-12-14 Sun
:END:
#+end_src

Tip1: If you do not want to specify the hour and minute for the repeat time,
use the abbreviated 3-segment format.
Tip2: You should not use org-repeat-by-cron and the built-in
Org repeater cookie (e.g., +1w) on the same task.
