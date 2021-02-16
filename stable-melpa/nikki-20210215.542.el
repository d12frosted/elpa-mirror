;;; nikki.el --- A simple diary mode -*- lexical-binding: t -*-
;;
;; Copyright © 2021 Taiki Harada
;;
;; Author: Taiki Harada <thdev994@gmail.com>
;; URL: https://github.com/th994/nikki
;; Package-Version: 20210215.542
;; Package-Commit: ca03d7d53c0dd004339a48b1979b22674b8ea445
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

(require 'cl-lib)
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

(defun nikki-time-alist (time)
  "Get the TIME, and make the alist."
  (let ((current-time-list
	 (split-string (format-time-string "%Y %m %d" time)))
	(keys '(year month day)))
    (cl-pairlis keys current-time-list)))

(defun nikki-cl-assoc-val (alist key)
  "Get the value of a pair from ALIST by KEY."
  (cdr (cl-assoc key alist)))

(defun nikki-write-initial-content (path)
  "Insert the date in the first line of the diary(PATH)."
  (write-region
   (format-time-string "%Y-%m-%d" (current-time)) nil path))

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
  
;;;###autoload
(defun nikki-open-by-calendar (&optional date event)
  "Get and execute a specific DATE in calendar mode.
EVENT specifies a buffer position to use for a date."
  (interactive (list nil last-nonmenu-event))
  (or date (setq date (calendar-cursor-to-date t event)))
  (let* ((fixed-date-list (mapcar #'nikki-add-zero-to-date-string date))
	 (year (car (last fixed-date-list)))
	 (month (car fixed-date-list))
	 (day (cadr fixed-date-list))
	 (file-name (concat year month day nikki-file-extension))
	 (file-path (concat (file-name-as-directory nikki-default-directory)
			    (file-name-as-directory year)
			    file-name)))
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
(defun nikki-make-diary ()
  "Create a diary for the day.  If it already exists, open it."
  (interactive)
  (let* ((current-time-list (nikki-time-alist (current-time)))
	 (year (nikki-cl-assoc-val current-time-list 'year))
	 (month (nikki-cl-assoc-val current-time-list 'month))
	 (day (nikki-cl-assoc-val current-time-list 'day))
	 (nikki-directory (concat (file-name-as-directory nikki-default-directory)
				  (file-name-as-directory year)))
	 (file-name (concat year month day nikki-file-extension))
	 (file-path (concat nikki-directory file-name)))
    (if (file-directory-p nikki-directory)
	(nikki-write-and-open-file file-path)
      (nikki-make-directories
       (list nikki-default-directory nikki-directory))
      (nikki-write-and-open-file file-path))))

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
