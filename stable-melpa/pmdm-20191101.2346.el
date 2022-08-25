;;; pmdm.el --- poor man's desktop-mode alternative.

;; Copyright (C) 2015-9 Free Software Foundation, Inc.

;; Author: Iñigo Serna <inigoserna@gmx.com>
;; URL: https://hg.serna.eu/emacs/pmdm
;; Package-Version: 20191101.2346
;; Package-Commit: 6d2af9f9e88e6c91eb74dafaddb5f009e1de4907
;; Version: 1.1
;; Keywords:

;; This file is not part of GNU Emacs.

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

;;; Commentary:

;; `pmdm.el' is a simple alternative to desktop-mode for storing
;; and opening loaded files.
;;
;; Run `pmdm-write-opened-files' manually (or in a hook) before quitting
;; emacs to save the files you want to restore later and `pmdm-load-files'
;; to open the stored files again.
;;
;; Customizable variable `pmdm-file-name' contains the name of the file
;; used to store the files list.

;;; Updates:

;; 2015/08/07 Initial version.
;; 2015/08/17 Adopted emacs-lisp code conventions.


;;; Code:

;;; Variables
(defvar pmdm-file-name (expand-file-name ".pmdm-files" user-emacs-directory)
  "Location of file to write in opened files.")

;;; Internal functions
(defun pmdm--read-files-list ()
  (when (file-exists-p pmdm-file-name)
    (with-temp-buffer
      (insert-file-contents pmdm-file-name)
      (delete-matching-lines "^;; ")
      (read (buffer-substring-no-properties (point-min) (point-max))))))

;;; Public interface
(defun pmdm-write-opened-files()
  "Write a list of currently opened files to the file defined in `pmdm-file-name'."
  (interactive)
  (let ((files (delq nil (mapcar 'buffer-file-name (buffer-list)))))
    (write-region (format ";; PMDM file.\n;; Please do not edit manually.\n%s"
                          (prin1-to-string files))
                  nil
                  pmdm-file-name)))

(defun pmdm-load-files ()
  "Load the files found in file `pmdm-file-name'."
  (interactive)
  (let ((opened-files (delq nil (mapcar 'buffer-file-name (buffer-list))))
        (files (pmdm--read-files-list))
        (count 0))
    (dolist (file files)
      (unless (member file opened-files)
        (find-file-noselect file)
        (setq count (1+ count))))
    (message (if (zerop count)
                 "No files opened"
               (format "%d file%s opened" count (if (> count 1) "s" ""))))))

(provide 'pmdm)
;;; pmdm.el ends here
