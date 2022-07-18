;;; dired-duplicates.el --- Find duplicate files locally and remotely  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Harald Judt

;; Author: Harald Judt <h.judt@gmx.at>
;; Maintainer: Harald Judt <h.judt@gmx.at>
;; Created: 2022
;; Version: 0.1
;; Package-Version: 20220716.2233
;; Package-Commit: 6df828caacdb5517f93423b1077af08104d217d4
;; Package-Requires: ((emacs "27.1"))
;; Keywords: files
;; Homepage: https://codeberg.org/hjudt/dired-duplicates

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

;; This package helps to find duplicate files on local and remote filesystems.
;; It is similar to the fdupes command-line utility but written in Emacs Lisp
;; and should also work on every remote filesystem that TRAMP supports and
;; where executable commands can be called remotely.  The only external
;; requirement is a checksum program like md5 or sha256sum that generates a
;; hash value from the contents of a file used for comparison, because Emacs
;; cannot do that in a performance-efficient way.
;;
;; dired-duplicates works by first searching files of the same size, then
;; invoking the calculation of the checksum for these files, and presents the
;; grouped results in a Dired buffer that the user can work with similarly to
;; a regular Dired buffer.

;;; Code:

(require 'cl-lib)
(require 'dired)

(defgroup dired-duplicates
  nil
  "Find duplicate files on local and/or remote filesystems."
  :tag "Dired Duplicates"
  :group 'dired)

(defcustom dired-duplicates-use-separators
  t
  "Whether to use a separator dummy file for separating search results."
  :group 'dired-duplicates
  :tag "Separate search results"
  :type 'boolean)

(defcustom dired-duplicates-separator-file
  (concat (temporary-file-directory) (make-string 40 ?-))
  "Path and name of the separator file.

This file is used for making search results easier to discern.
It will be created immediately before and deleted as soon as
possible after the search operation finishes."
  :group 'dired-duplicates
  :tag "Separator dummy file"
  :type 'string)

(defcustom dired-duplicates-checksum-exec
  "sha256sum"
  "Name of the executable used for creating file checksums.

The checksums will be used for comparison of files of the same
size."
  :group 'dired-duplicates
  :tag "Checksum executable"
  :type 'string)

(defcustom dired-duplicates-size-comparison-function
  '<
  "The comparison function used for sorting grouped results.

The sorting can be in ascending (<) or descending (>) order."
  :group 'dired-duplicates
  :tag "Ascending or descending file size sort order"
  :type '(choice (const :tag "Ascending" :value <)
                 (const :tag "Descending" :value >)))

(defcustom dired-duplicates-file-filter-functions
  nil
  "Filter functions applied to all files found in a directory.

A filter function must accept as its single argument the file and
return boolean t if the file matches a criteria, otherwise nil."
  :group 'dired-duplicates
  :tag "File filter functions"
  :type 'hook)

(defcustom dired-duplicates-search-directories-recursively
  t
  "Search directories recursively."
  :group 'dired-duplicates
  :tag "Search directories recursively"
  :type 'boolean)

(defvar dired-duplicates-directories nil
  "List of directories that will be searched for duplicate files.")

(defun dired-duplicates-checksum-file (file)
  "Create a checksum for FILE.

The executable used is defined by `dired-duplicates-checksum-exec'."
  (let* ((default-directory (file-name-directory (expand-file-name file)))
         (exec (executable-find dired-duplicates-checksum-exec t)))
    (unless exec
      (user-error "Checksum program %s not found in exec-path" exec))
    (car (split-string
          (shell-command-to-string
           (concat exec " \"" (expand-file-name (file-local-name file)) "\""))
          nil
          t))))

(defun dired-duplicates--ensure-separator-file ()
  "Ensure that the separator file exists.

The file is specified by `dired-duplicates-separator-file'."
  (unless (file-exists-p dired-duplicates-separator-file)
    (make-empty-file dired-duplicates-separator-file)))

(defun dired-duplicates--remove-separator-file ()
  "Remove the separator file specified by `dired-duplicates-separator-file'."
  (when (file-exists-p dired-duplicates-separator-file)
    (delete-file dired-duplicates-separator-file nil)))

(defmacro dired-duplicates-with-separator-file (&rest body)
  "Ensure separator file gets created and cleaned up before and after BODY."
  `(unwind-protect
       (progn
         (when dired-duplicates-use-separators
           (dired-duplicates--ensure-separator-file))
         ,@body)
     (when dired-duplicates-use-separators
       (dired-duplicates--remove-separator-file))))

(defun dired-duplicates--apply-file-filter-functions (files)
  "Apply file filter functions to FILES, returning the resulting list."
  (if (and dired-duplicates-file-filter-functions files)
      (dolist (filter-func dired-duplicates-file-filter-functions files)
        (setf files (cl-delete-if-not filter-func files)))
    files))

(defun dired-duplicates--find-and-filter-files (directories)
  "Search below DIRECTORIES for duplicate files.

It is possible to provide one or more root DIRECTORIES.  Returns
a hash-table with the checksums as keys and a list of size and
duplicate files as values."
  (cl-loop with files = (dired-duplicates--apply-file-filter-functions
                         (mapcan
                          (lambda (d)
                            (if dired-duplicates-search-directories-recursively
                                (directory-files-recursively d ".*")
                              (cl-remove-if #'file-directory-p (directory-files d t nil t))))
                          (if (listp directories)
                              directories
                            (list directories))))
           and same-size-table = (make-hash-table)
           and checksum-table = (make-hash-table :test 'equal)
           for f in files
           for size = (file-attribute-size (file-attributes f))
           do (setf (gethash size same-size-table)
                    (append (gethash size same-size-table) (list f)))
           finally
           (cl-loop for same-size-files being the hash-values in same-size-table
                    if (> (length same-size-files) 1) do
                    (cl-loop for f in same-size-files
                             for checksum = (dired-duplicates-checksum-file f)
                             do (setf (gethash checksum checksum-table)
                                      (append (gethash checksum checksum-table) (list f)))))
           (cl-loop for same-files being the hash-value in checksum-table using (hash-key checksum)
                    do
                    (if (> (length same-files) 1)
                        (setf (gethash checksum checksum-table)
                              (cons (file-attribute-size (file-attributes (car same-files)))
                                    (sort same-files #'string<)))
                      (remhash checksum checksum-table)))
           (cl-return checksum-table)))

(defun dired-duplicates--generate-dired-list (&optional directories)
  "Generate a list of grouped duplicate files in DIRECTORIES.

Optionally they can be separated by a separator file specified by
`dired-duplicates-separator-file'."
  (cl-loop with dupes-table = (dired-duplicates--find-and-filter-files
                               (or directories
                                   dired-duplicates-directories))
           with sorted-sums = (cl-sort
                               (cl-loop for k being the hash-key in dupes-table using (hash-value v)
                                        collect (list k (car v)))
                               dired-duplicates-size-comparison-function
                               :key #'cl-second)
           for (checksum) in sorted-sums
           append (cdr (gethash checksum dupes-table))
           when dired-duplicates-use-separators append (list dired-duplicates-separator-file)))

(defun dired-duplicates-dired-revert (&optional arg noconfirm)
  "Revert function used instead of `dired-revert' for Dired buffers.

The args ARG and NOCONFIRM are passed through from
`revert-buffer' to `dired-revert'."
  (message "Looking for remaining duplicate files...")
  (setq-local dired-directory
              (append (list (car dired-directory))
                      (dired-duplicates--generate-dired-list)))
  (message "Reverting buffer complete.")
  (dired-duplicates-with-separator-file
   (dired-revert arg noconfirm)))

;;;###autoload
(defun dired-duplicates (directories)
  "Find a list of duplicate files inside one or more DIRECTORIES.

The results will be shown in a Dired buffer."
  (interactive (list (completing-read-multiple "Directories: "
                                               #'read-file-name-internal
                                               #'file-directory-p
                                               t
                                               default-directory
                                               nil
                                               default-directory)))
  (let ((default-directory "/")
        (truncated-dirs (truncate-string-to-width (string-join directories ", ") 40 0 nil t)))
    (message "Finding duplicate files in %s..." truncated-dirs)
    (if-let ((results (dired-duplicates--generate-dired-list directories)))
        (progn
          (message "Finding duplicate files in %s completed." truncated-dirs)
          (dired-duplicates-with-separator-file
           (dired (cons "/" results))
           (setq-local dired-duplicates-directories directories)
           (setq-local revert-buffer-function 'dired-duplicates-dired-revert)))
      (message "No duplicate files found in %s." truncated-dirs))))

(provide 'dired-duplicates)

;;; dired-duplicates.el ends here
