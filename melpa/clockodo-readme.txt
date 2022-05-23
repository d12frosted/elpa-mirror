This package provides a minor mode to interact with the clockodo api
with simple commands and a simple clock.

At the moment, the minor mode provides only basic
api interaction from an employee perspective.
This means no higher adjustments or access to priviliged
spaces is provided.

There are two main components. First a set of functions
to query the api and secondly an integration of the timer functionality
which can be shown in the mode-line.

;; Installation

;;; MELPA

If you installed the package  from MELPA add (require 'clockodo) and you're done.

;;; Manual

Install the packages:
+ request
+ ts
+ org

Then put this file into your load-path and put this into your init file:
(require 'clockodo)

;; Usage

This package provides to components for the user. The first one generates
reports from the user perspective.

+ `clockodo-print-daily-overview' - Generates a daily report
+ `clockodo-print-weekly-overview' - Generates a table for the weekly report
+ `clockodo-print-monthly-overview' - Generates a monthly overview report
+ `clockodo-print-overall-overview' - Generates a report from the beginning of recording

Within the report buffers use \\[n] and \\[p] to view the previous or next buffer.
With \\[g] refresh the buffer.
In scoping order use \\[w], \\[m] and \\[y] to jump to the weekly, monthly or yearly reports.

To integrate the clockodo-timer run `clockodo-mode'.
This creates a background timer which prints to the modeline.

Afterwards, run one of these commands:
+ `clockodo-toggle-clock': Start the default clockodo timer.
+ All commands are bound to the prefix \\[C-c C-#]

The mode-line updater and the clock can be used independently which
means one can enable the clock from another application and just show
the current duration within Emacs.

;; Tips

+ You can customize settings in the `clockodo' group.
+ Use `clockodo-show-information' to see the raw api results.
+ Use (setq clockodo-debug t) to get the api calls printed to messages.

;; Credits

This package would not have been possible without the following
packages: request.el[1] and ts.el[3]

 [1] https://github.com/tkf/emacs-request/tree/master/tests
 [2] https://www.clockodo.com/de/api
 [3] https://github.com/alphapapa/ts.el
