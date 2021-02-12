
The list of official Swiss holidays. With regional holidays included.

Installation:

 M-x package-install RET swiss-holidays RET

Configuration:

To use `swiss-holidays' in your calendar

 (setq holiday-other-holidays swiss-holidays)

If you'd like to add regional holidays, pick additional holidays
from `swiss-holidays-catholic', `swiss-holidays-epiphany',
`swiss-holidays-st-joseph-day' or `swiss-holidays-labour-day'.

For the canton of Zürich for example you'd use the following:

 (setq holiday-other-holidays
       (append swiss-holidays swiss-holidays-labour-day))

For the canton of Schwyz you could use the following:

 (setq holiday-other-holidays
       (append swiss-holidays swiss-holidays-catholic
               swiss-holidays-epiphany swiss-holidays-st-joseph-day))

The code was inspired by russian-holidays.el and
https://www.emacswiki.org/emacs/CalendarLocalization
