;;; org-arbeitszeit.el --- Calculate your worktime               -*- lexical-binding: t; -*-

;; Copyright (C) 2022

;; Author:  Benjamin Kästner <benjamin.kaestner@gmail.com>
;; URL: https://github.com/bkaestner/org-arbeitszeit
;; Package-Version: 20220816.1447
;; Package-Commit: b22ae3292b24772aa37dd5a54cd551f7312b6213
;; Keywords: tools, org, calendar, convenience
;; Version: 0.0.4
;; Package-Requires: ((emacs "27.1"))

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

;; `org-arbeitszeit' provides a new dynamic block for Org called "arbeitszeit"
;; (German for "working hours").  The dynamic block collects all clocked hours
;; and provides a weekly table to quickly see your accumulated overtime.
;;
;; To insert a new block, use `M-x org-dynamic-block-insert-dblock'.
;;

;;; Todo:

;; For holidays and vacations, I want to support org-references to lists and
;; tables. This is where the parameters :days-per-week and :hours-per-day will
;; come into play.

;;; Code:
(require 'cl-lib)
(require 'org-clock)

(defgroup org-arbeitszeit nil
  "Calculate your worktime from org clock logbooks."
  :group 'org
  :link '(emacs-commentary-link "org-arbeitszeit")
  :link '(url-link :tag "GitHub page" "https://github.com/bkaestner/org-arbeitszeit"))

(defcustom org-arbeitszeit-hours-per-day 8
  "The hours per working day.

You can specify the hours per day on a block level via :hours-per-day, see `org-arbeitszeit--write-table'."
  :group 'org-arbeitszeit
  :safe 'numberp
  :type 'number)

(defcustom org-arbeitszeit-days-per-week 5
  "The days per week.

You can specify the hours per day on a block level via :hours-per-day, see `org-arbeitszeit--write-table'."
  :group 'org-arbeitszeit
  :safe 'numberp
  :type 'number)

(defcustom org-arbeitszeit-match nil
  "The matcher for Org headlines.

See info node `(org) Matching tags and properties' for a
description of proper values."
  :group 'org-arbeitszeit
  :safe 'stringp
  :link '(info-link :tag "Org's matching documentation" "(org) Matching tags and properties")
  :type '(choice (const :tag "All" nil) string))

(defun org-arbeitszeit--warn-reserved (prop)
  "Warn about the usage of the reserved parameter PROP."
  (display-warning
   'org-arbeitszeit
   (format "the %s parameter is reserved for future use but currently not working" prop)
   :warning))

(defun org-arbeitszeit--get-weektime (week match &optional file)
  "Get the weektime in WEEK matching MATCH in the current buffer.

All restrictions are ignored.  Use FILE as identifer for
`org-clock-get-table-data' if supplied."
  (save-excursion
    (save-restriction
      (widen)
      (cadr (org-clock-get-table-data file (list :block week :match match))))))

(defun org-arbeitszeit--write-table (params)
  "Create the Arbeitszeittabelle using PARAMS.

PARAMS is a plist containg the following entries:

  :tstart (REQUIRED) - the start of your tracked time
  :tend   (REQUIRED) - the end of your tracked time
                       (must be greater than :tstart)
  :scope             - one of the following variants:
     nil (or not specified) - current file
     agenda                - files in the agenda
     agenda-with-archives  - files in the agenda, including their archives
     (\"file1\" \"file2\") - list of files
  :hours-per-day     - your working hours per day, default `8'
  :days-per-week     - your working days per week, default '5'
  :start-with        - time that shall be added to the table in a first row
  :match             - see info node `(org) Matching tags and properties'

The parameters `:hours-per-day' and `:days-per-week' are used to calculate your
planned working time.  Currently, that might seem like a hassle, but will
hopefully make more sense when the `:holidays' and `:vacations' options are
implemented.

If you provide a :match value then only matched values will show up in your
table.  This can come in handy, for example if you also clock in your breaks
for a complete continous clocked day.

Assumed you use the :break: tag, you end up with:

    #+BEGIN: arbeitszeit :match \"-break\"
    ...
    #+END:"
  (mapc #'org-arbeitszeit--warn-reserved
        (seq-intersection params '(:holidays :vacations)))

  (let ((scope (plist-get params :scope))
        (ts (plist-get params :tstart))
        (te (plist-get params :tend))
        (hours-per-day (or (plist-get params :hours-per-day)
                           org-arbeitszeit-hours-per-day))
        (days-per-week (or (plist-get params :days-per-week)
                           org-arbeitszeit-days-per-week))
        (start-with (plist-get params :start-with))
        (match (or (plist-get params :match)
                   org-arbeitszeit-match))
        files)
    (setq files
          (pcase scope
            ((pred consp) scope)
            (`agenda (org-agenda-files t))
            (`agenda-with-archives
             (org-add-archive-files (org-agenda-files t)))))

    (unless (and ts te)
      (error "Needs both :tstart and :tend set"))
    (when (string-match-p "<\\|>" ts)
      (setq ts (org-format-time-string "%Y-%m-%d" (org-matcher-time ts))))
    (when (string-match-p "<\\|>" te)
      (setq te (org-format-time-string "%Y-%m-%d" (org-matcher-time te))))
    (setq ts (org-date-to-gregorian ts))
    (setq te (org-date-to-gregorian te))

    (when files
      (org-agenda-prepare-buffers (if (consp files) files (list files))))

    (insert-before-markers "| Week | Hours | +Time |\n|-\n")

    (when start-with
      (insert-before-markers "| Start |||\n"))

    (while (calendar-date-compare (list ts) (list te))
      (let ((week (org-format-time-string "%Y-W%0W" (org-time-from-absolute ts)))
            (nts  (list (car ts) (+ 7 (cadr ts)) (caddr ts)))
            (weektime 0))
        (setq weektime
              (if (consp files)
                  (cl-loop for file in files
                           sum (with-current-buffer (find-buffer-visiting file)
                                 (org-arbeitszeit--get-weektime week match)))
                (org-arbeitszeit--get-weektime week match)))
        (insert (format "|%s|%s|\n" week (org-duration-from-minutes weektime 'h:mm)))
        (setq ts nts)))
    (insert-before-markers "|-\n|Total:|\n")
    (insert-before-markers
     (format "#+TBLFM: $3=$2-%s;U::@>$2..@>$>=vsum(@I..@II);U"
             (* 60 60 hours-per-day days-per-week)))
    (when start-with
      (insert-before-markers (format "::@2$3=%s;U" start-with))))
  (forward-line -1)
  (org-table-recalculate t))

(defun org-dblock-write:arbeitszeit (params)
  "Write the standard Arbeitszeittabelle.

See `org-arbeitszeit--write-table' for a description of PARAMS."
  (interactive)
  (org-arbeitszeit--write-table params))

(defun org-arbeitszeit-point-in-arbeitszeittabelle-p ()
  "Check if the cursor is in a arbeitszeit block."
  (let ((pos (point)) start)
    (save-excursion
      (end-of-line 1)
      (and (re-search-backward "^[ \t]*#\\+BEGIN:[ \t]+arbeitszeit" nil t)
           (setq start (match-beginning 0))
           (re-search-forward "^[ \t]*#\\+END:.*" nil t)
           (>= (match-end 0) pos)
           start))))

(defun org-arbeitszeit-report ()
  "Update dynamic arbeitszeit block at point (or insert if there is no arbeitszeit at point)."
  (interactive)
  (pcase (org-arbeitszeit-point-in-arbeitszeittabelle-p)
    (`nil
     (org-create-dblock '(:tstart "<-4w>" :tend "<now>" :name "arbeitszeit")))
    (start (goto-char start)))
  (org-update-dblock))

(org-dynamic-block-define "arbeitszeit" #'org-arbeitszeit-report)

(provide 'org-arbeitszeit)
;;; org-arbeitszeit.el ends here
