

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
If set to t, time blocking will be ignored on any holiday.  It may
also be set to a regular expression or a list.  Holidays which
match either representation will cause time blocking to be ignored.

;; Defining Time Blocked Commands

Commands are only time-blocked if they're defined.  This is done
using the `define-time-blocked-command` macro, which behaves
similarly to `defun`.  After the lambda list, it has a list
describing blocking and blocking messages.  This is composed of a
symbol (a key in `time-block-groups') a block message, and an
optional override prompt (if present, the command will ask if you'd
like to override the block using `time-block-confirm-override').
An example is shown below.

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

;; Focus Mode

A "focus mode" may be enabled using the `time-block-focus-mode'
command.  This global minor mode by default will block all
block-groups, but this behavior may be changed using
`time-block-block-checkers'.

;; Relaxed Mode

A "relaxed mode" (disabling all blocking) may be enabled with the
`time-block-relaxed-mode' command.  This global minor mode will
disable all block groups (and ignore `time-block-focus-mode').  At
present, this behavior is not configurable.

;; Checking if A Group Is Blocked

You may check if a group is currently blocked using the
`time-block-blocked-p' function, which uses the functions in
`time-block-block-checkers' to determine if a group is presently
blocked.  Functions in this hook must take one argument, a group
name, and return non-nil if the group is to be blocked.

;; Manually advising commands to be time-blocked

Commands can also be manually advised.  This can be done to prevent
only certain cases from happening.  For instance, I use the following
code to delay myself from editing my Emacs configuration during the
workday.

(defun my/buffer-sets-around-advice (orig name)
  "Check if NAME is 'emacs', if so, follow time blocking logic before calling ORIG (`buffer-sets-load-set')."
  (unless (and (string= name "emacs")
               (time-block-blocked-p :workday)
               (not (time-block-confirm-override "You have decided not to edit your emacs configuration at this time.\nContinue?")))
    (funcall orig name)))
(advice-add 'buffer-sets-load-set :around #'my/buffer-sets-around-advice)

;; Confirmation Functions

When an automatically-advised function or function defined with
`define-time-block-command' provides an override prompt, the
function `time-block-confirm-override' is used to confirm that the
block should be overriden.  This is done following the logic of
`time-block-override-confirmation-functions', an alist from block
groups (or default t) to prompting functions. The prompting
function should take one argument (a confirmation prompt) and
return non-nil if the block should be overridden.  The default is
`yes-or-no-p', but the functions
`time-block-override-math-question' and
`time-block-override-random-string' may be used as well.
