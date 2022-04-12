;;; org-review.el --- schedule reviews for Org entries
;;
;; Copyright (C) 2016 Alan Schmitt
;;
;; Author: Alan Schmitt <alan.schmitt@polytechnique.org>
;; URL: https://github.com/brabalan/org-review
;; Package-Version: 20220411.1205
;; Package-Commit: 466f7d8f183f226f1e665cf806cb094471903d9c
;; Version: 0.3
;; Keywords: org review

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This allows to schedule reviews of org entries.
;;
;; Entries will be scheduled for review if their NEXT_REVIEW or their
;; LAST_REVIEW property is set. The next review date is the
;; NEXT_REVIEW date, if it is present, otherwise it is computed from
;; the LAST_REVIEW property and the REVIEW_DELAY period, such as
;; "+1m". If REVIEW_DELAY is absent, a default period is used. Note
;; that the LAST_REVIEW property is not considered as inherited, but
;; REVIEW_DELAY is, allowing to set it for whole subtrees.
;;
;; Checking of review dates is done through an agenda view, using the
;; `org-review-agenda-skip' skipping function. This function is based
;; on `org-review-toreview-p', that returns `nil' if no review is
;; necessary (no review planned or it happened recently), otherwise it
;; returns the date the review was first necessary (NEXT_REVIEW, or
;; LAST_REVIEW + REVIEW_DELAY, if it is in the past).
;;
;; To mark an entry as reviewed, use the function
;; `org-review-insert-last-review' to set the LAST_REVIEW date to the
;; current date. If `org-review-sets-next-date' is set (which is the
;; default), this function also computes the date of the next review
;; and inserts it as NEXT_REVIEW.
;;
;; Example use.
;;
;; 1 - To display the things to review in the agenda.
;;
;;   (setq org-agenda-custom-commands (quote ( ...
;;        ("R" "Review projects" tags-todo "-CANCELLED/"
;;         ((org-agenda-overriding-header "Reviews Scheduled")
;;         (org-agenda-skip-function 'org-review-agenda-skip)
;;         (org-agenda-cmp-user-defined 'org-review-compare)
;;         (org-agenda-sorting-strategy '(user-defined-down)))) ... )))
;;
;; 2 - To set a key binding to review from the agenda
;;
;;   (add-hook 'org-agenda-mode-hook (lambda () (local-set-key (kbd "C-c
;;        C-r") 'org-review-insert-last-review)))

;;; Changes
;;
;; 2016-08-18: better detection of org-agenda buffers
;; 2014-05-08: added the ability to specify next review dates

;; TODO
;; - be able to specify a function to run when marking an item reviewed

;;; Code:

(require 'org)
(require 'org-agenda)

;;; User variables:

(defgroup org-review nil
  "Org review scheduling."
  :tag "Org Review Schedule"
  :group 'org)

(defcustom org-review-last-timestamp-format 'naked
  "Timestamp format for last review properties."
  :type '(radio (const naked)
                (const inactive)
                (const active))
  :group 'org-review)

(defcustom org-review-next-timestamp-format 'naked
  "Timestamp format for last review properties."
  :type '(radio (const naked)
                (const inactive)
                (const active))
  :group 'org-review)

(defcustom org-review-last-property-name "LAST_REVIEW"
  "The name of the property for the date of the last review."
  :type 'string
  :group 'org-review)

(defcustom org-review-delay-property-name "REVIEW_DELAY"
  "The name of the property for setting the delay before the next review."
  :type 'string
  :group 'org-review)

(defcustom org-review-next-property-name "NEXT_REVIEW"
  "The name of the property for setting the date of the next review."
  :type 'string
  :group 'org-review)

(defcustom org-review-delay "+1m"
  "Time span between the date of last review and the next one.
The default value for this variable (\"+1m\") means that entries
will be marked for review one month after their last review.

If the review delay cannot be retrieved from the entry or the
subtree above, this delay is used."
  :type 'string
  :group 'org-review)

(defcustom org-review-sets-next-date t
  "Indicates whether marking a project as reviewed automatically
sets the next NEXT_REVIEW according to the current date and
REVIEW_DELAY."
  :type 'boolean
  :group 'org-review)

;;; Functions:

(defun org-review-last-planned (last delay)
  "Computes the next planned review, given the LAST review
date (in string format) and the review DELAY (in string
format)."
  (let ((lt (org-read-date nil t last))
        (ct (current-time)))
    (time-add lt (time-subtract (org-read-date nil t delay) ct))))

;;;###autoload
(defun org-review-last-review-prop (&optional pos)
  "Return the value of the last review property of the headline
at position POS, or the current headline if POS is not given."
  (org-entry-get (or pos (point)) org-review-last-property-name))

;;;###autoload
(defun org-review-next-review-prop (&optional pos)
  "Return the value of the review date property of the headline
at position POS, or the current headline if POS is not given."
  (org-entry-get (or pos (point)) org-review-next-property-name))

(defun org-review-review-delay-prop (&optional pos)
  "Return the value of the review delay property of the headline
at position POS, or the current headline if POS is not given,
considering inherited properties."
  (org-entry-get (or pos (point)) org-review-delay-property-name t))

(defun org-review-toreview-p (&optional pos)
  "Check if the entry at point should be marked for review.
Return nil if the entry does not need to be reviewed. Otherwise
return the date when the entry was first scheduled to be
reviewed.

If there is a next review date, consider it. Otherwise, if there
is a last review date, use it to compute the date of the next
review (adding the value of the review delay property, or
`org-review-delay' if there is no review delay property). If
there is no next review date and no last review date, return
nil."
  (let* ((lp (org-review-last-review-prop pos))
	 (np (org-review-next-review-prop pos))
	 (nextreview
	  (cond
	   (np (org-read-date nil t np))
	   (lp (org-review-last-planned
		lp
		(or (org-review-review-delay-prop pos)
		    org-review-delay)))
	   (t nil))))
    (and nextreview
	 (time-less-p nextreview (current-time))
	 nextreview)))

(defun org-review-insert-date (propname fmt date)
  "Insert the DATE under property PROPNAME, in the format
specified by FMT."
  (org-entry-put
   (if (equal major-mode 'org-agenda-mode)
       (or (org-get-at-bol 'org-marker)
	   (org-agenda-error))
     (point))
   propname
   (cond
    ((eq fmt 'inactive)
     (concat "[" (substring date 1 -1) "]"))
    ((eq fmt 'active) date)
    (t (substring date 1 -1)))))

;;;###autoload
(defun org-review-insert-last-review (&optional prompt)
  "Insert the current date as last review. If prefix argument:
prompt the user for the date. If `org-review-sets-next-date' is
set to t, also insert a next review date."
  (interactive "P")
  (let ((ts (if prompt
                (format-time-string (car org-time-stamp-formats) (org-read-date nil t))
              (format-time-string (car org-time-stamp-formats)))))
    (org-review-insert-date org-review-last-property-name
			    org-review-last-timestamp-format
			    ts)
    (when org-review-sets-next-date
      (org-review-insert-date
       org-review-next-property-name
       org-review-next-timestamp-format
       (format-time-string
        (car org-time-stamp-formats)
        (org-review-last-planned
         ts
         (or (org-review-review-delay-prop
              (if (equal major-mode 'org-agenda-mode)
                  (or (org-get-at-bol 'org-marker)
                      (org-agenda-error))
                (point)))
             org-review-delay)))))))

;;;###autoload
(defun org-review-insert-next-review ()
  "Prompt the user for the date of the next review, and insert
it as a property of the headline."
  (interactive)
  (let ((ts (format-time-string (car org-time-stamp-formats) (org-read-date nil t))))
    (org-review-insert-date org-review-next-property-name
			    org-review-next-timestamp-format
			    ts)))

;;;###autoload
(defun org-review-agenda-skip ()
  "To be used as an argument of `org-agenda-skip-function' to
skip entries that are not scheduled to be reviewed. This function
does not move the point; it returns nil if the entry is to be
kept, and the position to continue the search otherwise."
  (and (not (org-review-toreview-p))
       (org-with-wide-buffer (or (outline-next-heading) (point-max)))))

(defun org-review-compare (a b)
  "Compares the date of scheduled review for the two agenda
entries, to be used with `org-agenda-cmp-user-defined'. Returns
+1 if A has been scheduled for longer and -1 otherwise."
  (let* ((ma (or (get-text-property 0 'org-marker a)
                 (get-text-property 0 'org-hd-marker a)))
         (mb (or (get-text-property 0 'org-marker b)
                 (get-text-property 0 'org-hd-marker b)))
	 (ra (org-review-toreview-p ma))
	 (rb (org-review-toreview-p mb)))
    (if (time-less-p ra rb) 1 -1)))

(provide 'org-review)

;;; org-review.el ends here
