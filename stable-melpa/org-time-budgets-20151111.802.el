;;; org-time-budgets.el --- Define time budgets and display clocked time.

;; Author: Arthur Leonard Andersen <leoc.git@gmail.com>
;; Created: November 08, 2015
;; Version: 1.0.1
;; Package-Version: 20151111.802
;; Package-Commit: f2a8fe3d9d6104f3dd61fabbb385a596363b360b
;; Package-Requires: ((alert "0.5.10") (cl-lib "0.5"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; `org-time-budgets' lets you define time budgets and display your
;; clocked time in a neat table with progressbars.

;;; Code:
(eval-when-compile
  (require 'cl-lib))

(require 'org)
(require 'org-clock)
(require 'org-table)
(require 'org-agenda)

(defgroup org-time-budgets nil
  "Org time budgets customization."
  :tag "Org Time Budgets"
  :group 'org-progress)

(defcustom org-time-budgets nil
  "The list of time budgets.

See this example:

'((:title \"Business\" :tags \"+business\" :budget \"30:00\")
  (:title \"Practice Music\" :tags \"+practice+music\" :budget \"4:00\")
  (:title \"Exercise\" :tags \"+exercise\" :budget \"5:00\"))"
  :group 'org-pomodoro
  :type 'list)

(defun org-time-budgets-minutes-to-string (minutes)
  "Return the given MINUTES as string HH:MM."
  (let ((secs0 (abs (* minutes 60))))
    (org-format-seconds "%.2h:%.2m" secs0)))

(defun org-time-budgets-string-to-minutes (string)
  "Return the given STRING of format HH:MM as minutes."
  (/ (string-to-number
      (org-table-time-string-to-seconds string))
     60))

(defun org-time-budgets-bar (width progress goal)
  "Create a simple progress bar with WIDTH, displaying the PROGRESS relative to the set GOAL."
  (let* ((progress-width (floor (* (/ (float progress) (float goal)) width)))
         (progress (make-string (min (max 0 progress-width) width) ?|))
         (spacer (make-string (max 0 (- width progress-width)) ?.)))
    (concat
     (propertize progress 'font-lock-face '(:foreground "red"))
     spacer)))

(defun org-time-budgets-time (filters)
  "Return the clocked time matching FILTERS in agenda files."
  (apply '+
         (mapcar (lambda (file)
                   (nth 1 (save-window-excursion
                            (find-file file)
                            (org-clock-get-table-data file filters))))
                 org-agenda-files)))

(defun org-time-budgets-table ()
  "List the time budgets in a table."
  (let ((title-column-width (apply #'max
                                   (mapcar #'(lambda (budget) (string-width (plist-get budget :title)))
                                           org-time-budgets))))
    (mapconcat #'(lambda (budget)
                  (let* ((title (plist-get budget :title))
                         (tags (plist-get budget :tags))
                         (block (or (plist-get budget :block) 'week))

                         (trange (org-clock-special-range 'thisweek))
                         (tstart (nth 0 trange))
                         (tstart-s (format-time-string "[%Y-%m-%d]" tstart))
                         (tend (nth 1 trange))
                         (tworkweekend (time-add tstart (seconds-to-time
                                                         (* 5 24 60 60))))
                         (tend-s (format-time-string "[%Y-%m-%d]" tend))
                         (days-til-week-ends (ceiling
                                              (time-to-number-of-days
                                               (time-subtract tend (current-time)))))

                         (range-budget (org-time-budgets-string-to-minutes (plist-get budget :budget)))
                         (range-clocked (org-time-budgets-time `(:tags ,tags :tstart ,tstart-s :tend ,tend-s)))
                         (range-bar-length (floor (* (/ (float range-clocked) (float range-budget)) 14)))

                         (today-budget (if (eq block 'workweek)
                                           (/ range-budget 5)
                                         (/ range-budget 7)))
                         (today-clocked (org-time-budgets-time `(:tags ,tags :block today))))
                    (format "%s  [%s] %s / %s  [%s] %s / %s"
                             (concat
                              title
                              (make-string (max 0 (- title-column-width (string-width title))) ?\s))
                             (org-time-budgets-bar 14 today-clocked today-budget)
                             (org-time-budgets-minutes-to-string today-clocked)
                             (org-time-budgets-minutes-to-string today-budget)
                             (org-time-budgets-bar 14 range-clocked range-budget)
                             (org-time-budgets-minutes-to-string range-clocked)
                             (org-time-budgets-minutes-to-string range-budget))))
               org-time-budgets
               "\n")))

(defun org-time-budgets-in-agenda (arg)
  "Inhibit read-only and return the `org-time-budget-table'."
  (let ((inhibit-read-only t))
    (insert (org-time-budgets-table) "\n\n")))

(provide 'org-time-budgets)

;;; org-time-budgets.el ends here
