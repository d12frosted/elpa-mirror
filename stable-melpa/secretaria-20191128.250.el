;;; secretaria.el --- A personal assistant based on org-mode

;; Copyright (C) 2016-2019 Jorge Araya Navarro

;; Author: Jorge Araya Navarro <jorge@esavara.cr>
;; Keywords: org, convenience
;; Package-Commit: 03986130a2ada1fa952d45e83536729f20230fcf
;; Package-Requires: ((emacs "24.4") (alert "1.2") (s "1.12") (f "0.20.0") (org "9"))
;; Package-Version: 20191128.250
;; Package-X-Original-Version: 0.2.12
;; Homepage: https://gitlab.com/shackra/secretaria

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

;; # What's this?
;;
;; A personal assistant based on org-mode.  This package contains utilities that
;; enhance your experience with org-mode.
;;
;; # Features
;;
;; - Reminders
;;     - All tasks scheduled or which have a deadline set to "today", but have no time of the day
;;       specified.
;;     - The current clocked task, every N minutes (10 by default).
;;     - The current clocked task is saved in a file, Secretaria will alert you
;;       of that task when Emacs is restarted from a crash.
;;
;; # How to use
;;
;; This package should be available in Melpa, if you use `use-package`, throw this code snippet in your
;; Emacs configuration.
;;
;;     (use-package secretaria
;;       :config
;;       ;; use this for getting a reminder every 30 minutes of those tasks scheduled
;;       ;; for today and which have no time of day defined.
;;       (add-hook 'after-init-hook #'secretaria-unknown-time-always-remind-me))

;;; Prayer:

;; Domine Iesu Christe, Fili Dei, miserere mei, peccatoris
;; Κύριε Ἰησοῦ Χριστέ, Υἱὲ τοῦ Θεοῦ, ἐλέησόν με τὸν ἁμαρτωλόν.
;; אדון ישוע משיח, בנו של אלוהים, רחם עליי, החוטא.
;; Nkosi Jesu Kristu, iNdodana kaNkulunkulu, ngihawukele mina, isoni.
;; Señor Jesucristo, Hijo de Dios, ten misericordia de mí, pecador.
;; Herr Jesus Christus, Sohn Gottes, hab Erbarmen mit mir Sünder.
;; Господи, Иисусе Христе, Сыне Божий, помилуй мя грешного/грешную.
;; Sinjoro Jesuo Kristo, Difilo, kompatu min pekulon.
;; Tuhan Yesus Kristus, Putera Allah, kasihanilah aku, seorang pendosa.
;; Bwana Yesu Kristo, Mwana wa Mungu, unihurumie mimi mtenda dhambi.
;; Doamne Iisuse Hristoase, Fiul lui Dumnezeu, miluiește-mă pe mine, păcătosul.
;; 主耶穌基督，上帝之子，憐憫我罪人。

;;; Code:

