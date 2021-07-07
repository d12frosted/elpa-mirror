;;; punctuality-logger.el --- Punctuality logger for Emacs

;; Copyright (C) 2014 Philip Woods

;; Author: Philip Woods <elzairthesorcerer@gmail.com>
;; Version: 0.8
;; Package-Version: 20141120.2031
;; Package-Commit: e09e5dd37bc92289fa2f7dc44aed51a7b5e04bb0
;; Keywords: reminder, calendar
;; URL: https://gitlab.com/elzair/punctuality-logger

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package helps you keep track of when you are on time
;; and when you are late to your various appointments.

;; Create a new entry with M-x punctuality-logger-new-entry
;; View all days with M-x punctuality-logger-all-days
;; View just the days you were late with M-x puntuality-logger-late-days

;; All of these functions are also available through the menu bar:
;; Tools->Punctuality Logger

;;; Code:

(require 'cl)

;; User Customization

(defgroup punctuality-logger
  '()
  "Log when you are on time and when you are late."
  :group 'applications)

(defcustom punctuality-logger-log-dir
  (expand-file-name "~/punctuality-log")
  "Location of Punctuality Logger's entries."
  :type 'string
  :group 'punctuality-logger)

(defcustom punctuality-logger-on-time-message-template
  "You were on time on %s."
  "Format string for displaying on-time entries."
  :type 'string
  :group 'punctuality-logger)

(defcustom punctuality-logger-late-message-template
  "You were %d minutes late on %s."
  "Format string for displaying late entries."
  :type 'string
  :group 'punctuality-logger)

(defcustom punctuality-logger-use-version-control
  '()
  "Whether or not Punctuality Logger uses Version Control."
  :type 'boolean
  :group 'punctuality-logger)

(defcustom punctuality-logger-version-control-command
  "git add -A . && git commit -m 'Added another entry' && git push"
  "Command to commit logs to version control (if available)."
  :type 'string
  :group 'punctuality-logger)

; Utility functions and macros

(defun punctuality-logger-pp (lst)
    "Pretty print LST."
  (mapconcat #'identity lst "\n"))

(defmacro punctuality-logger-out (bufname &rest body)
  "Write output to buffer.

BUFNAME is the name of the buffer to create and switch to.

BODY is the code to evaluate to obtain the output."
  `(progn (switch-to-buffer (generate-new-buffer ,bufname))
          (insert (punctuality-logger-pp ,@body))))

(defun punctuality-logger-current-date ()
    "Evaluate to current date in YYYY-MM-DD format."
  (format-time-string "%Y-%m-%d"))

(defun punctuality-logger-log-name ()
  "Evaluate to the name of the log for the current day."
  (expand-file-name (punctuality-logger-current-date)
                    punctuality-logger-log-dir))

(defun punctuality-logger-log-template (latep &optional minutes-late)
  "Create template for tardiness log entry.

LATEP is whether or not you were late.

MINUTES-LATE is how many minutes you were late."
  (cons `(latep ,latep)
        (if (and (bound-and-true-p latep) (boundp 'minutes-late))
            (list `(minutes-late ,minutes-late))
          nil)))

(defun punctuality-logger-format-template (entry)
    "Create output template for punctuality-log entry ENTRY."
  (if (first (alist-get 'latep entry))
      (format punctuality-logger-late-message-template
            (first (alist-get 'minutes-late entry))
            (first (alist-get 'date entry)))
      (format punctuality-logger-on-time-message-template
              (first (alist-get 'date entry)))))

(defun punctuality-logger-ensure-log-dir-exists ()
    "Ensure the directory to store log files has been created."
  (make-directory punctuality-logger-log-dir t))

(defun punctuality-logger-write-string-to-file (string file)
    "Write the string STRING to file FILE."
  (with-temp-buffer
    (insert string)
    (when (file-writable-p file)
      (write-region (point-min)
                    (point-max)
                    file))))

(defun punctuality-logger-commit-to-version-control ()
    "Commit change to version control."
    (let ((cur-dir default-directory))
      (cd punctuality-logger-log-dir)
      (shell-command punctuality-logger-version-control-command)
      (cd cur-dir)))

(defun punctuality-logger-append-log-dir (entries)
    "Append `punctuality-logger-log-dir' to ENTRIES."
  (mapcar #'(lambda (x) (expand-file-name x punctuality-logger-log-dir))
          entries))

(defun punctuality-logger-log-names (&optional start-date)
  "Retrieve the names of all logs from `punctuality-logger-log-dir'.

START-DATE is the date from which to start."
   (remove-if #'(lambda (x) (or (equal x ".")
                                (equal x "..")
                                (equal x ".git")
                                (and (bound-and-true-p start-date)
                                     (string< x start-date))))
              (directory-files punctuality-logger-log-dir)))

(defun punctuality-logger-read-log (file)
  "Read in the contents of log entry.

FILE is the name of the file (it is also appended to the result alist)."
  (with-temp-buffer
    (insert-file-contents (expand-file-name file
                                            punctuality-logger-log-dir))
    (append (list (list 'date file))
            (eval (read (concat "'" (buffer-string)))))))


(defun punctuality-logger-logs (&optional start-date)
    "Evaluate to an alist containing the name & info of the logs.

START-DATE is the (optional) date to start the results."
  (mapcar (lambda (x)
            (punctuality-logger-read-log x))
          (punctuality-logger-log-names start-date)))

(defun punctuality-logger-write-log (latep &optional minutes-late)
    "Create a new log entry for the current day.

LATEP is whether or not you were late.

MINUTES-LATE is how many minutes you were late."
  (punctuality-logger-ensure-log-dir-exists)
  (punctuality-logger-write-string-to-file
   (pp-to-string (punctuality-logger-log-template latep minutes-late))
   (punctuality-logger-log-name)))

(defun punctuality-logger-entries (test-func &optional start-date)
    "Evaluate to a list of days that meet the given criteria.

TEST-FUNC is the function to test if a given entry meets the criteria.

START-DATE is the (optional) date to start the results."
  (mapcar #'(lambda (x)
              (punctuality-logger-format-template x))
          (remove-if-not test-func (punctuality-logger-logs start-date))))

;; Interactive Functions

;;;###autoload
(defun punctuality-logger-new-entry ()
    "Create a new log entry for the current day."
    (interactive)
    (if (y-or-n-p "Were you late today? ")
      (punctuality-logger-write-log t
                                    (read-number "By how many minutes? "))
      (punctuality-logger-write-log nil))
    (when punctuality-logger-use-version-control
      (punctuality-logger-commit-to-version-control)))

;;;###autoload
(defun punctuality-logger-late-days (&optional start-date)
    "Evaluate to the list of days you were late.

START-DATE is the (optional) date to start the results."
    (interactive)
    (punctuality-logger-out
     "late-days"
     (punctuality-logger-entries
      (lambda (x) (equal t (first (alist-get 'latep x))))
      start-date)))

;;;###autoload
(defun punctuality-logger-all-days (&optional start-date)
    "Evaluate to the list of all dates.

START-DATE is the (optional) date to start the results."
    (interactive)
    (punctuality-logger-out
     "late-days"
     (punctuality-logger-entries
      (lambda (x) t)
      start-date)))

;; Menu Bindings

;;;###autoload
(define-key-after global-map
  [menu-bar tools punctuality-logger]
  (cons "Punctuality Logger" (make-sparse-keymap "major modes"))
  'kill-buffer)

;;;###autoload
(define-key global-map
  [menu-bar tools punctuality-logger list-all-days]
  '("View All Days" . punctuality-logger-all-days))

;;;###autoload
(define-key global-map
  [menu-bar tools punctuality-logger view-late-days]
  '("View Late Days" . punctuality-logger-late-days))

;;;###autoload
(define-key global-map
  [menu-bar tools punctuality-logger new-entry]
  '("New Entry" . punctuality-logger-new-entry))

(provide 'punctuality-logger)
;;; punctuality-logger.el ends here
