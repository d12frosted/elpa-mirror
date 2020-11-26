;;; exiftool.el --- Elisp wrapper around ExifTool -*- lexical-binding: t -*-

;; Elisp wrapper around ExifTool
;; Copyright (C) 2017, 2019 by Arun I
;;
;; Author: Arun I <arunisaac@systemreboot.net>
;; Version: 0.3.2
;; Keywords: data
;; Homepage: https://git.systemreboot.net/exiftool.el
;; Package-Requires: ((emacs "25"))

;; This file is part of exiftool.el.

;; exiftool.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; exiftool.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with exiftool.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; exiftool.el is an elisp wrapper around ExifTool.  ExifTool supports
;; reading and writing metadata in various formats including EXIF, XMP
;; and IPTC.
;;
;; There is a significant overhead in loading ExifTool for every
;; command to be exected.  So, exiftool.el starts an ExifTool process
;; in the -stay_open mode, and passes all commands to it.  For more
;; about ExifTool's -stay_open mode, see
;; http://www.sno.phy.queensu.ca/~phil/exiftool/#performance

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'tq)

(defvar exiftool-executable "exiftool"
  "Executable used to invoke exiftool.")

(defun exiftool--tq-sync-query (tq question regexp)
  "Add a transaction to transaction queue TQ, block and read response.

See `tq-enqueue' for details of arguments QUESTION and REGEXP."
  (let ((response))
    (tq-enqueue tq question regexp nil
		(lambda (_ answer) (setq response answer)))
    (while (not response)
      (accept-process-output))
    response))

(defun exiftool-run ()
  "Start an exiftool process if one is not already running.

If an exiftool process is already running, delete it, and create
a new one.  Return the process object of the newly created
process."
  (when-let (exiftool (get-process "exiftool"))
    (delete-process exiftool))
  (start-process "exiftool" "*exiftool*"
                 exiftool-executable "-stay_open" "True" "-@" "-"))

;; Declare exiftool-command to pacify byte compiler
(declare-function exiftool-command "exiftool.el" (&rest args))

(let ((tq (tq-create (exiftool-run))))
  (defun exiftool-command (&rest args)
    "Execute a command in the currently running exiftool process.

ARGS are arguments of the command to be run, as provided to the
exiftool command line application."
    (string-trim
     (let ((suffix "{ready}\n"))
       (string-remove-suffix
	suffix (exiftool--tq-sync-query
		tq (concat (string-join args "\n")
			   "\n-execute\n")
		suffix))))))

(defun exiftool--assert-file-exists (file)
  (unless (file-exists-p file)
    (signal 'file-missing file)))

(defun exiftool-read (file &rest tags)
  "Read TAGS from FILE, return an alist mapping TAGS to values.

If a tag is not found, return an empty string \"\" as the
value. If no TAGS are specified, read all tags from FILE.

\(fn FILE TAG...)"
  (exiftool--assert-file-exists file)
  (mapcar
   (lambda (line)
     (string-match "\\([^:]*\\): \\(.*\\)" line)
     (let ((tag (match-string 1 line))
	   (value (match-string 2 line)))
       (cons tag (if (equal value "-")
		     (exiftool-command "-s" "-s" "-s"
				       (format "-%s" tag) file)
		   value))))
   (split-string
    (apply 'exiftool-command
	   "-s" "-s" "-f"
	   (append
	    (mapcar (apply-partially 'format "-%s") tags)
	    (list file)))
    "\n+")))

(defun exiftool-copy (source destination &rest tags)
  "Copy TAGS from SOURCE file to DESTINATION file.

If no TAGS are specified, copy all tags from SOURCE."
  (exiftool--assert-file-exists source)
  (exiftool--assert-file-exists destination)
  (apply 'exiftool-command
	 "-m" "-overwrite_original"
	 "-tagsFromFile" source
	 (append
	  (if tags
	      (mapcar (apply-partially 'format "-%s") tags)
	    (list "-all:all"))
	  (list destination)))
  destination)

(defun exiftool-write (file &rest tag-value-alist)
  "Write tags to FILE.

The metadata to be written is specified as (TAG . VALUE)
pairs.  Specifying the empty string \"\" for VALUE deletes that
TAG.

\(fn FILE (TAG . VALUE)...)"
  (exiftool--assert-file-exists file)
  (apply 'exiftool-command
	 "-m" "-overwrite_original"
	 (append
	  (mapcar
	   (cl-function
	    (lambda ((tag . value))
	      (format "-%s=%s" tag value)))
	   tag-value-alist)
	  (list file))))

(provide 'exiftool)

;;; exiftool.el ends here