(require 'alert)
(require 's)
(require 'org-clock)
(require 'org-duration)
(require 'subr-x)
(require 'f)
(require 'org)
(require 'org-agenda)
(require 'subr-x)
(eval-when-compile
  (require 'cl))

(defgroup secretaria nil
  "A personal assistant based on org-mode"
  :group 'org)

(defvar secretaria-uknown-time-reminder-timer nil
  "Timer for periodically remind the user about pending tasks.")

(defcustom secretaria-unknown-time-remind-time 30
  "Minutes before firing a reminder about tasks for today with no specified time of the day."
  :type 'integer
  :group 'secretaria)

(defvar secretaria-clocked-in-reminder-timer nil
  "A timer set when the user clocks in a task.")

(defcustom secretaria-clocked-in-reminder-every-minutes 10
  "Minutes before firing a reminder of the task clocked in."
  :type 'integer
  :group 'secretaria)

(defvar secretaria--org-url-regexp (rx "[[" (group (one-or-more (not (any "]")))) "][" (group (one-or-more (not (any "]")))) "]]")
  "Search for links in `org-mode' markup.")

(defcustom secretaria-notification-handler-overwrite t
  "Tells Secretaria we want to use her notification function with `org-show-notification-handler'.  WARNING: Change this if you know what you are doing!."
  :type 'bool
  :group 'secretaria)

(defcustom secretaria-notification-to-html nil
  "Convert org markup to HTML, otherwise to plain text if nil."
  :type 'bool
  :group 'secretaria)

(defcustom secretaria-clocked-task-save-file (locate-user-emacs-file "secretaria-clocked-task")
  "File which keeps the name of the current clocked in task."
  :type 'file
  :group 'secretaria)

(defun secretaria--skip-entry-if-done ()
  "Skip `org-mode' entries if they are DONE."
  (org-agenda-skip-entry-if 'todo 'done))

(defun secretaria--conditional-severity ()
  "Return a severity level for Alert if Emacs is ran as a daemon."
  (if (daemonp)
      'high
    'normal))

(defun secretaria--trim-replace (string)
  "Trim and replace any %d notation of STRING."
  (string-trim
   (replace-regexp-in-string "%[0-9]?d" "[0-9 ]+" string)))

(defun secretaria--leaders-prepare (&optional today)
  "Return a regexp for due `org-agenda' leaders.

If TODAY is non-nil, return a regexp string that will
match tasks scheduled or with deadline for today"
  (let* ((leaders))
    (if today
        (setf leaders `(,(nth 0 org-agenda-scheduled-leaders) ,(nth 0 org-agenda-deadline-leaders)))
      (setf leaders `(,(nth 1 org-agenda-scheduled-leaders) ,(nth 2 org-agenda-deadline-leaders))))
    (mapconcat 'identity (cl-map 'list #'secretaria--trim-replace leaders) "\\|")))

(defun secretaria-alert-due-appt ()
  "Tell the user about due TODOs tasks."
  (let ((due (length (secretaria-get-appt 'due))))
    (when (> due 0)
      (alert (format "Due entries: %s" due)
             :title "Attention, boss!"
             :severity 'high
             :mode 'org-mode))))

(defun secretaria-alert-unknown-time-appt ()
  "Tell the user about tasks scheduled for today.

Those tasks have no time of the day specified"
  (let ((appts (secretaria-get-appt 'unknown)))
    (dolist (entry appts)
      (alert "Task for today, time unspecified"
             :title (or entry "(no title)")
             :severity (secretaria--conditional-severity)
             :mode 'org-mode))))

(defun secretaria-alert-after-init ()
  "Entry point for all alerts about appointments."
  (secretaria-alert-due-appt)
  (secretaria-alert-unknown-time-appt))

(defun secretaria-org-file-agenda-p (filename-directory)
  "Return t if FILENAME-DIRECTORY is in variable `org-agenda-files' or exists in directory `org-directory'."
  (when (or (member (expand-file-name filename-directory) (org-agenda-files))
            (file-in-directory-p (file-name-nondirectory (expand-file-name filename-directory)) org-directory))
    t))

(defun secretaria-get-appt (kind)
  "Return a list of appointments.

KIND is either 'due or 'unknown.  'due is for due appointments,
'unknown is for today appointments with unspecified time of day"
  (let* ((files (org-agenda-files))
         (entries)
         (appts)
         (today (calendar-current-date))
         (regexp (secretaria--leaders-prepare (if (eq kind 'due) nil t)))
         (org-agenda-skip-function '(secretaria--skip-entry-if-done))
         (org-clock-current-task (or org-clock-current-task "")))
    (dolist (file files)
      ;; Took from https://github.com/kiwanami/emacs-calfw/issues/26#issuecomment-24881831
      (setf org-agenda-buffer
            (when (buffer-live-p org-agenda-buffer)
              org-agenda-buffer))
      (setf entries (org-agenda-get-day-entries file today :scheduled :deadline))
      (dolist (entry entries)
        (when (or (and (eq kind 'unknown)
                       (string-match-p regexp (get-text-property 0 'extra entry))
                       (string-empty-p (get-text-property 0 'time entry))
                       (not (string-equal org-clock-current-task (substring-no-properties (get-text-property 0 'txt entry)))))
                  (and (eq kind 'due)
                       (string-match-p regexp (get-text-property 0 'extra entry))))
          (push (substring-no-properties (get-text-property 0 'txt entry)) appts))))
    appts))

(defun secretaria-after-save-update-appt ()
  "Update appointments if the saved file is part of variable `org-agenda-files'."
  (interactive)
  (when (eq major-mode 'org-mode)
    (when (secretaria-org-file-agenda-p buffer-file-name)
      (org-agenda-to-appt t))))

(defun secretaria-unknown-time-always-remind-me ()
  "Timer for reminders of today tasks which have an unknown time of the day.

If the variable `secretaria-unknown-time-remind-time'
is 0, use the default of 30 minutes (to avoid accidents made by
the user)."
  (setf secretaria-uknown-time-reminder-timer
        (run-at-time (format "%s min" (or secretaria-unknown-time-remind-time 30))
                     (* (or secretaria-unknown-time-remind-time 30) 60) 'secretaria-alert-unknown-time-appt)))

(defun secretaria--org-to-html (message)
  "Convert a MESSAGE in org markup to HTML."
  (unless message
    "")
  (if secretaria-notification-to-html
      (replace-regexp-in-string secretaria--org-url-regexp "<a href=\"\\1\">\\2</a>" message)
    (replace-regexp-in-string secretaria--org-url-regexp "\\2" message)))

(defun secretaria-task-clocked-time ()
  "Return a string with the clocked time and effort, if any."
  (interactive)
  (let* ((clocked-time (org-clock-get-clocked-time))
         (h (floor clocked-time 60))
         (m (- clocked-time (* h 60)))
         (work-done-str (org-duration-from-minutes (+ (* h 60) m))))
    (if org-clock-effort
        (let* ((effort-in-minutes
                (org-duration-to-minutes org-clock-effort))
               (effort-h (floor effort-in-minutes 60))
               (effort-m (- effort-in-minutes (* effort-h 60)))
               (effort-str (org-duration-from-minutes (+ (* effort-h 60) effort-m))))
          (format "%s/%s" work-done-str effort-str))
      (format "%s" work-done-str))))

(defun secretaria-notification-handler (notification)
  "Handle `org-mode' notifications.

`NOTIFICATION' is, well, the notification from `org-mode'"
  (if (not (s-contains? "should be finished by now" notification))
      (alert notification :title "Secretaria: message from org-mode" :mode 'org-mode)
    (alert (secretaria--org-to-html org-clock-current-task)
           :title (format "Task effort reached (%s)" (secretaria-task-clocked-time))
           :severity 'high
           :mode 'org-mode)))

(defun secretaria-remind-task-clocked-in ()
  "Fires an alert for the user reminding him which task he is working on."
  (when org-clock-current-task
    (if (not org-clock-task-overrun)
        (alert (secretaria--org-to-html org-clock-current-task)
               :title "Currently clocked"
               :severity 'trivial
               :mode 'org-mode)
      (alert (secretaria--org-to-html org-clock-current-task)
             :title (format "Task effort exceeded (%s)" (secretaria-task-clocked-time))
             :severity 'urgent
             :mode 'org-mode))))

(defun secretaria-task-clocked-in ()
  "Start a timer when a task is clocked-in."
  (secretaria-task-save-clocked-task)
  (setf secretaria-clocked-in-reminder-timer (run-at-time (format "%s min" (or secretaria-clocked-in-reminder-every-minutes 10)) (* (or secretaria-clocked-in-reminder-every-minutes 10) 60) 'secretaria-remind-task-clocked-in))
  (alert (secretaria--org-to-html org-clock-current-task)
         :title (format "Task clocked in (%s)" (secretaria-task-clocked-time))
         :mode 'org-mode ))

(defun secretaria-task-clocked-out ()
  "Stop reminding the clocked-in task."
  (secretaria--task-delete-save-clocked-task)
  (ignore-errors (cancel-timer secretaria-clocked-in-reminder-timer))
  (when org-clock-current-task
    (alert (secretaria--org-to-html org-clock-current-task)
           :title (format "Task clocked out! (%s)" (secretaria-task-clocked-time))
           :severity 'high
           :mode 'org-mode)))

(defun secretaria-task-clocked-canceled ()
  "Stop reminding the clocked-in task if it's canceled."
  (cancel-timer secretaria-clocked-in-reminder-timer)
  (when org-clock-current-task
    (alert (secretaria--org-to-html org-clock-current-task)
           :title (format "Task canceled! (%s)" (secretaria-task-clocked-time))
           :severity 'high
           :mode 'org-mode)))

(defun secretaria-task-save-clocked-task ()
  "Save into a file the current clocked task."
  (when org-clock-current-task
    (with-temp-file (expand-file-name secretaria-clocked-task-save-file)
      (insert org-clock-current-task))))

(defun secretaria-task-load-clocked-task ()
  "Load the clocked task, if any.  And tell the user about it."
  (if (file-exists-p secretaria-clocked-task-save-file)
      (with-temp-buffer
        (insert-file-contents secretaria-clocked-task-save-file)
        (when (not (string-empty-p (buffer-string)))
          (alert (format "Something went wrong with Emacs while this task was clocked: <b>%s</b>" (buffer-string))
                 :title "Oops! Don't forget you were doing something, boss!"
                 :severity 'high)
          (secretaria--task-delete-save-clocked-task)))))

(defun secretaria--task-delete-save-clocked-task ()
  "Delete the saved clocked task."
  (ignore-errors (delete-file secretaria-clocked-task-save-file)))

(defun secretaria--task-saved-clocked-task-p ()
  "Check if the current clocked task was saved."
  (file-exists-p secretaria-clocked-task-save-file))

(add-hook 'after-init-hook #'secretaria-alert-after-init)
(add-hook 'after-init-hook #'secretaria-task-load-clocked-task)
(add-hook 'after-save-hook #'secretaria-after-save-update-appt)
(add-hook 'org-clock-in-hook #'secretaria-task-clocked-in t)
(add-hook 'org-clock-out-hook #'secretaria-task-clocked-out t)
(add-hook 'org-clock-cancel-hook #'secretaria-task-clocked-canceled t)

(when secretaria-notification-handler-overwrite
  (setf org-show-notification-handler 'secretaria-notification-handler))

(provide 'secretaria)
;;; secretaria.el ends here
