;;; reaper.el --- Interact with Harvest time tracking app  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Thomas Fini Hansen

;; Author: Thomas Fini Hansen <xen@xen.dk>
;; Created: August 11, 2019
;; Version: 1.0.0
;; Package-Version: 20201121.2302
;; Package-Commit: 93d21a26ca022d3929749a82498891054092094b
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tools
;; Url: https://github.com/xendk/reaper

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

;; Interactive tool for tracking time with Harvest.

(require 'cl-lib)
(require 'json)
(require 'url)

;; Declare what we're using from elsewhere.
(declare-function ivy-read "ivy")
(defvar calc-eval-error)

(defgroup reaper nil
  "Reaper configuration."
  :prefix "reaper-"
  :group 'communication)

(defcustom reaper-api-key ""
  "API key used to authenticate with Harvest."
  :type 'string
  :group 'reaper)

(defcustom reaper-account-id ""
  "Account id for Harvest."
  :type 'string
  :group 'reaper)

(defconst reaper--list-format
  [("Project" 32 nil)
   ("Task" 20 nil)
   ("Time" 5 nil)
   ("Note" 40 nil)
   ]
  "Reaper list format.")

(defconst reaper--time-regexp
  (rx (optional (group-n 1 (optional digit)) ":") (group-n 2 (one-or-more digit))))

;;; Code:
(defvar reaper-buffer-name " *Reaper*"
  "Name for Reaper buffer.")

(defvar reaper-total-hours 0
  "Total hours tracked on the currently selected day in the reaper buffer.")

(defvar reaper-running-hours 0
  "Hours tracked on the currently running timer.")

(defvar-local reaper-timeentries nil
  "Cache of Harvest time entries.")

(defvar-local reaper-project-tasks nil
  "Cache of projects and tasks.")

(defvar-local reaper-running-timer nil
  "Currently running timer.")

(defvar-local reaper-fetch-time nil
  "Timestamp of last fetch.")

(defvar-local reaper-date nil
  "Date displayed in Reaper buffer.")

(defvar-local reaper-update-timer nil
  "Timer for updating buffer.")

(defvar reaper-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "r") #'reaper-refresh-buffer)
    (define-key map (kbd "g") #'reaper-refresh)
    (define-key map (kbd "d") #'reaper-goto-date)
    (define-key map (kbd "f") #'reaper-goto-date+1)
    (define-key map (kbd "b") #'reaper-goto-date-1)
    (define-key map (kbd "SPC") #'reaper-start-timer)
    (define-key map (kbd "RET") #'reaper-start-timer-and-quit-window)
    (define-key map (kbd "c") #'reaper-start-new-timer)
    (define-key map (kbd "s") #'reaper-stop-timer)
    (define-key map (kbd "k") #'reaper-delete-entry)
    (define-key map (kbd "e e") #'reaper-edit-entry)
    (define-key map (kbd "e p") #'reaper-edit-entry-project)
    (define-key map (kbd "e t") #'reaper-edit-entry-task)
    (define-key map (kbd "e d") #'reaper-edit-entry-description)
    (define-key map (kbd "t") #'reaper-edit-entry-time)
    (define-key map (kbd "DEL") #'reaper-delete-entry)
    (define-key map (kbd "Q") #'reaper-kill-buffer)
    map)
  "Keymap for Harvest mode.")

(define-derived-mode reaper-mode tabulated-list-mode "Reaper"
  "Major mode for Reaper buffer.
\\<reaper-mode-map>
"
  :group 'reaper
  :syntax-table nil
  :abbrev-table nil
  (buffer-disable-undo)
  (kill-all-local-variables)
  (use-local-map reaper-mode-map)
  (setq buffer-read-only t
        truncate-lines t
        ;; Start with current date.
        reaper-date (format-time-string "%Y-%m-%d")
        ;; In special-mode, these get set up automatically, but in
        ;; tabulated-list-mode we have to do it ourselves.
        mode-name "Reaper"
        major-mode 'reaper-mode
        tabulated-list-format reaper--list-format
        tabulated-list-entries #'reaper--list-entries
        tabulated-list-padding 3)
  (reaper-refresh-buffer)
  ;; Start a timer to update the running timer.
  (setq reaper-update-timer (run-at-time t 60 #'reaper--update-timer))
  (add-hook 'kill-buffer-hook #'reaper-kill-buffer-hook))

(defmacro reaper-with-buffer (&rest body)
  "Run BODY with the Reaper buffer as current."
  `(with-current-buffer (reaper--buffer)
     ,@body))

;;;###autoload
(defun reaper ()
  "Open Reaper buffer."
  (interactive)
  (reaper--check-credentials)
  (reaper-with-buffer
   (select-window (display-buffer (current-buffer)))))

(defun reaper-kill-buffer-hook ()
  "Cancel running timers when the buffer gets killed."
  (when reaper-update-timer
    (cancel-timer reaper-update-timer)
    (setq reaper-update-timer nil)))

(defun reaper-refresh ()
  "Refresh data from Harvest and update buffer."
  (interactive)
  (reaper-with-buffer
   (setq reaper-timeentries nil)
   (reaper-refresh-buffer)))

(defun reaper-refresh-entries ()
  "Fetch time-entries from Harvest."
  (reaper--check-credentials)
  (reaper-with-buffer
   (message "Refreshing data from Harvest...")
   (let* ((response-entries
           (reaper-alist-get '(time_entries)
                             (reaper-api "GET"
                                         (format "time_entries?from=%s&to=%s&user_id=%s"  reaper-date reaper-date (reaper--get-user-id))
                                         nil
                                         "Refreshed cache of daily entries")))
          (request-time (current-time)))
     (setq reaper-running-timer nil)
     (setq reaper-timeentries
           (mapcar
            (lambda (entry)
              (when (reaper-alist-get '(is_running) entry)
                (setq reaper-running-timer (reaper-alist-get '(id) entry)))
              (cons (reaper-alist-get '(id) entry)
                    (list
                     (cons :id (reaper-alist-get '(id) entry))
                     (cons :project_id (reaper-alist-get '(project id) entry))
                     (cons :project (reaper-alist-get '(project name) entry))
                     (cons :task_id (reaper-alist-get '(task id) entry))
                     (cons :task (reaper-alist-get '(task name) entry))
                     (cons :is_running (reaper-alist-get '(is_running) entry))
                     (cons :hours (reaper-alist-get '(hours) entry))
                     (cons :notes (let ((notes (reaper-alist-get '(notes) entry)))
                                    (if notes (decode-coding-string notes 'utf-8) ""))))))
            ;; API returns newest entry first. Simply reverse the list.
            (reverse response-entries)))
     (setq reaper-fetch-time request-time))))

(defun reaper-refresh-project-tasks ()
  "Fetch projects and tasks from Harvest."
  (reaper-with-buffer
   (unless reaper-project-tasks
     (message "Refreshing projects and tasks from Harvest, please hold.")
     (let ((reaper-project-tasks-response
            (reaper-alist-get '(project_assignments)
                              (reaper-api "GET"
                                          "users/me/project_assignments"
                                          nil
                                          "Refreshed projects and tasks."))))
       (setq reaper-project-tasks
             (mapcar
              (lambda (entry)
                (cons (reaper-alist-get '(project id) entry)
                      (list
                       (cons :id (reaper-alist-get '(project id) entry))
                       (cons :name (reaper-alist-get '(project name) entry))
                       (cons :code (reaper-alist-get '(project code) entry))
                       (cons :client (reaper-alist-get '(client name) entry))
                       (cons :tasks (mapcar
                                     (lambda (task)
                                       (cons (reaper-alist-get '(task id) task) (reaper-alist-get '(task name) task)))
                                     (reaper-alist-get '(task_assignments) entry))))))
              reaper-project-tasks-response))))))

(defun reaper-refresh-buffer ()
  "Refresh Reaper buffer."
  (interactive)
  (unless (bound-and-true-p reaper-timeentries)
    (reaper-refresh-entries))
  (tabulated-list-init-header)
  (tabulated-list-print t)
  (reaper--highlight-running))

(defun reaper--goto-date (date-string)
  "Go to a date.

DATE-STRING can be given in ISO like format, year-month-day, with
- or . as a seperator.

Year and month can be left out and are assumed to be current,
unless the day number is equal or greater than todays date, in
which case the month is the previous.

Alternatively +<days>/-<days> can be used to move X days
forward/back from reaper-date."
  (let* ((date (reaper--parse-date-string date-string)))
    (if date
        (progn
          (setq reaper-date date)
          (reaper-refresh))
      (user-error "Invalid date %s" date-string))))

(defun reaper-goto-date ()
  "Go to new date.

Dates are given in ISO like format, year-month-day, with - or .
as a seperator.

Year and month can be left out and are assumed to be current,
unless the day number is equal or greater than todays date, in
which case the month is the previous.

Alternatively +<days>/-<days> can be used to move X days
forward/back from reaper-date."
  (interactive)
  (reaper--goto-date (read-string "Goto date: ")))

(defun reaper-goto-date+1 ()
  "Go a day forward."
  (interactive)
  (reaper--goto-date "+1"))

(defun reaper-goto-date-1 ()
  "Go a day back."
  (interactive)
  (reaper--goto-date "-1"))

(defun reaper-start-timer ()
  "Start the timer at point.
Stops any previously running timers."
  (interactive)
  (when (tabulated-list-get-id)
    (reaper-api "PATCH" (format "time_entries/%s/restart" (tabulated-list-get-id)) nil "Started timer")
    (reaper-refresh)))

(defun reaper-stop-timer ()
  "Stop running timer."
  (interactive)
  (when reaper-running-timer
    (reaper-api "PATCH" (format "time_entries/%s/stop" reaper-running-timer) nil "Stopped timer")
    (reaper-refresh)))

(defun reaper-start-timer-and-quit-window ()
  "Start timer at point and close window."
  (interactive)
  (reaper-start-timer)
  (quit-window))

(defun reaper-start-new-timer ()
  "Create a new running timer."
  (interactive)
  (unless (bound-and-true-p reaper-project-tasks)
    (reaper-refresh-project-tasks))
  (let* (
         (project (reaper-read-project (cdr (assoc :id (cdr (car reaper-project-tasks))))))
         (task-id (reaper-read-task project (car (car (cdr (assoc :tasks project))))))
         (notes (read-string "Description: "))
         (harvest-payload (make-hash-table :test 'equal)))
    (puthash "project_id" (cdr (assoc :id project)) harvest-payload)
    (puthash "task_id" task-id harvest-payload)
    (puthash "spent_date" (format-time-string "%Y-%m-%d") harvest-payload)
    (puthash "notes" notes harvest-payload)
    (reaper-api "POST" "time_entries" harvest-payload "Started timer")
    (reaper--last-used project task-id)
    (reaper-refresh)))

(defun reaper-delete-entry ()
  "Delete time entry at point."
  (interactive)
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries)))
    (when (and entry
               (yes-or-no-p (format "Are you sure you want to delete \"%s - %s: %s"
                                    (cdr (assoc :project entry))
                                    (cdr (assoc :task entry))
                                    (cdr (assoc :notes entry)))))
      ;; Go forward a line, so tabulated-list-mode has an entry to
      ;; stick to.
      (forward-line 1)
      (unless (tabulated-list-get-id)
        ;; If there's no entry on the following line, go back to the
        ;; previous instead.
        (forward-line -2))
      (reaper-api "DELETE" (format "time_entries/%s" entry-id) nil "Deleted entry")
      (reaper-refresh))))

(defun reaper-kill-buffer ()
  "Kill reaper buffer. Will remove timers and cached data."
  (interactive)
  (kill-buffer reaper-buffer-name))

(defun reaper-edit-entry ()
  "Edit entry at point."
  (interactive)
  (unless (bound-and-true-p reaper-project-tasks)
    (reaper-refresh-project-tasks))
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries)))
    (when entry
      (let* ((project (reaper-read-project (cdr (assoc :project_id entry))))
             (task-id (reaper-read-task project (cdr (assoc :task_id entry))))
             (notes (read-string "Description: " (cdr (assoc :notes entry))))
             (harvest-payload (make-hash-table :test 'equal)))
        (puthash "project_id" (cdr (assoc :id project)) harvest-payload)
        (puthash "task_id" task-id harvest-payload)
        (puthash "notes" notes harvest-payload)
        (reaper-api "PATCH" (format "time_entries/%s" entry-id) harvest-payload "Updated entry")
        (reaper-refresh)))))

(defun reaper-edit-entry-project ()
  "Edit project of entry at point."
  (interactive)
  (unless (bound-and-true-p reaper-project-tasks)
    (reaper-refresh-project-tasks))
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries)))
    (when entry
      (let* ((project (reaper-read-project (cdr (assoc :project_id entry))))
             ;; When changing project, the possible tasks change too.
             ;; So if the new project doesn't have the current task,
             ;; we need to ask for it.
             (current-task-id (cdr (assoc :task_id entry)))
             (task-id
              (if (assoc current-task-id (cdr (assoc :tasks project)))
                  current-task-id
                (reaper-read-task project (cdr (assoc :task_id entry)))))
             (harvest-payload (make-hash-table :test 'equal)))
        (puthash "project_id" (cdr (assoc :id project)) harvest-payload)
        (puthash "task_id" task-id harvest-payload)
        (reaper-api "PATCH" (format "time_entries/%s" entry-id) harvest-payload "Updated entry")
        (reaper-refresh)))))

(defun reaper-edit-entry-task ()
  "Edit task of entry at point."
  (interactive)
  (unless (bound-and-true-p reaper-project-tasks)
    (reaper-refresh-project-tasks))
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries)))
    (when entry
      (let* ((project (cdr (assoc (cdr (assoc :project_id entry)) reaper-project-tasks)))
             (task-id (reaper-read-task project (cdr (assoc :task_id entry))))
             (harvest-payload (make-hash-table :test 'equal)))
        (puthash "task_id" task-id harvest-payload)
        (reaper-api "PATCH" (format "time_entries/%s" entry-id) harvest-payload "Updated entry")
        (reaper-refresh)))))

(defun reaper-edit-entry-description ()
  "Edit description of entry at point."
  (interactive)
  (unless (bound-and-true-p reaper-project-tasks)
    (reaper-refresh-project-tasks))
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries)))
    (when entry
      (let* ((notes (read-string "Description: " (cdr (assoc :notes entry))))
             (harvest-payload (make-hash-table :test 'equal)))
        (puthash "notes" notes harvest-payload)
        (reaper-api "PATCH" (format "time_entries/%s" entry-id) harvest-payload "Updated entry")
        (reaper-refresh)))))

(defun reaper-edit-entry-time ()
  "Edit time of entry at point."
  (interactive)
  (let* ((entry-id (tabulated-list-get-id))
         (entry (assoc entry-id reaper-timeentries))
         ;; If the timer is running add the time since the data was fetched.
         (time (reaper--hours-to-time (reaper--hours-accounting-for-running-timer entry)))
         (new-time (reaper--time-to-hours-calculation (read-string "New time: " time)))
         (harvest-payload (make-hash-table :test 'equal)))
    (puthash "hours" new-time harvest-payload)
    (reaper-api "PATCH" (format "time_entries/%s" entry-id) harvest-payload "Updated entry")
    (reaper-refresh)))

(defun reaper-read-project (&optional default)
  "Read a project from the user. Default to DEFAULT."
  (let* ((projects (mapcar (lambda (project)
                             (cons (concat "[" (cdr (assoc :code project)) "] " (cdr (assoc :name project))) project))
                           reaper-project-tasks))
         (default (cdr (assoc default reaper-project-tasks)))
         (default-option (when default (concat "[" (cdr (assoc :code default)) "] " (cdr (assoc :name default)))))
         (project (cdr (assoc (reaper--completing-read "Project: " projects default-option) projects))))
    project))

(defun reaper-read-task (project &optional default)
  "Read a task for PROJECT from the user. Default to DEFAULT.
Returns task id."
  (let*
      ((tasks (mapcar (lambda (task) (cons (cdr task) (car task))) (cdr (assoc :tasks project))))
       (default (when default (cdr (assoc default (cdr (assoc :tasks project))))))
       (task-id (cdr (assoc (reaper--completing-read "Task: " tasks default) tasks))))
    task-id))

(defun reaper-api (method path payload completion-message)
  "Make an METHOD call to PATH with PAYLOAD and COMPLETION-MESSAGE."
  (reaper--check-credentials)
  (let* ((url-request-method method)
         ;;(url-set-mime-charset-string)
         (url-mime-language-string nil)
         (url-mime-encoding-string nil)
         (url-mime-accept-string "application/json")
         (url-personal-mail-address nil)
         (url-request-data (if (or (string-equal method "POST")
                                   (string-equal method "PATCH"))
                               (encode-coding-string (json-encode payload) 'utf-8)
                             nil))
         (request-url (format "https://api.harvestapp.com/v2/%s" path))
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("Authorization" . ,(concat "Bearer " reaper-api-key))
            ("Harvest-Account-Id" . ,reaper-account-id)
            ("User-Agent" . "Xen's Emacs client (fini@reload.dk)"))))
    (with-temp-buffer
      (reaper-url-insert-file-contents request-url)
      (goto-char (point-min))
      (message "%s" completion-message)
      ;; Ensure JSON false values is nil.
      (defvar json-false)
      (let ((json-false nil))
        (json-read)))))

(defun reaper-url-insert-file-contents (url &optional visit beg end replace)
  "Quiet version of `url-insert-file-contents'.
URL, VISIT, BEG, END and REPLACE is the same as for
`url-insert-file-contents'."
  (let ((buffer (url-retrieve-synchronously url t)))
    (unless buffer (signal 'file-error (list url "No Data")))
    (when (fboundp 'url-http--insert-file-helper)
      ;; XXX: This is HTTP/S specific and should be moved to url-http
      ;; instead.  See bug#17549.
      (url-http--insert-file-helper buffer url visit))
    (url-insert-buffer-contents buffer url visit beg end replace)))

(defun reaper-alist-get (symbols alist)
  "Look up the value for the chain of SYMBOLS in ALIST."
  (if symbols
      (reaper-alist-get (cdr symbols)
                        (assoc (car symbols) alist))
    (cdr alist)))

(defun reaper--update-timer ()
  "Update running timers in reaper buffer. Called by `run-at-time'."
  (when (get-buffer reaper-buffer-name)
    (reaper-with-buffer
     (reaper-refresh-buffer))))

(defun reaper--check-credentials ()
  "Check if Harvest credetials are set, or trigger an user error."
  (when (or (string= "" reaper-api-key) (string= "" reaper-account-id))
    (user-error "Please customize reaper-api-key and reaper-account-id")))

(defun reaper--buffer ()
  "Return reaper buffer.
Will create it if it doesn't exist yet."
  (or
   (get-buffer reaper-buffer-name)
   (with-current-buffer (get-buffer-create reaper-buffer-name)
     (reaper-mode)
     ;; Start out on the last entry.
     ;; (goto-char (point-max))
     ;; (forward-line -1)
     (current-buffer))))

(defun reaper--get-user-id ()
  "Return the Harvest user id of the current user."
  (or
   (reaper-alist-get '(id) (reaper-api "GET"
                                       "users/me"
                                       nil
                                       "Fetched user information"))
   (error "Could not fetch user id")))

(defun reaper--list-entries ()
  "Return list of entries for `tabulated-list-mode'."
  (reaper-with-buffer
   (unless (bound-and-true-p reaper-timeentries)
     (reaper-refresh-entries))
   (setq reaper-total-hours 0)
   (let
       ((entries (cl-loop for (id . entry) in reaper-timeentries
                          collect (list
                                   id
                                   (vector
                                    (cdr (assoc :project entry))
                                    (cdr (assoc :task entry))
                                    (let ((hours (reaper--hours-accounting-for-running-timer entry)))
                                      (setq reaper-total-hours (+ hours reaper-total-hours))
                                      (reaper--hours-to-time hours))
                                    ;; For running timer, use time since timer_started_at.
                                    ;; Replace newlines as they mess with tabulated-list-mode.
                                    (replace-regexp-in-string "\n" "\\\\n" (cdr (assoc :notes entry))))))))
     (append
      entries
      (list
       (list nil (vconcat [] (mapcar (lambda (x) (make-string (elt x 1) ?-)) reaper--list-format)))
       (list nil (vector "Total" "" (reaper--hours-to-time reaper-total-hours) "")))))))

(defun reaper--highlight-running ()
  "Highlight the currently running timer."
  (save-excursion
    (while (not (eobp))
      (tabulated-list-put-tag (if (and reaper-running-timer (eq (tabulated-list-get-id) reaper-running-timer)) "->" ""))
      (forward-line 1))))

(defun reaper--hours-to-time (hours)
  "Convert Harvest HOURS to a time string."
  (format "%d:%02d" (truncate hours) (floor (* 60 (- hours (truncate hours))))))

(defun reaper--time-to-hours-calculation (string)
  "Convert a time calculation STRING to hours.
A calculation is a number of time strings (as parsed by
`reaper--time-to-hours') separated by + or -."
  ;; Error out if string contains other characters than numbers,
  ;; colon, plus and minus. Calc might handle it alright, but due to
  ;; the time parsing even simple things like 2*10 produce unexpected
  ;; results, so let's disallow it.
  (unless (string-match (rx bos (1+ (any ?: ?+ ?- num)) eos) string)
    (user-error "Invalid hours calculation string"))
  ;; Let calc do the heavy lifting.
  (let ((calc-eval-error t))
    (string-to-number (calc-eval (replace-regexp-in-string
                                  reaper--time-regexp
                                  (lambda (num) (number-to-string (reaper--time-to-hours num)))
                                  string)))))

(defun reaper--time-to-hours (time)
  "Convert TIME to hours.
TIME is in HH:MM or MM format. Returns a float."
  (when (string-match (rx bos (regexp reaper--time-regexp) eos) time)
    (let ((hours (match-string-no-properties 1 time))
          (minutes (string-to-number (match-string-no-properties 2 time))))
      (+ (if hours (string-to-number hours) 0) (/ (float minutes) 60)))))

(defun reaper--parse-date-string (date-string)
  "Pass DATE-STRING into canonical Y-m-d format.

Dates are given in ISO like format, year-month-day, with - or .
as a seperator.

Year and month can be left out and are assumed to be current,
unless that would put the date in the future, in which case it
goes back a month or year.

If date is a number prefixed with -/+, it goes back/forward that
many days from reaper-date."
  (let ((current-date (decode-time (current-time)))
        (current-reaper-date (split-string reaper-date "[-]")))
    (if (string-match (rx bos (group-n 1 (any ?+ ?-) (one-or-more digit)) eos) date-string)
        (let* ((days-offset (string-to-number (match-string-no-properties 1 date-string))))
          (format-time-string "%Y-%m-%d" (encode-time 59 59 23
                                                      (+ (string-to-number (nth 2 current-reaper-date)) days-offset)
                                                      (string-to-number (nth 1 current-reaper-date))
                                                      (string-to-number (nth 0 current-reaper-date)))))
      (let* ((parts (reverse (split-string date-string "[-\.]")))
             (day (string-to-number (nth 0 parts)))
             (month (and (nth 1 parts) (string-to-number (nth 1 parts))))
             (year (and (nth 2 parts) (string-to-number (nth 2 parts))))
             (target-time (encode-time 59 59 23
                                       day
                                       (or month (nth 4 current-date))
                                       (or year (nth 5 current-date))))
             (target-time-month-ago (encode-time 59 59 23
                                                 day
                                                 (- (or month (nth 4 current-date)) 1)
                                                 (or year (nth 5 current-date))))
             (target-time-year-ago (encode-time 59 59 23
                                                day
                                                (or month (nth 4 current-date))
                                                (- (or year (nth 5 current-date)) 1)))
             (time (cond
                    ;; On empty input day is still parsed as 0
                    ;; (string-to-number "") returns 0.
                    ((< day 1) (current-time))
                    ((time-less-p target-time (current-time)) target-time)
                    ((and (not (nth 1 parts))
                          (time-less-p target-time-month-ago (current-time)))
                     target-time-month-ago)
                    ((and (not (nth 2 parts))
                          (time-less-p target-time-year-ago (current-time)))
                     target-time-year-ago)
                    (t nil))))
        (and time (format-time-string "%Y-%m-%d" time))))))

(defun reaper--hours-accounting-for-running-timer (entry)
  "Return hours from ENTRY, adding in time since request if the timer is running."
  (+  (cdr (assoc :hours entry))
      (if (cdr (assoc :is_running entry))
          (+ (/ (/ (time-to-seconds (time-subtract (current-time)
                                                   reaper-fetch-time)) 60) 60))
        0)))

(defun reaper--completing-read (prompt options default)
  "Complete with PROMPT, with OPTIONS and having DEFAULT.
Wraps `completing-read', or `ivy-read', in order to sort options
in last used order when using ivy."
  (if (eq completing-read-function 'ivy-completing-read)
      (ivy-read
       prompt options
       :require-match t
       :preselect default
       :def default)
    (completing-read prompt options nil t nil nil default)))

(defun reaper--last-used (project task-id)
  "Save PROJECT and TASK-ID as last used."
  ;; Simply move the last used project to the top of the list, and the
  ;; last used task to the top of the list of tasks on the project.
  (setq reaper-project-tasks (delq project reaper-project-tasks))
  (let* ((tasks (cdr (assoc :tasks project)))
         (task (assoc task-id tasks)))
    (cons task (delq task tasks))
    (setf (cdr (assoc :tasks project)) (cons task (delq task tasks))))
  (push project reaper-project-tasks))

(provide 'reaper)
;;; reaper.el ends here
