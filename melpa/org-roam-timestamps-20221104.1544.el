;;; org-roam-timestamps.el --- Keep track of modification times for org-roam -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Thomas F. K. Jorna
;;
;; Author: Thomas F. K. Jorna <https://github.com/thomas>
;; Maintainer: Thomas F. K. Jorna <jorna@jtrialerror.com>
;; Created: September 27, 2021
;; Modified: September 27, 2021
;; Version: 1.0.0
;; Package-Version: 20221104.1544
;; Package-Commit: c4ff1e2f5b0905b5caa917249aab56ddc1de1ab3
;; Keywords: calendar outlines files
;; Homepage: https://github.com/ThomasFKJorna/org-roam-timestamps/
;; Package-Requires: ((emacs "26.1") (org-roam "2.0.0"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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
;;
;;; Commentary:
;;
;; Automatically add modified and creation times to org-roam-nodes'
;; property drawers. Main usecase will be for org-roam-ui, but can still
;; be useful for other application which wish to sort nodes, not files,
;; by their modification time, and also keep track of creation times
;; without relying on the org-roam-slug.
;;
;;; Code:

(require 'org-roam)

(defgroup org-roam-timestamps nil
  "Creation and modification timestamps in Org-roam."
  :group 'org-roam
  :prefix "org-roam-timestamps-"
  :link '(url-link :tag "Github" "https://github.com/ThomasFKJorna/org-roam-timestamps"))

(defcustom org-roam-timestamps-timestamp-parent-file t
  "Whether to timestamp the parent file when modifying a child node."
  :group 'org-roam-timestamps
  :type 'boolean)

(defcustom org-roam-timestamps-remember-timestamps t
  "Whether to keep previous timestamps when updating the current one.
This allows you to see when you modified said file,
but will increase note and db file size."
  :group 'org-roam-timestamps
  :type 'boolean)

(defcustom org-roam-timestamps-minimum-gap 3600
  "Minimal timedelay between successive mtime recordings in seconds.
Only does something when `org-roam-timestamps-remember-timestamps' is t.
Defaults to one hour."
  :group 'org-roam-timestamps
  :type 'number)

;;;###autoload
(define-minor-mode org-roam-timestamps-mode
  "Automatically add creation and modification timestamps to org-roam nodes."
  :global t
  :group 'org-roam-timestamps
  :lighter " org-roam-timestamps"
  :init-value nil
  (if org-roam-timestamps-mode
      (add-hook 'before-save-hook #'org-roam-timestamps--on-save)
    (remove-hook 'before-save-hook #'org-roam-timestamps--on-save)))

(defun org-roam-timestamps--on-save ()
  "Set the MTIME property of the current org-roam-node to the current time."
  (when (org-roam-buffer-p)
    (let* ((node (org-roam-node-at-point))
           (file (org-roam-node-file node))
           (pos (org-roam-node-point node))
           (level (org-roam-node-level node))
           (mtime (org-roam-timestamps--get-mtime node)))

      (org-roam-timestamps--add-mtime node mtime)
      (unless (org-roam-timestamps--get-ctime pos)
        (org-roam-timestamps--add-ctime node))
      (when (and org-roam-timestamps-timestamp-parent-file (not (eq level 0)))
        (let* ((pnode (org-roam-timestamps--get-parent-file-node file))
               (pmtime (org-roam-timestamps--get-mtime pnode))
               (ppos (buffer-end -1)))
          (org-roam-timestamps--add-mtime pnode pmtime)
          (unless (org-roam-timestamps--get-ctime ppos)
            (org-roam-timestamps--add-ctime pnode))))
      nil)))

(defun org-roam-timestamps--add-mtime (node &optional mtime)
  "Add the current time to the node NODE.

Optionally checks the minimum time interval you want between mod times
if you supply the current MTIME."
  (org-with-wide-buffer
   (let ((pos (if node (org-roam-node-point node) (point-min)))
         (curr (org-roam-timestamps-decode (current-time))))
     (if (and org-roam-timestamps-remember-timestamps mtime)
         (when (> (org-roam-timestamps-subtract curr mtime t) org-roam-timestamps-minimum-gap)
           (org-entry-put pos "mtime" (concat (org-roam-timestamps-decode (current-time)) " " mtime)))
       (org-entry-put pos "mtime" curr)))))

(defun org-roam-timestamps--get-mtime (node)
  "Get the mtime of the org-roam node NODE."
  (org-with-wide-buffer
   (org-entry-get (if node (org-roam-node-point node) (point-min)) "mtime")))

(defun org-roam-timestamps--get-ctime (pos)
  "Return the current ctime for the node at point POS."
  (org-with-wide-buffer
   (org-entry-get pos "ctime")))

(defun org-roam-timestamps--add-ctime (node)
  "Return the current ctime for the node NODE.

For file level nodes it tries to deduce the creation time
from the slug, otherwise it uses the lowest mtime.
We can be assured an mtime is set, as that happens before setting the
ctime."
  (let ((pos (org-roam-node-point node))
        (file (org-roam-node-file node))
        (level (org-roam-node-level node)))
    (save-excursion
      (org-with-wide-buffer
       (if-let
           ((toplevel (= 0 (or level 0)))
            (filename (file-name-base file))
            (index (string-match "^[0-9]\\{14\\}" filename))
            (timestamp (substring filename index (+ index 14))))
           (org-entry-put pos "ctime" timestamp)
         (org-entry-put pos "ctime" (car(last (split-string (org-entry-get pos "mtime"))))))))))

(defun org-roam-timestamps--get-parent-file-id (file)
  "Find the top level node-id of FILE."
  (caar (org-roam-db-query `[:select nodes:id :from nodes :where (and (= nodes:file ,file) (= nodes:level 0))])))

(defun org-roam-timestamps--get-parent-file-node (file)
  "Find the top level node of FILE."
  (org-roam-node-from-id (org-roam-timestamps--get-parent-file-id file)))

(defun org-roam-timestamps-decode (mtime)
  "Decode a list of seconds since 1970 MTIME to an org-roam-timestamp."
  (let ((time (decode-time mtime))
        dec-time
        el)
    (dotimes (i 6 )
      (setq el (number-to-string (nth i time)))
      (when (eq (length el) 1) (setq el (concat "0" el)))
      (setq dec-time
            (concat el dec-time)))
    dec-time))

(defun org-roam-timestamps-encode (mtime)
  "Encode the current YYYYMMDDHHMMSS MTIME string to an Emacs format."
  (encode-time `(,(string-to-number (substring mtime 12 14))
                 ,(string-to-number (substring mtime 10 12))
                 ,(string-to-number (substring mtime 8 10))
                 ,(string-to-number (substring mtime 6 8))
                 ,(string-to-number (substring mtime 4 6))
                 ,(string-to-number (substring mtime 0 4))
                 nil -1 nil)))

(defun org-roam-timestamps-subtract (t1 t2 &optional abs)
  "Return the difference between two timestamps T1 and T2, as a time value.
If ABS is non-nil, return the absolute value."
  (let ((time
         (time-subtract (org-roam-timestamps-encode t1) (org-roam-timestamps-encode t2))))
    (if abs
        (abs time)
      time)))


(defun org-roam-timestamps-all ()
  "Go through all nodes and add timestamps to them."
  (interactive)
  (when (yes-or-no-p "This will modify all your current notes by adding a ctime and mtime property
to all property drawers. We will make a backup of your notes and db first.
This might take a second. Are you sure you want to continue?")
    (let ((backup-dir (expand-file-name "org-roam-timestamp.bak"
                                        (file-name-directory (directory-file-name org-roam-directory))))
          (backup-db (expand-file-name "org-roam-db.bak" (file-name-directory org-roam-db-location))))
      (message "Backing up files to %s" backup-dir)
      (copy-directory org-roam-directory backup-dir)
      (message "Backing up db to %s" backup-db)
      (copy-file org-roam-db-location backup-db))
    (let ((nodes (org-roam-db-query [:select id :from nodes])))
      (dolist (node nodes)
        (let* ((n (org-roam-node-from-id (car node)))
               (file (org-roam-node-file n))
               (mtime (org-roam-timestamps-decode (org-roam-node-file-mtime n)))
               (pos (org-roam-node-point n))
               (props (org-roam-node-properties n)))
          (org-roam-with-file file nil
            (goto-char pos)
            (unless (assoc-default "MTIME" props)
              (org-roam-property-add "mtime" mtime ))
            (unless (assoc-default "CTIME" props)
              (if-let ((filename (file-name-base file))
                       (index (string-match "^[0-9]\\{14\\}" filename))
                       (timestamp (substring filename index (+ index 14))))
                  (org-roam-property-add "ctime" timestamp)
                (org-roam-property-add "ctime" mtime)))
            (save-buffer))))))
  (org-roam-db-sync))

(defun org-roam-timestamps-clean-mtime ()
  "Truncate all timestamps to a single value."
  (interactive)
  (org-roam-timestamps-mode -1)
  (let ((nodes (org-roam-db-query [:select id :from nodes])))
    (dolist (node nodes)
      (let* ((n (org-roam-node-from-id (car node)))
             (file (org-roam-node-file n))
             (pos (org-roam-node-point n)))
        (org-roam-with-file file nil
          (org-with-wide-buffer
          (if-let ((mtime (org-roam-timestamps--get-mtime n))
                   (split (split-string mtime)))
                (org-entry-put pos "mtime"  (car split))
                (save-buffer)))))))
  (org-roam-timestamps-mode 1))

(provide 'org-roam-timestamps)
;;; org-roam-timestamps.el ends here
