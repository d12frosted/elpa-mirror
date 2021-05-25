;;; snapshot-timemachine-rsnapshot.el --- rsnapshot backend for snapshot-timemachine

;; Copyright (C) 2016 Nicolas Petton

;; Author: Nicolas Petton <nicolas@petton.fr>
;; Version: 0.2
;; Package-Version: 20170324.1213
;; Package-Commit: 72b0b700d80f1a0442e62bbbb6a0c8c59182f97f
;; Package: snapshot-timemachine-rsnapshot
;; Package-Requires: ((snapshot-timemachine "20160222.132") (seq "2.19"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; rsnapshot backend for snapshot-timemachine

;;; Code:

(require 'snapshot-timemachine)

(require 'seq)
(unless (fboundp 'seq-map-indexed)
  (require 'seq-25))

(defgroup snapshot-timemachine-rsnapshot nil
  "rsnapshot backend for snapshot-timemachine."
  :group 'snapshot-timemachine)

(defcustom snapshot-timemachine-rsnapshot-backup-dir "/backup"
  "Path to the rsnapshot backup directory."
  :type 'string
  :group 'snapshot-timemachine-rsnapshot)

(defcustom snapshot-timemachine-rsnapshot-backup-name "localhost"
  "Name of the backup location as specified in the rsnapshot config file."
  :type 'string
  :group 'snapshot-timemachine-rsnapshot)

(defun snapshot-timemachine-rsnapshot-finder (file)
  "Find snapshots of FILE in rsnapshot backups."
  (let* ((file (expand-file-name file))
         (backup-dirs (seq-filter #'file-directory-p
                                  (directory-files snapshot-timemachine-rsnapshot-backup-dir t)))
         (backup-files (seq-filter (lambda (spec)
                                     (file-exists-p (cdr spec)))
                                   (seq-map (lambda (dir)
                                              (cons dir (concat dir "/" snapshot-timemachine-rsnapshot-backup-name "/" file)))
                                            backup-dirs))))
    (seq-map-indexed (lambda (backup-file index)
               (make-snapshot :id index
                              :name (car backup-file)
                              :file (cdr backup-file)
                              :date (nth 5 (file-attributes (cdr backup-file)))))
             backup-files)))

(setq snapshot-timemachine-snapshot-finder #'snapshot-timemachine-rsnapshot-finder)

(provide 'snapshot-timemachine-rsnapshot)
;;; snapshot-timemachine-rsnapshot.el ends here
