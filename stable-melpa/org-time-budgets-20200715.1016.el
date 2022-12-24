;;; org-time-budgets.el --- Define time budgets and display clocked time.

;; Author: Arthur Leonard Andersen <leoc.git@gmail.com>
;; Created: November 08, 2015
;; Version: 1.0.1
;; Package-Version: 20200715.1016
;; Package-Commit: 1d6bfc323013bbf725167842d9e097fad805de03
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

'((:title \"Business\" :match \"+business\" :budget \"30:00\" :blocks (workday week))
  (:title \"Practice Music\" :match \"+practice+music\" :budget \"4:00\" :blocks (nil week))
  (:title \"Exercise\" :match \"+exercise\" :budget \"5:00\" :blocks (day)))"
  :group 'org-time-budgets
  :type 'list)

(defvar org-time-budgets-show-budgets t
  "If non-nil, show time-budgets in agenda buffers.")

(defface org-time-budgets-done-face
  '((((background light)) (:foreground "#4df946"))
    (((background dark)) (:foreground "#228b22")))
  "Face for budgets which are fulfilled."
  :group 'org-time-budgets
  :group 'org-faces)

(defface org-time-budgets-close-face
  '((((background light)) (:foreground "#ffc500"))
    (((background dark)) (:foreground "#b8860b")))
  "Face for budgets which are close to being fulfilled."
  :group 'org-time-budgets
  :group 'org-faces)

(defface org-time-budgets-todo-face
  '((((background light)) (:foreground "#fc7560"))
    (((background dark)) (:foreground "#8b0000")))
  "Face for budgets which are not yet fulfilled."
  :group 'org-time-budgets
  :group 'org-faces)

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
  (let* ((progress-percent (/ (float progress) (float goal)))
         (progress-width (floor (* progress-percent width)))
         (progress (make-string (min (max 0 progress-width) width) ?|))
         (spacer (make-string (max 0 (- width progress-width)) ?.))
         (face (cond
                ((>= progress-percent 1.0) 'org-time-budgets-done-face)
                ((> progress-percent 0.7) 'org-time-budgets-close-face)
                (t 'org-time-budgets-todo-face))))
    (concat
     (propertize progress 'face face)
     spacer)))

(defun org-time-budgets-time (filters)
  "Return the clocked time matching FILTERS in agenda files."
  (apply '+
         (mapcar (lambda (file)
                   (nth 1 (save-window-excursion
                            (find-file file)
                            (org-clock-get-table-data file filters))))
                 (org-agenda-files))))

(defun org-time-budgets-format-block (block)
  (let ((current (case block
                   (day     (org-time-budgets-time `(:match ,match :block today)))
                   (workday (org-time-budgets-time `(:match ,match :block today)))
                   (week    (org-time-budgets-time `(:match ,match :tstart ,tstart-s :tend ,tend-s)))))
        (budget (case block
                  (day     (/ range-budget 7))
                  (workday (/ range-budget 5))
                  (week    range-budget))))
    (if (and current budget)
        (format "[%s] %s / %s"
                (org-time-budgets-bar 14 current budget)
                (org-time-budgets-minutes-to-string current)
                (org-time-budgets-minutes-to-string budget))
      "                              ")))

(defun org-time-budgets-table ()
  "List the time budgets in a table."
  (let ((title-column-width (apply #'max
                                   (mapcar #'(lambda (budget) (string-width (plist-get budget :title)))
                                           org-time-budgets))))
    (mapconcat #'(lambda (budget)
                  (let* ((title (plist-get budget :title))
                         (match (or (plist-get budget :match)
                                    (plist-get budget :tags))) ;; support for old :tags syntax
                         (blocks (or (plist-get budget :blocks)
                                     (case (plist-get budget :block) ;; support for old :block syntax
                                       (week '(day week))
                                       (workweek '(workday week)))
                                     '(day week)))
                         (trange (org-clock-special-range 'thisweek))
                         (tstart (nth 0 trange))
                         (tstart-s (format-time-string "[%Y-%m-%d]" tstart))
                         (tend (nth 1 trange))
                         (tend-s (format-time-string "[%Y-%m-%d]" tend))
                         (days-til-week-ends (ceiling
                                              (time-to-number-of-days
                                               (time-subtract tend (current-time)))))
                         (range-budget (org-time-budgets-string-to-minutes (plist-get budget :budget))))
                    (format "%s  %s"
                             (concat
                              title
                              (make-string (max 0 (- title-column-width (string-width title))) ?\s))
                             (mapconcat
                              #'org-time-budgets-format-block
                              blocks
                              "  "))))
               org-time-budgets
               "\n")))

(defun org-time-budgets-in-agenda (arg)
  "Insert the `org-time-budget-table' at the top of the current
agenda."
  (save-excursion
    (let ((agenda-start-day (nth 1 (get-text-property (point) 'org-last-args)))
          (inhibit-read-only t))
      ;; find top of agenda
      (while (not (and (get-text-property (point) 'org-date-line)
                       (equal (get-text-property (point) 'day) agenda-start-day)))
        (forward-line -1))
      (insert (org-time-budgets-table) "\n\n"))))

(defun org-time-budgets-in-agenda-maybe (arg)
  "Return budgets table if org-time-budgets-show-budgets is set."
  (when org-time-budgets-show-budgets
    (org-time-budgets-in-agenda arg)))

(defun org-time-budgets-toggle-time-budgets ()
  "Toggle display of time-budgets in an agenda buffer."
  (interactive)
  (org-agenda-check-type t 'agenda)
  (setq org-time-budgets-show-budgets (not org-time-budgets-show-budgets))
  (org-agenda-redo)
  (org-agenda-set-mode-name)
  (message "Time-Budgets turned %s"
           (if org-time-budgets-show-budgets "on" "off")))

;; free agenda-mode-map keys are rare
(org-defkey org-agenda-mode-map "V" 'org-time-budgets-toggle-time-budgets)

(provide 'org-time-budgets)

;;; org-time-budgets.el ends here
