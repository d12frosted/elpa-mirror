;;; ddate.el --- Manage Discordian dates with ddate                     -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Erik L. Arneson

;; Author: Erik L. Arneson <earneson@arnesonium.com>
;; Keywords: lisp, dates, tools, dashboard
;; Package-Version: 20221030.406
;; Package-Commit: 48dcc8624146731bda086973ca83cc129701e55b
;; Version: 0.0.1
;; URL: https://git.sr.ht/~earneson/emacs-ddate
;; Package-Requires: ((emacs "24.4"))

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

;; This package uses the ddate command
;; (https://github.com/bo0ts/ddate) and then munges its output to
;; produce something pretty.  With faces.

;;; Code:

(defgroup ddate nil
  "Options for handling and displaying the Discordian date."
  :prefix "ddate-"
  :group 'applications)

(defcustom ddate-command "ddate"
  "Command to run to get Discordian date."
  :type 'string
  :group 'ddate)

(defcustom ddate-format-immediate "Today is %{%A, the %e day of %B%} in the YOLD %Y%N: Celebrate %H!"
  "Default format for current ddate.  Try to keep it all on one line."
  :type ':string
  :group 'ddate)

(defcustom ddate-format "%{%A, %B %d%}, %Y YOLD%N, %H"
  "Default format for non-current ddate calls.  Try to keep it all on one line."
  :type ':string
  :group 'ddate)

(defvar ddate-day-colors '(("Sweetmorn" . "white")
                           ("Boomtime" . "red")
                           ("Pungenday" . "yellow")
                           ("Prickle-Prickle" . "green")
                           ("Setting Orange" . "orange"))
  "Colors associated with the Discordian days of the week.")

(defvar ddate-holiday-names '("Mungday"
                              "Chaoflux"
                              "St. Tib's Day"
                              "Mojoday"
                              "Discoflux"
                              "Syaday"
                              "Confuflux"
                              "Zaraday"
                              "Bureflux"
                              "Maladay"
                              "Afflux")
  "Names of the Discordian holidays.")

(defun ddate-check-command ()
  "Check if the ddate command exists and is executable."
  (or (executable-find ddate-command)
      (file-executable-p ddate-command)))

(defun ddate (&optional day month year)
  "Return the Discordian date as a string.

DAY is the day of the month as an integer.
MONTH is the month as an integer.
YEAR is a year as an integer."
  (interactive)
  (let* ((format-string (if (or day month year)
                            ddate-format
                          ddate-format-immediate))
         (shell-command (format "%s +\"%s\"%s 2>/dev/null" ddate-command format-string
                                (if year
                                    (format " %d %d %d" day month year)
                                  "")))
         ddate-string)
    (unless (ddate-check-command)
      (error "Cannot find ddate executable"))
    (setq ddate-string (string-trim-right (shell-command-to-string shell-command)))
    (if (string= "Invalid date -- out of range" ddate-string)
        (error (concat "ddate: " ddate-string)))
    (if (string= "" ddate-string)
        (error "Unspecified error: no date returned"))
    ddate-string))

(defun ddate-pretty (&optional day month year)
  "Return the Discordian date as a propertized string.

DAY is the day of the month as an integer.
MONTH is the month as an integer.
YEAR is a year as an integer."
  (interactive)
  (let ((ddate-string (ddate day month year))
        (day-match-rx (concat "\\("
                              (mapconcat (lambda (item)
                                           (regexp-quote (car item)))
                                         ddate-day-colors "\\|")
                              "\\)"))
        (holiday-match-rx (concat "\\("
                                  (mapconcat #'regexp-quote ddate-holiday-names "\\|")
                                  "\\)"))
        day-name)
    ;; Apply colors to the days of the week
    (if (string-match day-match-rx ddate-string)
        (progn
          (setq day-name (match-string 1 ddate-string))
          (add-text-properties (match-beginning 1) (match-end 1)
                               (list 'font-lock-face (list ':foreground (cdr (assoc day-name ddate-day-colors))))
                               ddate-string)))
    ;; Is it a holiday? Let's celebrate.
    (if (string-match holiday-match-rx ddate-string)
        (add-text-properties (match-beginning 1) (match-end 1)
                             '(font-lock-face (:foreground "cyan" :weight bold))
                             ddate-string))
    ddate-string))

(provide 'ddate)

;;; ddate.el ends here
