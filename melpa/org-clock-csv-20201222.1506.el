;;; org-clock-csv.el --- Export `org-mode' clock entries to CSV format.

;; Copyright (C) 2016 Aaron Jacobs

;; Author: Aaron Jacobs <atheriel@gmail.com>
;; URL: https://github.com/atheriel/org-clock-csv
;; Package-Version: 20201222.1506
;; Package-Commit: af94b58c2e179a5bcc938f339e93de0eee3da99c
;; Keywords: calendar, data, org
;; Version: 1.2
;; Package-Requires: ((org "8.3") (s "1.0"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package makes use of the `org-element' API to extract clock
;; entries from org files and convert them into CSV format. It is
;; intended to facilitate clocked time analysis in external programs.

;; In interactive mode, calling `org-clock-csv' will open a buffer
;; with the parsed entries from the files in `org-agenda-files', while
;; `org-clock-csv-to-file' will write this output to a file. Both
;; functions take a prefix argument to read entries from the current
;; buffer instead.

;; There is also an `org-clock-csv-batch-and-exit' that will output
;; the CSV content to standard output (for use in batch mode).

;;; Code:

(require 's)
(require 'org)
(require 'org-agenda)
(require 'org-element)

(eval-when-compile
  (require 'cl-lib))

;; This is a simplified shim for `org-element-lineage', as needed for this
;; package, for very old versions of `org':
(when (version< (org-version) "8.3")
  (defun org-element-lineage (blob &optional types)
    (let ((up (org-element-property :parent blob)))
      (while (and up (not (memq (org-element-type up) types)))
        (setq up (org-element-property :parent up)))
      up)))

;;;; Configuration options:

(defgroup org-clock-csv nil
  "Export `org-mode' clock entries to CSV format."
  :group 'external)

(defcustom org-clock-csv-header "task,parents,category,start,end,effort,ishabit,tags"
  "Header for the CSV output.

Be sure to keep this in sync with changes to
`org-clock-csv-row-fmt'."
  :group 'org-clock-csv)

(defcustom org-clock-csv-headline-separator "/"
  "Character that separates each headline level within the \"task\" column."
  :group 'org-clock-csv)

(defcustom org-clock-csv-row-fmt #'org-clock-csv-default-row-fmt
  "Function to parse a plist of properties for each clock entry
and produce a comma-separated CSV row.

Be sure to keep this in sync with changes to
`org-clock-csv-header'.

See `org-clock-csv-default-row-fmt' for an example."
  :group 'org-clock-csv)

(defun org-clock-csv-default-row-fmt (plist)
  "Default row formatting function."
  (mapconcat #'identity
             (list (org-clock-csv--escape (plist-get plist ':task))
                   (org-clock-csv--escape (s-join org-clock-csv-headline-separator (plist-get plist ':parents)))
                   (org-clock-csv--escape (plist-get plist ':category))
                   (plist-get plist ':start)
                   (plist-get plist ':end)
                   (plist-get plist ':effort)
                   (plist-get plist ':ishabit)
                   (plist-get plist ':tags))
             ","))

;;;; Utility functions:

(defsubst org-clock-csv--pad (num)
  "Add a leading zero when NUM is less than 10."
  (if (> num 10) num (format "%02d" num)))

(defun org-clock-csv--escape (str)
  "Escapes STR so that it is suitable for a .csv file.

Since we don't expect newlines in any of these strings, it is
sufficient to escape commas and double quote characters."
  (if (s-contains? "\"" str)
      (concat "\"" (s-replace-all '(("\"" . "\"\"")) str) "\"")
    (if (s-contains? "," str) (concat "\"" str "\"") str)))

(defun org-clock-csv--read-property (plist property &optional default)
  "Properties are parsed from the PROPERTIES drawer as a plist of key/value pairs.

This function can be used in your csv-row-fmt function to extract custom properties.

Example:
(defun custom-org-clock-csv-row-fmt (plist)
  \"Example custom row formatting function w/property access.\"
  (mapconcat #'identity
             (list (org-clock-csv--escape (plist-get plist ':task))
                   (org-clock-csv--escape (s-join org-clock-csv-headline-separator (plist-get plist ':parents)))
                   (org-clock-csv--escape (plist-get plist ':category))
                   (org-clock-csv--escape (org-clock-csv--read-property plist \"CUSTOM_PROPERTY\"))
             \",\"))
"
  (or (lax-plist-get (plist-get plist ':properties) property) (or default "")))

;;;; Internal API:

(defun org-clock-csv--find-category (element default)
  "Find the category of a headline ELEMENT, optionally recursing
upwards until one is found.

Returns the DEFAULT file level category if none is found."
  (let ((category (org-element-property :CATEGORY element))
        (current element)
        (curlvl  (org-element-property :level element)))
    ;; If the headline does not have a category, recurse upwards
    ;; through the parent headlines, checking if there is a category
    ;; property in any of them.
    (while (not category)
      (setq current (if (equal curlvl 1)
                        (org-element-lineage current)
                      (org-element-lineage current '(headline)))
            curlvl (- curlvl 1))
      (setq category (org-element-property :CATEGORY current))
      ;; If we get to the root of the org file with no category, just
      ;; set it to the default file level category.
      (unless (equal 'headline (org-element-type current))
        (setq category default)))
    category))

(defun org-clock-csv--find-headlines (element)
  "Returns a list of headline ancestors from closest parent to the farthest"
  (let ((ph (org-element-lineage element '(headline))))
    (if ph
      (cons ph (org-clock-csv--find-headlines ph)))))

(defun org-clock-csv--get-properties-plist (element)
  "Returns a plist of the [inherited] properties drawer of an org element"
  ;; org-entry-properties returns an ALIST, but we don't want to have to handle
  ;; duplicate keys so we're going to `reduce' it to a plist.
  (let* ((el (org-element-property :begin element)))
    (seq-reduce
     (lambda (acc pair) (plist-put acc (car pair) (cdr pair)))
     (org-entry-properties el)
     (seq-reduce
      (lambda (acc key) (plist-put acc key (org-entry-get el key t)))
      (org-buffer-property-keys) nil))))

(defun org-clock-csv--parse-element (element title default-category)
  "Ingest clock ELEMENT and produces a plist of its relevant
properties."
  (when (and (equal (org-element-type element) 'clock)
             ;; Only ingest closed, inactive clock elements.
             (equal (org-element-property :status element) 'closed)
             (equal (org-element-property
                     :type (org-element-property :value element))
                    'inactive-range))
    (let* ((timestamp (org-element-property :value element))
           (headlines (org-clock-csv--find-headlines element)) ;; Finds the headlines ancestor lineage containing the clock element.
           (headlines-values (mapcar (lambda (h) (org-element-property :raw-value h)) headlines ))
           (task-headline (car headlines)) ;; The first headline containing this clock element.
           (task (car headlines-values))
           (parents (reverse (cdr headlines-values)))
           (effort (org-element-property :EFFORT task-headline))
           ;; TODO: Handle tag inheritance, respecting the value of
           ;; `org-tags-exclude-from-inheritance'.
           (tags (mapconcat #'identity
                            (org-element-property :tags task-headline) ":"))
           (ishabit (when (equal "habit" (org-element-property
                                          :STYLE task-headline))
                      "t"))
           (category (org-clock-csv--find-category task-headline default-category))
           (start (format "%d-%s-%s %s:%s"
                          (org-element-property :year-start timestamp)
                          (org-clock-csv--pad
                           (org-element-property :month-start timestamp))
                          (org-clock-csv--pad
                           (org-element-property :day-start timestamp))
                          (org-clock-csv--pad
                           (org-element-property :hour-start timestamp))
                          (org-clock-csv--pad
                           (org-element-property :minute-start timestamp))))
           (end (format "%d-%s-%s %s:%s"
                        (org-element-property :year-end timestamp)
                        (org-clock-csv--pad
                         (org-element-property :month-end timestamp))
                        (org-clock-csv--pad
                         (org-element-property :day-end timestamp))
                        (org-clock-csv--pad
                         (org-element-property :hour-end timestamp))
                        (org-clock-csv--pad
                         (org-element-property :minute-end timestamp))))
           (duration (org-element-property :duration element))
           (properties (org-clock-csv--get-properties-plist element)))
      (list :task task
            :headline task-headline
            :parents parents
            :title title
            :category category
            :start start
            :end end
            :duration duration
            :properties properties
            :effort effort
            :ishabit ishabit
            :tags tags))))

(defun org-clock-csv--get-org-data (property ast default)
  "Return the PROPERTY of the `org-data' structure in the AST
or the DEFAULT value if it does not exist."
  (let ((value (org-element-map ast 'keyword
		 (lambda (elem) (if (string-equal (org-element-property :key elem) property)
				    (org-element-property :value elem))))))
    (if (equal nil value) default (car value))))

(defun org-clock-csv--get-entries (filelist &optional no-check)
  "Retrieves clock entries from files in FILELIST.

When NO-CHECK is non-nil, skip checking if all files exist."
  (when (not no-check)
    ;; For the sake of better debug messages, check whether all of the
    ;; files exists first.
    (mapc (lambda (file) (cl-assert (file-exists-p file))) filelist))
  (cl-loop for file in filelist append
           (with-current-buffer (find-file-noselect file)
	     (let* ((ast (org-element-parse-buffer))
		    (title (org-clock-csv--get-org-data 'TITLE ast file))
		    (category (org-clock-csv--get-org-data 'CATEGORY ast "")))
	       (org-element-map ast 'clock
		 (lambda (c) (org-clock-csv--parse-element c title category))
		     nil nil)))))

;;;; Public API:

;;;###autoload
(defun org-clock-csv (&optional infile no-switch use-current)
  "Export clock entries from INFILE to CSV format.

When INFILE is a filename or list of filenames, export clock
entries from these files. Otherwise, use `org-agenda-files'.

When NO-SWITCH is non-nil, do not call `switch-to-buffer' on the
rendered CSV output, simply return the buffer.

USE-CURRENT takes the value of the prefix argument. When non-nil,
use the current buffer for INFILE.

See also `org-clock-csv-batch' for a function more appropriate
for use in batch mode."
  (interactive "i\ni\nP")
  (when use-current
    (unless (equal major-mode 'org-mode)
      (user-error "Not in an org buffer")))
  (let* ((infile (if (and use-current buffer-file-name)
                     (list buffer-file-name)
                   infile))
         (filelist (if (null infile) (org-agenda-files)
                     (if (listp infile) infile (list infile))))
         (buffer (get-buffer-create "*clock-entries-csv*"))
         (entries (org-clock-csv--get-entries filelist)))
    (with-current-buffer buffer
      (goto-char 0)
      (erase-buffer)
      (insert org-clock-csv-header "\n")
      (mapc (lambda (entry)
              (insert (concat (funcall org-clock-csv-row-fmt entry) "\n")))
            entries))
    (if no-switch buffer
      (switch-to-buffer buffer))))

;;;###autoload
(defun org-clock-csv-to-file (outfile &optional infile use-current)
  "Write clock entries from INFILE to OUTFILE in CSV format.

See `org-clock-csv' for additional details."
  (interactive "FFile: \ni\nP")
  (let ((buffer (org-clock-csv infile 'no-switch use-current)))
    (with-current-buffer buffer
      (write-region nil nil outfile nil nil))
    (kill-buffer buffer)))

;;;###autoload
(defun org-clock-csv-batch-and-exit ()
  "Export clock entries in CSV format to standard output.

This function is identical in function to `org-clock-csv' except
that it directs output to `standard-output'. It is intended for
use in batch mode."
  (or noninteractive
      (error "`org-clock-csv-batch' is designed for use in batch mode."))
  (let* ((filelist (if (= (length command-line-args-left) 0)
                       (org-agenda-files)
                     command-line-args-left))
         entries)
    (unwind-protect
        (progn
          (setq entries (org-clock-csv--get-entries filelist t))
          (princ (concat org-clock-csv-header "\n"))
          (mapc (lambda (entry)
                  (princ (concat (funcall org-clock-csv-row-fmt entry) "\n")))
                entries)
          (kill-emacs 0))
      (backtrace)
      (message "Error converting clock entries to CSV format.")
      (kill-emacs 2))))

(defalias 'org-clock-csv-batch 'org-clock-csv-batch-and-exit)

(provide 'org-clock-csv)

;; Local Variables:
;; coding: utf-8
;; End:

;;; org-clock-csv.el ends here
