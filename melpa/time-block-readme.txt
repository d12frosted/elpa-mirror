

This package requires [`ts.el`](https://github.com/alphapapa/ts.el) to
handle time parsing.

Download `time-block.el` to somewhere on your `load-path' and
load with `(require 'time-block)`.

;; Usage

To use this package it's necessary to do two things: define time
blocking groups and define time blocked commands.

;;  Time Blocking Groups

Customize the variable `time-block-groups'.  An example of a groups
definition is below.

(setf time-block-groups '((workday . ((1 . (("09:00" . "17:00")))
                                      (2 . (("09:00" . "17:00")))
                                      (3 . (("09:00" . "17:00")))
                                      (4 . (("09:00" . "17:00")))
                                      (5 . (("09:00" . "17:00")))))))

This variable is an alist of names (keywords) to group definitions.  A
group definition is an alist from days of the week (as numbers, Sunday
= 0/7, etc.) to lists of start/stop pairs (times in "HH:MM" form).

It is also possible to ignore time blocking on holidays.  This is
globally set using the `time-block-skip-on-holidays-p' variable.
This defaults to nil, which does not ignore blocking on holidays.
If set to t, time blocking will be ignored on holidays.

;; Defining Time Blocked Commands

Commands are only time-blocked if they're defined.  This is done using
the `define-time-blocked-command` macro, which behaves similarly to
`defun`.  After the lambda list, it has a list describing blocking and
blocking messages.  This is composed of a symbol (a key in
`time-block-groups') a block message, and an optional override prompt
(if present, the command will ask if you'd like to override the block
    using `yes-or-no-p').  An example is shown below.

(define-time-blocked-command my/start-elfeed ()
                             (workday "You have decided not to check news currently."
                                      "You have decided not to check news currently.\nStill start elfeed?")
  "Start `elfeed'.

Time blocked according to `time-block-groups'."
  (interactive)
  (elfeed))

;; Advising commands to be time-blocked

Commands can also be advised to use timeblocking.  This works for
simpler commands, and as a bonus, can make it harder to access the
commands when blocked.  Overall, the arguments for `group`,
`block-message` and `override-prompt` are as above.  Consider the
following example.

(time-block-advise my/elfeed-block-advice 'elfeed workday "You have decided not to check news currently."
                   "You have decided not to check news currently.\nStill start elfeed?")

;; Manually advising commands to be time-blocked

Commands can also be manually advised.  This can be done to prevent
only certain cases from happening.  For instance, I use the following
code to delay myself from editing my emacs configuration during the
workday.

(defun my/buffer-sets-around-advice (orig name)
  "Check if NAME is 'emacs', if so, follow time blocking logic before calling ORIG (`buffer-sets-load-set')."
  (unless (and (string= name "emacs")
               (time-block-group-blocked-p :workday)
               (not (yes-or-no-p "You have decided not to edit your emacs configuration at this time.\nContinue?")))
    (funcall orig name)))
(advice-add 'buffer-sets-load-set :around #'my/buffer-sets-around-advice)
