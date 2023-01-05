;;; chronometrist-goal.el --- Adds support for time goals to Chronometrist -*- lexical-binding: t; -*-

;; Author: contrapunctus <xmpp:contrapunctus@jabber.fr>
;; Maintainer: contrapunctus <xmpp:contrapunctus@jabber.fr>
;; Keywords: calendar
;; Package-Version: 20210510.1831
;; Package-Commit: 6cb939d160f5d5966d7853aa23f3ed7c7ef9df44
;; Homepage: https://tildegit.org/contrapunctus/chronometrist-goal
;; Package-Requires: ((emacs "25.1") (alert "1.2") (chronometrist "0.7.0"))
;; Version: 0.2.1

(require 'chronometrist)
(require 'alert)

;; This is free and unencumbered software released into the public domain.
;;
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;;
;; For more information, please refer to <https://unlicense.org>

;;; Commentary:
;; Add support for time goals to Chronometrist

;; For information on usage and customization, see https://tildegit.org/contrapunctus/chronometrist-goal#usage

;;; Code:

(declare-function chronometrist-last "chronometrist-queries")

(defvar chronometrist-goal--timers-list nil)

(defcustom chronometrist-goal-list nil
  "List to specify daily time goal for each task.
Each element must be in the form (GOAL TASK *).

GOAL is an integer specifying number of minutes.

TASK is the task on which you would like spend GOAL time.

There can be more than one TASK, to specify that you would
like to spend GOAL time on any one of those tasks."
  :group 'chronometrist
  :type '(repeat
          (list integer :value 15
                (repeat :inline t string))))

(defun chronometrist-goal-run-at-time (time repeat function &rest args)
  "Like `run-at-time', but append timers to `chronometrist-goal--timers-list'.
TIME, REPEAT, FUNCTION, and ARGS are as used in `run-at-time'."
  (->> (apply #'run-at-time time repeat function args)
       (list)
       (append chronometrist-goal--timers-list)
       (setq chronometrist-goal--timers-list)))

;; (mapcar #'chronometrist-goal-seconds->alert-string '(0 1 2 59 60 61 62 120 121 122))
(defun chronometrist-goal-seconds->alert-string (seconds)
  "Convert SECONDS to a string suitable for displaying in alerts.
SECONDS should be a positive integer."
  (-let [(h m _) (chronometrist-seconds-to-hms seconds)]
    (let* ((h-str  (unless (zerop h)
                     (number-to-string h)))
           (m-str  (unless (zerop m)
                     (number-to-string m)))
           (h-unit (cl-case h
                     (0 nil)
                     (1 " hour")
                     (t " hours")))
           (m-unit (cl-case m
                     (0 nil)
                     (1 " minute")
                     (t " minutes")))
           (and    (if (and h-unit m-unit)
                       " and "
                     "")))
      (concat h-str h-unit
              and
              m-str m-unit))))

(defun chronometrist-goal-approach-alert (task goal spent)
  "Alert the user when they are 5 minutes away from reaching GOAL for TASK.
TASK is the name of the current task (as a string).
GOAL is the goal time for that task (minutes as an integer).
SPENT is the time spent on that task (minutes as an integer)."
  (and goal
       (< spent goal)
       (chronometrist-goal-run-at-time (* 60 (- goal 5 spent)) ;; negative seconds = run now
                      nil
                      (lambda (task)
                        (alert (format "5 minutes remain for %s" task)))
                      task)))

(defun chronometrist-goal-complete-alert (task goal spent)
  "Alert the user when they have reached the GOAL for TASK.
TASK is the name of the current task (as a string).
GOAL is the goal time for that task (minutes as an integer).
SPENT is the time spent on that task (minutes as an integer)."
  (and goal
       ;; In case the user reaches GOAL but starts tracking again -
       ;; CURRENT is slightly over GOAL, but we notify the user of
       ;; reaching the GOAL anyway.
       (< spent (+ goal 5))
       (chronometrist-goal-run-at-time (* 60 (- goal spent)) ;; negative seconds = run now
                      nil
                      (lambda (task)
                        (alert (format "Goal for %s reached" task)))
                      task)))

(defun chronometrist-goal-exceed-alert (task goal spent)
  "Alert the user when they have exceeded the GOAL for TASK.
TASK is the name of the current task (as a string).
GOAL is the goal time for that task (minutes as an integer).
SPENT is the time spent on that task (minutes as an integer)."
  (and goal
       (chronometrist-goal-run-at-time (* 60 (- (+ goal 5) spent)) ;; negative seconds = run now
                      nil
                      (lambda (task)
                        (alert (format "You are exceeding the goal for %s!" task)
                               :severity 'medium))
                      task)))

(defun chronometrist-goal-no-goal-alert (task goal _spent)
  "If TASK has no GOAL, regularly remind the user of the time spent on it.
TASK is the name of the current task (as a string).
GOAL is the goal time for that task (minutes as an integer).
SPENT is the time spent on that task (minutes as an integer)."
  (unless goal
    (chronometrist-goal-run-at-time (* 15 60) ;; first run after 15 minutes from now
                   (* 15 60) ;; repeat every 15 minutes
                   (lambda (task)
                     ;; We cannot use SPENT here, because that will
                     ;; remain the value it had when we clocked in
                     ;; (when `chronometrist-goal-run-alert-timers'
                     ;; is run), and we need show the time spent at
                     ;; the time of notification.
                     (alert (format "You have spent %s on %s"
                                    (chronometrist-goal-seconds->alert-string
                                     (chronometrist-task-time-one-day task))
                                    task)))
                   task)))

