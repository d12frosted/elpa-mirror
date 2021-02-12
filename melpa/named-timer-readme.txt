This library provides functions for managing named timers. The
usual pattern for timer management in Emacs Lisp involves declaring
a timer variable, checking it for an existing timer, cancelling
that timer if it exists, setting the varaible to nil to indicate that
the timer is no longer active, and finally starting a new timer and
setting the variable to that value. For example:

(require 'timer)
(defvar my-timer nil)
(defun activate-my-timer ()
  (when my-timer
    (cancel-timer my-timer)
    (setq my-timer nil))
  (setq my-timer
        (run-with-timer 5 nil #'message "My timer ran!")))

With named timers, this simplifies to a single line:

(require 'named-timer)
(defun activate-my-timer ()
  (named-timer-run :my-timer 5 nil #'message "My timer ran!"))

In addition to being shorter, this code is less error prone: since
running a named timer automatically cancels any existing timer with
the same name, there is no chance of accidentally leaving multiple
timers by forgetting to cancel old timers. In short, all the
functions in this library are idempotent, which makes them much
easier to reason about.

The basic functions for managing named timers `named-timer-run',
`named-timer-idle-run', and `named-timer-cancel', which are,
respectively, analogues of `run-with-timer', `run-with-idle-timer',
and `cancel-timer'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
