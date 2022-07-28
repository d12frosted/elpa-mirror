;;; date2name.el --- Package to prepend ISO Timestamps to files  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Max Beutelspacher

;; Author: Max Beutelspacher
;; URL: https://github.com/DerBeutlin/date2name.el
;; Package-Version: 20190630.933
;; Package-Commit: 386dbe73678705d6107cd5c9bdeb4f7c97632360
;; Keywords: files, convenience
;; Version: 0.0.1
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A package to add daystamps and timestamps to filenames

;;; Code:

(require 'org)
(require 'dired)

(defgroup date2name nil "A helper for managing date and timestamps directly in the filename"
  :group 'applications)

(defvar date2name-date-regexp "^[0-9]\\{4\\}-[0-1][0-9]-[0-3][0-9]"
  "Regexp for detecting date in front of filename.
Should fit to the format in the variable `date2name-date-format'.")

(defvar date2name-date-format "%Y-%m-%d"
  "Format for formatting date at the beginning of the filename.
Should fit to the regexp in the variable `date2name-date-regexp'.")

(defvar date2name-datetime-regexp "^[0-9]\\{4\\}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9].[0-5][0-9].[0-5][0-9]"
  "Regexp for detecting datetime in front of filename.
Should fit to the format in the variable `date2name-datetime-format'.")

(defvar date2name-datetime-format "%Y-%m-%dT%H.%M.%S"
  "Format for formatting datetime at the beginning of the filename.
Should fit to the regexp in the variable `date2name-datetime-regexp'.")

(defvar date2name-default-separation-character "_"
  "Character which is used to seperate timestamp and filename.
if the variable `date2name-enable-smart-separation-character-chooser'
this character is only chosen if the filename does not contain a space,
otherwise a space is used as separation character.")

(defvar date2name-default-separation-character-regexp "[ _]"
  "Regexp for characters that can separate timestamp and filename.")

(defcustom date2name-enable-smart-separation-character-chooser nil
  "If t then the separation character depends on the filename.
If the original filename contains at least on space,
a space is used for seperation,
otherwise the variable `date2name-default-seperation-character' is used.
Example if t:

    foo_bar.txt -> 20180724T13.48.25_foo_bar.txt
    foo bar.txt -> 20180724T13.48.25 foo bar.txt" :type 'bool)


(defun date2name-choose-separation-character (path)
  "Select the right separition character depending on the PATH."
  (if date2name-enable-smart-separation-character-chooser
      (let ((filename (file-name-nondirectory path)))
        (if (string-match-p (regexp-quote " ")
                            filename)
            " "
          date2name-default-separation-character))
    date2name-default-separation-character))

(defun date2name-remove-date (path)
  "Remove potential prefixed dates from PATH and return the new path."
  (let ((directory (file-name-directory path))
        (file-name (file-name-nondirectory path)))
    (concat directory
            (replace-regexp-in-string (concat date2name-date-regexp date2name-default-separation-character-regexp)
                                      ""
                                      (replace-regexp-in-string (concat date2name-datetime-regexp date2name-default-separation-character-regexp)
                                                                ""
                                                                file-name)))))

(defun date2name-prepend-date (path time &optional withtime)
  "Prepend TIME to PATH.
If WITHTIME is not nil a timestamp in the format of
the variable `date2name-datetime-format' is used.
Otherwise a datestamp in the format of the variable
`date2name-date-format' is used."
  (let ((directory (file-name-directory path))
        (filename (date2name-remove-date (file-name-nondirectory path)))
        (datestring (if withtime
                        (format-time-string (concat date2name-datetime-format
                                                    (date2name-choose-separation-character path))
                                            time)
                      (format-time-string (concat date2name-date-format
                                                  (date2name-choose-separation-character path))
                                          time))))
    (concat directory datestring filename)))


(defun date2name-prepend-date-write (path time &optional withtime)
  "Prepend TIME to PATH and renames the file.
If WITHTIME is not nil a timestamp in the format of
the variable `date2name-datetime-format' is used.
Otherwise a datestamp in the format of the variable
`date2name-date-format' is used."
  (let ((new-path (date2name-prepend-date path time withtime)))
    (unless (string= path new-path)
      (dired-rename-file path new-path nil))))

(defun date2name-add-date-to-name (arg &optional withtime)
  "Add date to filenames.
The filenames are all marked files in dired or the
file under the point if no files are marked.
If ARG is nil use the modification time of the file.
With one prefix arg, prompt for a time individually for each file.
With two prefix args prompt for one time for all files.
If WITHTIME is not nil a timestamp in the format of
the variable `date2name-datetime-format' is used.
Otherwise a datestamp in the format of the variable
`date2name-date-format' is used."
  (let ((filenames (if (dired-get-marked-files)
                       (dired-get-marked-files)
                     '((dired-get-filename))))
        (save-date (when (equal (prefix-numeric-value arg) 16) (org-read-date withtime t))))
    (dolist (filename filenames)
      (let ((date (if (not save-date)
                      (if (not arg) (date2name-file-attribute-modification-time (file-attributes filename)) (org-read-date withtime t))
                    save-date)))
        (date2name-prepend-date-write filename date
                                      withtime)))))

(defun date2name-file-attribute-modification-time (attributes)
  "Extract the modification time from ATTRIBUTES."
  (if (fboundp 'file-attribute-modification-time)
      (file-attribute-modification-time attributes)
      (nth 5 attributes)))

;;;###autoload
(defun date2name-dired-add-date-to-name (arg)
  "Add date to filenames.
The filenames are all marked files in dired or the
file under the point if no files are marked.
If ARG is nil use the modification time of the file.
With one prefix arg, prompt for a time individually for each file.
With two prefix args prompt for one time for all files.
The format of the variable `date2name-date-format' is used
for the daystamp."
  (interactive "P")
  (date2name-add-date-to-name arg nil))

;;;###autoload
(defun date2name-dired-add-datetime-to-name (arg)
  "Add date to filenames.
The filenames are all marked files in dired or the
file under the point if no files are marked.
If ARG is nil use the modification time of the file.
With one prefix arg, prompt for a time individually for each file.
With two prefix args prompt for one time for all files.
The format of the variable `date2name-datetime-format' is used
for the timestamp."
  (interactive "P")
  (date2name-add-date-to-name arg t))

(provide 'date2name)
;;; date2name.el ends here
