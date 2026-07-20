org-habit-ng extends org-habit to support RFC 5545 RRULE recurrence
patterns that cannot be expressed with standard org repeaters.

Supported RRULE components:
  FREQ: DAILY, WEEKLY, MONTHLY, YEARLY
  INTERVAL: repeat every N periods
  BYDAY: weekdays with optional ordinals (MO, 2SA, -1FR)
  BYMONTHDAY: days of month (1, 15, -1 for last)
  BYMONTH: specific months
  BYSETPOS: position in set (1 for first, -1 for last)
  BYWEEKNO, BYYEARDAY, BYHOUR, BYMINUTE, BYSECOND
  COUNT, UNTIL: termination conditions

Extensions:
  X-REPEAT-FROM: completion | scheduled | scheduled-future
  X-WARN: warning duration (3d, 2w, 12h)

Installation:
  (require 'org-habit-ng)
  (org-habit-ng-mode 1)

RRULE Usage:
  Add a :RECURRENCE: property with RRULE syntax:

  * TODO Monthly review
  SCHEDULED: <2024-01-13 Sat .+1m>
  :PROPERTIES:
  :STYLE: habit
  :RECURRENCE: FREQ=MONTHLY;BYDAY=2SA;X-REPEAT-FROM=completion
  :END:

More RRULE examples:
  - Every weekday: FREQ=WEEKLY;BYDAY=MO,WE,FR
  - Last Friday of month: FREQ=MONTHLY;BYDAY=-1FR
  - Last day of month: FREQ=MONTHLY;BYMONTHDAY=-1
  - Last Sunday of December: FREQ=YEARLY;BYMONTH=12;BYDAY=-1SU
  - Every 3 days: FREQ=DAILY;INTERVAL=3
  - First weekday of month: FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1

The SCHEDULED timestamp must have a repeater (e.g., .+1m) for org-habit
compatibility, but org-habit-ng will override it with the correct date
based on the RECURRENCE rule when you mark the task as DONE.

The consistency graph accurately reflects RRULE due dates for complex
recurrence patterns (e.g., "2nd Saturday" shows exact intervals of 28-35 days).
