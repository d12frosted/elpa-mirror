;;; expenses.el --- Record and view expenses                  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Keywords: expense tracking, convenience
;; Package-Version: 20211220.1239
;; Package-Commit: d004cabd1a31f5010640371e8aa04f06a7d8ca29
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

(defcustom expenses-bank-profiles nil
  "Set profile for bank to use for importing expenses.
Alist bank profiles.  Each element has the form
\(BANKNAME SEP DATE-COL DEBIT-COL DATE-FORMAT NARRATIVE-COL CATEGORY-COL)."
  :type '(alist :value-type (group string integer integer string integer integer))
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

(defun expenses--get-date (file-name)
  "Get the date from a given FILE-NAME."
  (concat (substring (-last-item (split-string file-name "/")) 0 7) "-01"))

(defun expenses--goto-table-end (name)
  "Go to end of table named NAME if point is not in any table."
  (unless (org-at-table-p)
    (let ((org-babel-results-keyword "NAME"))
      (org-babel-goto-named-result name)
      (forward-line 2)
      (goto-char (org-table-end)))))

(defun expenses--goto-table-begin (name)
  "Go to begining of table named NAME if point is not in any table."
  (unless (org-at-table-p)
    (let ((org-babel-results-keyword "NAME"))
      (org-babel-goto-named-result name)
      (forward-line 2)
      (goto-char (org-table-begin)))))

(defun expenses--get-details-list (date &optional table-name)
  "Get the details list for a given month using DATE and an optional TABLE-NAME."
  (let ((file-name (expenses--get-file-name date))
	(buff-name (concat (temporary-file-directory) "test.org"))
	(details-string-list '()))
    (with-current-buffer (generate-new-buffer buff-name)
      (insert-buffer-substring (find-file-noselect file-name))
      (write-file buff-name)
      (expenses--goto-table-begin (or table-name "expenses"))
      (forward-line 2)
      (while (org-at-table-p)
	(push (string-trim (org-table-get-field 4)) details-string-list)
	(forward-line))
      (kill-buffer "test.org")
      (kill-buffer (-last-item (split-string file-name "/")))
      (delete-file buff-name)
      details-string-list)))

(defun expenses--sort-by-frequency (lst)
  "Sort a list LST by frequency."
  (let* ((unique-list (cl-remove-duplicates lst :test #'string-equal))
	 (item-frequency-alist)
	 (sorted-alist))
    (setq item-frequency-alist (cl-loop for item in unique-list
					collect (cons item (-sum (cl-loop for it in lst
									  if (string-equal item it)
									  collect 1)))))
    (setq sorted-alist (-sort (lambda (n1 n2)
				(let ((fr1 (cdr n1))
				      (fr2 (cdr n2)))
				  (> fr1 fr2))) item-frequency-alist))
    (mapcar #'car sorted-alist)))

(defun expenses--get-frequently-used-details-list (date)
  "For given DATE, get details from the already existing data.
Looks for the last two existing files and collect the details."
  (let* ((month (format-time-string "%m" (org-time-string-to-seconds date)))
	 (year (format-time-string "%Y" (org-time-string-to-seconds date)))
	 (last-month-date (org-read-date nil nil "-1m" nil (encode-time (list 0 0 0 1 (string-to-number month) (string-to-number year) nil nil nil))))
	 (details-strings-list (-remove #'string-blank-p (-flatten (cl-loop for d in (list date last-month-date)
									    collect (expenses--get-details-list d))))))
    (expenses--sort-by-frequency details-strings-list)))

(defun expenses--create-initial-file (date)
  "Create a file for a DATE with initial structure."
  (let ((file-name (expenses--get-file-name date))
	(month (format-time-string "%B" (org-time-string-to-seconds date)))
	(year (format-time-string "%Y" (org-time-string-to-seconds date))))
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
	 (amount (read-number "Amount: "))
	 (category (completing-read "Category: " expenses-category-list))
	 (details (completing-read "Details: " (expenses--get-frequently-used-details-list date)))
	 (file-name (expenses--get-file-name date)))
    (when (string-blank-p category)
      (setq category "Others"))
    (when (not (file-exists-p file-name))
      (expenses--create-initial-file date))
    (with-temp-buffer
      (insert (format "|%s |%.2f |%s |%s |\n" date amount category details))
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

;;; Import data from CSV and add entry to the expense file.
(defun expenses--read-file (file-name)
  "Read lines from file FILE-NAME and return a list of strings.
Each string represents a line in the file."
  (with-temp-buffer
   (insert-file-contents-literally file-name)
   (-remove #'string-blank-p (split-string (buffer-string) "\n"))))

(defun expenses--convert-date-to-org-format (date format)
  "Convert given DATE to yyyy-mm-dd from given FORMAT."
  (let ((day-position)
	(month-position)
	(year-position)
	(sep)
	(day)
	(month)
	(year)
	(old-list))
    (if (member format '("yyyy-mm-dd" "yyyy/mm/dd" "dd/mm/yyyy"))
	(progn (cond ((string-equal format "yyyy-mm-dd")
		      (setq day-position 2)
		      (setq month-position 1)
		      (setq year-position 0)
		      (setq sep "-"))
		     ((string-equal format "yyyy/mm/dd")
		      (setq day-position 2)
		      (setq month-position 1)
		      (setq year-position 0)
		      (setq sep "/"))
		     ((string-equal format "dd/mm/yyyy")
		      (setq day-position 0)
		      (setq month-position 1)
		      (setq year-position 2)
		      (setq sep "/")))
	       (setq old-list (split-string date sep))
	       (setq day (nth day-position old-list))
	       (setq month (nth month-position old-list))
	       (setq year (nth year-position old-list))
	       (when (< (length year) 4)
		 (setq year (concat "20" year)))
	       (format "%s-%02s-%02s" year month day))
      (let* ((time-list (parse-time-string date)))
	(setq day (nth 3 time-list))
	(setq month (nth 4 time-list))
	(unless month
	  (setq month 1))
	(setq year (nth 5 time-list))
	(when (< year 2000)
	  (setq year (concat "20" year)))
	(format "%s-%02d-%02d" year month day)))))

(defun expenses--import-data (file-name sep date-col debit-col date-format &optional narrative-col category-col)
  "Import data from FILE-NAME with SEP separated values.
Date and debit column are specified by DATE-COL and DEBIT-COL, respectively.
DATE-FORMAT specifies format of Date.
NARRATIVE-COL and CATEGORY-COL specify narrative and category column.
Column number starts with 0, i.e., second column has column no 1."
  (let* ((line-strings-list (cdr (expenses--read-file file-name)))
	 (dates)
	 (debits)
	 (narratives)
	 (categories))
    (while line-strings-list
      (let* ((current-line (car line-strings-list))
	     (current-list (split-string current-line sep))
	     (date (nth date-col current-list))
	     (debit (nth debit-col current-list))
	     (narrative "")
	     (category "ImportedFromBank"))
	(setq date (expenses--convert-date-to-org-format date date-format))
	(setq dates (cons date dates))
	(setq debits (cons debit debits))
	(when (> narrative-col 0)
	  (setq narrative (nth narrative-col current-list)))
	(when (> category-col 0)
	  (setq category (nth category-col current-list)))
	(setq narratives (cons narrative narratives))
	(setq categories (cons category categories)))
      (setq line-strings-list (cdr line-strings-list)))
    `(("dates" . ,(reverse dates))
      ("debits" . ,(reverse debits))
      ("narratives" . ,(reverse narratives))
      ("categories" . ,(reverse categories)))))

(defun expenses-test-import-data (file-name sep date-col debit-col date-format &optional narrative-col category-col)
  "Test imported data from FILE-NAME with SEP separated values.
Date and debit are specified by DATE-COL, DEBIT-COL.
DATE-FORMAT specifies date format.
Optional arguments are NARRATIVE-COL and CATEGORY-COL.
Column number starts with 0, i.e., second column has column no 1."
  (interactive
   (let ((file (read-file-name "Enter file name: "))
	 (sep (completing-read "Separtor: " '("," "\t")))
	 (date-col (read-number "date column number: (0 for first column) "))
	 (date-format (completing-read "date format" '("dd/mm/yyyy" "yyyy/mm/dd" "yyyy-mm-dd")))
	 (debit-col (read-number "debit column number: (0 for first column) "))
	 (narrative-col (read-number "narrative column number: (0 for first column, negative for no such column) "))
	 (category-col (read-number "category column number: (0 for first column, negative for no such column) ")))
     (list file sep date-col debit-col date-format narrative-col category-col)))
  (let* ((data (expenses--import-data file-name sep date-col debit-col date-format narrative-col category-col))
	 (dates (cdr (assoc "dates" data)))
	 (debits (cdr (assoc "debits" data)))
	 (narratives (cdr (assoc "narratives" data)))
	 (categories (cdr (assoc "categories" data)))
	 (test-buff "*expenses-test-import.org*")
	 (iter 0))
    (with-current-buffer (generate-new-buffer test-buff)
      (insert "|Date | Amount | Category | details|\n")
      (insert "|---|---|----|---|\n")
      (while (< iter 4)
	(let ((date (nth iter dates))
	      (amount (nth iter debits))
	      (category (nth iter categories))
	      (detail (nth iter narratives)))
	  (insert (format "|%s|%s|%s|%s|\n" date amount category detail)))
	(setq iter (1+ iter)))
      (write-file (concat (temporary-file-directory) "/" test-buff))
      (goto-char (point-max))
      (forward-line -1)
      (org-table-align)
      (write-file (concat (temporary-file-directory) "/" test-buff))
      (switch-to-buffer-other-window test-buff))))

(defun expenses-import-expense (file-name sep date-col debit-col date-format &optional narrative-col category-col)
  "Imported expense from FILE-NAME with SEP separated values.
Date and debit are specified by DATE-COL, DEBIT-COL.
DATE-FORMAT specifies date format.
Optional arguments are NARRATIVE-COL and CATEGORY-COL.
Column number starts with 0, i.e., second column has column no 1."
  (interactive
   (let ((file (read-file-name "Enter file name: "))
	 (sep (completing-read "Separtor: " '("," "\t")))
	 (date-col (read-number "date column number: (0 for first column) "))
	 (date-format (completing-read "date format" '("dd/mm/yyyy" "yyyy/mm/dd" "yyyy-mm-dd")))
	 (debit-col (read-number "debit column number: (0 for first column) "))
	 (narrative-col (read-number "narrative column number: (0 for first column, negative for no such column) "))
	 (category-col (read-number "category column number: (0 for first column, negative for no such column) ")))
     (list file sep date-col debit-col date-format narrative-col category-col)))
  (let* ((data (expenses--import-data file-name sep date-col debit-col date-format narrative-col category-col))
	 (dates (cdr (assoc "dates" data)))
	 (debits (cdr (assoc "debits" data)))
	 (narratives (cdr (assoc "narratives" data)))
	 (categories (cdr (assoc "categories" data)))
	 (add-narrative-p nil)
	 (add-category-p nil)
	 (add-one-category-for-all-entry-p nil)
	 (add-one-narrative-for-all-entry-p nil)
	 (one-narrative)
	 (one-category)
	 (file-names (delete-dups (-map #'expenses--get-file-name dates))))
    (when (< narrative-col 0)
      (when (string-equal (completing-read "No narrative column chosen. Do you want to add one for each entry?: " '("yes" "no")) "yes")
	(setq add-narrative-p t)
	(when (string-equal (completing-read "Do you want a single narrative for all entries?: " '("yes" "no")) "yes")
	  (setq add-one-narrative-for-all-entry-p t)
	  (setq one-narrative (read-string "Enter one narrative for all entries: ")))))
    (when (< category-col 0)
      (when (string-equal (completing-read "No category column chosen. Do you want to add one for each entry?: " '("yes" "no")) "yes")
	(setq add-category-p t)
	(when (string-equal (completing-read "Do you want a single category for all entries?: " '("yes" "no")) "yes")
	  (setq add-one-category-for-all-entry-p t)
	  (setq one-category (read-string "Enter one category for all entries: ")))))
    (dolist (file-name file-names)
      (unless (file-exists-p file-name)
	(expenses--create-initial-file (expenses--get-date file-name)))
      (with-temp-buffer
	(let ((new-entries))
	  (setq new-entries (cl-loop for date in dates
				     for amount in debits
				     for category in categories
				     for details in narratives
				     if (string-equal (expenses--get-file-name date) file-name)
				     collect (format "|%s |%.2f |%s |%s |"
						     date
						     (string-to-number amount)
						     (cond (add-one-category-for-all-entry-p one-category)
							   (add-category-p (completing-read (format "Add category for %s %s %s: " date amount details) expenses-category-list))
							   (t category))
						     (cond (add-one-narrative-for-all-entry-p one-narrative)
							   (add-narrative-p (read-string (format "Add details for %s %s %s: " date amount category)))
							   (t details)))))
	  (insert (string-join new-entries "\n"))
	  (append-to-file (point-min) (point-max) file-name)))
      (with-current-buffer (find-file-noselect file-name)
	(goto-char (point-max))
	(forward-line -2)
	(org-table-align)
	(write-file file-name)))))

(defun expenses-import-expense-with-bank-profile (file-name bank-name)
  "Import expenses from a CSV file with FILE-NAME for a bank with BANK-NAME."
  (interactive
   (list (read-file-name "Enter file name: ")
	 (if expenses-bank-profiles
	     (completing-read "Enter bank name: " (mapcar #'car expenses-bank-profiles))
	   (error "No bank profiles are found. Set the bank profile using `expenses-bank-profiles`!"))))
   (let* ((profile (cdr (assoc bank-name expenses-bank-profiles)))
	  (sep (-first-item profile))
	  (date-col (-second-item profile))
	  (debit-col (-third-item profile))
	  (date-format (-fourth-item profile))
	  (narrative-col (-fifth-item profile))
	  (category-col (nth 5 profile)))
     (expenses-import-expense file-name sep date-col debit-col date-format narrative-col category-col)))

(provide 'expenses)
;;; expenses.el ends here
