;;; dashboard-ls.el --- Display files/directories in current directory on Dashboard  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2023  Shen, Jen-Chieh
;; Created date 2020-03-24 17:49:59

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-dashboard/dashboard-ls
;; Package-Version: 20221231.1629
;; Package-Commit: b24e0bcb87e20ffcc71efb83a97f9516255fa8e4
;; Version: 0.3.0
;; Package-Requires: ((emacs "26.1") (dashboard "1.2.5"))
;; Keywords: convenience directory file show

;; This file is NOT part of GNU Emacs.

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
;;
;; Display files/directories in current directory on Dashboard.
;;

;;; Code:

(require 'dashboard)

(push '(ls-directories . dashboard-ls--insert-dir) dashboard-item-generators)
(push '(ls-files       . dashboard-ls--insert-file) dashboard-item-generators)

(defvar dashboard-ls-path nil
  "Update to date current path.
Use this variable when you don't have the `default-directory' up to date.")

(defvar dashboard-ls--record-path nil
  "Record of the current working directory.")

(defun dashboard-ls--current-path ()
  "Return the current path the user is on."
  (setq dashboard-ls--record-path (or dashboard-ls-path default-directory))
  dashboard-ls--record-path)

(defun dashboard-ls--entries (path)
  "Return entries from PATH."
  (when (file-directory-p path)
    (directory-files path nil directory-files-no-dot-files-regexp)))

(defun dashboard-ls--dirs ()
  "Return list of current directories."
  (let* ((current-dir (dashboard-ls--current-path))
         (entries (dashboard-ls--entries current-dir))
         result)
    (dolist (dir entries)
      (when (file-directory-p (expand-file-name dir current-dir))
        (setq dir (concat "/" dir))
        (push (concat dir "/") result)))
    (reverse result)))

(defun dashboard-ls--files ()
  "Return list of current files."
  (let* ((current-dir (dashboard-ls--current-path))
         (entries (dashboard-ls--entries current-dir))
         result)
    (dolist (file entries)
      (unless (file-directory-p (expand-file-name file current-dir))
        (push file result)))
    (reverse result)))

(defun dashboard-ls--insert-dir (list-size)
  "Add the list of LIST-SIZE items from current directory."
  (dashboard-insert-section
   "List Directories:"
   (dashboard-ls--dirs)
   list-size
   'ls-directories
   (dashboard-get-shortcut 'ls-directories)
   `(lambda (&rest _)
      (find-file-existing (concat dashboard-ls--record-path "/" ,el)))
   (abbreviate-file-name el)))

(defun dashboard-ls--insert-file (list-size)
  "Add the list of LIST-SIZE items from current files."
  (dashboard-insert-section
   "List Files:"
   (dashboard-ls--files)
   list-size
   'ls-files
   (dashboard-get-shortcut 'ls-files)
   `(lambda (&rest _)
      (find-file-existing (concat dashboard-ls--record-path "/" ,el)))
   (abbreviate-file-name el)))

(provide 'dashboard-ls)
;;; dashboard-ls.el ends here
