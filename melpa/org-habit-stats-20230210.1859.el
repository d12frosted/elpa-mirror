;;; org-habit-stats.el --- Display info about habits  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 ml729
;;
;; Author: ml729
;; Created: October 22, 2021
;; Version: 0.1
;; Package-Version: 20230210.1859
;; Package-Commit: 0e28b1c1ba330d7d07064a7272104f7e793be4ce
;; Keywords: calendar, org-mode, org-habit, habits, stats, statistics, charts, graphs
;; Homepage: https://github.com/ml729/org-habit-stats/
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; View stats, a calendar, and bar graphs of your org-habits.

;;; Code:

(require 'org-habit)
(require 'org-element)
(require 'cl-lib)
(require 'seq)
(require 'chart)

(defgroup org-habit-stats nil
  "Visualize your org-habits."
  :group 'org-progress
  :prefix "org-habit-stats-")

;;; Defcustoms
(defcustom org-habit-stats-include-uncompleted-today nil
  "If a habit is not done today, whether or not to include today."
  :group 'org-habit-stats
  :type 'boolean)

(defcustom org-habit-stats-graph-colors-list
  '("#ef7969"
    "#49c029"
    "#7090ff"
    "#e07fff"
    "#70d3f0"
    "#ffcf00")
  "Colors to use for bars of bar graph.
The default colors are Modus Vivendi's colors for graphs. The original value of
`chart-face-color-list` is unaffected."
  :group 'org-habit-stats
  :type '(list color))

(defcustom org-habit-stats-graph-width 70
  "Width of x-axis of graph (in columns), not including origin."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-height 12
  "Height of y-axis of graph (in line numbers), not including origin."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-left-margin 5
  "Number of columns to the left of y-axis."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-min-num-bars 3
  "How many bars to shift left when the bar graph is truncated."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-number-months 5
  "How many months to display when graph's x-axis is months."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-number-weeks 10
  "How many weeks to display when graph's x-axis is weeks."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-number-days 15
  "How many days to display when graph's x-axis is days."
  :group 'org-habit-stats
  :type 'integer)

(defcustom org-habit-stats-graph-data-horizontal-char ?-
  "Character used to draw horizontal lines for a graph's data."
  :group 'org-habit-stats
  :type 'character)

(defcustom org-habit-stats-graph-data-vertical-char ?|
  "Character used to draw vertical lines for a graph's data."
  :group 'org-habit-stats
  :type 'character)

(defcustom org-habit-stats-graph-axis-horizontal-char ?-
  "Character used to draw horizontal lines for a graph's axes."
  :group 'org-habit-stats
  :type 'character)

(defcustom org-habit-stats-graph-axis-vertical-char ?|
  "Character used to draw vertical lines for a graph's axes."
  :group 'org-habit-stats
  :type 'character)

(defcustom org-habit-stats-graph-show-values-on-bars t
  "Whether or not to show exact values on top of bars in the bar graph."
  :group 'org-habit-stats
  :type 'boolean)

(defcustom org-habit-stats-graph-command-prefix "g"
  "Prefix key for graph commands."
  :group 'org-habit-stats
  :type 'string)

(defcustom org-habit-stats-months-names-alist
  '(("Jan" . 1)
    ("Feb" . 2)
    ("Mar" . 3)
    ("Apr" . 4)
    ("May" . 5)
    ("Jun" . 6)
    ("Jul" . 7)
    ("Aug" . 8)
    ("Sep" . 9)
    ("Oct" . 10)
    ("Nov" . 11)
    ("Dec" . 12))
  "Month names used in graphs."
  :group 'org-habit-stats
  :type '(alist :key-type string :value-type integer))

(defcustom org-habit-stats-days-names-alist
  '(("Sun" . 1)
    ("Mon" . 2)
    ("Tue" . 3)
    ("Wed" . 4)
    ("Thu" . 5)
    ("Fri" . 6)
    ("Sat" . 7))
  "Day names used in graphs."
  :group 'org-habit-stats
  :type '(alist :key-type string :value-type integer))

(defcustom org-habit-stats-stat-date-format
  "%F"
  "Date format used in graphs for dates in stats."
  :group 'org-habit-stats
  :type 'string)

(defcustom org-habit-stats-graph-date-format
  "%m/%d"
  "Date format used in graphs for dates in graphs."
  :group 'org-habit-stats
  :type 'string)

(defcustom org-habit-stats-stat-functions-alist
  '((org-habit-stats-streak . "Current Streak")
    (org-habit-stats-exp-smoothing-list-today . "Habit Strength")
    (org-habit-stats-record-streak-days . "Record Streak")
    (org-habit-stats-record-streak-date . "Record Date")
    (org-habit-stats-unstreak . "Unstreak")
    (org-habit-stats-30-day-total . "30 day total")
    (org-habit-stats-30-day-percentage . "30 day percentage")
    (org-habit-stats-alltime-total . "Total Completions")
    (org-habit-stats-alltime-percentage . "Total Percentage"))
  "Alist mapping stat functions to a list of their names.
The name is used in the org-habit-stats buffer, and (after
replacing whitespace with underscores) in properties."
  :group 'org-habit-stats
  :type '(alist :key-type function :value-type string))

(defcustom org-habit-stats-message-functions-list
  '(org-habit-stats-streak-message
    org-habit-stats-unstreak-message
    org-habit-stats-comeback-message)
  "List of message functions.
A message function takes in the habit history, reversed habit
history, and parsed habit data, and returns a string."
  :group 'org-habit-stats
  :type '(list function))

(defcustom org-habit-stats-streak-message-alist
  '((10 . "Achieved streak 10! Reward: Study the GNU Emacs manuals")
    (20 . "Achieved streak 20! Reward: Configure my .emacs.d")
    (30 . "Achieved streak 30! Reward: Read Sacha Chua's Emacs News")
    (40 . "Achieved streak 40! Reward: Watch Protesilaos Emacs talks")
    (50 . "Achieved streak 50! Reward: Try out the latest (M)ELPA packages"))
  "Alist mapping current streak length to messages to be displayed.
Only displays the message when the streak length is exactly that value."
  :group 'org-habit-stats
  :type '(alist :key-type integer :value-type string))

(defcustom org-habit-stats-unstreak-message-alist
  '((10 . "It's never too late to start again."))
  "Alist mapping current unstreak length to messages to be displayed.
An unstreak is the sequence of consecutive misses. Only displays
the message when the unstreak length is exactly that value."
  :group 'org-habit-stats
  :type '(alist :key-type integer :value-type string))

(defcustom org-habit-stats-comeback-message
  "Record streak recovered!"
  "Message to display when record streak is achieved again."
  :group 'org-habit-stats
  :type 'string)

(defcustom org-habit-stats-exp-smoothing-alpha 0.052
  "Weight of completed days for exponential smoothing."
  :group 'org-habit-stats
  :type 'number)

(defcustom org-habit-stats-exp-smoothing-beta 0.10
  "Weight of missed days for exponential smoothing."
  :group 'org-habit-stats
  :type 'number)

(defcustom org-habit-stats-graph-functions-alist
  '((org-habit-stats-graph-completions-per-month . (:key "m"
                                                    :title "Monthly Completions"
                                                    :x-label "Months"
                                                    :y-label "Completions"
                                                    :dir horizontal
                                                    :max-bars 5))
    (org-habit-stats-graph-completions-per-week . (:key "w"
                                                   :title "Weekly Completions"
                                                   :x-label "Weeks"
                                                   :y-label "Completions"
                                                   :dir vertical
                                                   :max-bars 10))
    (org-habit-stats-graph-completions-per-weekday . (:key "d"
                                                      :title "Completions by Day"
                                                      :x-label "Day"
                                                      :y-label "Completions"
                                                      :dir vertical
                                                      :max-bars 7))
    (org-habit-stats-graph-daily-strength . (:key "s"
                                             :title "Daily Habit Strength"
                                             :x-label "Day"
                                             :y-label "Strength"
                                             :dir vertical
                                             :max-bars 14)))
  "Alist mapping graph functions to a list of key value pairs.
This includes the key that invokes the function, the title of the
graph, the name of the x-axis, the name of the y-axis, the graph
direction, and the max number of bars to show at a time."
  :group 'org-habit-stats
  :type '(alist :key-type function :value-type sexp))

(defcustom org-habit-stats-graph-default-func 'org-habit-stats-graph-completions-per-week
  "Current graph function used in org habit stats buffer."
  :group 'org-habit-stats
  :type 'function)

(defcustom org-habit-stats-show-blank-when-new-habit t
  "If t, display new habit message for a habit with 0 completions."
  :group 'org-habit-stats
  :type 'boolean)

(defcustom org-habit-stats-new-habit-message "A new habit."
  "Message to display when habit has 0 completions logged."
  :group 'org-habit-stats
  :type 'boolean)

(defcustom org-habit-stats-calendar-dont-highlight-whitespace nil
  "If t, don't highlight whitespace padding in calendar dates."
  :group 'org-habit-stats
  :type 'boolean)

;;; Defvars
(defvar org-habit-stats-buffer "*Org-Habit-Stats*"
  "Name of the buffer used for displaying stats, calendar, and graphs.")

(defvar org-habit-stats-calendar-buffer "*Org-Habit-Stats Calendar*"
  "Name of the buffer used for the calendar.")

(defvar org-habit-stats-displayed-month nil
  "Stores displayed-month value for calendar functions.")

(defvar org-habit-stats-displayed-year nil
  "Stores displayed-year value for calendar functions.")

(defvar org-habit-stats-graph-current-offset 0
  "How many bars to shift left when the bar graph is truncated.")

(defvar org-habit-stats-graph-face-list nil
  "Faces used for bars in graphs.
Generated from `org-habit-stats-graph-colors-list'.")

(defvar org-habit-stats-graph-current-func nil
  "Current graph function used in org habit stats buffer.")

(defvar-local org-habit-stats-habit-source nil)
(defvar-local org-habit-stats-stat-bounds nil)
(defvar-local org-habit-stats-calendar-bounds nil)
(defvar-local org-habit-stats-message-bounds nil)
(defvar-local org-habit-stats-graph-bounds nil)
(defvar-local org-habit-stats-current-habit-data nil)
(defvar-local org-habit-stats-current-habit-name nil)
(defvar-local org-habit-stats-current-habit-description nil)
(defvar-local org-habit-stats-current-history nil)
(defvar-local org-habit-stats-current-history-rev nil)
(defvar-local org-habit-stats-current-buffer nil)
(defvar-local org-habit-stats-current-calendar-buffer nil)

;;; Faces
(defface org-habit-stats-message-positive
  '((t (:foreground "#000000" :background "gold2")))
  "Face for positive messages."
  :group 'org-habit-stats)

(defface org-habit-stats-message-encouraging
  '((t (:foreground "#000000" :background "chocolate1")))
  "Face for encouraging messages."
  :group 'org-habit-stats)

(defface org-habit-stats-graph-label
  '((t (:inherit default)))
  "Face for a habit graph's axis labels."
  :group 'org-habit-stats)

(defface org-habit-stats-graph-name
  '((t (:weight bold)))
  "Face for a habit graph's axis name."
  :group 'org-habit-stats)

(defface org-habit-stats-graph-title
  '((t (:weight bold)))
  "Face for a habit graph's title."
  :group 'org-habit-stats)

(defface org-habit-stats-calendar-completed
  '((t (:foreground "#004c00" :background "#e0a3ff")))
  "Face for days in the calendar where the habit was completed."
  :group 'org-habit-stats)

(defface org-habit-stats-stat-value
  '((t (:foreground "#004c00" :background "#aceaac")))
  "Face for statistics value."
  :group 'org-habit-stats)

(defface org-habit-stats-stat-name
  '((t (:inherit org-agenda-structure-secondary)))
  "Face for statistics value."
  :group 'org-habit-stats)

(defface org-habit-stats-habit-name
  '((t (:inherit org-agenda-structure)))
  "Face for habit name."
  :group 'org-habit-stats)

(defface org-habit-stats-section-name
  '((t (:inherit default)))
  "Face for section name in org-habit-stats buffer."
  :group 'org-habit-stats)

;; Stats functions
(defun org-habit-stats-get-full-history-old-to-new (history)
  "Return the full history of a habit from old to new.
HISTORY is a list of dates of completions. A date here is the
number of days since December 31, 1 BC. The returned value is a
list of dates since the earliest date in history (inclusive)
where each element is a pair of the form (date . 0 or 1),
indicating if there was a completion or not on that day.

If today is marked completed, it is included in the history. If today is
not marked completed, it is included in the history if and only
if `org-habit-stats-include-uncompleted-today` is t."
  (let ((today (org-today))
        (bin-hist '())
        (history (reverse history)))
    (seq-reduce ;;replace with reduce
     (lambda (a b)
         (setq a (1- a))
       (while (> a b)
         (if (= a today)
             (if org-habit-stats-include-uncompleted-today
                 (push (cons a 0) bin-hist))
           (push (cons a 0) bin-hist))
         (setq a (1- a)))
       (push (cons b 1) bin-hist)
       b)
     history
     (1+ today))
    bin-hist))

(defun org-habit-stats-get-full-history-new-to-old (history)
  "Return the full history of a habit from old to new.
This returns the reverse of calling
`org-habit-stats-get-full-history-new-to-old` on HISTORY."
  (reverse (org-habit-stats-get-full-history-old-to-new history)))

(defun org-habit-stats-get-repeat-history-old-to-new (habit-data)
  "Return the history of a habit accounting for the repeat interval.

HABIT-DATA contains the result of calliing
`org-habit-stats-parse-todo' on a habit.

It modifies the full history of a habit (see
`org-habit-stats-get-full-history-new-to-old') by removing
certain days without completions.  For ++n or +n style habits,
misses occuring n-1 days after a scheduled date are removed.  For
.+n style habits, misses occuring n-1 days after a completed day
are removed."
  (let* ((partial-history (nth 4 habit-data))
         (repeat-type (nth 5 habit-data))
         (repeat-len (nth 1 habit-data))
         (next-scheduled (nth 0 habit-data))
         (full-history (org-habit-stats-get-full-history-old-to-new partial-history))
         (new-history '()))
    (cond ((= repeat-len 1) full-history)
          ((or (string= repeat-type "++")
               (string= repeat-type "+"))
           (dolist (x full-history (reverse new-history))
             ;; if a date minus next scheduled is nonzero mod repeat-len, and is incomplete, remove it
             (when (not (and (= 0 (cdr x))
                             (/= 0 (mod (- next-scheduled (car x)) repeat-len))))
               (push x new-history))))
          ((string= repeat-type ".+")
           (let ((most-recent-complete (caar full-history)))
             (dolist (x full-history (reverse new-history))
               (when (= 1 (cdr x))
                   (setq most-recent-complete (car x)))
               ;; if incomplete, and difference from prev completion is nonzero mod repeat len, remove it
               (when (not (and (= 0 (cdr x))
                             (/= 0 (mod (- (car x) most-recent-complete) repeat-len))))
                 (push x new-history)))))
          (t (error "Invalid repeat type %s" repeat-type)))))
  (defun org-habit-stats--streak (h)
    (if (and h (= (cdr (pop h)) 1))
        (1+ (org-habit-stats--streak h))
      0))

(defun org-habit-stats-streak (_history history-rev _habit-data)
  "Return current streak of the habit.

HISTORY contains a list of pairs (date . completed) where date is
represented as the number of days since December 31, 1 BC (as is
used by many `org-mode' functions) and completed is 1 if the
habit was completed that day, and 0 otherwise. It is in order
from oldest to newest. Days are skipped if the repeat interval of
the habit is greater than one. See
`org-habit-stats-get-repeat-history-old-to-new' for more
information.

HISTORY-REV is the reverse of history.

HABIT-DATA is the result of running
`org-habit-parse-todo' on a habit."
  (org-habit-stats--streak history-rev))

(defun org-habit-stats--unstreak (h)
  "Helper function for `org-habit-stats-unstreak'.

H must be new-to-old habit history."
  (if (and h (= (cdr (pop h)) 0))
      (1+ (org-habit-stats--unstreak h))
    0))
(defun org-habit-stats-unstreak (_history history-rev _habit-data)
  "Return the current unstreak (number of consecutive days missed).
If there is no history, returns 0.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats--unstreak history-rev))

(defun org-habit-stats--record-streak-full (history _history-rev _habit-data)
  "Return (record-streak . record-day).

The record-day is the last day of the record streak. If the
record streak occurs on multiple days, return the earliest one.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let ((record-streak 0)
        (record-day (org-today))
        (curr-streak 0)
        (curr-streak-start 0))
    (while history
      (let* ((next-pair (pop history))
             (curr-day (car next-pair))
             (curr-completed (cdr next-pair)))
        (if (= curr-completed 1)
            (progn
              (when (= curr-streak 0)
                (setq curr-streak-start curr-day))
              (setq curr-streak (1+ curr-streak)))
          (setq curr-streak 0))
        (when (> curr-streak record-streak)
          (setq record-streak curr-streak)
          (setq record-day (+ curr-streak-start curr-streak -1)))))
    (cons record-streak record-day)))

(defun org-habit-stats--single-whitespace-only (s)
  "Replace all contiguous whitespace with a single space in S."
  (string-join
   (seq-filter (lambda (x) (if (> (length x) 0) t))
               (split-string s " "))
   " "))

(defun org-habit-stats-record-streak-format (history history-rev habit-data)
  "Return human readable results from `org-habit-stats--record-streak-full'.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((record-data (org-habit-stats--record-streak-full history history-rev habit-data))
         (record-streak (car record-data))
         (record-day (cdr record-data)))
    (concat (number-to-string record-streak)
            ", on "
            (org-habit-stats--single-whitespace-only (org-agenda-format-date-aligned record-day)))))

(defun org-habit-stats-record-streak-days (history history-rev habit-data)
  "Return the record streak length.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (car (org-habit-stats--record-streak-full history history-rev habit-data)))

(defun org-habit-stats-record-streak-date (history history-rev habit-data)
  "Return the day the record streak is achieved.

If there are multiple record streaks, this returns the last day
of the latest one.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats-format-absolute-day-string
   org-habit-stats-stat-date-format
   (cdr (org-habit-stats--record-streak-full history history-rev habit-data))))

(defun org-habit-stats--N-day-total (history history-rev N)
  "Return the number of completions in the last N days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY and HISTORY-REV."
  (if (and (> N 0) history-rev)
      (if (= (cdr (pop history-rev)) 1)
          (1+ (org-habit-stats--N-day-total history history-rev (1- N)))
        (org-habit-stats--N-day-total history history-rev (1- N)))
    0))

(defun org-habit-stats-percentage-format (x)
  "Format real number X as a percent."
  (format "%.2f%%" (* 100 x)))

(defun org-habit-stats--N-day-percentage (history history-rev _habit-data N)
  "Return the percentage of completions in the last N days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats-percentage-format
   (/ (org-habit-stats--N-day-total history history-rev N) (float N))))

(defun org-habit-stats-30-day-percentage (history history-rev habit-data)
  "Return the percentage of completions in the last 30 days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats--N-day-percentage history history-rev habit-data 30))

(defun org-habit-stats-365-day-percentage (history history-rev habit-data)
  "Return the percentage of completions in the last 365 days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats--N-day-percentage history history-rev habit-data 365))

(defun org-habit-stats-alltime-percentage (history history-rev habit-data)
  "Return the percentage of completions since the first completion.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((numerator (org-habit-stats-alltime-total history history-rev habit-data))
        (denominator (float (length history))))
    (org-habit-stats-percentage-format (if (= denominator 0)
        0
      (/ numerator denominator)))))

(defun org-habit-stats-30-day-total (history history-rev _habit-data)
  "Return the total number of completions in the last 30 days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats--N-day-total history history-rev 30))

(defun org-habit-stats-365-day-total (history history-rev _habit-data)
  "Return the total number of completions in the last 365 days.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats--N-day-total history history-rev 365))

(defun org-habit-stats-alltime-total (_history _history-rev habit-data)
  "Return the total number of completions since the first completion.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (length (nth 4 habit-data)))

(defun org-habit-stats--exp-smoothing-list-full (history _history-rev _habit-data)
  "Return list of scores for a habit.
The list contains the scores for every day between today and the
first completion inclusive. The score is computed via exponential
smoothing. (Inspired by the GPLv3 Loop Habit Tracker app's
score.).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (if (not history) nil
    (let* ((scores '())
           (alpha org-habit-stats-exp-smoothing-alpha)
           (beta org-habit-stats-exp-smoothing-beta))
      (while history
        (let* ((completed (cdr (pop history)))
               (coeff (if (= completed 1) alpha beta))
               (prev-score (if scores (car scores) 0)))
          (push (+ (* (- 1 coeff) prev-score)
                   (* coeff completed)) scores)))
      ;; (print scores)
      (mapcar (lambda (x) (* 100 x)) scores))))

(defun org-habit-stats-exp-smoothing-list-today (history history-rev habit-data)
  "Return today's score for the habit.
See `org-habit-stats--exp-smoothing-list-full' for more details.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (if (not history) 0
    (car (org-habit-stats--exp-smoothing-list-full
          history history-rev habit-data))))

(defun org-habit-stats-get-freq (seq &optional key-func value-func)
  "Return frequencies of elements in SEQ.
If KEY-FUNC, use KEY-FUNC to produce keys for hash table. If
VALUE-FUNC, use VALUE-FUNC to produce values for hash table.
Credit to https://stackoverflow.com/a/6050245"
  (let ((h (make-hash-table :test 'equal))
        (freqs nil)
        (value-func (if value-func value-func (lambda (_) 1))))
    (dolist (x seq)
      (let ((key (if key-func (funcall key-func x) x)))
        (puthash key (+ (gethash key h 0) (funcall value-func x)) h)))
    (maphash (lambda (k v) (push (cons k v) freqs)) h)
    freqs))

(defun org-habit-stats-calculate-stats (history history-rev habit-data)
  "Return a list of cons pairs describing the stats for a habit.
Each pair is of the form (\"name of stat\" . stat).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let ((statresults '()))
    (dolist (x org-habit-stats-stat-functions-alist)
      (let* ((statfunc (car x))
             (statname (cdr x))
             (statresult (if (fboundp statfunc) (funcall statfunc history history-rev habit-data))))
        (when statresult
          (push (cons statname statresult) statresults))))
    (reverse statresults)))

(defun org-habit-stats-transpose-pair-list (a)
  "Convert a list of pairs A to a pair of two lists."
  (cons (mapcar #'car a) (mapcar #'cdr a)))

;;; Message functions
(defun org-habit-stats-get-messages (history history-rev habit-data)
  "Return list of messages to display for the habit.
It does so by calling all functions in
`org-habit-stats-message-functions-list' on the three forms of
the habit's data.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let ((messageslst '()))
    (dolist (x org-habit-stats-message-functions-list)
      (let ((x-message (funcall x history history-rev habit-data)))
        (when x-message
          (push x-message messageslst))))
    (reverse messageslst)))

(defun org-habit-stats-streak-message (history history-rev habit-data)
  "Return a message based on the habit's streak or nil.
When the current streak is equal to the first value in a pair in
`org-habit-stats-streak-message-alist', the second value of that
pair is returned as the message.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((streak (org-habit-stats-streak history history-rev habit-data))
        (message (alist-get streak org-habit-stats-streak-message-alist)))
    (when message
      (propertize message
        'face 'org-habit-stats-message-positive))))

(defun org-habit-stats-unstreak-message (history history-rev habit-data)
  "Return a message based on the habit's streak or nil.
When the current unstreak is equal to the first value in a pair in
`org-habit-stats-unstreak-message-alist', the second value of that
pair is returned as the message.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((unstreak (org-habit-stats-unstreak history history-rev habit-data))
        (message (alist-get unstreak org-habit-stats-unstreak-message-alist)))
    (when message
      (propertize message
       'face 'org-habit-stats-message-encouraging))))

(defun org-habit-stats-comeback-message (history history-rev habit-data)
  "Return a message when a comeback happens.
The message is `org-habit-stats-comeback-message'.

A comeback occurs when the user reaches a record streak that they
previously already obtained. It also only applies for streaks of
length at least 5.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((curr-streak (org-habit-stats-streak history history-rev habit-data))
         (record-data (org-habit-stats--record-streak-full history history-rev habit-data))
         (record-day (cdr record-data))
         (record-streak (car record-data)))
    (when (and (= curr-streak record-streak)
               (>= curr-streak 5)
               (/= record-day (org-today))
               (/= record-day (1- (org-today))))
      (propertize org-habit-stats-comeback-message
                  'face 'org-habit-stats-message-positive))))

;;; Calendar functions
(defun org-habit-stats-calendar-mark-habits (habit-data)
  "Mark completed habits in the internal calendar buffer.

See the docstring of `org-habit-stats-streak' for a description
of HABIT-DATA."
  (let ((completed-dates (nth 4 habit-data))
        (calendar-buffer org-habit-stats-calendar-buffer))
    (dolist (completed-day completed-dates nil)
      (let ((completed-day-gregorian (calendar-gregorian-from-absolute completed-day)))
        (when (calendar-date-is-visible-p completed-day-gregorian)
            (calendar-mark-visible-date completed-day-gregorian 'org-habit-stats-calendar-completed))))))

(defun org-habit-stats-get-calendar-contents ()
  "Return contents of `org-habit-stats-calendar-buffer'."
  (with-current-buffer org-habit-stats-calendar-buffer
    (buffer-string)))

(defun org-habit-stats-get-calendar-overlays ()
  "Return a list of all overlays in `org-habit-stats-calendar-buffer'.
These are overlays corresponding to completed days."
  (with-current-buffer org-habit-stats-calendar-buffer
    (let ((ol-list (overlay-lists)))
      (append (car ol-list) (cdr ol-list)))))

(defun org-habit-stats-apply-overlays (ol-list offset buffer)
  "Apply overlays in OL-LIST to BUFFER, by offset OFFSET."
  (dolist (ol ol-list)
    (let* ((new-start (+ (overlay-start ol) offset))
           (new-end (+ (overlay-end ol) offset))
          (space-at-new-start (save-excursion
                               (goto-char new-start)
                               (eq ?  (char-after))))
          (new-start-adjusted (if (and org-habit-stats-calendar-dont-highlight-whitespace
                                       space-at-new-start
                                     (< new-start new-end))
                                (1+ new-start)
                              new-start)))
     (move-overlay (copy-overlay ol)
                   new-start-adjusted
                   new-end
                   buffer))))

;; create calendar buffer, inject text at top, mark custom dates, set so curr month on the right first
(defun org-habit-stats-make-calendar-buffer (habit-data)
  "Create a `calendar-mode' buffer displaying completed days.
HABIT-DATA contains the results of `org-habit-parse-todo`."
  (with-current-buffer
      (get-buffer-create org-habit-stats-calendar-buffer)
    (calendar-mode)
    (let* ((date (calendar-current-date))
           (month (1- (calendar-extract-month date)))
           (year (calendar-extract-year date)))
      (let (calendar-today-visible-hook calendar-today-invisible-hook)
        (calendar-generate-window month year))
      (setq org-habit-stats-displayed-month month)
      (setq org-habit-stats-displayed-year year)
      (org-habit-stats-calendar-mark-habits habit-data))
    (run-hooks 'calendar-initial-window-hook)))

(defun org-habit-stats-refresh-calendar-buffer ()
  "Delete and re-insert calendar with updated info."
  (let* ((month org-habit-stats-displayed-month)
         (year org-habit-stats-displayed-year)
         (habit-data org-habit-stats-current-habit-data))
    (with-current-buffer org-habit-stats-calendar-buffer
      (setq buffer-read-only nil)
      (let (calendar-today-visible-hook calendar-today-invisible-hook)
        (calendar-generate-window month year))
      (org-habit-stats-calendar-mark-habits habit-data)
      (setq buffer-read-only t))))

;;; Calender commands
(defun org-habit-stats-increment-displayed-month (n)
  "Increment displayed month by N.
Adjusts displayed-year accordingly. N can be positive, zero, or
negative."
  (if (> n 0)
      (while (> n 12)
        (setq n (- n 12))
        (setq org-habit-stats-displayed-year
              (1+ org-habit-stats-displayed-year)))
    (while (< n 0)
      (setq n (+ n 12))
      (setq org-habit-stats-displayed-year
            (1- org-habit-stats-displayed-year))))
  (let ((sum (+ n org-habit-stats-displayed-month)))
    (if (> sum 12)
        (progn
          (setq org-habit-stats-displayed-month (mod sum 12))
          (setq org-habit-stats-displayed-year
                (1+ org-habit-stats-displayed-year)))
      (setq org-habit-stats-displayed-month sum))))

;; (defun org-habit-stats-send-calendar-command (cal-cmd)
;;   (with-current-buffer org-habit-stats-calendar-buffer
;;     (let* ((displayed-month org-habit-stats-displayed-month)
;;            (displayed-year org-habit-stats-displayed-year))
;;       (funcall cal-cmd)
;;       (org-habit-stats-calendar-mark-habits org-habit-stats-current-habit-data)))
;;   (org-habit-stats-refresh-buffer))

(defun org-habit-stats--calendar-scroll (n)
  "Scroll org-habit-stats calendar forward N months.
N can be positive, zero, or negative."
  (org-habit-stats-increment-displayed-month n)
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
  (org-habit-stats-refresh-calendar-buffer)
  (org-habit-stats-refresh-calendar-section)))

(defun org-habit-stats-calendar-scroll-right (arg)
  "Move the `org-habit-stats' calendar forward ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll arg))

(defun org-habit-stats-calendar-scroll-left (arg)
  "Move the `org-habit-stats' calendar backward ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll (- arg)))

(defun org-habit-stats-calendar-scroll-right-three-months (arg)
  "Move the `org-habit-stats' calendar forward 3*ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll (* 3 arg)))

(defun org-habit-stats-calendar-scroll-left-three-months (arg)
  "Move the `org-habit-stats' calendar backward 3*ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll (* -3 arg)))

(defun org-habit-stats-calendar-forward-year (arg)
  "Move the `org-habit-stats' calendar forward 12*ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll (* 12 arg)))

(defun org-habit-stats-calendar-backward-year (arg)
  "Move the `org-habit-stats' calendar backward 12*ARG months."
  (interactive "p")
  (org-habit-stats--calendar-scroll (* -12 arg)))

;;; Graph data functions
(defun org-habit-stats--unix-from-absolute-time (abs-time)
  "Convert time ABS-TIME (from end of 1 BC) to unix time.
Used because `org-habit-parse-todo`, `org-today`, etc. all return
days since the end of 1 BC."
  (- abs-time (org-habit-stats-days-to-time (calendar-absolute-from-gregorian '(12 31 1969)))))

(defun org-habit-stats-format-absolute-time-string (format-string &optional time zone)
  "Format time string given time TIME since end of 1 BC.
Uses `format-time-string` on FORMAT-STRING."
  (format-time-string format-string
                      (org-habit-stats--unix-from-absolute-time time)
                      zone))

(defun org-habit-stats-format-absolute-day-string (format-string &optional day zone)
  "Format time string given days DAY since end of 1 BC.
Uses `format-time-string` on FORMAT-STRING."
  (org-habit-stats-format-absolute-time-string format-string
                                               (org-habit-stats-days-to-time day)
                                               zone))

(defun org-habit-stats-graph-count-per-category (history category-func predicate-func format-func)
  "Return counts for each category of days.
For each date in HISTORY, get its category (e.g. which month,
which week, day of the week, etc.) using CATEGORY-FUNC, get
counts per category, sort categories with PREDICATE-FUNC, and
convert categories to readable names with FORMAT-FUNC. Returns a
pair of two lists, the first containing names of the categories,
the second containing the corresponding counts per category."
  (org-habit-stats-transpose-pair-list
   (mapcar (lambda (x) (cons (funcall format-func (car x)) (cdr x)))
           (sort (org-habit-stats-get-freq
                  (mapcar (lambda (x) (cons (funcall category-func (car x)) (cdr x)))
                          history)
                  (lambda (x) (car x))
                  (lambda (x) (cdr x)))
                 (lambda (x y) (funcall predicate-func (car x) (car y)))))))

(defun org-habit-stats-graph-completions-per-month (history _history-rev _habit-data)
  "Return a pair of lists (months . counts).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats-graph-count-per-category
   history
   (lambda (d) (let ((day (calendar-gregorian-from-absolute d)))
                     (list (car day) (caddr day)))) ;; converts absolute date to list (month year)
   (lambda (m1 m2) (cond ((< (nth 1 m1) (nth 1 m2)) t)
                         ((= (nth 1 m1) (nth 1 m2)) (if (< (nth 0 m1) (nth 0 m2)) t nil))
                         (t nil)))
   (lambda (m) (car (rassoc (nth 0 m) org-habit-stats-months-names-alist)))))

(defun org-habit-stats-graph-completions-per-week (history _history-rev _habit-data)
  "Return a pair of lists (weeks . counts).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats-graph-count-per-category
   history
   (lambda (d) (- d (mod d 7))) ;; converts absolute date to the sunday before or on; (month day year) format
   (lambda (d1 d2) (< d1 d2))
   (lambda (d) (let ((time (org-habit-stats-days-to-time d)))
                 (org-habit-stats-format-absolute-time-string org-habit-stats-graph-date-format
                                     time)))))

(defun org-habit-stats--pad-history (history n)
  "Pad the habit's HISTORY to length N.
Appends uncompleted days to before the first completion."
  (while (< (length history) n)
    (let ((prev-day (1- (if history (caar history) (org-today)))))
      (push (cons prev-day 0) history)))
  history)

(defun org-habit-stats-graph-completions-per-weekday (history _history-rev _habit-data)
  "Return a pair of lists (weeks . counts).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (org-habit-stats-graph-count-per-category
   (org-habit-stats--pad-history history 7)
   (lambda (d) (mod d 7))
   (lambda (d1 d2) (< d1 d2))
   (lambda (d) (car (rassoc (1+ d) org-habit-stats-days-names-alist)))))

(defun org-habit-stats-graph-daily-strength (history history-rev habit-data)
  "Return a pair of lists (days . habit strengths).

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((dayslst (mapcar (lambda (d) (org-habit-stats-format-absolute-time-string
                                   org-habit-stats-graph-date-format
                                   (org-habit-stats-days-to-time (car d))))
                        history)))
     (cons dayslst
           (reverse (org-habit-stats--exp-smoothing-list-full
                     history history-rev habit-data)))))

;;; Chart functions

(defclass org-habit-stats-chart-sequence ()
  ((data :initarg :data
         :initform nil)
   (name :initarg :name
         :initform "Data"))
  "Class used for all data in different charts.
Originally defined in charts.el as 'chart-sequence'. In some
earlier versions of Emacs the name of this class contains a
typo (chart-sequece) so we redefine it here under a new name.")

(defun org-habit-stats-graph-create-faces ()
  "Create faces for `org-habit-stats' graph.

It creates them out of the colors in
`org-habit-stats-graph-colors-list'."
  (let ((faces ())
        newface)
    (dolist (color org-habit-stats-graph-colors-list)
      (setq newface (make-face
                (intern (concat "org-habit-chart-" color))))
            (set-face-background newface color)
            (set-face-foreground newface "black")
            (push newface faces))
    (reverse faces)))

(defun org-habit-stats-chart-draw-line-custom-char (dir zone start end horizontal-char vertical-char)
  "Draw a line using line-drawing characters in direction DIR.
Use column or row ZONE between START and END. HORIZONTAL-CHAR
used for horizontal lines, VERTICAL-CHAR used for vertical
lines."
  (chart-display-label
   (make-string (- end start) (if (eq dir 'vertical) vertical-char horizontal-char))
   dir zone start end))

(defun org-habit-stats-chart-draw-line-data (dir zone start end)
  "Modification of `chart-draw-line' to use custom characters for bars.

See `chart-draw-line' for meaning of DIR, ZONE, START, and END."
  (org-habit-stats-chart-draw-line-custom-char dir zone start end
                                   org-habit-stats-graph-data-horizontal-char
                                   org-habit-stats-graph-data-vertical-char))

(defun org-habit-stats-chart-draw-line-axis (dir zone start end)
  "Modification of `chart-draw-line' to use custom characters for axes.

See `chart-draw-line' for meaning of DIR, ZONE, START, and END."
  (org-habit-stats-chart-draw-line-custom-char dir zone start end
                                   org-habit-stats-graph-axis-horizontal-char
                                   org-habit-stats-graph-axis-vertical-char))

(cl-defmethod org-habit-stats-chart-translate-xpos ((c chart) x)
  "Translate in chart C the coordinate X into a screen column."
  (let ((range (oref (oref c x-axis) bounds)))
    (+ (oref c y-margin)
       (round (* (float (- x (car range)))
                 (/ (float (oref c x-width))
                    (float (- (cdr range) (car range)))))))))

(cl-defmethod org-habit-stats-chart-draw-axis ((c chart))
  "Draw axis into the current buffer defined by chart C."
  (let ((ymarg (oref c y-margin))
        (xmarg (oref c x-margin))
        (ylen (oref c y-width))
        (xlen (oref c x-width)))
    (if (same-class-p (oref c y-axis) 'chart-axis-range)
        (org-habit-stats-chart-axis-draw (oref c y-axis) 'vertical ymarg
                                         (if (oref (oref c y-axis) loweredge) nil xlen)
                                         xmarg (+ xmarg ylen))
      (chart-axis-draw (oref c y-axis) 'vertical ymarg
                       (if (oref (oref c y-axis) loweredge) nil xlen)
                       xmarg (+ xmarg ylen)))
    (if (same-class-p (oref c x-axis) 'chart-axis-range)
        (org-habit-stats-chart-axis-draw (oref c x-axis) 'horizontal xmarg
                                         (if (oref (oref c x-axis) loweredge) nil ylen)
                                         ymarg (+ ymarg xlen))
      (chart-axis-draw (oref c x-axis) 'horizontal xmarg
                       (if (oref (oref c x-axis) loweredge) nil ylen)
                       ymarg (+ ymarg xlen)))))

(defun org-habit-stats-chart-draw-title (c &optional align-left)
  "Draw a title of chart C. By default, it is centered.
If ALIGN-LEFT non-nil, it is aligned left."
  (if align-left
      (chart-display-label (oref c title) 'horizontal
                           (- (oref c x-margin) 2)
                           (oref c y-margin) (+ (length (oref c title))
                                                (oref c y-margin))
                           (oref c title-face))
    (chart-display-label (oref c title) 'horizontal
                         (- (oref c x-margin) 3)
                         (oref c y-margin) (+ (oref c x-width)
                                              (oref c y-margin))
                         (oref c title-face))))

(cl-defmethod org-habit-stats-chart-axis-draw ((a chart-axis) &optional dir margin zone start end)
  "Draw some axis for A in direction DIR with MARGIN in boundary.
ZONE is a zone specification.
START and END represent the boundary."
  (org-habit-stats-chart-draw-line-axis dir (+ margin (if zone zone 0)) start end)
  (chart-display-label (oref a name) dir (if zone (+ zone margin 3)
                                           (if (eq dir 'horizontal)
                                               1 0))
                       start end (oref a name-face)))

(cl-defmethod org-habit-stats-chart-axis-draw ((a chart-axis-range) &optional dir margin zone _start _end)
  "Draw axis information based upon a range to be spread along the edge.
A is the chart to draw.  DIR is the direction.
MARGIN, ZONE, START, and END specify restrictions in chart space.
Corrected to use `org-habit-stats-chart-translate-xpos'."
  (cl-call-next-method)
  ;; We prefer about 5 spaces between each value
  (let* ((i (car (oref a bounds)))
         (e (cdr (oref a bounds)))
         (z (if zone zone 0))
         (s nil)
         (rng (- e i))
         ;; want to jump by units of 5 spaces or so
         (j (/ rng (/  (chart-size-in-dir (oref a chart) dir) 4)))
         p1)
    (if (= j 0) (setq j 1))
    (while (<= i e)
      (setq s
            (cond ((> i 999999)
                   (format "%dM" (/ i 1000000)))
                  ((> i 999)
                   (format "%dK" (/ i 1000)))
                  (t
                   (format "%d" i))))
      (if (eq dir 'vertical)
          (let ((x (+ (+ margin z) (if (oref a loweredge)
                                       (- (length s)) 1))))
            (if (< x 1) (setq x 1))
            (chart-goto-xy x (chart-translate-ypos (oref a chart) i)))
        (chart-goto-xy (org-habit-stats-chart-translate-xpos (oref a chart) i)
                       (+ margin z (if (oref a loweredge) -1 1))))
      (setq p1 (point))
      (insert s)
      (chart-zap-chars (length s))
      (put-text-property p1 (point) 'face (oref a labels-face))
      (setq i (+ i j)))))

(cl-defmethod org-habit-stats-chart-draw-data ((c chart-bar))
  "Display the data available in a bar chart C, maybe label with exact values.
This function is mostly the same as chart.el's `chart-draw-data`,
with the following modifications: 1. `chart-draw-line' is replaced
with org-habit-stats-chart-draw-line, which supports user
customized line drawing characters. 2. For horizontal charts, the
rightmost vertical line spans the entire bar height. 3. If
`org-habit-stats-chart-draw-values` is t, puts the exact value of
a bar next to it.''''"
  (cl-flet ((chart-draw-line (dir zone start end) (org-habit-stats-chart-draw-line-data
                                                   dir zone start end)))
    (let* ((data (oref c sequences))
           (dir (oref c direction))
           (odir (if (eq dir 'vertical) 'horizontal 'vertical))
           (faces
            (if (functionp chart-face-list)
                (funcall chart-face-list)
              chart-face-list)))
      (while data
        (if (stringp (car (oref (car data) data)))
            ;; skip string lists...
            nil
          ;; display number lists...
          (let ((i 0)
                (seq (oref (car data) data)))
            (while seq
              (let* ((rng (chart-translate-namezone c i))
                     (dp (if (eq dir 'vertical)
                             (chart-translate-ypos c (car seq))
                           (org-habit-stats-chart-translate-xpos c (car seq))))
                     (zp (if (eq dir 'vertical)
                             (chart-translate-ypos c 0)
                           (org-habit-stats-chart-translate-xpos c 0)))
                     (fc (if faces
                             (nth (% i (length faces)) faces)
                           'default))
                     (val (car seq))
                     (val-str
                      (cond ((integerp val) (format "%d" val))
                            ((floatp val) (format "%.1f" val))
                            (t val))))
                (if (< dp zp)
                    (progn
                      (chart-draw-line dir (car rng) dp zp)
                      (chart-draw-line dir (cdr rng) dp zp))
                  (chart-draw-line dir (car rng) zp (1+ dp))
                  (chart-draw-line dir (cdr rng) zp (1+ dp)))
                (if (= (car rng) (cdr rng)) nil
                  (if (eq dir 'vertical)
                      (chart-draw-line odir dp (1+ (car rng)) (cdr rng))
                    (chart-draw-line odir dp (+ 0 (car rng)) (+ 1 (cdr rng)))) ;; for vertical charts, draw the rightmost line over the horizontal lines
                  (chart-draw-line odir zp (car rng) (1+ (cdr rng))))
                (when org-habit-stats-graph-show-values-on-bars
                  (if (eq dir 'vertical)
                      (chart-display-label
                       val-str odir (1- dp) (car rng) (cdr rng))
                    (chart-display-label
                     val-str dir (/ (+ (car rng) (cdr rng)) 2) (1+ dp) (+ 1 dp (length val-str)))))
                (if (< dp zp)
                    (chart-deface-rectangle dir rng (cons dp zp) fc)
                  (chart-deface-rectangle dir rng (cons zp dp) fc)))
              ;; find the bounds, and chart it!
              ;; for now, only do one!
              (setq i (1+ i)
                    seq (cdr seq)))))
        (setq data (cdr data))))))

(defun org-habit-stats-chart-draw (c &optional buff)
  "Start drawing a chart object C in optional BUFF.
Begins at line LINE."
  (with-silent-modifications
    (save-excursion
      (if buff (set-buffer buff))
      ;; (goto-line line)
      (insert (make-string (window-height (selected-window)) ?\n))
      ;; (insert (make-string ((oref c 100) ?\n)))
      ;; Start by displaying the axis
      (org-habit-stats-chart-draw-axis c)
      ;; Display title
      (org-habit-stats-chart-draw-title c)
      ;; Display data
      (sit-for 0)
      (org-habit-stats-chart-draw-data c))))


(defun org-habit-stats--chart-trim-offset (seq max offset end)
  "Trim SEQ to be at most MAX elements.
If END is nil, trim OFFSET elements, keep the next MAX elements,
and trim the remaining elements.

Helper function for `org-habit-stats-chart-trim-offset.'"
  (if (> (+ offset max) (length seq))
      (setq org-habit-stats-graph-current-offset (- (length seq) max)))
  (let* ((newbeg (min offset (- (length seq) max)))
         (newend (min (+ offset max) (length seq))))
    (if (>= newbeg 0)
        (if end
            (seq-subseq seq (- newend) (if (> newbeg 0) (- newbeg)))
          (seq-subseq seq newbeg newend))
      seq)))

(cl-defmethod org-habit-stats-chart-trim-offset ((c chart) max offset end)
  "Trim all sequences in chart C to be MAX elements.
Does nothing if a sequence is less than MAX elements long. If END
is nil, trim OFFSET elements, keep the next MAX elements, and
trim the remaining elements. If END is t, trimming begins at the
end of the sequence instead."
  (let ((s (oref c sequences))
        (nx (if (equal (oref c direction) 'horizontal)
                (oref c y-axis) (oref c x-axis))))
    (dolist (x s)
      (oset x data (org-habit-stats--chart-trim-offset
                    (oref x data) max offset end)))
      (oset nx items (org-habit-stats--chart-trim-offset
                      (oref nx items) max offset end))))

(defun org-habit-stats-chart-bar-quickie-extended (dir title namelst nametitle numlst numtitle
                                                       &optional max sort-pred offset end width height
                                                       topmargin leftmargin titleface nameface labelface)
  "Modification of function `chart-bar-quickie'.
Supports custom graph dimensions, margins, and faces. Inserts
graph into current buffer, with width WIDTH, height HEIGHT,
vertical margin of TOPMARGIN from current line, horizontal margin
of LEFTMARGIN, face TITLEFACE for title, face NAMEFACE for axis
names, face LABELFACE for labels for values. Original Docstring:
Wash over the complex EIEIO stuff and create a nice bar chart.
Create it going in direction DIR [`horizontal' `vertical'] with
TITLE using a name sequence NAMELST labeled NAMETITLE with values
NUMLST labeled NUMTITLE. Optional arguments: Set the chart's max
element display to MAX, and sort lists with SORT-PRED if
desired.

See `org-habit-stats-chart-trim-offset' for the purpose of
OFFSET and END."
  (let ((nc (make-instance 'chart-bar
                           :title title
                           :title-face titleface
                           :x-margin topmargin
                           :y-margin leftmargin
                           :direction dir))
        (iv (eq dir 'vertical)))
    ;; chart.el sets the widths to the window dimensions after instantiation
    ;; manually set the widths to our values here
    (oset nc x-width width)
    (oset nc y-width height)
    (chart-add-sequence nc
                        (make-instance 'org-habit-stats-chart-sequence
                                       :data namelst
                                       :name nametitle)
                        (if iv 'x-axis 'y-axis))
    (chart-add-sequence nc
                        (make-instance 'org-habit-stats-chart-sequence
                                       :data numlst
                                       :name numtitle)
                        (if iv 'y-axis 'x-axis))
    (oset (oref nc x-axis) name-face nameface)
    (oset (oref nc x-axis) labels-face labelface)
    (oset (oref nc y-axis) name-face nameface)
    (oset (oref nc y-axis) labels-face labelface)
    (if sort-pred (chart-sort nc sort-pred))
    (if (integerp max) (org-habit-stats-chart-trim-offset nc max offset end))
    (org-habit-stats-chart-draw nc)))


;;; Draw graph
(defun org-habit-stats--draw-graph (dir title namelst nametitle numlst numtitle max-bars)
  "Draw the `org-habit-stats' graph.
DIR specifies the direction of the bars (horizontal or vertical).
TITLE is the title of the graph. NAMELST contains the list of
labels of the bars. NAMETITLE is the name of the axis of labels.
NUMLST contains the list of quantitative values for the bars.
NUMTITLE is the name of the quantitative axis. MAX-BARS is the
maximum number of bars displayed in the bar graph."
  (let ((namediff (- org-habit-stats-graph-min-num-bars (length namelst)))
        (numdiff (- org-habit-stats-graph-min-num-bars (length numlst))))
    (if (> namediff 0)
        (dotimes (_ namediff)
          (push "" namelst)))
    (if (> numdiff 0)
        (dotimes (_ numdiff)
          (push 0 numlst)))
    (let ((chart-face-list org-habit-stats-graph-face-list))
      (org-habit-stats-chart-bar-quickie-extended
       dir
       title
       namelst
       nametitle
       numlst
       numtitle
       max-bars
       nil
       org-habit-stats-graph-current-offset
       t
       org-habit-stats-graph-width
       org-habit-stats-graph-height
       (line-number-at-pos)
       org-habit-stats-graph-left-margin
       'org-habit-stats-graph-title
       'org-habit-stats-graph-name
       'org-habit-stats-graph-label))))

(defun org-habit-stats-draw-graph (history history-rev habit-data)
  "Draw the `org-habit-stats' bar graph.
See helper function `org-habit-stats--draw-graph'.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((graph-start (point))
         (func org-habit-stats-graph-current-func)
         (func-info (cdr (assoc func org-habit-stats-graph-functions-alist)))
         (graph-title (plist-get func-info :title))
         (x-name (plist-get func-info :x-label))
         (y-name (plist-get func-info :y-label))
         (dir (plist-get func-info :dir))
         (max-bars (plist-get func-info :max-bars))
         (graph-data-names (funcall func history history-rev habit-data))
         (graph-names (car graph-data-names))
         (graph-data (cdr graph-data-names)))
    (insert (make-string 2 ?\n))
    (org-habit-stats--draw-graph
     dir
     graph-title
     graph-names
     x-name
     graph-data
     y-name
     max-bars)
    (setq org-habit-stats-graph-bounds (cons graph-start (point-max)))))

;;; Graph commands
(defun org-habit-stats-switch-graph (graph-func)
  "Switch the graph to the graph with data produced by GRAPH-FUNC."
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
    (setq org-habit-stats-graph-current-func graph-func)
    (setq org-habit-stats-graph-current-offset 0)
    (org-habit-stats-refresh-graph-section)))

(defun org-habit-stats--scroll-graph (n)
  "Scroll graph to the left by N bars."
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
    (setq org-habit-stats-graph-current-offset
          (+ n org-habit-stats-graph-current-offset))
    (org-habit-stats-refresh-graph-section)))

(defun org-habit-stats-scroll-graph-left ()
  "Scroll graph to the left by 2 bars."
  (interactive)
  (org-habit-stats--scroll-graph 2))

(defun org-habit-stats-scroll-graph-right ()
  "Scroll graph to the right by 2 bars."
  (interactive)
  (if (> org-habit-stats-graph-current-offset 0)
      (org-habit-stats--scroll-graph -2)))

(defun org-habit-stats-scroll-graph-left-big ()
  "Scroll graph to the left by 7 bars."
  (interactive)
  (org-habit-stats--scroll-graph 7))

(defun org-habit-stats-scroll-graph-right-big ()
  "Scroll graph to the right by 7 bars."
  (interactive)
  (if (> org-habit-stats-graph-current-offset 0)
      (org-habit-stats--scroll-graph -7)))

;;; Insert sections
(defun org-habit-stats-days-to-time (days)
  "Convert number of days DAYS to number of seconds."
  (* days 86400))

(defun org-habit-stats-insert-habit-info (habit-data habit-name habit-description)
  "Insert information about the habit.

This includes the habit's name HABIT-NAME, description
HABIT-DESCRIPTION, repeat data, and the next day it is scheduled.
HABIT-DATA is the result of calling `org-habit-parse-todo'."
  (let ((habit-repeat-period (nth 1 habit-data))
        (habit-repeat-string (nth 5 habit-data))
        (habit-next-scheduled (nth 0 habit-data)))
    (insert (propertize habit-name 'face 'org-habit-stats-habit-name)
            "\n")
    (if habit-description
        (insert habit-description "\n"))
    ;; insert habit repeat data, next due date
    (insert (format "Repeats every %s%d days"
                    habit-repeat-string habit-repeat-period)
            "\n")
    (insert (org-habit-stats-format-absolute-time-string "Next Scheduled: %A, %B %d, %Y"
                                                         (org-habit-stats-days-to-time habit-next-scheduled))
            "\n")))

(defun org-habit-stats-format-one-stat (statname statdata)
  "Format stiatistic with name STATNAME and value STATDATA."
  (let* ((fdata (cond ((integerp statdata) (format "%d" statdata))
                      ((floatp statdata) (format "%.2f" statdata))
                      (t statdata)))
         (numspaces (- 39 (+ (length statname) (length fdata)))))
    (concat (propertize statname 'face 'org-habit-stats-stat-name)
            " "
            (propertize fdata 'face 'org-habit-stats-stat-value)
            (if (> numspaces 0)
                (make-string numspaces 32)))))

(defun org-habit-stats-insert-stats (history history-rev habit-data)
  "Insert all statistics into the buffer.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((i 0)
         (stats-start (point))
         (statresults (org-habit-stats-calculate-stats history history-rev habit-data)))
      (dolist (x statresults)
        (insert (org-habit-stats-format-one-stat (car x)
                                                 (cdr x)))
        (setq i (1+ i))
        (when (and (> i 0) (= (mod i 2) 0))
          (insert "\n")))
      (insert "\n")
      (setq org-habit-stats-stat-bounds (cons stats-start (point)))))

(defun org-habit-stats-insert-messages (history history-rev habit-data)
   "Insert all messages into the buffer.

See the docstring of `org-habit-stats-streak' for a description
of HISTORY, HISTORY-REV, HABIT-DATA."
  (let* ((messages-start (point))
         (messageslst (org-habit-stats-get-messages history history-rev habit-data)))
    (when messageslst
      (dolist (m messageslst)
        (insert m "\n"))
      (org-habit-stats--insert-divider)
      (setq org-habit-stats-message-bounds (cons messages-start (point))))))

(defun org-habit-stats-insert-calendar ()
  "Insert calendar displaying all completions into the buffer.

See the docstring of `org-habit-stats-streak' for a description
of HABIT-DATA."
  (let ((cal-start (point))
        (cal-start-line (line-number-at-pos))
        (cal-offset-for-overlay (1- (point))))
    (insert (org-habit-stats-get-calendar-contents))
    (org-habit-stats-apply-overlays (org-habit-stats-get-calendar-overlays)
                                    cal-offset-for-overlay
                                    (current-buffer))
    (let ((calendar-height (- (line-number-at-pos) cal-start-line)))
      (when (< calendar-height 8)
        (insert (make-string (- 7 calendar-height) ?\n)))
    (insert (make-string 1 ?\n))

    (when org-habit-stats-graph-bounds
      (let ((cal-bound-diff (- (point) (cdr org-habit-stats-calendar-bounds)))
            (graph-start (car org-habit-stats-graph-bounds))
            (graph-end (cdr org-habit-stats-graph-bounds)))
        (setq org-habit-stats-graph-bounds (cons (+ graph-start cal-bound-diff)
                                                 (+ graph-end cal-bound-diff)))))
    (setq org-habit-stats-calendar-bounds (cons cal-start (point))))))

;;; Refresh sections
(defun org-habit-stats-refresh-buffer ()
  "Refresh `org-habit-stats' buffer."
  (interactive)
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
    (erase-buffer)
    (org-habit-stats--insert-habit-buffer-contents)
    (set-buffer-modified-p nil)))

(defun org-habit-stats-refresh-graph-section ()
  "Refresh the graph in the `org-habit-stats' buffer."
  (let* ((graph-bounds org-habit-stats-graph-bounds)
         (graph-start (car graph-bounds))
         (graph-end (cdr graph-bounds))
         (history (org-habit-stats-get-repeat-history-old-to-new org-habit-stats-current-habit-data))
         (history-rev (reverse history)))
    (save-excursion
      (goto-char graph-start)
      (delete-region graph-start graph-end)
      (org-habit-stats-draw-graph history history-rev org-habit-stats-current-habit-data))
    (set-buffer-modified-p nil)))

(defun org-habit-stats-refresh-calendar-section ()
  "Refresh the calendar in the `org-habit-stats' buffer."
  (let* ((cal-bounds org-habit-stats-calendar-bounds)
         (cal-start (car cal-bounds))
         (cal-end (cdr cal-bounds)))
    (save-excursion
      (goto-char cal-start)
      (delete-region cal-start cal-end)
      (org-habit-stats-insert-calendar))
    (set-buffer-modified-p nil)))

;;; Create org-habit-stats buffer
(defun org-habit-stats--insert-divider ()
  "Insert a divider.
The divider consists of 80 `org-agenda-block-separator'."
  (insert (make-string 80
           ;; (max 80 (window-width))
           org-agenda-block-separator))
  (insert (make-string 1 ?\n)))

(defun org-habit-stats-insert-section-header (name)
  "Insert a section header with text NAME."
  (insert (propertize name 'face 'org-habit-stats-section-name)
          "\n"))

(defun org-habit-stats--insert-habit-buffer-contents ()
  "Insert all buffer contents for the `org-habit-stats' buffer."
  (let ((history org-habit-stats-current-history)
        (history-rev org-habit-stats-current-history-rev)
        (habit-data org-habit-stats-current-habit-data)
        (habit-name org-habit-stats-current-habit-name)
        (habit-description org-habit-stats-current-habit-description))
    (org-habit-stats-insert-habit-info habit-data habit-name habit-description)
    (org-habit-stats--insert-divider)
    (if (and org-habit-stats-show-blank-when-new-habit
             (= 0 (length (nth 4 habit-data))))
        (insert org-habit-stats-new-habit-message)
      (org-habit-stats-insert-messages history history-rev habit-data)
      (org-habit-stats-insert-section-header "Statistics")
      (org-habit-stats-insert-stats history history-rev habit-data)
      (org-habit-stats--insert-divider)
      (org-habit-stats-insert-section-header "History")
      (org-habit-stats-make-calendar-buffer habit-data)
      (org-habit-stats-insert-calendar)
      (org-habit-stats--insert-divider)
      (org-habit-stats-insert-section-header "Graph")
      (org-habit-stats-draw-graph history history-rev habit-data))))

(defun org-habit-stats-create-habit-buffer (habit-data habit-name habit-description habit-source)
  "Create buffer displaying statistics, a calendar, and a bar graph.

HABIT-DATA contains results from `org-habit-stats-parse-todo`.
The name of the habit HABIT-NAME and description
HABIT-DESCRIPTION are displayed at the top of the buffer. The
HABIT-SOURCE is either 'agenda or 'file, indicating what kind of
buffer the habit was located in. This is used by commands that
navigate between habits."
  (let* ((history (org-habit-stats-get-repeat-history-old-to-new habit-data))
         (history-rev (reverse history))
         (buff-name (concat "*Org-Habit-Stats "
                            (truncate-string-to-width habit-name 25 nil nil t)
                            "*"))
         (cal-buff-name (concat "*Org-Habit-Stats Calendar "
                            (truncate-string-to-width habit-name 25 nil nil t)
                            "*")))
    (setq org-habit-stats-current-buffer buff-name)
    (setq org-habit-stats-current-calendar-buffer cal-buff-name)
    (switch-to-buffer (get-buffer-create org-habit-stats-current-buffer))
    (erase-buffer)
    (org-habit-stats-mode)
    (setq org-habit-stats-habit-source habit-source)
    (setq org-habit-stats-current-history history)
    (setq org-habit-stats-current-history-rev history-rev)
    (setq org-habit-stats-current-habit-data habit-data)
    (setq org-habit-stats-current-habit-name habit-name)
    (setq org-habit-stats-current-habit-description habit-description)
    (org-habit-stats--insert-habit-buffer-contents)
    (set-buffer-modified-p nil)))

;;; Set stats as properties
(defun org-habit-stats-number-to-string-maybe (x)
  "Format X as a string whether it is an integer or float."
  (cond ((integerp x) (format "%d" x))
        ((floatp x) (format "%.5f" x))
        (t x)))

(defun org-habit-stats-format-property-name (s)
  "Replace spaces with underscores in string S."
  (replace-regexp-in-string "[[:space:]]" "_" s))

;;;###autoload
(defun org-habit-stats-update-properties ()
  "Set stats of habit at point as org properties."
  (interactive)
  (when (org-is-habit-p (point))
    (let* ((habit-data (org-habit-stats-parse-todo (point)))
           (history (org-habit-stats-get-repeat-history-old-to-new habit-data))
           (history-rev (reverse history))
           (statresults (org-habit-stats-calculate-stats history history-rev habit-data)))
      (dolist (x statresults)
        (org-set-property (org-habit-stats-format-property-name (car x))
                          (org-habit-stats-number-to-string-maybe (cdr x)))))))

;;; org-habit-stats commands
(defun org-habit-stats-parse-todo (&optional pom)
  "Get habit data by calling `org-habit-parse-todo` on POM.

Locally sets 'org-habit-preceding-days` to a big value to avoid
habit data getting truncated."
  (let ((org-habit-preceding-days 40000))
    (org-habit-parse-todo pom)))

;;;###autoload
(defun org-habit-stats-view-habit-at-point ()
  "Open an org-habit-stats buffer for the habit at point in a file."
  (interactive)
  (let ((habit-name (org-element-property :raw-value
                                          (save-excursion
                                            (when (not (eq (car (org-element-at-point)) 'headline))
                                              (outline-previous-heading))
                                            (org-element-at-point))))
        (habit-data (org-habit-stats-parse-todo (point)))
        (habit-description (org-entry-get (point) "DESCRIPTION")))
    (org-habit-stats-create-habit-buffer habit-data habit-name habit-description 'file)))

(defun org-habit-stats-view-next-habit-in-buffer ()
  "View next habit in current file (internal)."
  (interactive)
  (let ((orig-pos (point))
        habit-pos)
    (while (and (not (eobp))
                (not (setq habit-pos (org-is-habit-p (point)))))
      (outline-next-heading))
    (when (not habit-pos)
      (goto-char (point-min))
      (outline-next-heading)
      (while (and (< (point) orig-pos)
                  (not (setq habit-pos (org-is-habit-p (point)))))
        (outline-next-heading)))
    (if habit-pos
        (org-habit-stats-view-habit-at-point)
      (user-error "No habits found in buffer"))))

(defun org-habit-stats-view-previous-habit-in-buffer ()
  "View previous habit in current file (internal)."
  (interactive)
  (let ((orig-pos (point))
        habit-pos)
    (while (and (not (bobp))
                (not (setq habit-pos (org-is-habit-p (point)))))
      (outline-previous-heading))
    (when (not habit-pos)
      (goto-char (point-max))
      (outline-previous-heading)
      (while (and (> (point) orig-pos)
                  (not (setq habit-pos (org-is-habit-p (point)))))
        (outline-previous-heading)))
    (if habit-pos
        (org-habit-stats-view-habit-at-point)
      (user-error "No habits found in buffer"))))


(defun org-habit-stats--agenda-item-is-habit-p ()
  "Check if current agenda item is a habit."
  ;; (save-window-excursion
  ;;   (org-agenda-switch-to)
  ;;   (org-is-habit-p (point)))
  (get-text-property (point) 'org-habit-p))

;;;###autoload
(defun org-habit-stats-view-habit-at-point-agenda ()
  "Open an org-habit-stats buffer for the habit at point in agenda buffer."
  (interactive)
  (if (not (derived-mode-p 'org-agenda-mode))
      (user-error "Not in agenda buffer")
    (let (is-habit habit-name habit-data habit-description)
      (save-window-excursion
        (org-agenda-switch-to)
        (setq is-habit (org-is-habit-p (point)))
        (when is-habit
          (when (not (eq (car (org-element-at-point)) 'headline))
              (outline-previous-heading))
          (setq habit-name (org-element-property :raw-value (org-element-at-point))
                habit-data (org-habit-stats-parse-todo (point))
                habit-description (org-entry-get (point) "DESCRIPTION"))))
      (when is-habit
        (org-habit-stats-create-habit-buffer habit-data habit-name habit-description 'agenda)))))

(defun org-habit-stats-line-number-at-pos ()
  "Get line number at current point."
  (string-to-number (format-mode-line "%l")))

(defun org-habit-stats-view-next-habit-in-agenda ()
  "View next habit in the current org agenda buffer (internal)."
  (interactive)
  (if (not (derived-mode-p 'org-agenda-mode))
      (user-error "Not in agenda buffer")
  (let ((orig-pos (point))
        habit-pos)
    (while (and (not (eobp))
                (not (setq habit-pos (org-habit-stats--agenda-item-is-habit-p))))
      (forward-line))
    (when (not habit-pos)
      (goto-char (point-min))
      (while (and (< (point) orig-pos)
                  (not (setq habit-pos (org-habit-stats--agenda-item-is-habit-p))))
        (forward-line)))
    (if habit-pos
        (org-habit-stats-view-habit-at-point-agenda)
      (user-error "No habits found in agenda buffer")))))

(defun org-habit-stats-view-previous-habit-in-agenda ()
  "View previous habit in the current org agenda buffer (internal)."
  (interactive)
  (if (not (derived-mode-p 'org-agenda-mode))
      (user-error "Not in agenda buffer")
    (let ((orig-pos (point))
          habit-pos)
      (while (and (not (bobp))
                  (not (setq habit-pos (org-habit-stats--agenda-item-is-habit-p))))
        (forward-line -1))
      (when (not habit-pos)
        (goto-char (point-max))
        (while (and (> (point) orig-pos)
                    (not (setq habit-pos (org-habit-stats--agenda-item-is-habit-p))))
          (forward-line -1)))
      (if habit-pos
          (org-habit-stats-view-habit-at-point-agenda)
        (user-error "No habits found in agenda buffer")))))

;;;###autoload
(defun org-habit-stats-view-next-habit ()
  "From org-habit-stats buffer, view next habit in file or agenda."
  (interactive)
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
    (if (eq org-habit-stats-habit-source 'agenda)
        (progn
          (org-habit-stats-exit)
          (org-agenda-next-item 1)
          (org-habit-stats-view-next-habit-in-agenda))
      (org-habit-stats-exit)
      (outline-next-heading)
      (org-habit-stats-view-next-habit-in-buffer))))

;;;###autoload
(defun org-habit-stats-view-previous-habit ()
  "From org-habit-stats buffer, view previous habit in file or agenda."
  (interactive)
  (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
    (if (eq org-habit-stats-habit-source 'agenda)
        (progn
          (org-habit-stats-exit)
          (org-agenda-previous-item 1)
          (org-habit-stats-view-previous-habit-in-agenda))
      (org-habit-stats-exit)
      (outline-previous-heading)
      (org-habit-stats-view-previous-habit-in-buffer))))


;;;###autoload
(defun org-habit-stats-exit ()
  "Kill org-habit-stats buffer and the internal calendar buffer."
  (interactive)
   (if (not (derived-mode-p 'org-habit-stats-mode))
      (user-error "Not in an org-habit-stats-mode buffer")
  (when (bufferp org-habit-stats-calendar-buffer)
      (kill-buffer org-habit-stats-calendar-buffer))
  (kill-buffer org-habit-stats-current-buffer)))

;;; Major mode
(defun org-habit-stats-format-graph-func-name (s)
  "Replace spaces with hyphens in string S, and lowercase the result."
  (downcase (replace-regexp-in-string "[[:space:]]" "-" s)))

(defvar org-habit-stats-mode-map
  (let ((map (make-keymap)))
    (suppress-keymap map)
    (define-key map "q"   'org-habit-stats-exit)
    (define-key map "<"   'org-habit-stats-calendar-scroll-left)
    (define-key map ">"   'org-habit-stats-calendar-scroll-right)
    (define-key map "C-v"   'org-habit-stats-calendar-scroll-left-three-months)
    (define-key map "M-v"   'org-habit-stats-calendar-scroll-right-three-months)
    (define-key map "C-x ]"   'org-habit-stats-calendar-forward-year)
    (define-key map "C-x ["   'org-habit-stats-calendar-backward-year)
    (define-key map "[" 'org-habit-stats-scroll-graph-left)
    (define-key map "]" 'org-habit-stats-scroll-graph-right)
    (define-key map "{" 'org-habit-stats-scroll-graph-left-big)
    (define-key map "}" 'org-habit-stats-scroll-graph-right-big)
    (define-key map "." 'org-habit-stats-view-next-habit)
    (define-key map "," 'org-habit-stats-view-previous-habit)
    (dolist (x org-habit-stats-graph-functions-alist)
      (let* ((graph-func (car x))
             (graph-key (plist-get (cdr x) :key))
             (graph-switch-func-name (concat (symbol-name graph-func) "-switch"))
             (graph-switch-func (intern graph-switch-func-name)))
        (fset graph-switch-func (lambda () (interactive) (org-habit-stats-switch-graph graph-func)))
        (define-key map (kbd (concat org-habit-stats-graph-command-prefix graph-key))
          graph-switch-func)))
    map)
  "Keymap for `org-habit-stats-mode'.")

(define-derived-mode org-habit-stats-mode special-mode "Org-Habit-Stats"
  "A major mode for the org-habit-stats window.
\\<org-habit-stats-mode-map>\\{org-habit-stats-mode-map}"
  (setq buffer-read-only nil
        buffer-undo-list t
        indent-tabs-mode nil)
  (setq org-habit-stats-graph-current-offset 0)
  (if org-habit-stats-graph-default-func
        (setq org-habit-stats-graph-current-func org-habit-stats-graph-default-func)
    (setq org-habit-stats-graph-current-func (caar org-habit-stats-graph-functions-alist)))
  (setq org-habit-stats-graph-face-list (org-habit-stats-graph-create-faces)))


(provide 'org-habit-stats)
;;; org-habit-stats.el ends here
