;;; harvest.el --- Harvest integration
;;
;; Copyright (C) 2016  Kosta Harlan

;; Author: Kosta Harlan <kosta@kostaharlan.net>
;; Maintainer: Kosta Harlan <kosta@kostaharlan.net>
;; Homepage: https://github.com/kostajh/harvest.el
;; Keywords: harvest
;; Package-Version: 20170822.1746
;; Package-Commit: 7acbc0564b250521b67131ee2a0a92720239454f
;; Package-Requires: ((swiper "0.7.0") (hydra "0.13.0") (s "1.11.0"))
;;
;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; harvest.el provides integration with the Harvest time
;; tracking service (getharvest.com).  The package supports creating and
;; modifying time entries for the current day.  To begin, run
;; M-x harvest-authenticate, and then M-x harvest to get started with
;; logging time.

;;; Code:

(require 'url)
(require 'json)
(require 'ivy)
(require 'hydra)
(require 's)

(defvar hydra-harvest nil)
(defvar harvest-cached-daily-entries nil)
(defvar hydra-harvest-day-entry nil)
(defvar harvest-selected-entry nil)
(defvar harvest-dot-directory (concat user-emacs-directory ".harvest"))
(defvar harvest-dot-directory-auth (concat harvest-dot-directory "/auth.el"))

(defhydra hydra-harvest ()
  "harvest"
  ("v" (harvest-search-daily-entries) "view day entries" :color blue)
  ("n" (harvest-create-new-entry) "new entry")
  ("o" (harvest-clock-out) "clock out" :color pink)
  ("r" (harvest-refresh-entries) "refresh entries")
  ("q" nil "quit"))

(defhydra hydra-harvest-day-entry ()
  "day entry"
  ("d" (harvest-edit-description harvest-selected-entry) "edit description")
  ("h" (harvest-edit-hours harvest-selected-entry) "edit hours")
  ("t" (harvest-toggle-timer-for-entry harvest-selected-entry) "toggle timer")
  ("q" hydra-harvest/body "quit" :exit t))

(defun harvest-authenticate()
  "Authenticate with Harvest. Stores basic auth credentials and subdomain"
  (interactive)
  (let ((harvest-auth-hash (make-hash-table :test 'equal)))
    (puthash "subdomain" (read-string "Enter the subdomain (e.g.'example' for a site like 'example.harvestapp.com'): ") harvest-auth-hash)
    (puthash "auth" (concat "Basic " (base64-encode-string (concat (read-string "Enter your username: ") ":" (read-passwd "Enter your password: ")))) harvest-auth-hash)
    (unless (file-exists-p harvest-dot-directory)
      (mkdir harvest-dot-directory))
    (if (file-exists-p harvest-dot-directory-auth)
        (delete-file harvest-dot-directory-auth))
    (create-file-buffer harvest-dot-directory-auth)
    (let (print-length print-level)
      (write-region (prin1-to-string harvest-auth-hash) nil harvest-dot-directory-auth harvest-auth-hash)
      (message (format "Credentials stored in '%s'" harvest-dot-directory-auth))
      ))
  (message "Retrieving data from Harvest")
  (harvest-refresh-entries)
  (hydra-harvest/body))

(defun harvest-get-credentials()
  "Load credentials from the auth.el file"
  (if (file-exists-p harvest-dot-directory-auth)
      (progn
        (with-temp-buffer
          (insert-file-contents harvest-dot-directory-auth)
          (read (buffer-string))))
    (message (format "No file exists at '%s'. Try running harvest-authenticate()" harvest-dot-directory-auth))))

;;;###autoload
(defun harvest ()
  "Start the main Harvest hydra."
  (interactive)
  (hydra-harvest/body))

(defun harvest-refresh-entries()
  "Refresh the local cache of day entries and projects/tasks. N.B. this is called before harvest-clock-in, so you usually don't need to run this yourself."
  (interactive)
  (setq harvest-cached-daily-entries (harvest-api "GET" "daily" nil "Refreshed cache of daily entries")))

(defun harvest-search-daily-entries ()
  "Ivy interface to search through day entries."
  (harvest-refresh-entries)
  ;; TODO: Sort by most recent entry.
  (ivy-read "Day entries: "
            (mapcar (lambda (entry)
                      (cons (harvest-format-entry entry) entry))
                    (harvest-alist-get '(day_entries) harvest-cached-daily-entries))
            :require-match t
            :action (lambda (x)
                      (setq harvest-selected-entry x)
                      (hydra-harvest-day-entry/body)))
  )

(defun harvest-create-new-entry ()
  "Create a new entry for a particular project and task."
  ;; TODO: Sort by name.
  (ivy-read "Project: "
            (mapcar (lambda (entry)
                      (cons (harvest-format-project-entry entry) entry))
                    (harvest-alist-get '(projects) harvest-cached-daily-entries))
            :require-match t
            :action (lambda (x)
                      (setq harvest-selected-entry x)
                      (ivy-read "Task: "
                                (harvest-get-tasks-for-project harvest-selected-entry)
                                :require-match t
                                :action (lambda (selection)
                                          (harvest-clock-in-project-task-entry nil selection))))
            ))

(defun harvest-alist-get (symbols alist)
  "Look up the value for the chain of SYMBOLS in ALIST."
  (if symbols
      (harvest-alist-get (cdr symbols)
                         (assoc (car symbols) alist))
    (cdr alist)))

(defun harvest-format-entry (entry)
  "Format an ENTRY as a string.
Format is PROJECT (CLIENT) \n TASK - NOTES"
  (let ((formatted-string (concat
                           (harvest-alist-get '(project) entry)
                           " ("
                           (harvest-alist-get '(client) entry)
                           ")"
                           "\n"
                           (harvest-alist-get '(task) entry)
                           " – "
                           (harvest-alist-get '(notes) entry)
                           "\t["
                           (number-to-string (harvest-alist-get '(hours) entry))
                           "]"
                           )))
    (if (harvest-alist-get '(timer_started_at) entry)
        (propertize formatted-string 'face '(:background "#D4F1FF" :foreground "#000000"))
      (propertize formatted-string 'face 'nil))))

(defun harvest-format-project-entry (entry)
  "Show available projects and clients to clock in for ENTRY."
  (concat (harvest-alist-get '(name) entry) " (" (harvest-alist-get '(client) entry) ")")
  )

(defun harvest-get-cached-daily-entries ()
  "Get daily entries from the variable, or query Harvest if not set."
  (if (boundp 'harvest-cached-daily-entries)
      harvest-cached-daily-entries
    (harvest-refresh-entries))
  harvest-cached-daily-entries)

(defun harvest-edit-description (entry)
  "Edit the description for a Harvest day ENTRY."
  (let ((harvest-payload (make-hash-table :test 'equal)))
    ;; Not ideal to overwrite hours in Harvest, but unless we do it,
    ;; the time entry is reset to 0.
    (puthash "hours" (harvest-alist-get '(hours) entry) harvest-payload)
    (puthash "project_id" (harvest-alist-get '(project_id) entry) harvest-payload)
    (puthash "task_id" (harvest-alist-get '(task_id) entry) harvest-payload)
    (puthash "notes" (read-string "Notes: " (harvest-alist-get '(notes) entry)) harvest-payload)
    (harvest-api "POST" (format "daily/update/%s" (harvest-alist-get '(id) entry)) harvest-payload (format "Updated notes for task %s in %s for %s" (harvest-alist-get '(task) entry) (harvest-alist-get '(project) entry) (harvest-alist-get '(client) entry))))
  (harvest-refresh-entries))

(defun harvest-edit-hours (entry)
  "Edit the description for a Harvest day ENTRY."
  (let ((harvest-payload (make-hash-table :test 'equal)))
    ;; Not ideal to overwrite hours in Harvest, but unless we do it,
    ;; the time entry is reset to 0.
    (puthash "hours" (read-number "Hours spent: " (harvest-alist-get '(hours) entry)) harvest-payload)
    (puthash "project_id" (harvest-alist-get '(project_id) entry) harvest-payload)
    (puthash "task_id" (harvest-alist-get '(task_id) entry) harvest-payload)
    (harvest-api "POST" (format "daily/update/%s" (harvest-alist-get '(id) entry)) harvest-payload (format "Updated hours for task %s in %s for %s" (harvest-alist-get '(task) entry) (harvest-alist-get '(project) entry) (harvest-alist-get '(client) entry))))
  (harvest-refresh-entries))

;;;###autoload
(defun harvest-clock-out ()
  "Clock out of any active timer."
  (interactive)
  (mapcar (lambda (entry)
            (if (harvest-alist-get '(timer_started_at) entry)
                (harvest-api "GET" (format "daily/timer/%s" (harvest-alist-get '(id) entry)) nil (message (format "Clocked out of %s in %s - %s" (harvest-alist-get '(task) entry) (harvest-alist-get '(project) entry) (harvest-alist-get '(client) entry))))))
          (harvest-alist-get '(day_entries) (harvest-get-cached-daily-entries)))
  (harvest-refresh-entries)
  )

(defun harvest-get-tasks-for-project (project)
  "Get all available tasks for PROJECT."
  (mapcar (lambda (task)
            (cons
             (harvest-alist-get '(name) task)
             (format "%d:%d" (harvest-alist-get '(id) project) (harvest-alist-get '(id) task))))
          (harvest-alist-get '(tasks) project)))

(defun harvest-api (method path payload completion-message)
  "Make an METHOD call to PATH with PAYLOAD and COMPLETION-MESSAGE."
  (let* ((harvest-auth (harvest-get-credentials))
         (url-request-method method)
         (url-set-mime-charset-string)
         (url-mime-language-string nil)
         (url-mime-encoding-string nil)
         (url-mime-accept-string "application/json")
         (url-personal-mail-address nil)
         (url-request-data (if (string-equal method "POST")
                               (json-encode payload)
                             nil))
         (request-url (concat "https://" (gethash "subdomain" harvest-auth) (format ".harvestapp.com/%s" path)))
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("Authorization" . ,(gethash "auth" harvest-auth)))))
    (with-current-buffer (url-retrieve-synchronously request-url)
      (goto-char (point-min))
      (search-forward "\n\n" nil t)
      (delete-region (point-min) (point))
      (message "%s" completion-message)
      (json-read)
      )))

(defun harvest-clock-in-project-task-entry (entry task)
  "Start a new timer for an ENTRY on a particular TASK.
Entry is actually not populated, which is why we need to split task on the
colon to retrieve project and task info."
  (let ((harvest-payload (make-hash-table :test 'equal)))
    (puthash "project_id" (car (s-split ":" (cdr task))) harvest-payload)
    (puthash "task_id" (car (cdr (s-split ":" (cdr task)))) harvest-payload)
    (puthash "notes" (read-string "Notes: ") harvest-payload)
    (harvest-api "POST" "daily/add" harvest-payload (format "Started new task: %s" (gethash "notes" harvest-payload))))
  (harvest-refresh-entries))

(defun harvest-toggle-timer-for-entry (entry)
  "Clock in or out of a given ENTRY."
  (if (assoc 'timer_started_at entry)
      (when (yes-or-no-p (format "Are you sure you want to clock out of %s?" (harvest-format-entry entry)))
        (harvest-api "GET" (format "daily/timer/%s" (harvest-alist-get '(id) entry)) nil (format "Clocked out of %s" (harvest-format-entry entry))))
    (when (yes-or-no-p (format "Are you sure you want to clock in for %s?" (harvest-format-entry entry)))
      (harvest-api "GET" (format "daily/timer/%s" (harvest-alist-get '(id) entry)) nil (format "Clocked in for of %s" (harvest-format-entry entry))))))

(provide 'harvest)
;;; harvest.el ends here
