;;; kill-file-path.el --- Copy file name into kill ring -*- lexical-binding: t -*-
;; Copyright 2022 by Adam Chyła <adam@chyla.org>

;; Author: Adam Chyła <adam@chyla.org>
;; Version: 1.0
;; Package-Version: 20230306.1041
;; Package-Commit: 5dcbce69cbae17665216a32dd20f27de54c62972
;; Keywords: files
;; URL: https://github.com/chyla/kill-file-path/kill-file-path.el
;; Package-Requires: ((emacs "26"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `kill-file-path.el` is a package for Emacs that provides a collection
;; of interactive commands that can be used to kill (copy)
;; buffer file name or path.

;;; Code:

;;;###autoload
(defun kill-file-path-basename ()
  "Insert the file name with extension into kill ring."
  (interactive)
  (if (not buffer-file-name)
      (message "No file for buffer.")
    (defvar file-basename)
    (setq file-basename (file-name-nondirectory buffer-file-name))
    (kill-new file-basename)
    (message "Copied: %s" file-basename)))

;;;###autoload
(defun kill-file-path-basename-without-extension ()
  "Insert the file name without extension into kill ring."
  (interactive)
  (if (not buffer-file-name)
      (message "No file for buffer.")
    (defvar file-basename-no-ext)
    (setq file-basename-no-ext (file-name-base buffer-file-name))
    (kill-new file-basename-no-ext)
    (message "Copied: %s" file-basename-no-ext)))

;;;###autoload
(defun kill-file-path-dirname ()
  "Insert the file directory path into kill ring."
  (interactive)
  (if (not buffer-file-name)
      (message "No file for buffer.")
    (defvar file-directory-path)
    (setq file-directory-path (file-name-directory buffer-file-name))
    (kill-new file-directory-path)
    (message "Copied: %s" file-directory-path)))

;;;###autoload
(defun kill-file-path ()
  "Insert the full file path into kill ring."
  (interactive)
  (if (not buffer-file-name)
      (message "No file for buffer.")
    (kill-new buffer-file-name)
    (message "Copied: %s" buffer-file-name)))

(provide 'kill-file-path)

;;; kill-file-path.el ends here
