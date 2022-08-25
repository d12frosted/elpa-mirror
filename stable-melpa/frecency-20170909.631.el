;;; frecency.el --- Library for sorting items by frequency and recency of access -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/frecency.el
;; Package-Version: 20170909.631
;; Package-Commit: 132130088ef5695cffed6fcacfa219cb0c389026
;; Version: 0.1-pre
;; Package-Requires: ((emacs "25.1") (a "0.1") (dash "2.13.0"))
;; Keywords: libraries recency recent frequency frequent

;;; Commentary:

;; This library provides a way to sort items by "frecency" (frequency
;; and recency).

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Install these required packages:
;;
;; + a
;; + dash
;;
;; Then put this file in your load-path.

;;;; Usage

;; Load the library with:
;;
;; (require 'frecency)
;;
;; The library operates on individual items.  That is, you have a list
;; of items that are frequently (or not-so-frequently) accessed, and
;; you pass each item to these functions:
;;
;; + `frecency-score' returns the score for an item, which you may use
;; to sort a list of items (e.g. you may pass `frecency-score' to
;; `cl-sort' as the `:key' function).
;;
;; + `frecency-sort' returns a list sorted by frecency.  Each item in
;; the list must itself be a collection with valid frecency keys and
;; values.
;;
;; + `frecency-update' returns an item with its frecency values
;; updated.  If the item doesn't have any frecency keys (e.g. if it's
;; the first time it's been accessed or recorded), they will be added.
;;
;; An item should be an alist or a plist.  These keys are used by the
;; library:
;;
;; + :frecency-num-timestamps
;; + :frecency-timestamps
;; + :frecency-total-count
;;
;; All other keys are ignored and returned with the item.
;;
;; The library uses alists by default, but it can operate on plists,
;; hash-tables, or other collections by setting `:get-fn' and
;; `:set-fn' when calling a function (e.g. when using plists, set them
;; to `plist-get' and `plist-put' respectively).  `:get-fn' should
;; have the signature (ITEM KEY), and `:set-fn' (ITEM KEY VALUE).

;;;; Tips

;; + You can customize settings in the `frecency' group.

;;;; Credits

;; This package is based on the "frecency" algorithm which was
;; (perhaps originally) implemented in Mozilla Firefox, and has since
;; been implemented in other software.  Specifically, this is based on
;; the implementation described here:

;; <https://slack.engineering/a-faster-smarter-quick-switcher-77cbc193cb60>

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

;;;; Requirements

(require 'a)
(require 'dash)

;;;; Variables

(defgroup frecency nil
  "Settings for `frecency'."
  :link '(url-link "http://github.com/alphapapa/frecency.el"))

(defcustom frecency-max-timestamps 10
  "Maximum number of timestamps to record for each item."
  :type 'integer)

;;;; Functions

;;;;; Public

(cl-defun frecency-score (item &key (get-fn #'a-get))
  "Return score of ITEM.
ITEM should be a collection (an alist by default).  If not an
alist, GET-FN should be set accordingly (e.g. `plist-get' for a
plist)."
  (declare (indent defun))
  (let* ((timestamps (funcall get-fn item :frecency-timestamps))
         (num-timestamps (funcall get-fn item :frecency-num-timestamps))
         (latest-timestamp (car timestamps))
         (latest-timestamp-score (frecency--score-timestamp latest-timestamp))
         (total-count (funcall get-fn item :frecency-total-count)))
    (/ (* total-count latest-timestamp-score)
       num-timestamps)))

(cl-defun frecency-sort (list &optional &key (get-fn #'a-get))
  "Return LIST sorted by frecency.
Uses `cl-sort'.  This is a destructive function; it reuses the
storage of LIST if possible."
  (cl-sort list #'> :key (lambda (item)
                           (frecency-score item :get-fn get-fn))))

(cl-defun frecency-update (item &optional &key (get-fn #'a-get) (set-fn #'a-assoc))
  "Return ITEM with current timestamp added and counts incremented.
ITEM should be a collection (an alist by default).  If not an
alist, GET-FN and SET-FN should be set
accordingly (e.g. `plist-get' and `plist-put' for a plist)."
  (declare (indent defun))
  (let* ((current-time (float-time (current-time)))
         (timestamps (cons current-time (funcall get-fn item :frecency-timestamps)))
         (num-timestamps (length timestamps))
         (total-count (or (funcall get-fn item :frecency-total-count) 0)))
    (when (> num-timestamps frecency-max-timestamps)
      (setq timestamps (cl-subseq timestamps 0 frecency-max-timestamps)
            num-timestamps frecency-max-timestamps))
    (--> item
         (funcall set-fn it :frecency-timestamps timestamps)
         (funcall set-fn it :frecency-num-timestamps num-timestamps)
         (funcall set-fn it :frecency-total-count (1+ total-count)))))

;;;;; Private

(defun frecency--score-timestamp (timestamp &optional current-time)
  "Return score for TIMESTAMP depending on current time.
If CURRENT-TIME is given, it is used instead of getting the
current time."
  (let* ((current-time (float-time (or current-time (current-time))))
         (difference (- current-time timestamp)))
    (cond
     ((<= difference 14400) ;; Within past 4 hours
      100)
     ((<= difference 86400) ;; Within last day
      80)
     ((<= difference 259200) ;; Within last 3 days
      60)
     ((<= difference 604800) ;; Within last week
      40)
     ((<= difference 2419200) ;; Within last 4 weeks
      20)
     ((<= difference 7776000) ;; Within last 90 days
      10)
     (t ;; More than 90 days
      0))))

;;;; Footer

(provide 'frecency)

;;; frecency.el ends here
