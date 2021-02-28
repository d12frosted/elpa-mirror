;;; nikki.el --- A simple diary mode -*- lexical-binding: t -*-
;;
;; Copyright © 2021 Taiki Harada
;;
;; Author: Taiki Harada <thdev994@gmail.com>
;; URL: https://github.com/th994/nikki
;; Package-Version: 20210227.1707
;; Package-Commit: b2ea20d04a061df88d72bd8dd0412a6e7876458d
;; Version: 0.0.5
;; Keywords: convenience
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Create a simple diary.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'calendar)

(defgroup nikki nil
  "nikki configuration."
  :prefix "nikki-"
  :group 'convenience)

(defcustom nikki-default-directory (concat user-emacs-directory "nikki/")
  "Default diary directory."
  :group 'nikki
  :type 'string)

(defcustom nikki-file-extension ".txt"
  "Diary extension."
  :group 'nikki
  :type 'string)

(defcustom nikki-write-initial-content-func
  #'nikki-write-initial-content
  "Write initial contents to diary."
  :group 'nikki
  :type 'symbol)

(defun nikki-date-list (time)
  "Create a list of dates from TIME."
  (split-string (format-time-string "%m %d %Y" time)))

(defun nikki-year (date-list)
  "Extract the year from a DATE-LIST(%m %d %Y)."
  (car (last date-list)))

(defun nikki-month (date-list)
  "Extract the month from a DATE-LIST(%m %d %Y)."
  (car date-list))

(defun nikki-day (date-list)
  "Extract the day from a DATE-LIST(%m %d %Y)."
  (cadr date-list))

(defun nikki-write-initial-content (path)
  "Insert the date in the first line of the diary(PATH)."
  (let ((content (format-time-string "%Y-%m-%d" (current-time))))
    (write-region content nil path)))

(defun nikki-write-and-open-file (path)
  "If the diary(PATH) of the day does not exist, create it and open."
  (unless (file-exists-p path)
    (nikki-write-initial-content path))
  (find-file path))

(defun nikki-add-zero-to-date-string (num)
  "Convert an date NUM to a string.
If the date string are single digits, add a leading zero."
  (let ((str (number-to-string num)))
    (cond ((= (length str) 1) (concat "0" str))
	  (t str))))

(defun nikki-make-directories (path-list)
  "If the directory included in the PATH-LIST does not exist, create it."
  (mapcar
   (lambda (path)
      (unless (file-directory-p path)
	(make-directory path)))
   path-list))

(defun nikki-make-diary-path (date-list)
  "Create a path to save the diary from DATE-LIST(%m %d %Y).
Path format is the following.
`nikki-default-directory'/%Y/%Y-%m-%d.`nikki-file-extension'"
  (let* ((year (nikki-year date-list))
	 (month (nikki-month date-list))
	 (day (nikki-day date-list))
	 (nikki-dir (concat (file-name-as-directory nikki-default-directory)
		      (file-name-as-directory year)))
	 (file-name (concat year month day nikki-file-extension)))
    (concat nikki-dir file-name)))

(defun nikki-make-diary (time)
  "Create a diary from time to TIME.
If the directory for the target year does not exist under the `nikki-default-directory', create it."
  (let* ((date-list (nikki-date-list time))
	 (nikki-path (nikki-make-diary-path date-list))
	 (nikki-dir (file-name-directory nikki-path)))
    (if (file-directory-p nikki-dir)
	(nikki-write-and-open-file nikki-path)
      (nikki-make-directories
       (list nikki-default-directory nikki-dir))
      (nikki-write-and-open-file nikki-path))))
      
;;;###autoload
(defun nikki-open-by-calendar (&optional date event)
  "Get and execute a specific DATE in calendar mode.
EVENT specifies a buffer position to use for a date."
  (interactive (list nil last-nonmenu-event))
  (or date (setq date (calendar-cursor-to-date t event)))
  (let* ((fixed-date-list (mapcar #'nikki-add-zero-to-date-string date))
	 (file-path (nikki-make-diary-path fixed-date-list)))
    (if (file-exists-p file-path)
	(find-file file-path)
      (user-error "Diary not found at %s (nikki)" file-path))))

;;;###autoload
(defun nikki-find-diary ()
  "Find the directory where the diary is stored and open it with dired.
If it doesn't exist, create it."
  (interactive)
  (let ((nikki-directory nikki-default-directory))
    (if (file-directory-p nikki-directory)
	(find-file nikki-directory)
      (make-directory nikki-directory)
      (find-file nikki-directory))))

;;;###autoload
(defun nikki-make-diary-today ()
  "Create a diary for today.  If it already exists, open it."
  (interactive)
  (nikki-make-diary (current-time)))

(defvar nikki-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-n") 'nikki-open-by-calendar)
    map)
  "Map for variable `nikki-mode'.")

;;;###autoload
(define-minor-mode nikki-mode
  "Toggle nikki mode on or off.

Local bindings (`nikki-mode-map'):
\\{nikki-mode-map}"
  :keymap nikki-mode-map
  :lighter " nikki")

(provide 'nikki)
;;; nikki.el ends here
