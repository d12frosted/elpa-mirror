;;; text-categories.el --- Assign text categories to a buffer for mass deletion -*- lexical-binding: t -*-

;; Copyright (C) 2021 Dionisios Spiliopoulos

;; Author: Dionisios Spiliopoulos <dennisspiliopoylos@gmail.com>
;; Keywords: lisp
;; Package-Version: 20211001.830
;; Package-Commit: f73b0e63072463c91a75a292fa21d39a9f06b81c
;; Version: 0.0.1
;; URL: https://github.com/Dspil/text-categories
;; Package-Requires: ((emacs "26.2"))

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

;; Annotates each character in the buffer with a category chosen by
;; the user.  The user can delete all characters belonging to a
;; certain category.

;;; Code:

;; libraries

(require 'cl-lib)

;; variables

(defvar-local text-categories nil "Tracks whether text-categories is enabled.")
(defvar-local text-categories-category nil "Tracks the current text category number.\nCan be a single digit number.")
(defvar-local text-categories-suppress-changes nil "Tracks whether we are deleting right now.")
(defvar-local text-categories-default "0" "Holds the default text category number.")
(defvar-local text-categories-file-prefix "~text_categories::" "The prefix of text categories files.")
(defvar-local text-categories-viz-prefix "~text_categories_viz::" "The prefix of text categories vizualization buffer.")
(defvar-local text-categories-stored '() "Assoc list holding all the stored categories.")
(defvar-local text-categories-default-cycle '("0" "1") "Default categories to cycle them easily.")

(defvar text-categories-save t "If t, saving the buffer saves the text categories of its characters.")
(defvar text-categories-colorwheel '("dark orange" "deep pink" "chartreuse" "deep sky blue" "yellow" "orchid" "spring green" "sienna1") "Contains the colors of the categories to show in the visualization.")

;; helper functions

(defun text-categories-viz-buffer ()
  "Return a visualization buffer name corresponding to the current buffer."
  (concat text-categories-viz-prefix (buffer-name)))

(defun text-categories-kill-viz ()
  "Kill the visualization buffer if it exists."
  (when (get-buffer (text-categories-viz-buffer))
    (kill-buffer (text-categories-viz-buffer))))

(defun text-categories-filename ()
  "Return a filename corresponding to the current buffer."
  (concat text-categories-file-prefix (buffer-name)))

(defun text-categories-dump (data filename)
  "Dump DATA in the file FILENAME."
  (with-temp-file filename
    (prin1 data (current-buffer))))

(defun text-categories-load (filename)
  "Restore data from the file FILENAME."
  (with-temp-buffer
    (insert-file-contents filename)
    (cl-assert (bobp))
    (read (current-buffer))))

(defun text-categories-list ()
  "Return the distinct text categories existing in the current buffer."
  (let ((found '()))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
	(let ((property (get-text-property (point) 'text-categories-category)))
	  (unless (member property found)
	    (setq found (cons property found))))
	(forward-char)))
    found))

(defun text-categories-list-stored ()
  "Return the stored categories."
  (cl-map 'list 'car text-categories-stored))

(defun text-categories-load-categories ()
  "Load categories from file if it exists."
  (if (file-exists-p (text-categories-filename))
      (progn
	(setq-local text-categories-suppress-changes t)
	(let* ((data (text-categories-load (text-categories-filename)))
	       (stored (nth 0 data))
	       (foundmap (nth 1 data))
	       (catstring (nth 2 data)))
	  (setq-local text-categories-stored stored)
	  (save-excursion
	    (goto-char (point-min))
	    (while (not (eobp))
	      (put-text-property (point) (1+ (point)) 'text-categories-category (car (rassoc (string-to-char (substring catstring (1- (point)) (point))) foundmap)))
	      (forward-char))))
	(setq-local text-categories-suppress-changes nil))
    (put-text-property (point-min) (point-max) 'text-categories-category text-categories-default)))

(defun text-categories-color-map-helper (found colors acc)
  "Helper function for making the color map using FOUND categories COLORS as the available colors and ACC for aggregating it."
  (if (equal (length found) 0)
      acc
    (when (equal (length colors) 0)
      (setq colors text-categories-colorwheel))
    (text-categories-color-map-helper (cdr found) (cdr colors) (cons (cons (car found) (car colors)) acc))))

(defun text-categories-color-map (found)
  "Make an association list of FOUND categories with cycling the colorwheel."
  (text-categories-color-map-helper found '() '()))

(defun text-categories-make-legend (found stored)
  "Print the description of the visualization buffer for FOUND and STORED categories."
  (let ((str "Helper Buffer for inspecting text categories.\nCategories in buffer:\n")
	(nostart nil))
    (while (> (length found) 0)
      (setq str (concat str (and nostart " | ") (propertize (car found) 'text-categories-category (car found))))
      (setq nostart t)
      (setq found (cdr found)))
    (when stored
      (setq str(concat str "\nStored categories:\n"))
      (setq nostart nil)
      (while (> (length stored) 0)
	(setq str (concat str (and nostart " | ") (propertize (car stored) 'text-categories-category (car stored))))
	(setq nostart t)
	(setq stored (cdr stored))))
    (insert str "\nBuffer contents:\n\n")))

(defun text-categories-list-next (l i)
  "Get the next item in list L from item I cycling to the first item if I is the last one."
  (text-categories-list-next-helper l i (car l)))

(defun text-categories-list-next-helper (l i first)
  "Get the next item in list L from item I cycling to FIRST item if I is the last one."
  (if (equal (car l) i)
      (if (not (cdr l)) first (nth 1 l))
    (text-categories-list-next-helper (cdr l) i first)))

;; enable-disable

(defun text-categories-enable ()
  "Enable text categories."
  (setq-local text-categories t)
  (setq-local text-categories-category text-categories-default)
  (setq-local text-categories-stored '())
  (if text-categories-save
      (text-categories-load-categories)
    (put-text-property (point-min) (point-max) 'text-categories-category text-categories-default))
  (text-categories-enable-hooks)
  (message "Text categories enabled"))

(defun text-categories-disable ()
  "Disable text categories."
  (setq-local text-categories nil)
  (text-categories-disable-hooks)
  (text-categories-kill-viz)
  (when (buffer-file-name)
    (let ((text-categories-file
	   (concat
	    (file-name-directory (buffer-file-name))
	    (concat text-categories-file-prefix (file-name-nondirectory (buffer-file-name))))))
      (when (file-exists-p text-categories-file)
	(delete-file text-categories-file))))
  (message "Text categories disabled"))

;; commands

(defun text-categories-get (category)
  "Get a CATEGORY from the user."
  (interactive "sEnter category: ")
  category)

(defun text-categories ()
  "Toggle text categories."
  (interactive)
  (if text-categories (text-categories-disable) (text-categories-enable)))

(defun text-categories-change (category)
  "Change the text category.\n CATEGORY: the category to change to."
  (interactive "sEnter category: ")
  (unless text-categories (text-categories-enable))
  (if (assoc category text-categories-stored)
      (message "Can't change to a stored category.")
    (setq-local text-categories-category category)))

(defun text-categories-delete (category)
  "Delete each character belonging to text category CATEGORY."
  (interactive "sEnter category to delete: ")
  (when text-categories
    (setq-local text-categories-suppress-changes t)
    (let ((prevpoint (point)))
      (goto-char (point-min))
      (while (not (eobp))
	(if (equal (get-text-property (point) 'text-categories-category) category)
	    (progn
	      (delete-char 1)
	      (when (<= (point) prevpoint)
		(setq prevpoint (1- prevpoint))))
	  (forward-char)))
      (goto-char prevpoint)
      (setq-local text-categories-suppress-changes nil)))
  (when (not text-categories) (message "Text categories are not active.")))

(defun text-categories-report ()
  "Report the current text category and all the categories that exist in the buffer."
  (interactive)
  (when text-categories
    (message "Current text category: %s\nCategories in buffer: %s" text-categories-category (text-categories-list)))
  (when (not text-categories) (message "Text categories are not active.")))

(defun text-categories-reset ()
  "Reset the text category to the default one."
  (interactive)
  (setq-local text-categories-category text-categories-default)
  (text-categories-report))

(defun text-categories-visualize ()
  "Show the text categories of characters in a separate buffer."
  (interactive)
  (if text-categories
      (progn
	(let* ((name (buffer-name))
	       (found (sort (text-categories-list) 'string-lessp))
	       (stored (sort (text-categories-list-stored) 'string-lessp))
	       (cmap (text-categories-color-map (sort (cl-concatenate 'list stored found) 'string-lessp))))
	  (with-current-buffer (get-buffer-create (text-categories-viz-buffer))
	    (setq-local buffer-read-only nil)
	    (erase-buffer)
	    (text-categories-make-legend found stored)
	    (insert-buffer-substring name)
	    (goto-char (point-min))
	    (while (not (eobp))
	      (let* ((cat (get-text-property (point) 'text-categories-category))
		     (color (cdr (assoc cat cmap))))
		(put-text-property (point) (1+ (point)) 'face (list :foreground color)))
	      (forward-char))
	    (goto-char (point-min))
	    (put-text-property (point-min) (point-max) 'invisible nil)
	    (setq-local buffer-read-only t))
	  (pop-to-buffer (text-categories-viz-buffer))))
    (message "Text categories are not active.")))

(defun text-categories-change-region-category (start end)
  "Print number of lines and characters in the active region START - END."
  (interactive "r")
  (when mark-active
    (let ((cat (call-interactively 'text-categories-get)))
      (if (assoc cat text-categories-stored)
	  (message "Cannot update region category to a stored one.")
	(setq text-categories-suppress-changes t)
	(put-text-property start end 'text-categories-category cat)
	(setq text-categories-suppress-changes nil))))
  (when (not mark-active) (message "Mark is inactive.")))

(defun text-categories-toggle-hidden (category)
  "Toggle the visibility of characters belonging to CATEGORY."
  (interactive "sEnter category: ")
  (when text-categories
    (setq text-categories-suppress-changes t)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
	(when (equal (get-text-property (point) 'text-categories-category) category)
	  (put-text-property (point) (1+ (point)) 'invisible (not (get-text-property (point) 'invisible))))
	(forward-char)))
    (setq text-categories-suppress-changes nil))
  (when (not text-categories)
    (message "Text categories are not active.")))

(defun text-categories-enable-on-find-file ()
  "If ENABLE is t, when loading a file that has a corresponding text categories file, it will enable the text categories and load them from the file."
  (interactive)
  (add-hook 'find-file-hook 'text-categories-after-load-fun))

(defun text-categories-store-category (category)
  "Store the characters belonging to CATEGORY for later restore."
  (interactive "sEnter category: ")
  (when text-categories
    (if (assoc category text-categories-stored)
	(message "Can't store an already stored category.")
      (let ((regions '()))
	(save-excursion
	  (goto-char (point-min))
	  (when (equal (get-text-property (point) 'text-categories-category) category)
	    (setq regions (cons '(1) regions))
	    (when (not (equal (get-text-property (1+ (point)) 'text-categories-category) category))
	      (setq regions (cons (list (substring-no-properties (buffer-string) 0 1) 1 1) '()))
	      (delete-char 1)))
	  (forward-char)
	  (while (not (equal (point) (1- (point-max))))
	    (let ((prev (get-text-property (1- (point)) 'text-categories-category))
		  (cur (get-text-property (point) 'text-categories-category))
		  (next (get-text-property (1+ (point)) 'text-categories-category)))
	      (when (and (not (equal prev category)) (equal cur category))
		(setq regions (cons (list (point)) regions)))
	      (when (and (not (equal next category)) (equal cur category))
		(setq regions (cons (cons (substring-no-properties (buffer-string) (1- (car (car regions))) (point)) (cons (point) (car regions))) (cdr regions)))
		(save-excursion
		  (let ((catend (nth 1 (car regions)))
			(catstart (nth 2 (car regions))))
		    (goto-char catstart)
		    (delete-char (1+ (- catend catstart))))))
	      (forward-char)))
	  (when (integerp (car (car regions)))
	    (setq regions (cons (cons (substring-no-properties (buffer-string) (1- (car (car regions))) (point)) (cons (point) (car regions))) (cdr regions)))
	    (save-excursion
	      (let ((catend (nth 1 (car regions)))
		    (catstart (nth 2 (car regions))))
		(goto-char catstart)
		(delete-char (1+ (- catend catstart))))))
	  (when (and (equal (get-text-property (1- (point-max)) 'text-categories-category) category)
		     (not (equal (get-text-property (- (point-max) 2) 'text-categories-category) category)))
	    (setq regions (cons (list (substring-no-properties (buffer-string) (- (point-max) 2) (1- (point-max))) (1- (point-max)) (1- (point-max))) regions))
	    (save-excursion
	      (goto-char (point-max))
	      (delete-char -1))))
	(when regions
	  (when (equal text-categories-category category)
	    (setq text-categories-category text-categories-default))
	  (setq-local text-categories-stored (cons (cons category regions) text-categories-stored)))))))

(defun text-categories-restore-category (category)
  "Restore the characters belonging to CATEGORY."
  (interactive "sEnter category: ")
  (when text-categories
    (save-excursion
    (let ((stored (assoc category text-categories-stored)))
      (if (not stored)
	  (message "No such category stored.")
	(setq text-categories-suppress-changes t)
	(let ((regions (cdr stored)))
	  (while regions
	    (let ((cattext (car (car regions)))
		  (catend (nth 1 (car regions)))
		  (catstart (nth 2 (car regions))))
	      (goto-char catstart)
	      (insert cattext)
	      (put-text-property catstart (1+ catend) 'text-categories-category category)
	      (setq regions (cdr regions)))))
	(setq-local text-categories-stored (assoc-delete-all category text-categories-stored))
	(setq text-categories-suppress-changes nil))))))

(defun text-categories-store-restore (category)
  "If CATEGORY is not stored, store it, else restore it."
  (interactive "sEnter category: ")
  (when text-categories
    (if (assoc category text-categories-stored)
	(text-categories-restore-category category)
      (text-categories-store-category category))))

(defun text-categories-cycle-line ()
  "Cycle through the default categories cycle to the next one for this line."
  (interactive)
  (when (not text-categories)
    (text-categories-enable))
  (save-excursion
    (setq text-categories-suppress-changes t)
    (let ((prevpoint (point))
	  (beg 0)
	  (end 0)
	  (found '()))
      (while (not (or (bobp) (equal (char-before) ?\n)))
	(backward-char))
      (setq beg (point))
      (goto-char prevpoint)
      (while (not (or (eobp) (equal (char-after) ?\n)))
	(forward-char))
      (setq end (point))
      (when (equal (char-after) ?\n)
	(setq end (1+ end)))
      (goto-char beg)
      (while (not (equal (point) end))
	(let ((property (get-text-property (point) 'text-categories-category)))
	  (unless (member property found)
	    (setq found (cons property found))))
	(forward-char))
      (if (not (equal (length found) 1))
	  (progn
	    (put-text-property beg end 'text-categories-category (car text-categories-default-cycle))
	    (message "Category of line changed to: %s" (car text-categories-default-cycle)))
	(let ((cat (car found)))
	  (if (member cat text-categories-default-cycle)
	      (let ((newcat (text-categories-list-next text-categories-default-cycle cat)))
		(put-text-property beg end 'text-categories-category newcat)
		(message "Category of line changed to: %s" newcat))
	    (put-text-property beg end 'text-categories-category (car text-categories-default-cycle))
	    (message "Category of line changed to: %s" (car text-categories-default-cycle))))))
    (setq text-categories-suppress-changes nil)))

;; hooks

(defun text-categories-after-load-fun ()
  "After opening a file, if a categories file exist, enable text categories."
  (when (file-exists-p (text-categories-filename))
    (text-categories-enable)))

(defun text-categories-after-changes-fun (beg end len)
  "Do the corresponding change to the text categories buffer at position BEG - END with previous length of string LEN.  This function is hooked to 'after-change-functions'."
  (unless text-categories-suppress-changes
    (put-text-property beg end 'text-categories-category text-categories-category))
  (setq-local text-categories-stored
	      (cl-map 'list
		   (lambda (cat)
		     (cons (car cat)
			   (cl-map 'list
				(lambda (region)
				  (let ((cattext (nth 0 region))
					(catend (nth 1 region))
					(catstart (nth 2 region)))
				    (if (> catstart beg)
					(list cattext
					      (+ catend (- (- end beg) len))
					      (+ catstart (- (- end beg) len)))
				      (list cattext catend catstart))))
				(cdr cat))))
		   text-categories-stored)))

(defun text-categories-after-save-fun ()
  "Save the text categories of characters of the saved buffer in a file for later use."
  (when (and text-categories (> (point-max) 1))
    (let* ((found (text-categories-list))
	   (foundmap (cl-mapcar #'cons found (number-sequence 1 (length found))))
	   (catstring ""))
      (save-excursion
	(goto-char (point-min))
	(while (not (eobp))
	  (setq catstring (concat catstring (string (cdr (assoc (get-text-property (point) 'text-categories-category) foundmap)))))
	  (forward-char)))
      (text-categories-dump (list text-categories-stored foundmap catstring) (text-categories-filename)))))

(defun text-categories-enable-hooks ()
  "Add text categories hooks."
  (add-hook 'after-change-functions 'text-categories-after-changes-fun t t)
  (add-hook 'kill-buffer-hook 'text-categories-kill-viz)
  (when text-categories-save
    (add-hook 'after-save-hook 'text-categories-after-save-fun)))

(defun text-categories-disable-hooks ()
  "Remove all text categories hooks."
  (remove-hook 'after-change-functions 'text-categories-after-changes-fun t)
  (remove-hook 'kill-buffer-hook 'text-categories-kill-viz)
  (remove-hook 'after-save-hook 'text-categories-after-save-fun))

(provide 'text-categories)

;;; text-categories.el ends here
