;;; eyebrowse-restore.el --- Persistent Eyebrowse for all frames   -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jakub Kadlčík

;; Author: Jakub Kadlčík <frostyx@email.cz>
;; URL: https://github.com/FrostyX/eyebrowse-restore
;; Package-Version: 20230122.1510
;; Package-Commit: 77f171de019586a66481bcde6ab11f3689e97bc6
;; Version: 1.0
;; Package-Requires: ((emacs "26.3") (eyebrowse "0.7.8") (dash "2.19.1") (s "1.13.0"))
;; Keywords: convenience, eyebrowse, helm, persistent

;;; License:

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

;; Never lose your Eyebrowse window configurations again


;;; Code:

(require 'eyebrowse)
(require 'dash)
(require 's)

;;;; Customization

(defgroup eyebrowse-restore nil
  "Persistent Eyebrowse for all frames."
  :prefix "eyebrowse-restore-"
  :group 'eyebrowse)

(defcustom eyebrowse-restore-dir
  (concat user-emacs-directory "eyebrowse-restore")
  "Path to the directory where to store Eyebrowse window configs."
  :type 'directory
  :group 'eyebrowse-restore)

(defcustom eyebrowse-restore-save-interval 300
  "How often (in seconds) to save all Eyebrowse window configs."
  :type 'number
  :group 'eyebrowse-restore)

(defcustom eyebrowse-restore-keep-old-backups 10
  "How many old backups should we keep."
  :type 'integer
  :group 'eyebrowse-restore)

(defcustom eyebrowse-restore-if-only-one t
  "Restore without asking?
If there is only one backup in the `eyebrowse-restore-dir',
automatically restore from it without prompting the user."
  :type 'boolean
  :group 'eyebrowse-restore)

;;;; Variables

(defvar eyebrowse-restore-timer nil
  "Timer to automatically save Eyebrowse window configurations.")

;;;; Modes

;;;###autoload
(define-minor-mode eyebrowse-restore-mode
  "Toggle `eyebrowse-restore-mode'.
This global minor mode provides a timer to automatically
save Eyebrowse window configurations for all Emacs frames.
It also provides a hook to save window configuration for a
frame before closing it."
  :global t
  (if eyebrowse-restore-mode
      (progn
        (add-to-list 'delete-frame-functions #'eyebrowse-restore-save)
        (setq eyebrowse-restore-timer
              (run-at-time 0 eyebrowse-restore-save-interval
                           #'eyebrowse-restore-save-all)))
    (progn
      (setq delete-frame-functions
            (delete #'eyebrowse-restore-save delete-frame-functions))
      (cancel-timer eyebrowse-restore-timer))))

;;;; Commands

;;;###autoload
(defun eyebrowse-restore-save-all ()
  "Save the Eyebrowse window configurations for all frames."
  (interactive)
  (make-directory eyebrowse-restore-dir t)
  (dolist (frame (frame-list))
    (eyebrowse-restore-save frame)))

;;;###autoload
(defun eyebrowse-restore-save (frame)
  "Save the Eyebrowse window configurations for the specified FRAME."
  (interactive)
  (let* ((name (frame-parameter frame 'name))
         (name (eyebrowse-restore--encode-name name))
         (path (concat (file-name-as-directory eyebrowse-restore-dir) name))
         (window-configs (eyebrowse--get 'window-configs frame)))

    (with-temp-file path
      (prin1 window-configs (current-buffer))))
  (eyebrowse-restore--remove-unused-backups))

;;;###autoload
(defun eyebrowse-restore (&optional name)
  "Restore an Eyebrowse window configuration from a backup.

If a backup NAME is not specified, a `completing-read' with
backup names appears.  Selected backup of an Eyebrowse window
configurations is applied to the current frame.

Warning! The current Eyebrowse window configurations for the
active frame will be destroyed."
  (interactive)

  (let ((name (eyebrowse-restore--decode-name name))
        (backups (mapcar #'eyebrowse-restore--decode-name
                         (eyebrowse-restore--list-backups))))
    (if (and (not name)
             (= (length backups) 1)
             eyebrowse-restore-if-only-one)
        (eyebrowse-restore (car backups))

      (let* ((name (or name (completing-read "Eyebrowse backups: " backups)))
             (name (eyebrowse-restore--encode-name name))
             (path (concat (file-name-as-directory eyebrowse-restore-dir) name)))

        (with-temp-buffer
          (insert-file-contents path)
          (eyebrowse--set 'window-configs
            (read (buffer-string))))))))

;;;; Functions

;;;;; Private

(defun eyebrowse-restore--encode-name (name)
  "Generate a backup file.
Create a safe backup name based on an input string, ideally
a frame NAME.  The returned name should not cause any issues
on the filesystem."
  (if name
      (s-replace "/" "%2F" name)))

(defun eyebrowse-restore--decode-name (name)
  "Convert encoded backup NAME back to the human-readable format."
  (if name
      (s-replace "%2F" "/" name)))

(defun eyebrowse-restore--list-backups ()
  "List all files stored in the `eyebrowse-restore-dir'directory."
  (let* ((with-attrs (directory-files-and-attributes eyebrowse-restore-dir))
		 (sort-by-date (lambda (x y) (time-less-p (nth 5 y) (nth 5 x))))
		 (sorted (sort with-attrs sort-by-date))
		 (files (mapcar #'car sorted)))
	(seq-filter (lambda (x) (not (member x '("." "..")))) files)))

(defun eyebrowse-restore--list-unused-backups ()
  "Return unused backups.
Return a list of unused backups while respecting the
`eyebrowse-restore-keep-old-backups' number of unused
backups to keep."
  (-slice (seq-filter #'eyebrowse-restore--unused-backup-p
					  (eyebrowse-restore--list-backups))
		  eyebrowse-restore-keep-old-backups))

(defun eyebrowse-restore--unused-backup-p (name)
  "Return t if there isn't any frame with this `NAME'."
  (not (member
        name
        (mapcar (lambda (x) (frame-parameter x 'name))
                (frame-list)))))

(defun eyebrowse-restore--remove-unused-backups ()
  "Remove unused backups.
Remove all files from the `eyebrowse-restore-dir' that
doesn't correspond with any of the active frames or is
older than `eyebrowse-restore-keep-old-backups'."
  (dolist (name (eyebrowse-restore--list-unused-backups))
    (delete-file (concat (file-name-as-directory eyebrowse-restore-dir) name))))

;;;; Footer

(provide 'eyebrowse-restore)

;;; eyebrowse-restore.el ends here
