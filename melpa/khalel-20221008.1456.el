;;; khalel.el --- Import, edit and create calendar events through khal -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Hanno Perrey
;;
;; Author: Hanno Perrey <http://gitlab.com/hperrey>
;; Maintainer: Hanno Perrey <hanno@hoowl.se>
;; Created: september 10, 2021
;; Modified: september 4, 2021
;; Version: 0.1.9
;; Package-Version: 20221008.1456
;; Package-Commit: fce18763a07769f2dbbb84eb20490aabbf612b66
;; Keywords: event, calendar, ics, khal
;; Homepage: https://gitlab.com/hperrey/khalel
;; Package-Requires: ((emacs "27.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;    This program is free software: you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation, either version 3 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;    GNU General Public License for more details.
;;
;;    You should have received a copy of the GNU General Public License
;;    along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Khalel provides helper routines to import current events from a local
;;  calendar through the command-line tool khal into an org-mode file. Commands
;;  to edit and to capture new events allow modifications to the calendar.
;;  Changes to the local calendar can be transfered to remote CalDAV servers
;;  using the command-line tool vdirsyncer which can be called from within
;;  khalel.
;;
;;  First steps/quick start:
;;  - install, configure and run vdirsyncer
;;  - install and configure khal
;;  - customize the values for default calendar, capture file and import file for khalel
;;  - call `khalel-add-capture-template' to set up a capture template
;;  - import events through `khalel-import-events',
;;    edit them through `khalel-edit-calendar-event' or create new ones through `org-capture'
;;  - consider adding the import org file to your org agenda to show current events there
;;
;;; Code:

;;;; Requirements

(require 'org)
(require 'ox-icalendar)
(require 'org-capture)

;;;; Customization

(defgroup khalel nil
  "Calendar import functions using khal."
  :group 'calendar)

(defgroup khalel-advanced nil
  "Advanced options for khal and khalel."
  :group 'khalel)

(defcustom khalel-khal-command "khal"
  "The command to run when executing khal.

When set to nil then it will be guessed."
  :group 'khalel
  :type 'string)

(defcustom khalel-khal-config nil
  "The configuration file to use when executing khal.

When set to nil then the default location
\($XDG_CONFIG_HOME/khal/config\) will be used."
  :group 'khalel-advanced
  :type 'string)

(defcustom khalel-default-calendar "private"
  "The khal calendar to import into by default.

The calendar for a new event can be modified during the capture
process. Set to nil to use the default calendar configured for
khal instead."
  :group 'khalel
  :type 'string)

(defcustom khalel-default-alarm "10"
  "The default time (in minutes) before an event to display an alarm.
Set to empty string to disable the alarm."
  :group 'khalel
  :type 'string)

(defcustom khalel-capture-key "e"
  "The key used for the `org-capture' template for events.

Run `khalel-add-capture-template' to register the template."
  :group 'khalel
  :type 'string)

(defcustom khalel-import-org-file (concat org-directory "calendar.org")
  "The file to import khal calendar entries into.

CAUTION: the file will be overwritten with each import! The
prompt for overwriting the file can be disabled by setting
`khalel-import-org-file-confirm-overwrite' to nil."
  :group 'khalel
  :type 'string)

(defcustom khalel-import-org-file-read-only 't
  "Whether or not the imported file should be configured as read-only.

As the file is overwritten on repeated imports, modifications would get
lost. If this variable is set to non-nil values, the file will have the
buffer-local variable `buffer-read-only' enabled. Otherwise, the file will
be read-writeable and the user is tasked to be cautious."
  :group 'khalel-advanced
  :type 'boolean)

(defcustom khalel-import-org-file-confirm-overwrite 't
  "When nil, always overwrite the org file into which events are imported.
Otherwise, ask for confirmation."
  :group 'khalel
  :type 'boolean)

(defcustom khalel-import-format "* {title} {cancelled} :{calendar}:\n\
:PROPERTIES:\n:CALENDAR: {calendar}\n\
:LOCATION: {location}\n\
:ID: {uid}\n\
:END:\n\
- When: <{start-date-long} {start-time}>--<{end-date-long} {end-time}>\n\
- Where: {location}\n\
- Description: {description}\n\
- URL: {url}\n- Organizer: {organizer}\n\n\
[[elisp:(khalel-edit-calendar-event)][Edit this event]]\
    [[elisp:(progn (khalel-run-vdirsyncer) (khalel-import-events))]\
[Sync and update all]]\n"
  "The format string to pass to khal when importing events.

See the documentation to khal for valid placeholders (in curly
brackets). The result should be properly formated 'org-mode'
syntax."
  :group 'khalel-advanced
  :type  'string)

(defcustom khalel-import-org-file-header "#+TITLE: khalel imported calendar events\n\n\
*NOTE*: this file has been generated by \
[[elisp:(khalel-import-events)][khalel-import-events]] \
and /any changes to this document will be lost on the next import/!
Instead, use =khalel-edit-calendar-event= or =khal edit= to edit the \
underlying calendar entries, then re-import them here.

You can use [[elisp:(khalel-run-vdirsyncer)][khalel-run-vdirsyncer]] \
to synchronize with remote calendars.

Consider adding this file to your list of agenda files so that events \
show up there.\n\n"
  "The header to insert into the org file when importing events."
  :group 'khalel-advanced
  :type  'string)

(defcustom khalel-import-start-date "today"
  "The start date of events to consider when import.
Can be given anything that will be understood by `org-read-date'.
Used as START argument to the khal date range."
  :group 'khalel
  :type 'string)

(defcustom khalel-import-end-date "+30d"
  "The end date of events to consider when import.
Can be given anything that will be understood by `org-read-date'.
Used as END argument to the khal date range."
  :group 'khalel
  :type 'string)

(defcustom khalel-vdirsyncer-command "vdirsyncer"
  "The command to run when executing vdirsyncer.

When set to nil then it will be guessed."
  :group 'khalel
  :type 'string)

(define-obsolete-variable-alias 'khalel-update-upcoming-events-after-capture
  'khalel-import-events-after-capture "0.1.8")

(defcustom khalel-import-events-after-capture 't
  "Whether to automatically update the imported events after a new capture."
  :group 'khalel
  :type 'boolean)

(make-obsolete-variable 'khalel-import-time-delta
                        "The import range is now controlled via start \
and end dates set\
via `khalel-import-start-date' and `khalel-import-end-date',\
respectively" "0.1.8")

;;;; Commands

(make-obsolete 'khalel-import-upcoming-events 'khalel-import-events "0.1.8")

(defun khalel-import-events ()
  "Imports calendar entries by calling khal externally.

The time delta which determines how far into the future events
are imported is configured through `khalel-import-start-date'
and `khalel-import-end-date'.
CAUTION: The results are imported into the file
`khalel-import-org-file' which is overwritten to avoid adding
duplicate entries already imported previously. As default, the
file is configured to be read-only. This can be adjusted by
configuring `khalel-import-org-file-read-only'.

When a prefix argument is given, the import will be limited to
the calendar `khalel-default-calendar'.

Please note that the resulting org file does not necessarily
include all information contained in the .ics files it is based
on. Khal only supports certain (basic) fields when creating lists.

Examples of missing fields are timezone information, categories,
alarms or settings for repeating events."
  (interactive)
  (let*
      ( ;; call khal directly.
       (khal-bin (or khalel-khal-command
                     (executable-find "khal")))
       (khal-cfg (when khalel-khal-config (format "-c %s" khalel-khal-config)))
       (khal-cal (when current-prefix-arg (format "-a%s" khalel-default-calendar)))
       (khal-start (org-read-date nil nil khalel-import-start-date))
       (khal-end (org-read-date nil nil khalel-import-end-date))
       (dst (generate-new-buffer "*khal-output*"))
       (err (get-buffer-create "*khal-errors*"))
       (errfn (make-temp-file "khalel-khal-errors-"))
       ;; determine arguments for khal call
       (args
        (remq nil  ;; remove nil elements
              `(,khal-cfg "list" ,khal-cal "--format"
                          ,khalel-import-format
                          "--day-format" ""
                          ,khal-start ,khal-end)))
       (exitval (apply 'call-process khal-bin nil
                       (list dst errfn) nil
                       args)))
    (save-excursion
      (with-current-buffer err
        (goto-char (point-max))
        (insert-file-contents errfn))
      (with-current-buffer dst
          ;; cosmetic fix for all-day events w/o start or end times:
          ;; remove spaces after dates
          (goto-char (point-min))
          (while (re-search-forward "^\\(- When:.*?\\) \\(>--<.*\\) >" nil t)
            (replace-match "\\1\\2>" nil nil))
          ;; fix multi-line location property making property drawer invalid
          (goto-char (point-min))
          (while (re-search-forward "^:LOCATION: " nil t)
            (save-match-data
              (while (looking-at "\\(.*\\)\n\\([^:]\\)")
                (replace-match "\\1, \\2" nil nil))))
          ;; events that are scheduled as full-day and span multiple days will
          ;; also appear multiple times in the output of `khal list' but will
          ;; each keep the entire range in the time stamp. This results in
          ;; identical entries in the output file and multiple occurances in the
          ;; org-agenda. Filter these duplicates out here.
          (let ((content (khalel--get-buffer-content-list)))
            (with-temp-buffer
              (khalel--insert-import-file-header khal-start khal-end)
              (insert
               (mapconcat 'identity
                          (delete-dups content)
                          ""))
              (write-file khalel-import-org-file
                          khalel-import-org-file-confirm-overwrite)
          (message "Imported %d events from khal into %s"
                   (length (org-map-entries nil nil nil))
                   khalel-import-org-file)))))
    (if (/= 0 exitval)
        (message "khal exited with non-zero exit code; see buffer `*khal-errors*' for details.")
      (kill-buffer dst))
    ;; revert any buffer visisting the file
    (let ((buf (find-buffer-visiting khalel-import-org-file)))
      (when buf (with-current-buffer buf (revert-buffer :ignore-auto :noconfirm))))))


(defun khalel-export-org-subtree-to-calendar ()
  "Exports current subtree as ics file and into an external khal calendar.
An ID will be automatically be created and stored as property of
the subtree. See documentation of `org-icalendar-export-to-ics'
for details of the supported fields.

Note that the UID used in the ics file is based upon but not
identical to the ID of the org entry. Export of imported
entries will likely result in duplicates in the calendar.

Return t on success and nil otherwise."
  (interactive)
  (save-excursion
    ;; org-icalendar-export-to-ics doesn't reliably export the full event when
    ;; operating on a subtree only; narrowing the buffer, however, works fine
    (org-narrow-to-subtree)
    (let*
        ;; store IDs right away to avoid duplicates
        ((org-icalendar-store-UID 't)
         ;; create events from non-TODO entries with scheduled time
         (org-icalendar-use-scheduled '(event-if-not-todo))
         (khal-bin (or khalel-khal-command
                       (executable-find "khal")))
         (capturefn (buffer-file-name
                 (buffer-base-buffer)))
         (path (file-name-directory capturefn))
         (entriescal (org-entry-get nil "calendar"))
         (calendar (or
                    (when (and entriescal (string-match "[^[:blank:]]" entriescal)) entriescal)
                    khalel-default-calendar))
         ;; export to ics
         (ics (khalel--sanitize-ics
               (org-icalendar-export-to-ics nil nil 't)))
         (khal-cfg (when khalel-khal-config (format "-c %s" khalel-khal-config)))
         ;; determine args to khal
         (args
          (remq nil ;; remove nil elements
                `(,khal-cfg
                  "import"
                  ,(when calendar
                     (format "-a%s" calendar))
                  "--batch"
                  ,(concat path ics))))
         ;; call khal import only if ics verification succeeds
         (import
          (or (khalel--verify-exported-ics ics)
              (with-temp-buffer
                (list
                 :process khal-bin
                 :exit-status
                 (apply 'call-process
                        khal-bin nil t nil
                        args)
                 :output
                 (buffer-string))))))
      (widen)
      (let ((exitstat (plist-get import :exit-status)))
        (when
            (/= 0 exitstat)
          (let ((buf (generate-new-buffer "*khalel-capture-errors*")))
            (khalel--make-temp-window buf 16)
            (with-current-buffer buf
              (insert
               (message
                (format
                 "%s failed on %s for calendar '%s' and exited with status %d\n"
                 (plist-get import :process)
                 ics
                 calendar
                 exitstat)))
              (insert "\n" (plist-get import :output) "\n")
              (insert
               (format
               "Once the issues in the captured entry (%s) \
are fixed, you can re-run the export \
by calling `khalel-export-org-subtree-to-calendar'"
               capturefn))
              (special-mode)))
          ;; show captured file to fix issues
          (find-file capturefn))
        (zerop exitstat)))))


(defun khalel-add-capture-template (&optional key)
  "Add an `org-capture' template with KEY for creating new events.
If argument is nil then `khalel-capture-key' will be used as
default instead. New events will be captured in a temporary file
and immediately exported to khal."
  (add-to-list 'org-capture-templates
               `(,(or key khalel-capture-key) "calendar event"
                 entry
                 (function khalel--make-temp-file)
                 ,(concat "* %?\nSCHEDULED: %^T\n:PROPERTIES:\n\
:CREATED: %U\n:CALENDAR: \n\
:CATEGORY: event\n:LOCATION: \n\
:APPT_WARNTIME: " khalel-default-alarm "\n:END:\n" )))
  (add-hook 'org-capture-before-finalize-hook
            #'khalel--capture-finalize-calendar-export)
  ;; do not store the ids in `org-id-locations-file'
  (advice-add 'org-id-add-location
              :around #'khalel--ignore-khal-captures-in-org-id-locations-file-a))


(defun khalel-run-vdirsyncer ()
  "Run vdirsyncer process to synchronize local calendar entries."
  (interactive)
  (let ((buf "*VDIRSYNCER-OUTPUT-BUFFER*"))
    (with-output-to-temp-buffer buf
        (khalel--make-temp-window buf 16)
        (set-process-sentinel
         (start-process
          "khalel-vdirsyncer-process"
          buf
          (or khalel-vdirsyncer-command
              (executable-find "vdirsyncer"))
          "sync")
         #'khalel--delete-process-window-when-done)
        ;; show output
        (sit-for 1)
        (with-current-buffer buf
          (set-window-point
           (get-buffer-window (current-buffer) 'visible)
           (point-min))))))

(defun khalel-edit-calendar-event ()
  "Edit the event at the cursor position using khal's interactive edit command.
Works on imported events and used their ID to search for the
  correct event to modify."
  (interactive)
  (let* ((buf (get-buffer-create "*khal-edit*"))
         (uid (org-entry-get nil "id")))
    (khalel--make-temp-window buf 16)
    (if (and uid (string-match "[^[:blank:]]" uid))
        (progn
          (set-process-sentinel
           (get-buffer-process (make-comint-in-buffer
                                "khal-edit" nil
                                khalel-khal-command nil
                                "edit" "--show-past" uid))
           #'khalel--delete-process-window-when-done)
          (pop-to-buffer buf))
      (message "khalel: could not find ID associated with current entry."))))

;;;; Functions
(defun khalel--make-temp-file ()
  "Create and visit a temporary file for capturing and exporting events."
  (set-buffer (find-file-noselect (make-temp-file "khalel-capture-" nil "-tmp.org")))
  ;; mark buffer as new and appropriate to kill after capture process.
  (org-capture-put :new-buffer t)
  (org-capture-put :kill-buffer t))

(defun khalel--ignore-khal-captures-in-org-id-locations-file-a (fn &rest args)
  "Ignore khalel capture files when storing ids in the database of id locations.
FN is `org-id-add-location' that comes from advice and ARGS are
passed to it."
  (let ((file (cadr args)))
  (when (not
         (string-match-p "khalel-capture-.*-tmp\\.org"
                         (file-name-nondirectory file)))
         (apply fn args))))

(defun khalel--capture-finalize-calendar-export ()
  "Export current event capture.
To be added as hook to `org-capture-before-finalize-hook'."
  (let ((key  (plist-get org-capture-plist :key)))
    (when (and
           (not org-note-abort)
           (equal key khalel-capture-key))
      (if
          (not (khalel-export-org-subtree-to-calendar))
          ;; export finished with non-zero exit status,
          ;; do not clean up buffer/wconf to leave error msg intact and visible
          (progn
            (org-capture-put :new-buffer nil)
            (org-capture-put :kill-buffer nil)
            (org-capture-put :return-to-wconf (current-window-configuration)))
        (when
            khalel-import-events-after-capture
          (khalel-import-events))))))

(defun khalel--sanitize-ics (ics)
  "Remove some modifications to data fields in ICS file.

When exporting, `org-icalendar-export-to-ics' changes an entry's
ID, description and summary depending on the type of date (deadline, scheduled
or active/inactive timestamp) was discovered. Some are changed back
here where appropriate for our use case."
  (with-temp-file ics
    (insert-file-contents ics)
    (goto-char (point-min))
    (while (re-search-forward "^\\(SUMMARY:[[:blank:]]*\\)S: " nil t)
      (replace-match "\\1" nil nil))
    (goto-char (point-min))
    (while (re-search-forward "^\\(DESCRIPTION:[[:blank:]]*\\)S: " nil t)
      (replace-match "\\1" nil nil)))
  ics)


(defun khalel--verify-exported-ics (ics)
  "Check the exported ICS file for potential issues.

Return a plist with details of problems or nil if no issues were found."
  (let ((result nil))
  (with-temp-buffer
    (insert-file-contents ics)
    (goto-char (point-min))
    ;; make sure that the file contains a VEVENT
    (when (not (re-search-forward "^BEGIN:VEVENT" nil t))
      (setq result "`org-icalendar-export-to-ics' did not produce a VEVENT. Please check that the org heading contains a valid 'SCHEDULED: <TIMESTAMP>' line right after the heading.")))
  (and result (list
               :exit-status 1
               :process "org-icalendar-export-to-ics output verification"
               :output result))))

(defun khalel--get-buffer-content-list ()
  "Return the entire content of each subtree of the current buffer asa list."
  (let ((content-list '())) ; start with empty list
    (org-element-map (org-element-parse-buffer) 'headline
      (lambda (x)
        (let* ((begin (org-element-property :begin x))
               (end (org-element-property :end x))
               (content (buffer-substring begin end)))
          (push content content-list ))))
    (nreverse content-list)))

(defun khalel--insert-import-file-header (sdate edate)
  "Insert imported events file header information into current buffer.
SDATE and EDATE denote the start and end dates, respectively, of
the current import date range."
  (when khalel-import-org-file-read-only
    (insert "# -*- buffer-read-only: 1; -*-\n"))
  (insert khalel-import-org-file-header)
  (insert (format "*Events scheduled between %s and %s*:\n" sdate edate))
  (insert (format "/(Last import: %s)/\n\n" (current-time-string))))

(defun khalel--make-temp-window (buf height)
  "Create a temporary window with HEIGHT at the frame bottom displaying buffer BUF."
  (or (get-buffer-window buf 'visible)
      (let ((win
             (split-window
              (frame-root-window)
              (- (window-height (frame-root-window)) height))))
        (set-window-buffer win buf)
        (set-window-dedicated-p win t)
        win)))

(defun khalel--delete-process-window-when-done (process _event)
  "Check status of PROCESS at each EVENT and delete window after process finished."
  (let ((buf (process-buffer process)))
    (when (= 0 (process-exit-status process))
      (when (get-buffer buf)
        (with-current-buffer buf
          (set-window-point
           (get-buffer-window (current-buffer) 'visible)
           (point-max)))
        (sit-for 2)
        (delete-window (get-buffer-window buf))
        (kill-buffer buf)))))

;;;; Footer
(provide 'khalel)
;;; khalel.el ends here
