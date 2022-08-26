;;; yesterbox.el --- Count number of inbox messages by day -*- lexical-binding: t; -*-
;; Copyright (C) 2018 Stephen J Eglen

;; Author: Stephen J. Eglen <sje30@cam.ac.uk>
;; Version: 0.2
;; Package-Version: 20200327.52
;; Package-Commit: 7d890ab3f012b1a48a0e8e437f5fcaeba9825fdc
;; Created: 23 Nov 2018
;; Keywords: mail
;; URL: http://github.com/sje30/yesterbox
;; Package-Requires: ((emacs "24.3"))
;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License is available at
;; https://www.r-project.org/Licenses/

;;; Commentary:

;; The `yesterbox' approach to handling email is to focus on
;; reading/replying to messages sent yesterday (a finite number),
;; rather than trying to keep up with today's email (a moving target).

;; This mode assumes that you use the excellent `mu4e' mail program,
;; but could be adapted to work with other Emacs mailers.

;; When you call `M-x yesterbox', you will see a new *yesterbox*
;; buffer containing something like:
;;
;; Days  Count
;;    1     19
;;    2      5
;;    3      7
;;  4-6     13
;; 7-10     21

;; This shows that there are 19 messages in the inbox from yesterday
;; (1 day ago), 5 messages from 2 days ago and so on.  The last entry
;; shows that there are 21 messages aged between 7 and 10 days
;; inclusive.  If you then wish to see those 19 messages from
;; yesterday, just press RETURN on the corresponding line.

;; The days for which yesterbox will search can be changed by updating
;; the variable `yesterbox-days'.  If you wish to see the number of
;; messages from today you can include 0 in that list, but then you
;; might be tempted to work on today's messages...

;; The program also assumes your primary inbox is called "inbox";
;; change the variable `yesterbox-inbox' if you use a different
;; name.  Setting the variable to "inbox/" (note the final forward
;; slash) will search for the pattern "inbox" and look for emails in
;; multiple accounts.  See https://github.com/sje30/yesterbox/issues/1
;; for details.

;; Acknowledgements: Thanks to Laurent Gatto for testing and feedback.

;; TODO:
;; When quitting the search buffer, maybe return to *yesterbox* rather
;; than the mu main header.  Remember window configuration?

;;; Code:

(require 'cl-lib)

(defvar yesterbox-days '(1 2 3 (4 . 6) (7 . 10))
  "*List of days to search for in yesterbox.
Each element should either be an integer or a dotted pair of integers.
For dotted pairs, (a . b), we search for days A through B inclusive.")

(defvar yesterbox-inbox "inbox"
  "*Name of your primary inbox.")

(defun yesterbox-search-string (n)
  "Return a mu search string to find inbox messages from N days ago.
If N is an integer, search for N days ago.
If N is a dotted pair (a . b), search for messages between a and b days ago.
The name of your inbox is stored in `yesterbox-inbox'."
  (if (consp n)
      (format "maildir:/%s AND date:%s..%s"
	      yesterbox-inbox
	      (yesterbox-n-days-ago (cdr n))
	      (yesterbox-n-days-ago (car n)))
    (format "maildir:/%s AND date:%s"
	    yesterbox-inbox
	    (yesterbox-n-days-ago n))))

(defun yesterbox-n-days-ago (n)
  "Return N days ago as an absolute date."
  (format-time-string "%Y%m%d"
		      (time-subtract (current-time) (days-to-time n))))

(defun yesterbox-count-matches (search)
  "Return number of messages that match SEARCH string."
  (string-to-number
   (shell-command-to-string
    (format "mu find %s | wc -l" search))))

(defvar yesterbox-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "c" 'yesterbox-print-current-line-id)
    (define-key map "\C-m" 'yesterbox-search-current-line-id)
    (define-key map "g" 'yesterbox)
    map)
  "Local keymap for `yesterbox-mode' buffers.")

(define-derived-mode yesterbox-mode
  tabulated-list-mode "ybox" "Major mode for `yesterbox'"
  (setq tabulated-list-format [("Days" 4 t :right-align t)
			       ("Count" 6 t :right-align t)
			       ])
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Days" nil))
  (tabulated-list-init-header))

(defun yesterbox-print-current-line-id ()
  "Test for yesterbox."
  (interactive)
   (message (concat "current line ID is: " (tabulated-list-get-id))))

;;;###autoload
(defun yesterbox ()
  "Count number of inbox messages in each of the last few days.
To run the search for a given line, simply press RETURN on the
correspodning line."
  (interactive)
  (let*
      ((yesterbox-searches (mapcar #'yesterbox-search-string
				   yesterbox-days))
       (yesterbox-counts   (mapcar #'yesterbox-count-matches
				   yesterbox-searches)))
    (pop-to-buffer "*yesterbox*" nil)
    (yesterbox-mode)
    (setq tabulated-list-entries (cl-mapcar #'yesterbox-make-line
					    yesterbox-searches
					    yesterbox-days
					    yesterbox-counts))
    (tabulated-list-print t)))



(defun yesterbox-make-line (search d count)
  "Return a vector to summarise SEARCH for days D and COUNT.
This vector is used to populate `tabulated-list-entries'."
  (let ((day
	 (if (consp d)
	     (format "%s-%s" (car d) (cdr d))
	   (number-to-string d))))
    (list search (vector day (number-to-string count) ))))

;; (yesterbox-make-line "apple" 2 3)
;; (yesterbox-make-line "bee" '(2 . 4) 5)

(defun yesterbox-search-current-line-id ()
  "Run the search command associated with the current line."
  (interactive)
  (mu4e-headers-search (tabulated-list-get-id)))


;;(mu4e-headers-search "maildir:/inbox AND date:20181119..20181121")

(provide 'yesterbox)

;;; yesterbox.el ends here
