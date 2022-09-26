;;; org-custom-cookies.el --- Custom cookies for org-mode -*- lexical-binding: t -*-

;; Author: Gulshan Singh <gsingh2011@gmail.com>
;; Version: 0.1
;; Package-Version: 20220922.241
;; Package-Commit: e7474cc839a750c37de93ab7b1ac65ed61f6fe95
;; Package-Requires: ((emacs "27.2"))
;; URL: https://github.com/gsingh93/org-custom-cookies

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org mode supports the [/] and [%] statistics cookies by default
;; (https://orgmode.org/manual/Breaking-Down-Tasks.html), but does not allow you
;; to add additional types of cookies.  This package allows you to add your own
;; custom cookies and comes with implementations for cookies that calculate the
;; total duration of scheduled time, clocked time, and effort in a subtree.

;;; Code:

(require 'org)

(defcustom org-custom-cookies-alist
  '(("\\[S: ?\\(?:[0-9]*:[0-9]*\\)?\\]" . org-custom-cookies--subtree-scheduled-duration-cookie)
    ("\\[C: ?\\(?:[0-9]*:[0-9]*\\)?\\]" . org-custom-cookies--subtree-clocksum-cookie)
    ("\\[E: ?\\(?:[0-9]*:[0-9]*\\)?\\]" . org-custom-cookies--subtree-effort-cookie))
  "Association list of custom cookie regex and callback functions."
  :type '(alist :key-type string :value-type function)
  :group 'org-custom-cookies)

;;;; Scheduled time custom cookie callback

(defun org-custom-cookies--org-timestamp-string-to-duration-seconds (timestamp-string)
  "Calculates the duration in seconds of the org timestamp in TIMESTAMP-STRING."
  (let* ((ts (org-timestamp-from-string timestamp-string))
         (start-time (org-timestamp-to-time ts nil))
         (end-time (org-timestamp-to-time ts t)))
    ;; If the start and end time are equal, the timestamp is either nil or there
    ;; is no end time. In both cases, we return a duration of zero seconds
    (if (time-equal-p start-time end-time)
        0
      (time-subtract end-time start-time))))

(defun org-custom-cookies--get-entry-scheduled-duration-seconds ()
  "Return the duration in seconds of the SCHEDULED property of an org entry.

If the SCHEDULED property does not exist, or if the SCHEDULED
property does not contain an end time, zero is returned."
  (org-custom-cookies--org-timestamp-string-to-duration-seconds
   (org-entry-get nil "SCHEDULED")))

(defun org-custom-cookies--calculate-subtree-scheduled-duration-minutes ()
  "Calculate the total duration of all scheduled org entries in a subtree.

The result will be the total duration in minutes."
  (/
   (apply '+
          (org-map-entries
           'org-custom-cookies--get-entry-scheduled-duration-seconds t 'tree))
   60))

(defun org-custom-cookies--subtree-scheduled-duration-cookie ()
  "Return the total duration of all scheduled entries in a subtree.

The result will be a string of the form '[S: <duration>]'."
  (format "[S: %s]"
          (org-duration-from-minutes
           (org-custom-cookies--calculate-subtree-scheduled-duration-minutes))))

;;;; Clocksum custom cookie callback

(defun org-custom-cookies--subtree-clocksum-cookie ()
  "Return the clocksum of a subtree as a cookie string."
  (progn
    ;; `org-clock-sum' computes the CLOCKSUM property of all headings in minutes
    ;; and stores it in the :org-clock-minutes property of the heading
    (org-clock-sum)
    ;; If this heading has a clock sum, return it, otherwise return zero
    (format "[C: %s]" (org-duration-from-minutes
                       (or (get-text-property (point) :org-clock-minutes) 0)))))

;;;; Effort custom cookie callback

(defun org-custom-cookies--get-effort-minutes ()
  "Return the effort of an org entry in minutes."
  (org-duration-to-minutes (org-entry-get nil "Effort")))

(defun org-custom-cookies--calculate-subtree-effort-minutes ()
  "Calculates the total effort of all entries in a subtree in minutes."
  (apply '+ (org-map-entries
             'org-custom-cookies--get-effort-minutes "+Effort<>\"\"" 'tree)))

(defun org-custom-cookies--subtree-effort-cookie ()
  "Return the total effort of entries in a subtree as a cookie string."
  (format "[E: %s]" (org-duration-from-minutes
                     (org-custom-cookies--calculate-subtree-effort-minutes))))

;;;; Generic custom cookie code

(defun org-custom-cookies--update-current-heading-cookie (regex callback)
  "Replace a cookie in the current heading.

Cookies matching REGEX in the current heading, if any, will be
replaced with the result of CALLBACK."
  (save-excursion
    ;; Move to the beginning of the heading or point-min if this is run before
    ;; any heading
    (org-back-to-heading-or-point-min t)
    ;; Only attempt to update cookies if we're at a heading that matches the
    ;; cookie regex
    (when (and (org-at-heading-p) (re-search-forward regex (line-end-position) t))
      ;; If we find a match, call callback function to get the new text of
      ;; the cookie. We need to save the match data so we can replace the
      ;; matched cookie after the callback returns, as the callback may
      ;; overwrite the match data
      (let ((result
             (save-match-data
               ;; Return to the beginning of the heading so the callback
               ;; function can assume it's at the beginning of a heading
               (org-back-to-heading-or-point-min t)
               ;; Call the callback
               (funcall callback))))
        ;; Replace the cookie with the updated text
        (replace-match result t t)
        ;; Return t to indicate we successfully replaced the cookie
        t))))

(defun org-custom-cookies--update-nearest-heading-cookie (regex callback)
  "Replace a cookie matching REGEX with the result of CALLBACK.

If a cookie matching REGEX cannot be found in the current
heading, we go up a heading and try again until we reach the
top-level heading."
  (save-excursion
    ;; Try to update the cookie at the current heading. If the regex doesn't
    ;; match, go to the parent heading so we can try again. If there is no
    ;; parent heading, we return without doing anything
    (when
        (and
         (not (org-custom-cookies--update-current-heading-cookie regex callback))
         (org-up-heading-safe))
      ;; Try again at the parent heading
      (org-custom-cookies--update-nearest-heading-cookie regex callback))))

(defun org-custom-cookies--update-all-cookies-nearest-heading ()
  "Update all custom cookies for the nearest parent heading containing the cookie."
  (cl-loop for (regex . callback) in org-custom-cookies-alist
           do (org-custom-cookies--update-nearest-heading-cookie regex callback)))

(defun org-custom-cookies--update-all-cookies-current-heading ()
  "Update all custom cookies for the current heading."
  (cl-loop for (regex . callback) in org-custom-cookies-alist
           do (org-custom-cookies--update-current-heading-cookie regex callback)))

;;;###autoload
(defun org-custom-cookies-update-nearest-heading (&optional all)
  "Update all custom cookies for the nearest parent heading containing the cookie.

When called with a \\[universal-argument] prefix or with the
optional argument ALL, update all custom cookies in the buffer.

To customize the cookies, see `org-custom-cookies-alist'."
  (interactive "P")
  (if all
      (org-custom-cookies-update-all)
    (org-custom-cookies--update-all-cookies-nearest-heading)))

;;;###autoload
(defun org-custom-cookies-update-current-heading (&optional all)
  "Update all custom cookies defined for the current heading.

When called with a \\[universal-argument] prefix or with the
optional argument ALL, update all custom cookies in the buffer.

To customize the cookies, see `org-custom-cookies-alist'."
  (interactive "P")
  (if all
      (org-custom-cookies-update-all)
    (org-custom-cookies--update-all-cookies-current-heading)))

;;;###autoload
(defun org-custom-cookies-update-subtree (&optional all)
  "Update all custom cookies defined in the current subtree.

Cookies in the current heading will also be updated, along with
the cookies in all the child headings in the subtree.

When called with a \\[universal-argument] prefix or with the
optional argument ALL, update all custom cookies in the buffer.

To customize the cookies, see `org-custom-cookies-alist'."
  (interactive "P")
  (if all
      (org-custom-cookies-update-all)
    (org-map-entries
     'org-custom-cookies--update-all-cookies-current-heading t 'tree)))

;;;###autoload
(defun org-custom-cookies-update-containing-subtree (&optional all)
  "Update all custom cookies for all headings in the containing subtree.

The containing subtree is the subtree starting with the first
parent heading of the current heading that contains the cookie.

When called with a \\[universal-argument] prefix or with the
optional argument ALL, update all custom cookies in the buffer.

To customize the cookies, see `org-custom-cookies-alist'."
  (interactive "P")
  (if all
      (org-custom-cookies-update-all)
    (cl-loop for (regex . callback) in org-custom-cookies-alist
             do (when-let ((outline-path (org-get-outline-path t))
                           ;; Search for the first heading in this subtree that
                           ;; matches the regex
                           (heading-index
                            (cl-position regex outline-path :test 'string-match))
                           (dist (- (length outline-path) (+ 1 heading-index))))
                  (save-excursion
                    (unless (zerop dist)
                      ;; Go to that heading if we're not already there
                      (outline-up-heading dist t))
                    ;; Update that subtree
                    (org-map-entries
                     'org-custom-cookies--update-all-cookies-current-heading t 'tree))))))

;;;###autoload
(defun org-custom-cookies-update-all ()
  "Update all custom cookies for all headings in the buffer.

To customize the cookies, see `org-custom-cookies-alist'."
  (interactive)
  (org-map-entries 'org-custom-cookies--update-all-cookies-current-heading))

(provide 'org-custom-cookies)
;;; org-custom-cookies.el ends here
