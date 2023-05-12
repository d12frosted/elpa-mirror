;;; time-block.el --- Block running commands using time -*- lexical-binding: t -*-

;; Author: Samuel W. Flint <swflint@flintfam.org>
;; URL: https://git.sr.ht/~swflint/time-block-command
;; Package-Version: 20230511.1434
;; Package-Commit: 0fdb488c3fa3da2934ee486613f5bf46712b97d6
;; Version: 1.6.2
;; Package-Requires: ((emacs "25.1") (ts "0.1"))
;; Keywords: tools, productivity, convenience
;; SPDX-FileCopyrightText: 2022 Samuel W. Flint <swflint@flintfam.org>
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;

;; This package requires [`ts.el`](https://github.com/alphapapa/ts.el) to
;; handle time parsing.
;;
;; Download `time-block.el` to somewhere on your `load-path' and
;; load with `(require 'time-block)`.
;;
;;;; Usage
;;
;; To use this package it's necessary to do two things: define time
;; blocking groups and define time blocked commands.
;;
;;;;  Time Blocking Groups
;;
;; Customize the variable `time-block-groups'.  An example of a groups
;; definition is below.
;;
;; (setf time-block-groups '((workday . ((1 . (("09:00" . "17:00")))
;;                                       (2 . (("09:00" . "17:00")))
;;                                       (3 . (("09:00" . "17:00")))
;;                                       (4 . (("09:00" . "17:00")))
;;                                       (5 . (("09:00" . "17:00")))))))
;;
;; This variable is an alist of names (keywords) to group definitions.  A
;; group definition is an alist from days of the week (as numbers, Sunday
;; = 0/7, etc.) to lists of start/stop pairs (times in "HH:MM" form).
;;
;; It is also possible to ignore time blocking on holidays.  This is
;; globally set using the `time-block-skip-on-holidays-p' variable.
;; This defaults to nil, which does not ignore blocking on holidays.
;; If set to t, time blocking will be ignored on any holiday.  It may
;; also be set to a regular expression or a list.  Holidays which
;; match either representation will cause time blocking to be ignored.
;;
;;;; Defining Time Blocked Commands
;;
;; Commands are only time-blocked if they're defined.  This is done
;; using the `define-time-blocked-command` macro, which behaves
;; similarly to `defun`.  After the lambda list, it has a list
;; describing blocking and blocking messages.  This is composed of a
;; symbol (a key in `time-block-groups') a block message, and an
;; optional override prompt (if present, the command will ask if you'd
;; like to override the block using `time-block-confirm-override').
;; An example is shown below.
;;
;; (define-time-blocked-command my/start-elfeed ()
;;                              (workday "You have decided not to check news currently."
;;                                       "You have decided not to check news currently.\nStill start elfeed?")
;;   "Start `elfeed'.
;;
;; Time blocked according to `time-block-groups'."
;;   (interactive)
;;   (elfeed))
;;
;;;; Advising commands to be time-blocked
;;
;; Commands can also be advised to use timeblocking.  This works for
;; simpler commands, and as a bonus, can make it harder to access the
;; commands when blocked.  Overall, the arguments for `group`,
;; `block-message` and `override-prompt` are as above.  Consider the
;; following example.
;;
;; (time-block-advise my/elfeed-block-advice 'elfeed workday "You have decided not to check news currently."
;;                    "You have decided not to check news currently.\nStill start elfeed?")
;;
;;;; Focus Mode
;;
;; A "focus mode" may be enabled using the `time-block-focus-mode'
;; command.  This global minor mode by default will block all
;; block-groups, but this behavior may be changed using
;; `time-block-block-checkers'.
;;
;;;; Relaxed Mode
;;
;; A "relaxed mode" (disabling all blocking) may be enabled with the
;; `time-block-relaxed-mode' command.  This global minor mode will
;; disable all block groups (and ignore `time-block-focus-mode').  At
;; present, this behavior is not configurable.
;;
;;;; Checking if A Group Is Blocked
;;
;; You may check if a group is currently blocked using the
;; `time-block-blocked-p' function, which uses the functions in
;; `time-block-block-checkers' to determine if a group is presently
;; blocked.  Functions in this hook must take one argument, a group
;; name, and return non-nil if the group is to be blocked.
;;
;;;; Manually advising commands to be time-blocked
;;
;; Commands can also be manually advised.  This can be done to prevent
;; only certain cases from happening.  For instance, I use the following
;; code to delay myself from editing my Emacs configuration during the
;; workday.
;;
;; (defun my/buffer-sets-around-advice (orig name)
;;   "Check if NAME is 'emacs', if so, follow time blocking logic before calling ORIG (`buffer-sets-load-set')."
;;   (unless (and (string= name "emacs")
;;                (time-block-blocked-p :workday)
;;                (not (time-block-confirm-override "You have decided not to edit your emacs configuration at this time.\nContinue?")))
;;     (funcall orig name)))
;; (advice-add 'buffer-sets-load-set :around #'my/buffer-sets-around-advice)
;;
;;;; Confirmation Functions
;;
;; When an automatically-advised function or function defined with
;; `define-time-block-command' provides an override prompt, the
;; function `time-block-confirm-override' is used to confirm that the
;; block should be overriden.  This is done following the logic of
;; `time-block-override-confirmation-functions', an alist from block
;; groups (or default t) to prompting functions. The prompting
;; function should take one argument (a confirmation prompt) and
;; return non-nil if the block should be overridden.  The default is
;; `yes-or-no-p', but the functions
;; `time-block-override-math-question' and
;; `time-block-override-random-string' may be used as well.
;;

(require 'ts)
(require 'cl-lib)

;;; Code:

;; Variables:

(defgroup time-block ()
  "Block running groups of commands using the current day and time."
  :group 'applications
  :link '(url-link :tag "Homepage" "https://git.sr.ht/~swflint/time-block-command")
  :link '(emacs-library-link :tag "Library Source" "time-block.el")
  :prefix "time-block-")

(defcustom time-block-groups nil
  "Define time blocking groups.

This variable is an alist from group names (keywords) to group
definitions.

Group definitions are alists from days of the week (numbers,
below) to (plural) start/end pairs.

Day        Number
---------- ------
Sunday     0, 7
Monday     1
Tuesday    2
Wednesday  3
Thursday   4
Friday     5
Saturday   6"
  :group 'time-block
  :type '(alist :tag "Group Definitions"
                :key-type (symbol :tag "Group Name")
                :value-type (alist :tag "Group Definition"
                                   :key-type (natnum :tag "Day Number")
                                   :value-type (repeat :tag "Start/End Times"
                                                       (cons (string :tag "Start")
                                                             (string :tag "End"))))))

(make-obsolete-variable 'time-block-command-groups 'time-block-groups "time-block 0.1.0")

(defcustom time-block-skip-on-holidays-p nil
  "How holidays should be skipped when blocking commands.

If nil, no holidays will be skipped; if t, all holidays will be
skipped; if a list, only those holidays in the list will be
skipped; if a regexp, only holidays matching will be skipped."
  :group 'time-block
  :type '(choice (const :tag "Continue blocking on holidays" nil)
                 (regexp :tag "Matching regexp")
                 (repeat :tag "Listed holidays" string)
                 (const :tag "All holidays" t)))

(defcustom time-block-override-confirmation-functions '((t . yes-or-no-p))
  "How should different blocks be overriden?

Alist from groups (or t) to a single-argument function (taking a
PROMPT) which returns non-nil if the block should be overridden.
Default functions are `yes-or-no-p',
`time-block-override-math-question' (after yes/no question, solve
a math problem), and `time-block-override-random-string' (after
yes/no question, type in a random ASCII string)."
  :group 'time-block
  :type '(alist :key-type (choice
                           (symbol :tag "Group Name")
                           (const :tag "Default" t))
                :value-type (choice
                             (function-item :tag "Yes or No" yes-or-no-p)
                             (function-item :tag "Math Question" time-block-override-math-question)
                             (function-item :tag "Type Random String" time-block-override-random-string)
                             (function :tag "Arbitrary Function"))))

(defcustom time-block-block-checkers (list
                                      #'time-block-focus-mode-p
                                      #'time-block-group-blocked-p)
  "How should it be determined if a group is blocked?

These functions should take one argument (a group), and return
non-nil if the group should be blocked.  They are run one at a
time until a function returns non-nil."
  :group 'time-block
  :type 'hook)


;; Focus Mode

(define-minor-mode time-block-focus-mode
  "Enable `focus-mode' for time blocking."
  :global t
  :lighter " FOCUS")

(defun time-block-focus-mode-p (_group)
  "Is `focus mode' currently enabled?  See also `time-block-focus-mode-p'."
  time-block-focus-mode)


;; Relaxed Mode

(define-minor-mode time-block-relaxed-mode
  "Disable time blocking temporarily."
  :global t
  :lighter " RELAXED")


;; Utility Functions

(defun time-block-confirm-override (block-group prompt)
  "Confirm override of BLOCK-GROUP using PROMPT.

This obeys `time-block-override-confirmation-functions'."
  (let ((prompt (format-message prompt))
        (confirmation-function (cdr (or (assoc block-group time-block-override-confirmation-functions)
                                        (assoc t time-block-override-confirmation-functions)))))
    (funcall confirmation-function prompt)))

(defun time-block-is-skipped-holiday-p ()
  "Determine if today is a skipped holiday."
  (when-let ((holidays time-block-skip-on-holidays-p)
             (holidays-today (calendar-check-holidays (list (ts-month (ts-now))
                                                            (ts-day (ts-now))
                                                            (ts-year (ts-now))))))
    (cond
     ((listp holidays)
      (cl-find-if #'(lambda (x)
                      (cl-member x holidays :test #'string=))
                  holidays-today))
     ((stringp holidays)
      (cl-find-if #'(lambda (x)
                      (string-match-p holidays x))
                  holidays-today))
     (t t))))

(defun time-block-group-blocked-p (block-group)
  "Is group BLOCK-GROUP currently blocked?"
  (unless (or time-block-relaxed-mode
              (time-block-is-skipped-holiday-p))
    (when-let ((group (cl-rest (assoc block-group time-block-groups)))
               (ts-now (ts-now))
               (current-day (ts-dow ts-now))
               (day-blocks (cl-rest (assoc current-day group)))
               (now (ts-parse (ts-format "%H:%M" ts-now))))
      (cl-do* ((pair (cl-first day-blocks) (cl-first blocks-left))
               (blocks-left (cl-rest day-blocks) (cl-rest blocks-left))
               (start (ts-parse (car pair)) (ts-parse (car pair)))
               (end (ts-parse (cdr pair)) (ts-parse (cdr pair))))
          ((or (null blocks-left)
               (and (ts<= start now)
                    (ts<= now end)))
           (and (ts<= start now)
                (ts<= now end)))))))

(defun time-block-blocked-p (group)
  "Is GROUP currently blocked?

Ways that a group may be blocked are determined by `time-block-block-checkers'."
  (run-hook-with-args-until-success 'time-block-block-checkers group))



;; Alternative block commands

(defun time-block-override-math-question (prompt)
  "Ask to override with PROMPT and a math problem.

If user elects to override, then use a math problem (addition,
multiplication, subtraction) to override."
  (let* ((a (random 100))
         (b (random 100))
         (op (seq-random-elt (list '* '+ '-)))
         (ans (funcall op a b)))
    (and (yes-or-no-p prompt)
         (= ans (read-number (format-message "Are you sure?\n%d %s %d = " a op b))))))

(defun time-block-override-random-string (prompt)
  "Ask to override with PROMPT and typing of random string.

If user elects to override, then require a random 16-32 character
string is typed exactly to override."
  (let* ((length (+ 16 (random 17)))
         (characters (cl-loop for i from 1 to length
                              collect (+ 33 (random 94))))
         (string (mapconcat #'(lambda (x) (format "%c" x)) characters nil)))
    (and (yes-or-no-p prompt)
         (string= string
                  (read-string (format-message "Please type the string `%s': " string))))))


;; Main definition macro

(cl-defmacro define-time-blocked-command (name argslist (group block-message &optional override-prompt) &body body)
  "Define NAME as a time-blocked command.

ARGSLIST are the arguments which the command takes.
DOCSTRING is the documentation string and is optional.

GROUP is the `time-block-groups' to use to determine
whether or not to run.

BLOCK-MESSAGE is the message to show when run is blocked.

If OVERRIDE-PROMPT is present, then ask if blocking should be
overriden using `time-block-confirm-override'.

BODY is the body of the code.  This should include an
`interactive' specification matching \\=ARGSLIST.

\(fn NAME ARGSLIST (GROUP BLOCK-MESSAGE [OVERRIDE-PROMPT]) [DOCSTRING] [INTERACTIVE-SPEC] [BODY...])"
  (declare (debug (&define name lambda-list
                           sexp
                           [&optional lambda-doc]
                           [&optional ("interactive" interactive) def-body]))
           (indent 3)
           (doc-string 4))
  (let* ((docstring (when (stringp (cl-first body)) (cl-first body)))
         (body (if docstring (cl-rest body) body))
         (interactive-spec (when (and (listp (cl-first body))
                                      (equal 'interactive (cl-first (cl-first body))))
                             (cl-first body)))
         (body (if interactive-spec (cl-rest body) body))
         (condition (if override-prompt
                        `(and (time-block-blocked-p ,group)
                              (not (time-block-confirm-override ,group ,override-prompt)))
                      `(time-block-blocked-p ,group))))
    (if docstring
        `(defun ,name ,argslist
           ,docstring
           ,interactive-spec
           (if ,condition
               (message ,block-message)
             ,@body))
      `(defun ,name ,argslist
         ,interactive-spec
         (if ,condition
             (message ,block-message)
           ,@body)))))

(make-obsolete 'timeblock-define-block-command 'define-time-blocked-command "time-block 0.1.0")


;; Advice macro

(defmacro time-block-advise (advice-name command group block-message &optional override-prompt)
  "Define `:around' advice for COMMAND called ADVICE-NAME.

Use BLOCK-MESSAGE to notify user if run is currently blocked by
GROUP.  If OVERRIDE-PROMPT is present, use
`time-block-confirm-override' to override."
  (let ((condition (if override-prompt
                       `(and (time-block-blocked-p ,group)
                             (not (time-block-confirm-override ,group ,override-prompt)))
                     `(time-block-blocked-p ,group))))
    `(progn
       (defun ,advice-name (orig &rest args)
         (interactive)
         (if ,condition
             (message ,block-message)
           (if (called-interactively-p)
               (call-interactively orig)
             (apply orig args))))
       (advice-add ,command :around #',advice-name))))

(provide 'time-block)

;;; time-block.el ends here