(defcustom chronometrist-goal-alert-functions
  '(chronometrist-goal-approach-alert
    chronometrist-goal-complete-alert
    chronometrist-goal-exceed-alert
    chronometrist-goal-no-goal-alert)
  "List to describe timed alerts.
Each element should be a function, which will be called with
three arguments - the name of the current task (as a string) and
the goal time for that task (minutes as an integer), and the time
spent on that task (minutes as an integer).

Typically, each function in this list should call `run-at-time'
to run another function, which in turn should call `alert' to
notify the user.

The timer returned by `run-at-time' should also be appended to
`chronometrist-goal--timers-list', so that it can later be stopped by
`chronometrist-goal-stop-alert-timers'. `chronometrist-goal-run-at-time'
will do that for you.

Note - the time spent passed to these functions is calculated
when `chronometrist-goal-run-alert-timers' is run, i.e. when the
user clocks in. To obtain the time spent at the time of
notification, use `chronometrist-task-time-one-day' within the
function passed to `run-at-time'."
  :group 'chronometrist
  :type 'hook)

;; TODO - if there are multiple tasks associated with a single time
;; goal (i.e. `(int "task1" "task2" ...)'), and the user has reached
;; the goal for one of those tasks, don't display the goal for the
;; other associated tasks
(cl-defun chronometrist-goal-get (task &optional (goal-list chronometrist-goal-list))
  "Return time goal for TASK from GOAL-LIST.
Return value is minutes as an integer, or nil.

If GOAL-LIST is not supplied, `chronometrist-goal-list' is used."
  (cl-loop for list in goal-list
           when (member task list)
           return (car list)))

(defun chronometrist-goal-run-alert-timers (task)
  "Run timers to alert the user of the time spent on TASK.
To use, add this to `chronometrist-after-in-functions', and
`chronometrist-goal-stop-alert-timers' to
`chronometrist-after-out-functions'."
  (let ((goal    (chronometrist-goal-get task))
        (spent   (/ (chronometrist-task-time-one-day task) 60)))
    (add-hook 'chronometrist-file-change-hook #'chronometrist-goal-on-file-change)
    (mapc (lambda (f)
            (funcall f task goal spent))
          chronometrist-goal-alert-functions)))

(defun chronometrist-goal-stop-alert-timers (&optional _task)
  "Stop timers to alert the user of the time spent on TASK.
To use, add this to `chronometrist-after-out-functions', and
`chronometrist-goal-run-alert-timers' to
`chronometrist-after-in-functions'."
  (and chronometrist-goal--timers-list ;; in case of start task -> exit Emacs without stopping -> start Emacs -> stop task
       (mapc #'cancel-timer chronometrist-goal--timers-list)
       (setq chronometrist-goal--timers-list   nil)))

(defun chronometrist-goal-on-file-change ()
  "Manage timed alerts when `chronometrist-file' changes."
  (let ((last (chronometrist-last)))
    (chronometrist-goal-stop-alert-timers)
    ;; if there's a task running, start timed alerts for it
    (unless (plist-get last :stop)
      (chronometrist-goal-run-alert-timers (plist-get last :name)))))

;;;; minor mode
(defun chronometrist-goal-entry-transformer (entry)
  "Add goal information to the return value of `chronometrist-entries'.
ENTRY must be a valid element in the list specified by
  `tabulated-list-entries'."
  (-let* (((task vector) entry)
          (goal (aif (chronometrist-goal-get task) (format "% 4d" it) "")))
    (list task (vconcat vector `[,goal]))))

(defun chronometrist-goal-list-format-transformer (format)
  "Add a goal column to the return value of `tabulated-list-format'.
FORMAT should be a vector (see `tabulated-list-format')."
  (vconcat format `[("Target" 3 t)]))

(defun chronometrist-goal-setup ()
  "Add `chronometrist-goal' functions to `chronometrist' hooks."
  (add-to-list 'chronometrist-entry-transformers       #'chronometrist-goal-entry-transformer)
  (add-to-list 'chronometrist-list-format-transformers #'chronometrist-goal-list-format-transformer)
  (add-hook 'chronometrist-after-in-functions  #'chronometrist-goal-run-alert-timers)
  (add-hook 'chronometrist-after-out-functions #'chronometrist-goal-stop-alert-timers))

(defun chronometrist-goal-teardown ()
  "Remove `chronometrist-goal' functions from `chronometrist' hooks."
  (setq chronometrist-entry-transformers
        (remove #'chronometrist-goal-entry-transformer chronometrist-entry-transformers)
        chronometrist-list-format-transformers
        (remove #'chronometrist-goal-list-format-transformer chronometrist-list-format-transformers))
  (remove-hook 'chronometrist-after-in-functions  #'chronometrist-goal-run-alert-timers)
  (remove-hook 'chronometrist-after-out-functions #'chronometrist-goal-stop-alert-timers))

(define-minor-mode chronometrist-goal-minor-mode
  "Toggle `chronometrist-goal-minor-mode'.
With a prefix argument ARG, enable
`chronometrist-goal-minor-mode' if ARG is positive, and disable
it otherwise. If called from Lisp, enable the mode if ARG is
omitted or nil."
  nil nil nil
  ;; when being enabled/disabled, `chronometrist-goal-minor-mode' will already be t/nil here
  (if chronometrist-goal-minor-mode (chronometrist-goal-setup) (chronometrist-goal-teardown)))

(provide 'chronometrist-goal)

;; Local Variables:
;; nameless-current-name: "chronometrist-goal"
;; End:

;;; chronometrist-goal.el ends here
