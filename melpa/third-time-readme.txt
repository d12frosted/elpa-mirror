
This package provides Third Time
(https://www.lesswrong.com/posts/RWu8eZqbwgB9zaerh/third-time-a-better-way-to-work)
support for Emacs.

;; Installation

This package is compatible with Emacs >= 27.1 and has no external
dependencies.  The file `third-time.el' may be placed on the
`load-path' and `require'd or auto-loaded.

;; Usage

It is recommended that you bind `third-time-start-work' to `C-x M-t
w' (or `third-time-prefix w', see below for information about the
prefix).

The command `third-time-start-work' (`C-x M-t w') starts or
restarts work.  It enables the mode if it is not enabled.

The command `third-time-start-break' (`C-x M-t b') starts a break.
If the prefix argument is passed, it will prompt for how long the
break should be, otherwise, all remaining break time is used
instead.

`third-time-long-break' (`C-x M-t l', `C-x M-t m') starts a long
(or meal) break.

`third-time-end-session' (`C-x M-t e', `C-x M-t s') ends a Third
Time session (i.e., workday).

Finally, the command `third-time-summary' (`C-x M-t S') describes
the current status, including current time in state, and
information about break times.

;; Configuration

`third-time-fraction' controls what fraction of time is used for
breaks.  It should be a positive integer.

The hooks `third-time-working-hook', `third-time-break-hook',
`third-time-long-break-hook', and `third-time-change-hook' are run
on state changes.  Those with a named state are run on change to
that state, and `third-time-change-hook' is run for all changes.
`third-time-mode-hook' is run when the mode is enabled.

;;; Logging

This library supports logging of state changes when
`third-time-log-file' is a string referring to a file.  The
variables `third-time-log-format' and `third-time-log-time-format'
control the log format, the latter of which should comply with
`format-time-strings.

`third-time-log-format' describes what a log entry looks like.  It
may contain the following formatting codes:

 - %T: the time as formatted using `third-time-log-time-format'.
 - %s: the state entered.
 - %h: the time which has been worked at `%T'.
 - %b: the time remaining for breaks.

;;; Alerting

`third-time' uses a simple minibuffer message alerting mechanism by
default.  This can be overriden with `third-time-alert-function'
which should be a function which takes one argument, a message to
alert the user with.  Other information can be `third-time-state'
for more advanced formatting.

Additionally, there's a "nag" timer which can be used to
periodically remind the user that a break has been completed.  It
is controlled with the `third-time-nag-time' which is a number of
minutes, if it is 0, no nagging will take place.

;; External Package Integration: Universal Sidecar

Users of the Universal Sidecar package
(https://git.sr.ht/~swflint/emacs-universal-sidecar) can add
`third-time-section' to `universal-sidecar-sections' to see a
summary of the current third-time status in the sidecar.

;; Bug Reports and Patches

If you find a bug or wish to submit a patch, send an email to
~swflint/emacs-utilities@lists.sr.ht.
