;;; expenses.el --- Record and view expenses                  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Keywords: expense tracking, convenience
;; Package-Version: 20211206.602
;; Package-Commit: b5a3d7c6333aad6343a9fcffd4152afa9ec521f2
;; Version: 0.0.1
;; Homepage: https://github.com/md-arif-shaikh/expenses
;; URL: https://github.com/md-arif-shaikh/expenses
;; Package-Requires: ((emacs "26.1") (dash "2.19.1"))

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
;; Keep record of expenses and view the expenses for given period.
;; Add an expense entry conveniently using the interactive command
;; expenses-add-expense
;; A list of desired categories could be set using
;; setq expenses-category-list '(category1 category2 ..)
;; Set the desired destination for the expense files using
;; setq expenses-directory "desired/destination"
;; View the org file using
;; expenses-view-expense
;; Expenses for a given period like a date, month, months or year could be
;; calculated using appropriate interactive functions.  See the README on the github

;;; Code:
(require 'org)
(require 'dash)

(defcustom expenses-directory nil
  "Directory to save and look for the expense files."
  :type 'string
  :group 'expenses)

(defcustom expenses-category-list nil
  "List of categories for expenses."
  :type 'list
  :group 'expenses)

(defcustom expenses-currency nil
  "Currency."
  :type 'string
  :group 'expenses)

(defcustom expenses-month-names nil
  "Month names."
  :type 'list
  :group 'expenses)

(defcustom expenses-add-hline-in-org nil
  "Option to add or not add hline in the org files."
  :type 'boolean
  :group 'expenses)

(defvar expenses-color--expense "#98C379"
  "Color to indicate a expense.")
(defvar expenses-color--date "#BE5046"
  "Color to indicate a date.")
(defvar expenses-color--message "#E5C07B"
  "Color for message.")

(defface expenses-face-expense
  `((t :foreground ,expenses-color--expense
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for expense."
  :group 'expenses)

(defface expenses-face-date
  `((t :foreground ,expenses-color--date
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for date."
  :group 'expenses)

(defface expenses-face-message
  `((t :foreground ,expenses-color--message
       :weight extra-bold
       :box nil
       :underline nil))
  "Face for message."
  :group 'expenses)

(setq expenses-directory "~/Dropbox/Important_Works/Different Expenses/Monthly expenses/")
(setq expenses-category-list '("Grocery" "Shopping" "Travel" "Subscription" "Health" "Electronics" "Entertainment" "Rent" "Salary" "Others"))
(setq expenses-currency "Rs.")
(setq expenses-month-names '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))

(defun expenses--get-file-name (date)
  "Get the name of file from the DATE."
  (let ((year-month (substring date 0 7)))
    (concat expenses-directory year-month "-" "expenses.org")))

(defun expenses--create-initial-file (date)
  "Create a file for a DATE with initial structure."
  (let ((file-name (expenses--get-file-name date))
	(month (format-time-string "%B" (org-time-string-to-seconds date)))
	(year (format-time-string "%Y" (org-time-string-to-seconds date))))
    (message month)
    (with-temp-buffer
      (insert (format "#+TITLE: Expenses for %s %s\n\n" month year))
      (insert "* Expenses\n")
      (insert "#+TBLNAME: expenses\n")
      (insert "|--|--|--|--|\n")
      (insert "|Date |Amount | Category | Details |\n")
      (insert "|--|--|--|--|\n")
      (append-to-file (point-min) (point-max) file-name))))

(defun expenses-add-expense ()
  "Add expense."
  (interactive)
  (let* ((date (org-read-date nil nil nil "Date: "))
	 (amount (read-string "Amount: "))
	 (category (completing-read "Category: " expenses-category-list))
	 (details (read-string "Details: "))
	 (file-name (expenses--get-file-name date)))
    (when (string-blank-p category)
      (setq category "Others"))
    (when (not (file-exists-p file-name))
      (expenses--create-initial-file date))
    (with-temp-buffer
      (insert (format "|%s |%s |%s |%s |\n" date amount category details))
      (when expenses-add-hline-in-org (insert "|--|--|--|--|\n"))
      (append-to-file (point-min) (point-max) file-name))
    (when (string-equal (completing-read "Add another expense: " '("no" "yes")) "yes")
      (expenses-add-expense))
    (with-current-buffer (find-file-noselect file-name)
      (goto-char (point-max))
      (forward-line -1)
      (org-table-align)
      (write-file file-name))))

(defun expenses-view-expense ()
  "View expense."
  (interactive)
  (let* ((date (org-read-date nil nil nil "Date: "))
	 (file-name (expenses--get-file-name date)))
    (if (file-exists-p file-name)
	(find-file-other-window file-name)
      (let ((month (format-time-string "%B" (org-time-string-to-seconds date)))
	    (year (format-time-string "%Y" (org-time-string-to-seconds date))))
	(message "No expense file is found for %s %s" month year)))))

(defun expenses--goto-table-end (name)
  "Go to end of table named NAME if point is not in any table."
  (unless (org-at-table-p)
    (let ((org-babel-results-keyword "NAME"))
      (org-babel-goto-named-result name)
      (forward-line 2)
      (goto-char (org-table-end)))))

(defun expenses--get-expense-for-file (file-name &optional table-name)
  "Calculate expenses for given FILE-NAME and TABLE-NAME."
  (let ((buff-name (concat (temporary-file-directory) "test.org")))
        (with-current-buffer (generate-new-buffer buff-name)
          (insert-buffer-substring (find-file-noselect file-name))
          (expenses--goto-table-end (or table-name "expenses"))
          (forward-line)
          (insert "|||||\n")
          (insert "#+TBLFM: @>$2 = vsum(@2..@-1)")
          (write-file buff-name)
          (org-table-calc-current-TBLFM)
	  (write-file buff-name)
          (forward-line -1)
	  (let ((expense (string-trim (org-table-get-field 2))))
	    (delete-file buff-name)
	    (kill-buffer "test.org")
	    expense))))

(defun expenses--get-expense-filtered-by-date (dates amounts date-to-filter-with)
  "Given DATES list and AMOUNTS list filter the AMOUNT list using DATE-TO-FILTER-WITH and return the sum of the filterd list."
  (cl-loop for date in dates
	   for amount in amounts
	   if (equal date date-to-filter-with)
	   collect amount into filtered-amounts
	   finally return (-sum filtered-amounts)))

(defun expenses--get-expense-filtered-by-dates-and-categories (dates amounts categories dates-to-filter-with categories-to-filter-with)
  "Given DATES list, AMOUNTS list and CATEGORIES list, filter the AMOUNT list using DATES-TO-FILTER-WITH and the CATEGORIES-TO-FILTER-WITH and return the sum of the filterd list."
  (let ((dates-filter (if (not (listp dates-to-filter-with)) (list dates-to-filter-with) dates-to-filter-with))
	(categories-filter (mapcar #'upcase (if (not (listp categories-to-filter-with)) (list categories-to-filter-with) categories-to-filter-with))))
    (cl-loop for date in dates
	     for amount in amounts
	     for category in (mapcar #'upcase categories)
	     if (and (member date dates-filter) (member category categories-filter))
	     collect amount into filtered-amounts
	     finally return (-sum filtered-amounts))))

(defun expenses--get-expense-filtered-by-categories (amounts categories categories-to-filter-with)
  "Given AMOUNTS list and CATEGORIES list, filter the AMOUNT list using CATEGORIES-TO-FILTER-WITH and return the sum of the filterd list."
  (let ((categories-filter (mapcar #'upcase (if (not (listp categories-to-filter-with)) (list categories-to-filter-with) categories-to-filter-with))))
    (cl-loop for amount in amounts
	     for category in (mapcar #'upcase categories)
	     if (member category categories-filter)
	     collect amount into filtered-amounts
	     finally return (-sum filtered-amounts))))

(defun expenses--get-expense-for-day-filtered-by-categories (date categories &optional table-name)
  "Calculate expenses for a DATE and TABLE-NAME filtered by CATEGORIES."
  (let ((file-name (expenses--get-file-name date)))
    (if (file-exists-p file-name)
	(let ((buff-name (concat (temporary-file-directory) "test.org")))
          (with-current-buffer (generate-new-buffer buff-name)
            (insert-buffer-substring (find-file-noselect file-name))
            (expenses--goto-table-end (or table-name "expenses"))
            (forward-line)
            (insert "|||||\n")
	    (if (not (listp categories))
		(insert (format "#+TBLFM: @>$2 = '(expenses--get-expense-filtered-by-dates-and-categories (split-string \"@2$1..@-1$1\" \" \") (list @2$2..@-1$2) (split-string \"@2$3..@-1$3\" \" \") \"%s\" \"%s\");L" date categories))
	      (insert (format "#+TBLFM: @>$2 = '(expenses--get-expense-filtered-by-dates-and-categories (split-string \"@2$1..@-1$1\" \" \") (list @2$2..@-1$2) (split-string \"@2$3..@-1$3\" \" \") \"%s\" (split-string (substring \"%s\" 1 -1) \" \"));L" date categories)))
            (write-file buff-name)
            (org-table-calc-current-TBLFM)
	    (write-file buff-name)
            (forward-line -1)
	    (let ((expense (string-trim (org-table-get-field 2))))
	      (delete-file buff-name)
	      (kill-buffer "test.org")
	      expense)))
      nil)))

(defun expenses--get-expense-for-month-filtered-by-categories (date categories &optional table-name)
  "Calculate expenses for a DATE and TABLE-NAME filtered by CATEGORIES."
  (let ((file-name (expenses--get-file-name date)))
    (if (file-exists-p file-name)
	(let ((buff-name (concat (temporary-file-directory) "test.org")))
          (with-current-buffer (generate-new-buffer buff-name)
            (insert-buffer-substring (find-file-noselect file-name))
            (expenses--goto-table-end (or table-name "expenses"))
            (forward-line)
            (insert "|||||\n")
	    (if (not (listp categories))
		(insert (format "#+TBLFM: @>$2 = '(expenses--get-expense-filtered-by-categories (list @2$2..@-1$2) (split-string \"@2$3..@-1$3\" \" \") \"%s\");L" categories))
	      (insert (format "#+TBLFM: @>$2 = '(expenses--get-expense-filtered-by-categories (list @2$2..@-1$2) (split-string \"@2$3..@-1$3\" \" \") (split-string (substring \"%s\" 1 -1) \" \"));L" categories)))
            (write-file buff-name)
            (org-table-calc-current-TBLFM)
	    (write-file buff-name)
            (forward-line -1)
	    (let ((expense (string-trim (org-table-get-field 2))))
	      (delete-file buff-name)
	      (kill-buffer "test.org")
	      expense)))
      nil)))

(defun expenses--ask-for-categories ()
  "Ask for categories from user."
  (if (null expenses-category-list)
      (error "The custom variable `expenses-category-list` is empty!")
    (let* ((chosen-category (completing-read "category: " (-flatten (list "All" expenses-category-list))))
	   (category-list (list chosen-category)))
      (if (string-equal chosen-category "All")
	  expenses-category-list
	(while (string-equal "yes" (completing-read "choose another category: " '("no" "yes")))
	  (push (completing-read "category: " expenses-category-list) category-list))
	category-list))))

(defun expenses-calc-expense-for-day-filtered-by-categories ()
  "Calculate expense for DATE and TABLE-NAME filtered by CATEGORIES and show in a buffer."
  (interactive)
  (let* ((date (org-read-date nil nil nil "Date: "))
	 (categories (expenses--ask-for-categories))
	 (month (format-time-string "%B" (org-time-string-to-seconds date)))
	 (year (format-time-string "%Y" (org-time-string-to-seconds date)))
	 (day (format-time-string "%d" (org-time-string-to-seconds date)))
	 (buff-name (format "*expenses-%s-%s*" date (string-join categories "-")))
	 (expenses (cl-loop for category in categories
			    collect (expenses--get-expense-for-day-filtered-by-categories date category)))
	 (message-strings (cl-loop for category in categories
				   for expense in expenses
				   collect (format "%s = %s %11s"
						   (propertize category 'face 'expenses-face-message)
						   (or expenses-currency "")
						   (propertize (format "%.2f" (string-to-number expense)) 'face 'expenses-face-expense)))))
    (if expenses
	(with-current-buffer (generate-new-buffer buff-name)
	  (insert (propertize "---------------------------------\n" 'face 'expenses-face-message)
		  (format "%s %s %s"
			  (propertize month 'face 'expenses-face-date)
			  (propertize day 'face 'expenses-face-date)
			  (propertize year 'face 'expenses-face-date))
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message)
		  (string-join message-strings "\n")
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message)
		  (format "%s = %s %11s"
			  (propertize "Total expenses" 'face 'expenses-face-message)
			  expenses-currency
			  (propertize (format "%.2f" (string-to-number (expenses--get-expense-for-day-filtered-by-categories date categories))) 'face 'expenses-face-expense))
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message))
	  (align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
	  (switch-to-buffer-other-window buff-name))
      (message "%s %s %s %s"
	       (propertize "No expense file is found for" 'face 'expenses-face-message)
	       (propertize month 'face 'expenses-face-date)
	       (propertize day 'face 'expenses-face-date)
	       (propertize year 'face 'expenses-face-date)))))

(defun expenses-calc-expense-for-month-filtered-by-categories ()
  "Calculate expense for month filtered by categories and show result in a buffer."
  (interactive)
  (let* ((date (org-read-date nil nil nil "Date: "))
	 (categories (expenses--ask-for-categories))
	 (month (format-time-string "%B" (org-time-string-to-seconds date)))
	 (year (format-time-string "%Y" (org-time-string-to-seconds date)))
	 (buff-name (format "*expenses-%s-%s-%s*" month year (string-join categories "-")))
	 (expenses (cl-loop for category in categories
			    collect (expenses--get-expense-for-month-filtered-by-categories date category)))
	 (message-strings (cl-loop for category in categories
				   for expense in expenses
				   collect (format "%s = %s %11s"
						   (propertize category 'face 'expenses-face-message)
						   (or expenses-currency "")
						   (propertize (format "%.2f" (string-to-number expense)) 'face 'expenses-face-expense)))))
    (if expenses
	(with-current-buffer (generate-new-buffer buff-name)
	  (insert (propertize "---------------------------------\n" 'face 'expenses-face-message)
		  (format "%s %s"
			  (propertize month 'face 'expenses-face-date)
			  (propertize year 'face 'expenses-face-date))
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message)
		  (string-join message-strings "\n")
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message)
		  (format "%s = %s %11s"
			  (propertize "Total expenses" 'face 'expenses-face-message)
			  expenses-currency
			  (propertize (format "%.2f" (string-to-number (expenses--get-expense-for-month-filtered-by-categories date categories))) 'face 'expenses-face-expense))
		  (propertize "\n---------------------------------\n" 'face 'expenses-face-message))
	(align-regexp (point-min) (point-max) "\\(\\s-*\\)=")
	(switch-to-buffer-other-window buff-name))
      (message "%s %s %s"
	       (propertize "No expense file is found for" 'face 'expenses-face-message)
	       (propertize month 'face 'expenses-face-date)
	       (propertize year 'face 'expenses-face-date)))))

(defun expenses--get-expense-for-day (date &optional table-name)
  "Calculate expenses for a DATE and TABLE-NAME."
  (let ((file-name (expenses--get-file-name date)))
    (if (file-exists-p file-name)
	(let ((buff-name (concat (temporary-file-directory) "test.org")))
          (with-current-buffer (generate-new-buffer buff-name)
            (insert-buffer-substring (find-file-noselect file-name))
            (expenses--goto-table-end (or table-name "expenses"))
            (forward-line)
            (insert "|||||\n")
	    (insert (format "#+TBLFM: @>$2 = '(expenses--get-expense-filtered-by-date (split-string \"@2$1..@-1$1\" \" \") (list @2$2..@-1$2) \"%s\");L" date))
            (write-file buff-name)
            (org-table-calc-current-TBLFM)
	    (write-file buff-name)
            (forward-line -1)
	    (let ((expense (string-trim (org-table-get-field 2))))
	      (delete-file buff-name)
	      (kill-buffer "test.org")
	      expense)))
      nil)))

(defun expenses-calc-expense-for-day (date &optional table-name)
  "Calculate expense for DATE and TABLE-NAME and show message."
  (interactive
   (list (org-read-date nil nil nil "Date: ")))
  (let* ((month (format-time-string "%B" (org-time-string-to-seconds date)))
	 (year (format-time-string "%Y" (org-time-string-to-seconds date)))
	 (day (format-time-string "%d" (org-time-string-to-seconds date)))
	 (expenses (expenses--get-expense-for-day date table-name)))
    (if expenses
	(message "%s %s %s %s = %s %s"
		 (propertize "Total expenses for" 'face 'expenses-face-message)
		 (propertize month 'face 'expenses-face-date)
		 (propertize day 'face 'expenses-face-date)
		 (propertize year 'face 'expenses-face-date)
		 (or expenses-currency "")
		 (propertize (format "%.2f" (string-to-number expenses)) 'face 'expenses-face-expense))
      (message "%s %s %s %s"
	       (propertize "No expense file is found for" 'face 'expenses-face-message)
	       (propertize month 'face 'expenses-face-date)
	       (propertize day 'face 'expenses-face-date)
	       (propertize year 'face 'expenses-face-date)))))

(defun expenses--get-expense-for-month (date)
  "Calculate expense for a month specified by any DATE in that month in format YYYY-MM-DD."
  (let* ((file-name (expenses--get-file-name date)))
    (if (file-exists-p file-name)
	(expenses--get-expense-for-file file-name)
      nil)))

(defun expenses-calc-expense-for-month (date)
  "Calculate expense for a month specified by any DATE in that month in format YYYY-MM-DD."
  (interactive
   (let ((date (org-read-date nil nil nil "Date: ")))
     (list date)))
  (let* ((month (format-time-string "%B" (org-time-string-to-seconds date)))
	 (year (format-time-string "%Y" (org-time-string-to-seconds date)))
	 (expenses (expenses--get-expense-for-month date)))
    (if expenses
	(message "%s %s %s = %s %s"
		 (propertize "Total expenses for" 'face 'expenses-face-message)
		 (propertize month 'face 'expenses-face-date)
		 (propertize year 'face 'expenses-face-date)
		 (or expenses-currency "")
		 (propertize (format "%.2f" (string-to-number expenses)) 'face 'expenses-face-expense))
      (message "%s %s %s"
	       (propertize "No expense file is found for" 'face 'expenses-face-message)
	       (propertize month 'face 'expenses-face-date)
	       (propertize year 'face 'expenses-face-date)))))

(defun expenses--get-expense-for-year (year &optional start end)
  "Calculate expenses for a YEAR with optional arguments START month and END month START and END should be 1-12."
  (let* ((expenses-list (cl-loop for n in (number-sequence (or start 1) (or end 12))
				      collect (let* ((date (format "%s-%02d-01" year n))
						     (month (format-time-string "%B" (org-time-string-to-seconds date))))
						(cons month (expenses--get-expense-for-month date)))))
	 (months (mapcar #'car expenses-list))
	 (expenses (mapcar #'cdr expenses-list))
	 (total-expense (-sum (-map-when 'stringp #'string-to-number (-replace nil 0 expenses)))))
    `(("months" . ,months)
      ("expenses" . ,expenses)
      ("total" . ,total-expense))))

(defun expenses-calc-expense-for-months (year &optional start end)
  "Calculate expenses for months between START and END of a YEAR."
  (interactive
   (let* ((current-year (string-to-number (format-time-string "%Y")))
	  (picked-year (completing-read "Enter year: " (cl-loop for year-num in (number-sequence current-year (- current-year 10) -1) collect (number-to-string year-num))))
	  (picked-start (1+ (-elem-index (completing-read "Start month: " expenses-month-names) expenses-month-names)))
	  (picked-end (1+ (-elem-index (completing-read "End month: " expenses-month-names) expenses-month-names))))
     (list picked-year picked-start picked-end)))
  (let* ((expense-alist (expenses--get-expense-for-year year start end))
	 (months (cdr (assoc "months" expense-alist)))
	 (expenses (cdr (assoc "expenses" expense-alist)))
	 (total (cdr (assoc "total" expense-alist)))
	 (num-res (length months))
	 (message-strings (cl-loop for n from 0 to (1- num-res)
				  collect (let ((month (nth n months))
						(expense (nth n expenses)))
					    (format "%s = %s %11s"
						    (propertize month 'face 'expenses-face-date)
						    expenses-currency
						    (if (stringp expense)
							(propertize (format "%.2f" (string-to-number expense)) 'face 'expenses-face-expense)
						      expense)))))
	 (buffer-name (concat "*Expenses-" year (if (equal (length months) 12) "" (string-join months "-")) "*")))
    (generate-new-buffer buffer-name)
    (with-current-buffer buffer-name
      (insert (propertize "---------------------------------\n" 'face 'expenses-face-message))
      (insert (propertize (format "   Expenses for the year %s\n" year) 'face 'expenses-face-message))
      (insert (propertize "---------------------------------\n" 'face 'expenses-face-message))
      (insert (string-join message-strings "\n"))
      (insert (propertize "\n---------------------------------\n" 'face 'expenses-face-message))
      (insert (format "%s = %s %11s"
		      (propertize "Total" 'face 'expenses-face-date)
		      expenses-currency
		      (propertize (format "%.2f" total) 'face 'expenses-face-expense)))
      (insert (propertize "\n---------------------------------\n" 'face 'expenses-face-message))
      (align-regexp (point-min) (point-max) "\\(\\s-*\\)="))
    (switch-to-buffer-other-window buffer-name)))

(defun expenses-calc-expense-for-year (year)
  "Calculate expenses in a YEAR."
  (interactive
   (let* ((current-year (string-to-number (format-time-string "%Y")))
	  (picked-year (completing-read "Enter year: " (cl-loop for year-num in (number-sequence current-year (- current-year 10) -1) collect (number-to-string year-num)))))
     (list picked-year)))
  (expenses-calc-expense-for-months year))

(defun expenses-calc-expense-by-category ()
  "Calculate expenses by category."
  (interactive)
  (let ((calc-for (completing-read "Calculate expenses for: " '("day" "month" "year"))))
    (cond ((string-equal calc-for "day") (expenses-calc-expense-for-day-filtered-by-categories))
	  ((string-equal calc-for "month") (expenses-calc-expense-for-month-filtered-by-categories))
	  ((string-equal calc-for "year") (message "Will be implemented soon...")))))

(provide 'expenses)
;;; expenses.el ends here
