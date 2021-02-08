;;; metrics-tracker.el --- Generate reports of personal metrics from diary entries  -*- lexical-binding: t -*-

;; Copyright (C) 2019-2020 Ian Martins

;; Author: Ian Martins <ianxm@jhu.edu>
;; URL: https://github.com/ianxm/emacs-tracker
;; Package-Version: 20210207.1100
;; Package-Commit: e0ddd7a17da899fa85b1d49f1260042f8caa0612
;; Version: 0.3.9
;; Keywords: calendar
;; Package-Requires: ((emacs "24.4") (seq "2.3"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; metrics-tracker.el generates tables and graphs from the personal metrics
;; data found in your diary entries.

;;; Code:

(require 'seq)
(require 'timezone)
(require 'calendar)

;; custom variables

(defgroup metrics-tracker nil
  "Options for customizing Metrics Tracker reports."
  :group 'diary
  :tag "Metrics Tracker")

(defcustom metrics-tracker-graph-size '(700 . 500)
  "Specifies the size as (width . height) to be used for graph images."
  :type '(cons integer integer)
  :group 'metrics-tracker)

(defcustom metrics-tracker-metric-name-whitelist nil
  "List of metric names to include in reports.
If this is specified, only the metrics in this list are
considered.  All others are filtered out.  If this is set, then
`metrics-tracker-metric-name-blacklist' has no effect.

For example: '(\"pushups\" \"situps\")"
  :type '(list :inline t string)
  :group 'metrics-tracker)

(defcustom metrics-tracker-metric-name-blacklist nil
  "List of metric names to exclude from reports.
This is ignored if `metrics-tracker-metric-name-whitelist' is set.

For example: '(\"pushups\" \"situps\")"
  :type '(list :inline t string)
  :group 'metrics-tracker)

(defcustom metrics-tracker-graph-colors '(("#1f77b4" "#ff7f0e" "#2ca02c" "#d62728" "#9467bd" "#8c564b" "#e377c2" "#7f7f7f" "#bcbd22" "#17becf")
                                          ("#4d871a" "#81871a" "#87581a" "#1a5a87" "#761a87" "#871a1a" "#833a3a" "#403a83" "#3a7f83" "#83743a"))
  "Colors to use for each series in graphs.  The first list is used when in light mode; the second list for dark mode."
  :type '(list (list :inline t string)  ; light mode colors
               (list :inline t string)) ; dark mode colors
  :group 'metrics-tracker)

(defcustom metrics-tracker-dark-mode nil
  "If \"t\", generate graph images with dark backgrounds."
  :type 'boolean
  :group 'metrics-tracker)

(defcustom metrics-tracker-named-reports nil
  "Pre-configured reports that can be re-rendered by name with current data.

All metrics tracker report types are supported.  Add to this list
by generating the report to save and then calling
`metrics-tracker-save-last-report', or by editing this list in
`customize'.

Display a report from this list using `metrics-tracker-show-named-report'."
  :type '(repeat
          (choice (list :tag "Table Report"
                        (string :tag "Report Name")
                        (const :tag "Table Report" table)
                        (repeat :tag "Metric Names" string)
                        (choice :tag "Date Grouping  " (const day) (const week) (const month) (const year) (const full))
                        (choice :tag "Value Transform" (const total) (const min) (const max) (const avg) (const count) (const percent)
                                (const :tag "per day" per-day) (const :tag "per week" per-week) (const :tag "per month" per-month) (const :tag "per year" per-year)
                                (const :tag "difference total" diff-total) (const :tag "difference min" diff-min) (const :tag "difference max" diff-max)
                                (const :tag "difference average" diff-avg) (const :tag "difference count" diff-count) (const :tag "difference percent" diff-percent)
                                (const :tag "difference per day" diff-per-day) (const :tag "difference per week" diff-per-week)
                                (const :tag "difference per month" diff-per-month) (const :tag "difference per year" diff-per-year)
                                (const :tag "accumulate" accum) (const :tag "accumulate count" accum-count))
                        (choice :tag "Start Date     " (const :tag "first occurrence" nil) (string :tag "date string"))
                        (choice :tag "End Date       " (const :tag "last occurrence" nil) (string :tag "date string")))
                  (list :tag "Calendar Report"
                        (string :tag "Report Name")
                        (const :tag "Calendar Report" cal)
                        (string :tag "Metric Names")
                        (choice :tag "Value Transform" (const total) (const count))
                        (choice :tag "Start Date     " (const :tag "first occurrence" nil) (string :tag "date string"))
                        (choice :tag "End Date       " (const :tag "last occurrence" nil) (string :tag "date string")))
                  (list :tag "Graph Report"
                        (string :tag "Report Name")
                        (const :tag "Graph Report" graph)
                        (repeat :tag "Metric Names" string)
                        (choice :tag "Date Grouping  " (const day) (const week) (const month) (const year) (const full))
                        (choice :tag "Value Transform" (const total) (const min) (const max) (const avg) (const count) (const percent)
                                (const :tag "per day" per-day) (const :tag "per week" per-week) (const :tag "per month" per-month) (const :tag "per year" per-year)
                                (const :tag "difference total" diff-total) (const :tag "difference min" diff-min) (const :tag "difference max" diff-max)
                                (const :tag "difference average" diff-avg) (const :tag "difference count" diff-count) (const :tag "difference percent" diff-percent)
                                (const :tag "difference per day" diff-per-day) (const :tag "difference per week" diff-per-week)
                                (const :tag "difference per month" diff-per-month) (const :tag "difference per year" diff-per-year)
                                (const :tag "accumulate" accum) (const :tag "accumulate count" accum-count))
                        (choice :tag "Start Date     " (const :tag "first occurrence" nil) (string :tag "date string"))
                        (choice :tag "End Date       " (const :tag "last occurrence" nil) (string :tag "date string"))
                        (choice :tag "Graph Type     " (const line) (const bar) (const stacked) (const scatter))
                        (choice :tag "Graph Output   " (const ascii) (const svg) (const png)))))

  :group 'metrics-tracker)

(defcustom metrics-tracker-derived-metrics nil
  "List of metrics which are computed based on other metrics.

Metrics can be derived from other derived metrics, but circular
references are not allowed.

If not specified, `Expression' defaults to summing all base
metric values for each day.  If specified, it takes an arbitrary
math expression evaluated by calc which uses $N for the Nth base
metric."
  :type '(repeat
          (list
           (string :tag "metric name")        ; the name of the derived metric
           (repeat :tag "Base Metric" string) ; the names of the metrics from which it is derived
           (choice :tag "Expression"          ; default is "$1 + $2 + ..."
                   (const :tag "sum values" nil)
                   (string :tag "defined"))))
  :group 'metrics-tracker)

;; dynamically scoped constants and variables and associated helper functions

(defvar metrics-tracker-metric-index nil
  "This is the list of metrics read from the diary file.
It is a list containing: (name count first last) for each metric.
It is cleared when the metrics-tracker output buffer is killed, forcing
the diary file to be re-read if the data is needed again.")

(defvar metrics-tracker-tempfiles nil
  "This is the list of tempfiles (graph images) that have been created during the current session.")

(defvar metrics-tracker-metric-names (make-vector 5 0)
  "This is an obarray of all existing metric names.")

(defvar metrics-tracker-last-report-config nil
  "This holds the configuration of the last report that was rendered.")

(defconst metrics-tracker-output-buffer-name "*Metrics Tracker Output*"
  "The name of the output buffer.")

(define-error 'metrics-tracker-invalid-value "The given value cannot be parsed")

(defconst metrics-tracker-grouping-and-transform-options
  '(day (total count accum accum-count)
        week (total min max avg count percent per-day
                    diff-total diff-min diff-max diff-avg diff-count diff-percent diff-per-day)
        month (total min max avg count percent per-day per-week
                     diff-total diff-min diff-max diff-avg diff-count diff-percent diff-per-day diff-per-week)
        year (total min max avg count percent per-day per-week per-month
                    diff-total diff-min diff-max diff-avg diff-count diff-percent diff-per-day diff-per-week diff-per-month)
        full (total min max avg count percent per-day per-week per-month per-year
                    diff-total diff-min diff-max diff-avg diff-count diff-percent diff-per-day diff-per-week diff-per-month diff-per-year))
  "This is a plist of date-grouping options mapped to value-transform options.")

(defun metrics-tracker--date-grouping-options ()
  "Pull the list of date-grouping options out of `metrics-tracker-grouping-and-transform-options'."
  (seq-filter (lambda (x) (symbolp x)) metrics-tracker-grouping-and-transform-options))

(defun metrics-tracker--value-transform-options (date-grouping)
  "Return the valid value-transforms for the given DATE-GROUPING."
  (plist-get metrics-tracker-grouping-and-transform-options date-grouping))

(defconst metrics-tracker-graph-options '(line bar stacked scatter)
  "The types of supported graphs.")

(defun metrics-tracker--graph-options (date-transform)
  "Return the valid graph-options for the given DATE-TRANSFORM.
We have to filter graph-options based on DATE-TRANSFORM because
line and scatter graphs don't work if there's just one data
point."
  (if (eq date-transform 'full)
      (seq-difference metrics-tracker-graph-options '(line scatter))
    metrics-tracker-graph-options))

(defconst metrics-tracker-graph-output-options '(ascii svg png)
  "The graph output options.")

(defun metrics-tracker--presorted-options (options)
  "Prevent Emacs from sorting OPTIONS.
Some versions of Emacs sort the given options instead of just
presenting them.

Solution taken from:
https://emacs.stackexchange.com/questions/41801/how-to-stop-completing-read-ivy-completing-read-from-sorting"
  (lambda (string pred action)
    (if (eq action 'metadata)
        '(metadata (display-sort-function . identity)
                   (cycle-sort-function . identity))
      (complete-with-action
       action options string pred))))

(defmacro metrics-tracker--min-date (d1 d2)
  "Return the earlier of the given dates D1 and D2."
  `(if (time-less-p ,d1 ,d2) ,d1 ,d2))

(defmacro metrics-tracker--max-date (d1 d2)
  "Return the later of the given dates D1 and D2."
  `(if (time-less-p ,d1 ,d2) ,d2 ,d1))

(defun metrics-tracker--string-to-time (&optional date-str)
  "Return a time value for DATE-STR if given, else for today.
Returned a time value with hours, minutes, seconds zeroed out."
  (apply #'encode-time (mapcar #'(lambda (x) (or x 0)) ; convert nil to 0
                               (seq-take (parse-time-string (or date-str (format-time-string "%F"))) 6))))

(defmacro metrics-tracker--num-sort (col)
  "Sort string numbers in column COL of a tabulated list."
  `(lambda (x y) (< (string-to-number (elt (nth 1 x) ,col))
                      (string-to-number (elt (nth 1 y) ,col)))))

(defmacro metrics-tracker--sort-dates (dates)
  "Sort a list of DATES."
  `(sort ,dates (lambda (a b) (time-less-p a b))))

(defconst metrics-tracker--entry-format
  (rx line-start
      (group (or
              (seq (= 4 digit) ?- (= 2 digit) ?- (= 2 digit))                  ; YYYY-MM-DD
              (seq (= 2 digit) ?/ (repeat 2 3 alpha) ?/ (= 4 digit))           ; YYYY/MMM/DD
              (seq (>= 2 alpha) space (repeat 1 2 digit) ?, space (= 4 digit)) ; MMM DD, YYYY
              (seq (repeat 1 2 digit) space (>= 2 alpha) space (= 4 digit))))  ; DD MMM YYYY
      (opt (1+ space) (repeat 1 2 digit) ?: (= 2 digit)                        ; HH:MM
           (opt (0+ space) (in ?A ?a ?P ?p) (in ?M ?m)))                       ; (am|pm)
      (1+ space) (group (1+ ascii))                                            ; metric name
      (1+ space) (group (1+ (in digit ?. ?: ?-)))                              ; (1.5|1:30)
      (0+ space) line-end))

(defconst metrics-tracker--time-format
  (rx line-start
      (opt (group (repeat 1 2 digit)) ?:)        ; hh:
      (group (= 2 digit)) ?: (group (= 2 digit)) ; mm:ss
      (opt ?. (1+ digit))                        ; .ms
      line-end))

(defun metrics-tracker--process-diary (filter action &optional start-date end-date)
  "Parse the diary file.
For each valid metrics entry found, parse the fields and then
apply the given FILTER and ACTION.

Optionally, filter out metrics before START-DATE or after END-DATE.

Valid metrics entries look like \"DATE TIME METRICNAME VALUE\" where
- DATE looks like \"2020-01-01\" or \"Jan 1, 2020\" or \"1 Jan 2020\"
- TIME (optional, and we ignore it) looks like \"10:30\" or \"10:30a\" or \"10:30 am\"
- METRICNAME is any string, whitespace included
- VALUE is a decimal number like \"1\" or \"1.2\" or a duration value like \"10:01\" or \"1:20:32.21\""

  (let (metric-name metric-date metric-value)
    (with-temp-buffer
      (insert-file-contents diary-file)
      (dolist (line (split-string (buffer-string) "\n" t))
        (condition-case nil
            (when (string-match metrics-tracker--entry-format line)
              (setq metric-date (apply #'encode-time (mapcar #'(lambda (x) (or x 0)) ; convert nil to 0
                                                             (seq-take (parse-time-string (match-string 1 line)) 6)))
                    metric-name (intern (match-string 2 line) metrics-tracker-metric-names)
                    metric-value (metrics-tracker--try-read-value (match-string 3 line)))
              (when (and (funcall filter metric-date metric-name)
                         (or (null start-date)
                             (time-less-p start-date metric-date)
                             (equal start-date metric-date))
                         (or (null end-date)
                             (time-less-p metric-date end-date)
                             (equal metric-date end-date)))
                (funcall action metric-date metric-name metric-value)))
          (metrics-tracker-invalid-value nil) ; the regexes aren't strict enough to filter this out, but it should be skipped
          (error (format "Error parsing line: %s" line)))))))

(defun metrics-tracker--try-read-value (string-value)
  "Read a value from STRING-VALUE, or signal that no value can be read.

Any string that matches the `valid-formats' regex can end up
here, but not all can be parsed (for example \"10::21\").  In
those cases we raise the `metric-tracker-invalid-value' signal.

STRING-VALUE [string] is expected to contain a metric value.  It
may be formatted as a number (10.21) or a duration (10:21). Hours
are optional for duration values."
  (cond ((string-match metrics-tracker--time-format string-value) ; duration as hh:mm:ss.ms
         (let ((h (if (match-string 1 string-value) (string-to-number (match-string 1 string-value)) 0))
               (m (string-to-number (match-string 2 string-value)))
               (s (string-to-number (match-string 3 string-value))))
           (+ h (/ m 60.0) (/ s 3600.0)))) ; return duration in hours
        ((string-match "^[[:digit:]\.]+$" string-value) ; number like 10.21
         (string-to-number string-value))
        (t ; skip
         (signal 'metrics-tracker-invalid-value string-value))))

(defun metrics-tracker-clear-data ()
  "Clear cached data and delete tempfiles.
Clear the data cached in `metrics-tracker-metric-index' in order to force
it to be re-read from the diary file the next time it is
needed.  Also delete the tempfiles (graph images) listed in
`metrics-tracker-tempfiles'."
  (when (string= (buffer-name (current-buffer)) metrics-tracker-output-buffer-name)
    (setq metrics-tracker-metric-index nil)
    (metrics-tracker-remove-tempfiles)
    (remove-hook 'kill-buffer-hook #'metrics-tracker-clear-data)))

(defun metrics-tracker-remove-tempfiles ()
  "Remove any tempfiles (graph images) that were created during the current session."
  (dolist (elt metrics-tracker-tempfiles)
    (if (file-exists-p elt)
        (delete-file elt)))
  (setq metrics-tracker-tempfiles nil)
  (remove-hook 'kill-emacs-hook #'metrics-tracker-remove-tempfiles))

(defun metrics-tracker--load-index ()
  "Make sure the metric index has been populated.
This reads the diary file and populated in
`metrics-tracker-metric-list' if it is nil.

`metrics-tracker-metric-list' is a list of

  \(metric-name count first last daysago)

sorted by 'last'.  For derived metrics, each field applies to
each base metric.  For example, `count' is the count of
occurrences of all base metrics, and `daysago' is the number of
days since the last occurrence of any base metric."
  (unless metrics-tracker-metric-index
    (let* ((metrics (make-hash-table :test 'equal)) ; hash of metric-name -> (metric-name count first last daysago)
           existing-metric
           (today (metrics-tracker--string-to-time))
           (list-filter-fcn (cond ((not (null metrics-tracker-metric-name-whitelist))
                                   (lambda (_date name) ; filter out non-whitelisted metrics
                                     (seq-contains metrics-tracker-metric-name-whitelist (symbol-name name))))
                                  ((not (null metrics-tracker-metric-name-blacklist))
                                   (lambda (_date name) ; filter out blacklisted metrics
                                     (not (seq-contains metrics-tracker-metric-name-blacklist (symbol-name name)))))
                                  (t                    ; keep all metrics
                                   (lambda (_date _name) t))))
           (list-action-fcn (lambda (date name _value)
                              (setq existing-metric (gethash name metrics))
                              (if (not existing-metric)
                                  (puthash name
                                           (list name 1 date date (- (time-to-days today) (time-to-days date)))
                                           metrics)
                                (setcar (nthcdr 1 existing-metric) (1+ (nth 1 existing-metric)))
                                (setcar (nthcdr 2 existing-metric) (metrics-tracker--min-date (nth 2 existing-metric) date))
                                (setcar (nthcdr 3 existing-metric) (metrics-tracker--max-date (nth 3 existing-metric) date))
                                (setcar (nthcdr 4 existing-metric) (- (time-to-days today)
                                                                      (time-to-days (nth 3 existing-metric))))))))

      ;; read the diary file, fill `metrics' plist with "name -> (name count first last)"
      (metrics-tracker--process-diary list-filter-fcn list-action-fcn)

      ;; mix in the derived metrics
      (let (derived-metric-name ; metric name as a symbol
            derived-from        ; list of metrics from which the current metric is derived
            count)              ; count of entries
        (dolist (metric metrics-tracker-derived-metrics)
          (setq derived-metric-name (intern (car metric) metrics-tracker-metric-names)
                derived-from (mapcar (lambda (ii) (gethash (intern ii metrics-tracker-metric-names) metrics))
                                     (nth 1 metric)))
          (setq count (seq-reduce (lambda (count ii) (+ count (or (nth 1 ii) 0))) derived-from 0))
          (if (eq 0 count) ; filter out derived metrics
              (message (format "Ignoring derived metric with no entries: %s" derived-metric-name))
            (puthash derived-metric-name
                     (list derived-metric-name
                           count
                           (seq-reduce (lambda (first ii) (if (time-less-p first (nth 2 ii)) first (nth 2 ii))) derived-from today)
                           (seq-reduce (lambda (last ii) (if (time-less-p last (nth 2 ii)) (nth 3 ii) last)) derived-from 0)
                           (seq-reduce (lambda (daysago ii) (min daysago (or (nth 4 ii) most-positive-fixnum))) derived-from most-positive-fixnum))
                     metrics))))

      ;; convert hash to list and sort by last update date
      (setq metrics-tracker-metric-index (sort (hash-table-values metrics) (lambda (a b) (> (nth 4 b) (nth 4 a)))))
      (add-hook 'kill-buffer-hook #'metrics-tracker-clear-data))))

(defmacro metrics-tracker--validate-input (variable choice options)
  "Validate that VARIABLE was set to a CHOICE that is among the valid OPTIONS."
  `(if (not (seq-contains ,options ,choice))
       (error (concat ,variable " must be one of: " (mapconcat #'symbol-name ,options ", ")))
     t))

; public

;;;###autoload
(defun metrics-tracker-index ()
  "Display a list of all saved metrics along with some useful stats about each.

This reads the diary file.

Note that derived metrics are counted every time one of their
base metrics occurs.  If multiple base metrics occur on the same
day, this will count it multiple times.  That's fine when base
metrics are separate terms ($1+$2) but not when they're part of
the same term ($1/$2)."
  (interactive)

  (metrics-tracker--load-index)

  (metrics-tracker--setup-output-buffer)
  (tabulated-list-mode)

  ;; set headers
  (let ((metric-name-width (seq-reduce (lambda (width ii) (max width (length ii)))
                                       (mapcar (lambda (ii) (symbol-name (nth 0 ii))) metrics-tracker-metric-index)
                                       10)))
    (setq-local tabulated-list-format (vector (list "metric" metric-name-width t)
                                              (list "days ago" 10 (metrics-tracker--num-sort 1))
                                              (list "first" 12 t)
                                              (list "last" 12 t)
                                              (list "count" 8 (metrics-tracker--num-sort 4)))))
  ;; configure
  (setq-local tabulated-list-padding 2)
  (setq-local tabulated-list-sort-key (cons "days ago" nil))

  ;; populate the table data
  (let (data)
    (dolist (metric metrics-tracker-metric-index)
      (setq data (cons (list (symbol-name (nth 0 metric))
                             (vector (symbol-name (nth 0 metric))
                                     (number-to-string (nth 4 metric))
                                     (format-time-string "%F" (nth 2 metric))
                                     (format-time-string "%F" (nth 3 metric))
                                     (number-to-string (nth 1 metric))))
                       data)))
    (setq-local tabulated-list-entries data))

  ;; render the table
  (tabulated-list-init-header)
  (tabulated-list-print nil nil)

  (metrics-tracker--show-output-buffer))

(defun metrics-tracker--insert-base-metrics (metric-names &optional cycle-metrics)
  "Insert base metrics in front of derived metrics in METRIC-NAMES.

METRIC-NAMES [list string] names of metrics requested for this
report.

CYCLE-METRICS [list string] list of metrics that have already been
added for this report.  If we have to add a metric from this list
it'll be a cycle.

Return [list string] input list but insert dependencies in front
of the derived metrics that depend on them."
  (let (derived-metric result)
    (dolist (metric-name metric-names)
      (if (seq-contains cycle-metrics metric-name)
          (error (format "Cycle detected in derived metric dependency: %s" metric-name)))
      (setq derived-metric (seq-find (lambda (ii) (string= metric-name (car ii)))
                                     metrics-tracker-derived-metrics))
      (if derived-metric
          (setq cycle-metrics (append (list metric-name) cycle-metrics)
                result (append (list metric-name)
                               (metrics-tracker--insert-base-metrics (nth 1 derived-metric)
                                                                     cycle-metrics)
                  result))
        (setq result (append (list metric-name) result))))
    (nreverse result)))

(defun metrics-tracker--date-to-bin (date date-grouping)
  "Return the start date of the bin containing DATE of size DATE-GROUPING.

DATE [time] any date, but probably the date of an occurrence.

DATE-GROUPING [symbol] defines bin size."
  (if (eq date-grouping 'full)
      'full
    (let ((date-fields (decode-time date))
          (offset (pcase date-grouping
                   (`day 0)
                   (`week (nth 6 (decode-time date)))
                   (`month (1- (nth 3 (decode-time date))))
                   (`year (1- (string-to-number (format-time-string "%j" date)))))))
      (encode-time 0 0 0
                   (- (nth 3 date-fields) offset)
                   (nth 4 date-fields)
                   (nth 5 date-fields)))))

(defun metrics-tracker--date-to-next-bin (date date-grouping)
  "Advance to the bin following DATE.
This can be used to advance through the calendar stepping by DATE-GROUPING.

DATE [time] any date.

DATE-GROUPING [symbol] defines bin size.

Return [time] the start date of the next bin."
  (if (eq date-grouping 'full)
      'full
    (let* ((date-fields (decode-time date))
           (is-dst (nth 7 date-fields))
           (next-date-fields date-fields)
           next-date)
      (pcase date-grouping
       (`day (setcar (nthcdr 3 next-date-fields) (1+ (nth 3 next-date-fields))))
       (`week (setcar (nthcdr 3 next-date-fields) (+ 7 (nth 3 next-date-fields))))
       (`month (setcar (nthcdr 4 next-date-fields) (1+ (nth 4 next-date-fields))))
       (`year (setcar (nthcdr 5 next-date-fields) (1+ (nth 5 next-date-fields)))))
      (setq next-date (apply #'encode-time next-date-fields))
      (setq next-date-fields (decode-time next-date))
      ;; suppress daylight savings shifts
      (when (and (not is-dst)
                 (nth 7 next-date-fields))
        (setq next-date (seq-take (time-subtract next-date (seconds-to-time 3600)) 2)))
      (when (and is-dst
                 (not (nth 7 next-date-fields)))
        (setq next-date (seq-take (time-add next-date (seconds-to-time 3600)) 2)))
      ;; return next-date
      next-date)))

(defun metrics-tracker--val-to-bin (value existing-value value-transform)
  "Merge a new VALUE into a bin.

VALUE [number] new value to add to the bin.

EXISTING-VALUE [number|cons|nil] current bin value.

VALUE-TRANSFORM [symbol] defines an operation to apply to bin values.

Return [number|cons] bin value after merging the new value."
  (cond
   ((seq-contains '(count percent diff-count diff-percent accum-count) value-transform)
    (1+ (or existing-value 0)))
   ((or (eq value-transform 'min)
        (eq value-transform 'diff-min))
    (if existing-value (min value existing-value) value))
   ((or (eq value-transform 'max)
        (eq value-transform 'diff-max))
    (if existing-value (max value existing-value) value))
   ((or (eq value-transform 'avg) ; for avg case, put (total . count) in bin
        (eq value-transform 'diff-avg))
    (setq existing-value (or existing-value '(0 . 0)))
    (unless (consp value)
      (setq value (cons value 1)))
    (cons (+ (car value) (car existing-value))
          (+ (cdr value) (cdr existing-value))))
   (t
    (+ value (or existing-value 0)))))

(defun metrics-tracker--date-bin-format (date-grouping)
  "Get the format string for the the bin based on the DATE-GROUPING.
Return [string]."
  (pcase date-grouping
   (`day "%Y-%m-%d")
   (`week "%Y-%m-%d")
   (`month "%Y-%m")
   (`year "%Y")))

(defun metrics-tracker--clip-duration (bin-start span first-date last-date)
  "Clip the given duration if it falls outside of first and last dates.

The bin is the interval [BIN-START BIN-START+SPAN] (inclusive).
Intersect it with the interval [FIRST-DATE
LAST-DATE] (inclusive), and return the length of the result.

SPAN [number] number of days in the initial bin.

BIN-START [time] date at the start of the bin.

FIRST-DATE [time] clip the bin to start on this date.

LAST-DATE [time] clip the bin to end on this date.

Return [number] number of days in the clipped span."
  (let ((bin-end (time-add bin-start (seconds-to-time (* span 86400)))))
    (cond
     ((time-less-p bin-start first-date) ; bin starts before first occurrence
      (float (max 0 (- (time-to-days bin-end)
                       (time-to-days first-date)))))
     ((time-less-p last-date bin-end)    ; bin ends after last occurrence
      (float (1+ (- (time-to-days last-date)
                    (time-to-days bin-start)))))
     (t
      (float span)))))

(defun metrics-tracker--days-of-month (date)
  "Find the number of days in the month containing DATE.
This depends on `timezeone'.

DATE [time] any date."
  (let ((date-fields (decode-time date)))
    (timezone-last-day-of-month (nth 4 date-fields) (nth 5 date-fields))))

(defun metrics-tracker--bin-to-val (value
                            value-transform date-grouping
                            bin-date first-date last-date)
  "Transform and format the bin VALUE into the value used in reporting.

VALUE [number|cons|nil] is usually a number but can be a cons
containing (total . count) if the VALUE-TRANSFORM is avg, or nil
for gaps.

VALUE-TRANSFORM [symbol] and DATE-GROUPING [symbol] are used to
transform the value.

BIN-DATE [time], FIRST-DATE [time], LAST-DATE [time
value] are needed to determine the number of days in the current
bin.

Return [number|nil] transformed value of the bin."
  (let ((bin-duration (pcase date-grouping
                       (`day 1.0)
                       (`week (metrics-tracker--clip-duration bin-date 7 first-date last-date))
                       (`month (metrics-tracker--clip-duration bin-date (metrics-tracker--days-of-month bin-date) first-date last-date))
                       (`year (metrics-tracker--clip-duration bin-date 365 first-date last-date))
                       (`full (float (- (time-to-days last-date)
                                        (time-to-days first-date)))))))
    (cond
     ((null value)
      value)

     ((seq-contains '(total min max count diff-total diff-min diff-max diff-count accum accum-count) value-transform)
      value)

     ((or (eq value-transform 'avg)
          (eq value-transform 'diff-avg))
      (if (consp value)
          (/ (car value) (float (cdr value)))
        value))
     ((or (eq value-transform 'percent)
          (eq value-transform 'diff-percent))
      (* (/ value bin-duration) 100))

     ((or (eq value-transform 'per-day)
          (eq value-transform 'diff-per-day))
      (* value (/ 1 bin-duration)))

     ((or (eq value-transform 'per-week)
          (eq value-transform 'diff-per-week))
      (* value (/ 7 bin-duration)))

     ((or (eq value-transform 'per-month)
          (eq value-transform 'diff-per-month))
      (* value (/ 30 bin-duration)))

     ((or (eq value-transform 'per-year)
          (eq value-transform 'diff-per-year))
      (* value (/ 365 bin-duration))))))

(defun metrics-tracker--bin-metric-data (metric-names-str date-grouping value-transform start-date end-date &optional allow-gaps-p)
  "Read the requested metric data from the diary.

METRIC-NAMES-STR [list string] keep entries for these metrics.

DATE-GROUPING [symbol] defines bin size.

VALUE-TRANSFORM [symbol] defines operations to perform on bin values.

START-DATE [time] date on which report should start.

END-DATE [time] date on which report should end, and when to end gap filling.

ALLOW-GAPS-P [boolean] If t, don't fill gaps.

Return the bin data as [hash symbol->[hash time->number]]."
  (let* ((bin-data-all (make-hash-table :size 4))      ; [hash symbol->[hash time->number]] bin data for all metrics
         (metric-names (mapcar                         ; [list symbol] chosen metrics
                        (lambda (name) (intern name metrics-tracker-metric-names))
                        metric-names-str))
         (metric-names-with-deps (mapcar               ; [list symbol] metric-names with dependencies inserted in front of metrics that depend on them
                                  (lambda (name) (intern name metrics-tracker-metric-names))
                                  (metrics-tracker--insert-base-metrics metric-names-str)))
         date-bin                                      ; [time] current date bin used by bin-action-fcn
         existing-value                                ; [number] current value used by bin-action-fcn
         bin-data                                      ; [hash time->number] current bin data used by bin-action-fcn
         effective-date-grouping                       ; [symbol] current date-grouping for binning
         (bin-filter-fcn (lambda (_date name)          ; [fcn] filters diary entries
                           (seq-contains metric-names-with-deps name)))
         (bin-action-fcn (lambda (date name value)     ; [fcn] puts values in appropriate bins
                           (setq bin-data (gethash name bin-data-all)
                                 date-bin (metrics-tracker--date-to-bin date effective-date-grouping)
                                 existing-value (gethash date-bin bin-data))
                           (puthash date-bin (metrics-tracker--val-to-bin value existing-value value-transform)
                                    bin-data)))
         (derived-metric-names (mapcar                 ; [list symbol] list of all derived metric names
                                (lambda (ii) (intern (car ii) metrics-tracker-metric-names))
                                metrics-tracker-derived-metrics)))

    ;; init bin-data-all hash
    (dolist (name metric-names-with-deps)
      (puthash name (make-hash-table :test 'equal) bin-data-all))

    ;; read the diary file, fill day bins for base metrics
    (setq effective-date-grouping 'day)
    (metrics-tracker--process-diary bin-filter-fcn bin-action-fcn start-date end-date)
    (setq effective-date-grouping date-grouping) ; revert back to chosen `date-grouping'

    ;; compute derived metrics
    (metrics-tracker--compute-derived-metrics (seq-filter (lambda (ii) (seq-contains derived-metric-names ii)) metric-names-with-deps)
                                              bin-data-all value-transform)
    (unless (eq date-grouping 'day)
      (metrics-tracker--translate-bins metric-names bin-data-all bin-action-fcn))

    ;; prune base metrics
    (seq-do (lambda (ii) (remhash ii bin-data-all))
            (seq-difference metric-names-with-deps metric-names))

    ;; fill gaps and apply value transforms for base metrics, compute values for derived metrics
    (dolist (metric-name metric-names)
      (let* ((first-date (nth 2 (nth 0 (seq-filter                ; [time] first date of metric data as a time value
                                        (lambda (item) (eq (car item) metric-name)) metrics-tracker-metric-index))))
             (first-date-bin (metrics-tracker--date-to-bin        ; [time] date bin containing first date
                              first-date date-grouping))
             (end-date-bin (metrics-tracker--date-to-bin end-date ; [time] date bin containing the `end-date'
                                                      date-grouping))
             (bin-data (gethash metric-name bin-data-all)))       ; [hash time->number]

        (if (eq date-grouping 'full)
            (puthash 'full
                     (metrics-tracker--bin-to-val (gethash 'full bin-data) value-transform date-grouping 'full first-date end-date)
                     bin-data)
          (let* ((current-date-bin first-date-bin)
                 (last-value (metrics-tracker--bin-to-val        ; the value from the last bin we visited
                              (gethash current-date-bin bin-data) value-transform date-grouping current-date-bin first-date end-date))
                 (total-value 0)                                 ; the total so far if we're accumulating
                 current-value                                   ; the value from the bin we're currently visiting
                 write-value)                                    ; the value to write for the current bin
            (while (or (time-less-p current-date-bin end-date-bin)
                       (equal current-date-bin end-date-bin))
              (when (or (gethash current-date-bin bin-data)
                        (not allow-gaps-p))
                (setq current-value (metrics-tracker--bin-to-val ; the value for the current bin
                                     (gethash current-date-bin bin-data 0)
                                     value-transform date-grouping current-date-bin first-date end-date))
                (cond ((seq-contains '(diff-total diff-min diff-max diff-avg diff-count diff-percent
                                                  diff-per-day diff-per-week diff-per-month diff-per-year)
                                     value-transform)
                       (setq write-value (- current-value last-value))) ; apply diff
                      ((seq-contains '(accum accum-count) value-transform)
                       (setq total-value (+ total-value current-value)) ; compute and use total
                       (setq write-value total-value))
                      (t
                       (setq write-value current-value)))

                (puthash current-date-bin write-value bin-data))
              (setq last-value current-value                        ; save last value for diff
                    current-date-bin (metrics-tracker--date-to-next-bin current-date-bin date-grouping))))))) ; increment to next bin
    bin-data-all))

(defun metrics-tracker--compute-derived-metrics (chosen-derived-metrics bin-data-all value-transform)
  "Compute derived metrics and update bins.

CHOSEN-DERIVED-METRICS [list symbol] derived metrics included in report.

BIN-DATA-ALL [hash symbol->[hash time->number]] bin data for all metrics.

VALUE-TRANSFORM [symbol] defines an operation to perform on bin values."
  (dolist (derived-metric-name chosen-derived-metrics)
    (let* ((derived-metric (seq-find (lambda (ii) (string= (car ii) derived-metric-name)) metrics-tracker-derived-metrics))
           ;; merge dates across base metrics for this derived metric
           (merged-dates (seq-reduce (lambda (dates bin-data) (append (hash-table-keys bin-data) dates))
                                     (mapcar (lambda (base-metric-name)
                                               (gethash (intern base-metric-name metrics-tracker-metric-names) bin-data-all))
                                             (nth 1 derived-metric))
                                     nil))
           (merged-dates (delete-dups merged-dates))
           bin-data val)

      ;; compute for each day
      (setq bin-data (gethash derived-metric-name bin-data-all))
      (dolist (date merged-dates)
        (setq val (metrics-tracker--compute-val derived-metric-name date bin-data-all value-transform))
        (unless (null val)
          (puthash date val bin-data))))))

(defun metrics-tracker--translate-bins (metric-names bin-data-all bin-action-fcn)
  "Replace day bins with chosen date-group bins.

METRIC-NAMES [list symbol] metrics that are part of this report.

BIN-DATA-ALL [hash symbol->[hash time->number]] bin data for all
metrics.  Initially BIN-DATA-ALL should contain bin data with
`day' as `date-grouping'.  This replaces those bin data hashes
with bin data hashes with the chosen `date-grouping'.

BIN-ACTION-FCN [fcn] puts values in appropriate bins."
  (let (day-bin-data bin-data)
    (dolist (metric-name metric-names)
      (setq day-bin-data (gethash metric-name bin-data-all)
            bin-data (make-hash-table :test 'equal))
      (puthash metric-name bin-data bin-data-all)
      (dolist (date (hash-table-keys day-bin-data))
        (funcall bin-action-fcn date metric-name (gethash date day-bin-data))))))

(defun metrics-tracker--compute-val (metric-name date-bin bin-data-all value-transform)
  "Return computed value for METRIC-NAME at DATE-BIN.

METRIC-NAME [symbol] the name of a derived metric.

DATE-BIN [time|'full] the date bin to compute.

BIN-DATA-ALL [hash symbol->[hash time->number]] bin data for all metrics.

VALUE-TRANSFORM [symbol] defines an operation to perform on bin values."
  (let* ((derived-metric-def (seq-find (lambda (ii) (string= (car ii) metric-name)) metrics-tracker-derived-metrics))
         (dep-metrics (mapcar (lambda (ii) (intern ii metrics-tracker-metric-names))
                              (nth 1 derived-metric-def)))
         (expression (nth 2 derived-metric-def))
         (dep-values (mapcar (lambda (ii)
                               (let ((value (gethash date-bin (gethash ii bin-data-all))))
                                 (if (consp value)
                                     (/ (car value) (float (cdr value)))
                                   value)))
                             dep-metrics))
         float-values value-str)
    ;; for count or percent just sum values, otherwise apply the expression
    (if (or (seq-contains '(count percent diff-count diff-percent accum-count) value-transform)
            (null expression))
        (apply '+ (seq-remove #'null dep-values))
      (setq float-values (mapcar ; convert values to math-floats for calc
                          (lambda (val) (math-float (list 'float (floor (* (or val 0) 10000)) -4)))
                          dep-values)
            value-str (apply 'calc-eval (append (list expression "") float-values)))
      (cond ((string-match "/ 0." value-str) nil)
            (t (string-to-number value-str))))))

(defun metrics-tracker--setup-output-buffer ()
  "Create and clear the output buffer."
  (let ((buffer (get-buffer-create metrics-tracker-output-buffer-name)))
    (set-buffer buffer)
    (read-only-mode)
    (let ((inhibit-read-only t))
      (erase-buffer))))

(defun metrics-tracker--show-output-buffer ()
  "Show the output buffer."
  (let ((buffer (get-buffer metrics-tracker-output-buffer-name)))
    (set-window-buffer (selected-window) buffer)))

(defun metrics-tracker--check-gnuplot-exists ()
  "Signal an error if gnuplot is not installed on the system."
  (unless (eq 0 (call-process-shell-command "gnuplot --version"))
    (error "Cannot find gnuplot")))

(defun metrics-tracker--ask-for-metrics (multp)
  "Prompt for metric names.

If MULTP [boolean] is false, only ask for one metric, else loop until
\"no more\" is chosen.  Return the selected list of metric names."
  (let* ((all-metric-names (mapcar #'car metrics-tracker-metric-index))
         (last-metric-name (completing-read "Metric: " (metrics-tracker--presorted-options all-metric-names) nil t))
         (metric-names (cons last-metric-name nil)))
    (setq all-metric-names (cons "no more" all-metric-names))
    (while (and (not (string= last-metric-name "no more"))
                multp)
      (setq all-metric-names (seq-remove (lambda (elt) (string= elt last-metric-name)) all-metric-names)
            last-metric-name (completing-read "Metric: " (metrics-tracker--presorted-options all-metric-names) nil t))
      (if (not (string= last-metric-name "no more"))
          (setq metric-names (cons last-metric-name metric-names))))
    (nreverse metric-names)))

(defun metrics-tracker--ask-for-date (prompt)
  "Display the PROMPT, return the response or nil if no response given.

PROMPT [string] prompt to show the user when asking for the start
date or end date."
  (let ((date-str (read-string prompt)))
    (if (string= "" date-str) nil date-str)))

;;;###autoload
(defun metrics-tracker-table (arg)
  "Interactive way to get a tabular view of the requested metric.

This function gets user input and then delegates to
`metrics-tracker-table-render'.

ARG is optional, but if given and it is the default argument,
allow selection of multiple metrics and date ranges."
  (interactive "P")

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((ivy-sort-functions-alist nil)
         ;; ask for params
         (extrap (equal arg '(4)))
         (metric-names-str (metrics-tracker--ask-for-metrics extrap))
         (date-grouping (intern (completing-read "Group dates by: " (metrics-tracker--presorted-options
                                                                     (metrics-tracker--date-grouping-options))
                                                 nil t nil nil "month")))
         (value-transform (intern (completing-read "Value transform: " (metrics-tracker--presorted-options
                                                                        (metrics-tracker--value-transform-options date-grouping))
                                                   nil t nil nil "total")))
         (start-date (and extrap (metrics-tracker--ask-for-date "Start date (optional): ")))
         (end-date (and extrap (metrics-tracker--ask-for-date "End date (optional): "))))
    (metrics-tracker-table-render (list metric-names-str date-grouping value-transform
                                        start-date end-date))))

;;;###autoload
(defun metrics-tracker-table-render (table-config)
  "Programmatic way to get a tabular view of the requested metric.

TABLE-CONFIG [list] should contain all inputs needed to render a table.
1. [list string] metric names.
2. [symbol] date grouping.
3. [symbol] value transform.
4. [date string] (optional) ignore occurrences before.
5. [date string] (optional) ignore occurrences after.
Date strings can be in any format `parse-time-string' can use.

For example:
    '((\"metricname\") year total nil nil)"

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((today (metrics-tracker--string-to-time))
         (all-metric-names                        ; [list symbol] all metric names
          (mapcar #'car metrics-tracker-metric-index))
         (metric-names-str (nth 0 table-config))  ; [list string] chosen metric names
         (metric-names                            ; [list symbol] chosen metric names
          (mapcar (lambda (name) (intern name metrics-tracker-metric-names)) metric-names-str))
         (date-grouping (nth 1 table-config))     ; [symbol] chosen date grouping
         (value-transform (nth 2 table-config))   ; [symbol] chosen value transform as a symbol
         (start-date (and (nth 3 table-config)    ; [time] chosen start date as a time value
                          (metrics-tracker--string-to-time (nth 3 table-config))))
         (end-date (and (nth 4 table-config)      ; [time] chosen start date as a time value
                          (metrics-tracker--string-to-time (nth 4 table-config))))
         bin-data-all)                            ; [hash symbol->[hash time->number]] bin data for all metrics

    ;; validate inputs
    (dolist (metric metric-names t)
      (metrics-tracker--validate-input "metric" metric all-metric-names))
    (metrics-tracker--validate-input "date-grouping" date-grouping (metrics-tracker--date-grouping-options))
    (metrics-tracker--validate-input "value-transform" value-transform (metrics-tracker--value-transform-options date-grouping))
    (unless (or (null start-date) (null end-date) (time-less-p start-date end-date))
      (error "The end date is before the start date"))

    ;; save the config
    (setq metrics-tracker-last-report-config (cons 'table table-config))

    ;; load metric data into bins; hash containing `bin-data' for each metric in `metric-names' plus any needed base metrics
    (setq bin-data-all (metrics-tracker--bin-metric-data metric-names-str date-grouping value-transform
                                                         start-date (if (time-less-p today end-date) today end-date)))

    (if (and (eq date-grouping 'full)
             (= 1 (length metric-names)))
        ;; if there's only one value to print, just write it to the status line
        (message "Overall %s %s: %s"
                 (car metric-names)
                 (replace-regexp-in-string "-" " " (symbol-name value-transform))
                 (metrics-tracker--format-value (gethash 'full (car (hash-table-values bin-data-all))) ""))

      ;; otherwise write a table
      (metrics-tracker--setup-output-buffer)
      (tabulated-list-mode)

      ;; set table headers
      (setq tabulated-list-format
            (vconcat (list (list (symbol-name date-grouping) 12 t))
                     (let ((labels (metrics-tracker--choose-labels metric-names-str value-transform))
                           headers)
                       (dotimes (ii (length labels))
                         (setq headers (cons
                                       (list (nth ii labels)
                                             (max 10 (+ 3 (length (nth ii labels))))
                                             (metrics-tracker--num-sort (1+ ii)))
                                       headers)))
                       (nreverse headers))))

      ;; configure
      (setq tabulated-list-padding 2)
      (setq tabulated-list-sort-key (cons (symbol-name date-grouping) nil))

      ;; compute and set table data
      (setq-local tabulated-list-entries (metrics-tracker--format-data metric-names bin-data-all
                                                                        date-grouping start-date end-date nil))

      ;; render the table
      (let ((inhibit-read-only t))
        (tabulated-list-init-header)
        (tabulated-list-print nil nil))

      (metrics-tracker--show-output-buffer))))

(defun metrics-tracker--choose-labels (metric-names-str value-transform)
  "Return report labels based on chosen metrics.

METRIC-NAMES-STR [list string] chosen metric names.

VALUE-TRANSFORM [symbol] chosen value transform.

Return [list string] report labels."
  (mapcar (lambda (metric-name) (format "%s %s"
                                        metric-name
                                        (replace-regexp-in-string "-" " " (symbol-name value-transform))))
          metric-names-str))

(defun metrics-tracker--format-data (metric-names bin-data-all date-grouping start-date end-date graph-type)
  "Return a list of '(date-str [date-str metric1 ...]) formed from bin data.

METRIC-NAMES [list symbol] is the list of chosen metrics.

BIN-DATA-ALL [hash symbol->[hash time->number]] bin data for chosen each metric.

DATE-GROUPING [symbol] is the selected bin size.

START-DATE [time] if given, filter occurrences before.

END-DATE [time] if given, filter occurrences after.

GRAPH-TYPE [symbol] is the selected graph type, if the current operation is a graph."
  (let ((filler (cond ((eq graph-type 'line) ".")    ; line graphs
                      ((eq graph-type 'scatter) ".") ; scatter graphs
                      ((not (null graph-type)) "0")  ; other graphs
                      (t "")))                       ; tables
        merged-dates data)
    ;; merge dates across metrics and sort
    (setq merged-dates (seq-reduce (lambda (dates bin-data) (append (hash-table-keys bin-data) dates))
                                   (hash-table-values bin-data-all)
                                   nil)
          merged-dates (delete-dups merged-dates)
          merged-dates (metrics-tracker--sort-dates merged-dates))

    ;; pull data for each metric for each date (builds a list backwards)
    (dolist (date merged-dates)
      (when (and (or (null start-date) ; only use occurrences between `start-date' and `end-date', inclusive
                     (not (time-less-p date start-date)))
                 (or (null end-date)
                     (not (time-less-p end-date date))))
        (let* ((date-str (if (eq date-grouping 'full)
                             "full"
                           (format-time-string (metrics-tracker--date-bin-format date-grouping) date)))
               (computed-values (mapcar (lambda (metric-name) (gethash date (gethash metric-name bin-data-all)))
                                        metric-names))
               (formatted-values (mapcar (lambda (value) (metrics-tracker--format-value value filler)) computed-values)))
          (setq data (cons (list date-str
                                 (vconcat (list date-str) formatted-values))
                           data)))))
    (nreverse data))) ; return data


(defun metrics-tracker--format-value (value filler)
  "Round and format VALUE so it can be presented.
If VALUE isn't a number, return FILLER value."
  (if (numberp value)
      (format "%g" (/ (round (* value 100)) 100.0))
    filler))

;;;###autoload
(defun metrics-tracker-cal (arg)
  "Interactive way to get a calendar view of a requested metric.

This function gets user input and then delegates to
`metrics-tracker-cal-render'.

ARG is optional, but if given and it is the default argument,
allow selection of date ranges."
  (interactive "P")

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((ivy-sort-functions-alist nil)
         ;; ask for params
         (extrap (equal arg '(4)))
         (all-metric-names (mapcar #'car metrics-tracker-metric-index))
         (metric-name-str (completing-read "Metric: " (metrics-tracker--presorted-options all-metric-names) nil t))
         (value-transform (intern (completing-read "Value transform: " (metrics-tracker--presorted-options
                                                                        (metrics-tracker--value-transform-options 'day))
                                                   nil t nil nil "total")))
         (start-date (and extrap (metrics-tracker--ask-for-date "Start date (optional): ")))
         (end-date (and extrap (metrics-tracker--ask-for-date "End date (optional): "))))
    (metrics-tracker-cal-render (list metric-name-str value-transform start-date end-date))))

;;;###autoload
(defun metrics-tracker-cal-render (cal-config)
  "Programmatic way to get a calendar view of a requested metric.

CAL-CONFIG [list] should contain all inputs needed to generate the calendar.
1. [string] metric name.
2. [symbol] value transform.
3. [date string] (optional) ignore occurrences before.
4. [date string] (optional) ignore occurrences after.
Date strings must be in YYYY-MM-DD format.

For example:
    '((\"metricname\") total nil nil)"

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((today (metrics-tracker--string-to-time))
         (all-metric-names (mapcar #'car metrics-tracker-metric-index))
         (metric-name-str (nth 0 cal-config))
         (metric-name (intern metric-name-str metrics-tracker-metric-names))
         (value-transform (nth 1 cal-config))
         (start-date (and (nth 2 cal-config)
                          (metrics-tracker--string-to-time (nth 2 cal-config))))
         (end-date (and (nth 3 cal-config)
                        (metrics-tracker--string-to-time (nth 3 cal-config)))))

    ;; validate inputs
    (metrics-tracker--validate-input "metric" metric-name all-metric-names)
    (metrics-tracker--validate-input "value-transform" value-transform (metrics-tracker--value-transform-options 'day))
    (unless (or (null start-date) (null end-date) (time-less-p start-date end-date))
      (error "The end date is before the start date"))

    ;; save the config
    (setq metrics-tracker-last-report-config (cons 'cal cal-config))

    (metrics-tracker--setup-output-buffer)
    (special-mode)

    ;; render the calendars
    (let* ((inhibit-read-only t)
           (label (nth 0 (metrics-tracker--choose-labels (list metric-name-str) value-transform)))

           ;; load metric data into bins; list of `bin-data' for each metric in the same order as `metric-names'
           (bin-data-all (metrics-tracker--bin-metric-data (list metric-name-str) 'day value-transform
                                                           start-date (if (time-less-p today end-date) today end-date) t))

           ;; find the first date
           (dates (hash-table-keys (car (hash-table-values bin-data-all))))
           (first (or start-date
                      (seq-reduce (lambda (first ii) (if (time-less-p first ii) first ii))
                                  dates (car dates))))
           (first-decoded (decode-time first))
           (month (nth 4 first-decoded))
           (year (nth 5 first-decoded))
           ;; find the month on which to end
           (end (or end-date today))
           (end-decoded (decode-time end))
           (end-month (nth 4 end-decoded))
           (end-year (nth 5 end-decoded)))
      (insert (format "  %s\n\n" label))
      (put-text-property (point-min) (point-max) 'face 'bold)
      (while (or (< year end-year)
                 (and (= year end-year)
                      (<= month end-month)))
        (metrics-tracker--print-month month year bin-data-all first end)
        (insert "\n\n\n")
        (setq month (1+ month))
        (when (> month 12)
          (setq month 1
                year (1+ year)))))

    (metrics-tracker--show-output-buffer)))

(defun metrics-tracker--print-month (month year bin-data-all first today)
  "Write metric data as a calendar for MONTH of YEAR.

BIN-DATA-ALL [hash symbol->[hash time->number]] bin data to render.

FIRST [time] start of date range.

TODAY [time] end of date range."
  (let ((first-day (encode-time 0 0 0 1 month year))
        day filler computed-value formatted-value)
    (insert (format "                    %s\n\n" (format-time-string "%b %Y" first-day)))
    (insert "      Su    Mo    Tu    We    Th    Fr    Sa\n  ")
    (dotimes (_ii (nth 6 (decode-time first-day)))
      (insert "      "))
    (dotimes (daynum (metrics-tracker--days-of-month first-day))
      (setq day (encode-time 0 0 0 (1+ daynum) month year)
            filler (cond ((time-less-p day first) "_") ; before data
                         ((time-less-p today day) "_") ; after today
                         (t "."))                      ; gap in data
            computed-value (gethash day (car (hash-table-values bin-data-all)))
            formatted-value (metrics-tracker--format-value computed-value filler))
      (insert (format "%6s" formatted-value))
      (when (= (nth 6 (decode-time day)) 6)
          (insert "\n  ")))))

;;;###autoload
(defun metrics-tracker-graph (arg)
  "Interactive way to get a graph of requested metrics.

This function gets user input and then delegates to
`metrics-tracker-graph-render'.

ARG is optional, but if given and it is the default argument,
allow selection of multiple metrics and date ranges."
  (interactive "P")

  (metrics-tracker--check-gnuplot-exists)

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((ivy-sort-functions-alist nil)
         ;; ask for params
         (extrap (equal arg '(4)))
         (metric-names-str (metrics-tracker--ask-for-metrics extrap))
         (date-grouping (intern (completing-read "Group dates by: " (metrics-tracker--presorted-options
                                                                     (metrics-tracker--date-grouping-options))
                                                 nil t nil nil "month")))
         (value-transform (intern (completing-read "Value transform: " (metrics-tracker--presorted-options
                                                                        (metrics-tracker--value-transform-options date-grouping))
                                                   nil t nil nil "total")))
         (start-date (and extrap (metrics-tracker--ask-for-date "Start date (optional): ")))
         (end-date (and extrap (metrics-tracker--ask-for-date "End date (optional): ")))
         (graph-type (intern (completing-read "Graph type: " (metrics-tracker--presorted-options
                                                              (metrics-tracker--graph-options date-grouping))
                                              nil t)))
         (graph-output (intern (completing-read "Graph output: " (metrics-tracker--presorted-options
                                                                  metrics-tracker-graph-output-options)
                                                nil t nil nil "ascii"))))

    (metrics-tracker-graph-render (list metric-names-str date-grouping value-transform
                                        start-date end-date graph-type graph-output))))

;;;###autoload
(defun metrics-tracker-graph-render (graph-config)
  "Programmatic way to get a graph of the requested metric.

GRAPH-CONFIG [list] should be a list of all inputs needed to render a graph.
1. [list string] chosen metric names.
2. [symbol] date grouping.
3. [symbol] value transform.
4. [date string] (optional) ignore occurrences before.
5. [date string] (optional) ignore occurrences after.
6. [symbol] graph type.
7. [symbol] graph output.
Date strings must be in YYYY-MM-DD format.

For example:
    '((\"metricname\") year total nil nil line svg)"

  (metrics-tracker--check-gnuplot-exists)

  ;; make sure `metrics-tracker-metric-index' has been populated
  (metrics-tracker--load-index)

  (let* ((ivy-sort-functions-alist nil)
         (today (metrics-tracker--string-to-time))
         ;; ask for params
         (all-metric-names (mapcar #'car metrics-tracker-metric-index))
         (metric-names-str (nth 0 graph-config))
         (metric-names (mapcar (lambda (name) (intern name metrics-tracker-metric-names)) metric-names-str))
         (date-grouping (nth 1 graph-config))
         (value-transform (nth 2 graph-config))
         (start-date (and (nth 3 graph-config)
                          (metrics-tracker--string-to-time (nth 3 graph-config))))
         (end-date (and (nth 4 graph-config)
                        (metrics-tracker--string-to-time (nth 4 graph-config))))
         (graph-type (nth 5 graph-config))
         (graph-output (nth 6 graph-config))
         buffer fname)

    (dolist (metric metric-names t)
      (metrics-tracker--validate-input "metric" metric all-metric-names))
    (metrics-tracker--validate-input "date-grouping" date-grouping (metrics-tracker--date-grouping-options))
    (metrics-tracker--validate-input "value-transform" value-transform (metrics-tracker--value-transform-options date-grouping))
    (metrics-tracker--validate-input "graph-type" graph-type (metrics-tracker--graph-options date-grouping))
    (metrics-tracker--validate-input "graph-output" graph-output metrics-tracker-graph-output-options)
    (unless (or (null start-date) (null end-date) (time-less-p start-date end-date))
      (error "The end date is before the start date"))

    ;; save the config
    (setq metrics-tracker-last-report-config (cons 'graph graph-config))

    ;; prep output buffer
    (setq buffer (get-buffer-create metrics-tracker-output-buffer-name)
          fname (and (not (eq graph-output 'ascii)) (make-temp-file "metrics-tracker" nil (format ".%s" graph-output))))

    (with-temp-buffer
      ;; load metric data into bins; hash of `bin-data' for each metric
      (let* ((bin-data-all (metrics-tracker--bin-metric-data metric-names-str date-grouping value-transform
                                                             start-date (if (time-less-p today end-date) today end-date)))
             ;; determine series labels
             (labels (metrics-tracker--choose-labels metric-names-str value-transform))
             ;; prepare the graph data from the bin data
             (data (metrics-tracker--format-data metric-names bin-data-all date-grouping start-date end-date graph-type)))
        (metrics-tracker--make-gnuplot-config labels data date-grouping value-transform graph-type graph-output fname))

      (save-current-buffer
        (metrics-tracker--setup-output-buffer)
        (special-mode))

      (unless (null fname)
        (setq metrics-tracker-tempfiles (cons fname metrics-tracker-tempfiles)) ; keep track of it so we can delete it
        (add-hook 'kill-emacs-hook #'metrics-tracker-remove-tempfiles))

      (let ((inhibit-read-only t))
        (call-process-region (point-min) (point-max) "gnuplot" nil buffer)
        (set-buffer buffer)
        (goto-char (point-min))
        (if (eq graph-output 'ascii)
            (while (re-search-forward "\f" nil t) ; delete the formfeed in gnuplot output
              (replace-match ""))
          (insert-image (create-image fname) (format "graph image tempfile: %s" fname)) ; insert the tempfile into the output buffer
          (insert "\n")
          (goto-char (point-min))))

      (metrics-tracker--show-output-buffer))))

(defun metrics-tracker--make-gnuplot-config (labels data
                                             date-grouping value-transform
                                             graph-type graph-output fname)
  "Write a gnuplot config (including inline data) to the (empty) current buffer.

LABELS [list string] series labels being plotted.

DATA [list list number] the graph data.

DATE-GROUPING [symbol] tells how to label the x axis.

VALUE-TRANSFORM [symbol] tells how to label the y axis.

GRAPH-TYPE [symbol] the type of graph (line, bar, scatter).

GRAPH-OUTPUT [symbol] graph output format (ascii, svg, png).

FNAME [string] filename of the temp file to write."
  (let ((date-format (metrics-tracker--date-bin-format date-grouping))
        (term (pcase graph-output
                (`svg "svg")
                (`png "pngcairo font \"Arial,10\"")
                (_ "dumb")))
        (width (if (eq graph-output 'ascii) (1- (window-width)) (car metrics-tracker-graph-size)))
        (height (if (eq graph-output 'ascii) (1- (window-height)) (cdr metrics-tracker-graph-size)))
        (title (if (= 1 (length labels)) (car labels) ""))
        (fg-color (if metrics-tracker-dark-mode "grey50" "grey10"))
        (bg-color (if metrics-tracker-dark-mode "grey10" "grey90")))

    (cond ((eq graph-output 'ascii)
           (insert (format "set term %s size %d, %d\n\n" term width height))
           (insert (format "set title \"%s\"\n" title)))
          (t ; output an image
           (insert (format "set term %s size %d, %d background rgb \"%s\"\n\n" term width height bg-color))
           (insert (format "set xtics tc rgb \"%s\"\n" fg-color))
           (insert (format "set title \"%s\" tc rgb \"%s\"\n" title fg-color))
           (insert (format "set output \"%s\"\n" fname))))
    (insert "set tics nomirror\n")
    (insert "set xzeroaxis\n")
    (insert (format "set border 3 back ls -1 lc rgb \"%s\"\n" fg-color))
    (insert (format "set xlabel \"%s\" tc rgb \"%s\"\n" date-grouping fg-color))
    (insert (format "set key tc rgb \"%s\"\n" fg-color))
    (when date-format ; not 'full
      (insert (format "set timefmt \"%s\"\n" date-format))
      (insert (format "set format x \"%s\"\n" date-format)))
    (insert (format "set ylabel \"%s\" tc rgb \"%s\"\n"
                    (replace-regexp-in-string "-" " " (symbol-name value-transform))
                    fg-color))
    (cond ((or (eq graph-type 'line)
               (eq graph-type 'scatter))
           (insert "set xdata time\n")
           (insert (format "set xrange [\"%s\":\"%s\"]\n" (caar data) (caar (last data))))
           (insert (format "set grid back ls 0 lc \"%s\"\n" fg-color))
           (insert "set pointsize 0.5\n"))
          ((or (eq graph-type 'bar)
               (eq graph-type 'stacked))
           (insert (format "set boxwidth %f relative\n" (if (eq graph-type 'bar) 1.0 0.6)))
           (insert "set style data histogram\n")
           (insert (format "set style histogram %s\n"
                           (if (eq graph-type 'bar) "cluster" "rowstacked")))
           (insert "set style fill solid\n")
           (insert (format "set grid ytics back ls 0 lc \"%s\"\n" fg-color))
           (if (eq graph-type 'stacked)
               (insert "set key invert\n"))))
    (insert "set xtics rotate by 45 right\n")
    (insert (metrics-tracker--define-plot graph-type graph-output labels) "\n")
    (dotimes (_ii (length labels))
      (if (not date-format) ; is 'full
          (insert (format ". %s\n" (mapconcat #'identity (cdar data) " ")))
        (dolist (entry data)
          (insert (concat (mapconcat #'identity (nth 1 entry) " ") "\n"))))
      (insert "\ne\n"))))

(defun metrics-tracker--define-plot (graph-type graph-output labels)
  "Return the plot definition command.

GRAPH-TYPE [symbol] is one of line, bar, point.

GRAPH-OUTPUT [symbol] is one of ascii, svg, png.

LABELS [list string] series labels being plotted."
  (let ((plot-def "plot")
        (colors (nth (if metrics-tracker-dark-mode 1 0) metrics-tracker-graph-colors))
        (num-lines (length labels)))
    (dotimes (ii num-lines)
      (let ((dash (if (= 0 ii) "-" ""))
            (label (if (= 1 num-lines) "notitle" (format "title \"%s\"" (nth ii labels))))
            (comma (if (< ii (1- num-lines)) "," "")))
        (cond
         ((eq graph-type 'line)
          (setq plot-def (concat plot-def (format " \"%s\" using 1:%d with lines %s lt %s lw 1.2 lc rgbcolor \"%s\"%s"
                                                  dash (+ ii 2) label (1+ ii) (nth ii colors) comma))))
         ((or (eq graph-type 'bar)
              (eq graph-type 'stacked))
          (setq plot-def (concat plot-def (format " \"%s\" using %d:xtic(1) %s lc rgbcolor \"%s\"%s"
                                                  dash (+ ii 2) label (nth ii colors) comma))))
         ((eq graph-type 'scatter)
          (setq plot-def (concat plot-def (format " \"%s\" using 1:%d with points %s lt %d %s lc rgbcolor \"%s\"%s"
                                                  dash (+ ii 2) label
                                                  ; set pointtype to capital letters for ascii or dots for images
                                                  (if (eq graph-output 'ascii) (1+ ii) 7)
                                                  ; but override pointtype to '*' for ascii plots with one metric
                                                  (if (and (eq graph-output 'ascii)
                                                           (= num-lines 1)) "pt \"*\"" "")
                                                  (nth ii colors) comma)))))))
    plot-def))

;;;###autoload
(defun metrics-tracker-save-last-report (name)
"Save the last report as a report named NAME.

NAME [string] name to assign to the saved report."
  (interactive "sReport name: ")

  ;; verify there is a last report
  (if (null metrics-tracker-last-report-config)
      (error "There is no last report to save"))

  (setq metrics-tracker-named-reports (nconc metrics-tracker-named-reports
                                             (list (cons name metrics-tracker-last-report-config))))
  (message "Saved"))

;;;###autoload
(defun metrics-tracker-show-named-report ()
"Render a previously saved report.
This prompts for which report (saved in
`metrics-tracker-named-reports') to render, then renders it."
  (interactive)

  (if (= (length metrics-tracker-named-reports) 0)
      (error "There are no named reports"))

  (let* ((report-name (completing-read "Named report: " (mapcar #'car metrics-tracker-named-reports) nil t))
         (report (seq-find (lambda (item) (equal (nth 0 item) report-name))
                           metrics-tracker-named-reports))
         (report-type (cadr report))
         (report-config (cddr report)))
    (pcase report-type
      (`table (metrics-tracker-table-render report-config))
      (`cal (metrics-tracker-cal-render report-config))
      (`graph (metrics-tracker-graph-render report-config)))))

(provide 'metrics-tracker)

;;; metrics-tracker.el ends here
