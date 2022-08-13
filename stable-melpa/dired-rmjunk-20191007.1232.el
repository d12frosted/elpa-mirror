;;; dired-rmjunk.el --- A home directory cleanup utility for Dired. -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jakob L. Kreuze

;; Author: Jakob L. Kreuze <zerodaysfordays@sdf.lonestar.org>
;; Version: 1.2
;; Package-Requires (cl-lib dired)
;; Keywords: files matching
;; URL: https://git.sr.ht/~jakob/dired-rmjunk

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

;; dired-rmjunk is a port of Jakub Klinkovský's home directory cleanup tool to
;; Dired. The interactive function, `dired-rmjunk' will mark all files in the
;; current Dired buffer that match one of the patterns specified in
;; `dired-rmjunk-patterns'. The tool is intended as a simple means for
;; keeping one's home directory tidy -- removing "junk" dotfiles.

;; The script that this is based on can be found at:
;; <https://github.com/lahwaacz/Scripts/blob/master/rmshit.py>

;;; Code:

(defgroup dired-rmjunk ()
  "Remove junk files with dired."
  :group 'dired)

(defcustom dired-rmjunk-patterns
  '(".adobe" ".macromedia" ".recently-used"
    ".local/share/recently-used.xbel" "Desktop" ".thumbnails" ".gconfd"
    ".gconf" ".local/share/gegl-0.2" ".FRD/log/app.log" ".FRD/links.txt"
    ".objectdb" ".gstreamer-0.10" ".pulse" ".esd_auth" ".config/enchant"
    ".spicec" ".dropbox-dist" ".parallel" ".dbus" "ca2" "ca2~"
    ".distlib" ".bazaar" ".bzr.log" ".nv" ".viminfo" ".npm" ".java"
    ".oracle_jre_usage" ".jssc" ".tox" ".pylint.d" ".qute_test"
    ".QtWebEngineProcess" ".qutebrowser" ".asy" ".cmake" ".gnome"
    "unison.log" ".texlive" ".w3m" ".subversion" "nvvp_workspace")
  "Default list of files to remove. Current as of f707d92."
  :type '(list string))

(defvar dired-rmjunk--responsible-for-last-mark nil
  "Whether or not `dired-rmjunk' was responsible for any of the
current dired marks.")

(defvar dired-rmjunk--visit-queue nil
  "Queue of directories to visit following a removal.")

;;;###autoload
(defun dired-rmjunk ()
  "Mark all junk files in the current dired buffer.
'Junk' is defined to be any file with a name matching one of the
patterns in `dired-rmjunk-patterns'. A pattern is said to match
under the following conditions:

  1. If the pattern lacks a directory component, matching means
  that the regexp specified by the pattern matches the file-name.
  2. If the pattern lacks a directory component, matching means
  that that the regexp specified by the file-name component of
  the pattern matches the file-name, AND the regexp specified by
  the directory component of the pattern matches the current
  directory."
  (interactive)
  (when (eq major-mode 'dired-mode)
    (save-excursion
      (let ((files-marked-count 0))
        (dolist (file (directory-files dired-directory))
          (dolist (pattern dired-rmjunk-patterns)
            (when (or (and (not (dired-rmjunk--dir-name pattern))
                           (string-match pattern file))
                      (and (dired-rmjunk--dir-name pattern)
                           (string-match (dired-rmjunk--dir-name pattern)
                                         (dired-current-directory))
                           (string-match (dired-rmjunk--file-name pattern) file)))
              (setq files-marked-count (1+ files-marked-count))
              (dired-goto-file (concat (expand-file-name dired-directory) file))
              (dired-flag-file-deletion 1))))
        (if (zerop files-marked-count)
            (message "No junk files found :)")
          (progn
            (message "Junk files marked.")
            (setq dired-rmjunk--responsible-for-last-mark t)))
        files-marked-count))))

(advice-add #'dired-do-flagged-delete :after #'dired-rmjunk--after-delete)

(defun dired-rmjunk--after-delete ()
  ;; Prompt the user for whether or not they want to visit the subdirectories
  ;; named in dired-rmjunk-patterns.
  (when (and (not dired-rmjunk--visit-queue)
             dired-rmjunk--responsible-for-last-mark)
    (let* ((to-visit (map 'list
                          #'(lambda (subdir) (concat (dired-current-directory) "/" subdir))
                          (dired-rmjunk--directories-in-patterns)))
           (to-visit (cl-remove-if-not #'file-exists-p to-visit)))
      (when (and to-visit
                 (y-or-n-p "Visit subdirectories?"))
        (setq dired-rmjunk--visit-queue to-visit))))

  ;; Visit the next subdirectory in the queue.
  (when dired-rmjunk--visit-queue
    (while (and dired-rmjunk--visit-queue
                (set-buffer (dired (first dired-rmjunk--visit-queue)))
                (message "Visiting %s..." (first dired-rmjunk--visit-queue))
                (zerop (dired-rmjunk)))
      (setq dired-rmjunk--visit-queue
            (rest dired-rmjunk--visit-queue))))

  (setq dired-rmjunk--responsible-for-last-mark nil))

(defun dired-rmjunk--dir-name (path)
  "Return the directory portion of PATH, or `nil' if the path
does not contain a directory component."
  (let ((split-offset (cl-position ?\/ path :from-end t)))
    (if split-offset
        (cl-subseq path 0 (1+ split-offset)))))

(defun dired-rmjunk--file-name (path)
  "Return the file-name portion of PATH."
  (let ((split-offset (cl-position ?\/ path :from-end t)))
    (if split-offset
        (cl-subseq path (1+ split-offset))
      ;; If there's no directory component, `path' IS the file-name!
      path)))

(defun dired-rmjunk--directories-in-patterns (&optional patterns)
  (let ((patterns (or patterns dired-rmjunk-patterns)))
    (cl-remove-duplicates
     (cl-remove-if #'null
                   (map 'list #'dired-rmjunk--dir-name patterns))
     :test #'string=)))

(provide 'dired-rmjunk)
;;; dired-rmjunk.el ends here
