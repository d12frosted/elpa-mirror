;;; org-reverse-datetree.el --- Create reverse date trees in org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.3.5
;; Package-Version: 20210531.1929
;; Package-Commit: e7a7109e4c34811d471bf685b710234564a556f6
;; Package-Requires: ((emacs "26.1") (dash "2.12") (org "9.3"))
;; Keywords: outlines
;; URL: https://github.com/akirak/org-reverse-datetree

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides a function for creating reverse date trees,
;; which is similar to date trees supported by `org-capture' but
;; in a reversed order.  This is convenient in situation where
;; you want to find the latest status of a particular subject
;; using a search tool like `helm-org-rifle'.

;;; Code:

(require 'org)
(require 'subr-x)
(require 'seq)
(require 'cl-lib)
(require 'dash)

;; Silent byte compilers
(declare-function org-element-map "ext:org-element")
(declare-function org-element-parse-buffer "ext:org-element")
(declare-function org-element-property "ext:org-element")
(defvar org-agenda-buffer-name)
(defvar org-agenda-bulk-marked-entries)
(defvar org-agenda-persistent-marks)
(declare-function org-agenda-error "ext:org-agenda")
(declare-function org-agenda-bulk-unmark-all "ext:org-agenda")
(declare-function org-agenda-redo "ext:org-agenda")
(declare-function org-remove-subtree-entries-from-agenda "ext:org-agenda")
(declare-function org-agenda-archive-with "ext:org-agenda")
(defvar org-archive-subtree-save-file-p)
(defvar org-archive-save-context-info)
(defvar org-archive-mark-done)
(defvar org-archive-subtree-add-inherited-tags)
(defvar org-archive-file-header-format)
(defvar org-refile-active-region-within-subtree)
(declare-function project-roots "ext:project")
(declare-function project-current "ext:project")
(declare-function org-inlinetask-remove-END-maybe "ext:org-inlinetask")

(defgroup org-reverse-datetree nil
  "Reverse date trees for Org mode."
  :group 'org
  :prefix "org-reverse-datetree-")

(defcustom org-reverse-datetree-year-format "%Y"
  "Year format used by org-reverse-datetree."
  :type '(choice string function)
  :group 'org-reverse-datetree)

(defcustom org-reverse-datetree-month-format "%Y-%m %B"
  "Month format used by org-reverse-datetree."
  :type '(choice string function)
  :group 'org-reverse-datetree)

(defcustom org-reverse-datetree-week-format "%Y W%W"
  "Week format used by org-reverse-datetree.

%U is the week number starting on Sunday and %W starting on Monday."
  :type '(choice string function)
  :group 'org-reverse-datetree)

(defcustom org-reverse-datetree-date-format "%Y-%m-%d %A"
  "Date format used by org-reverse-datetree."
  :type '(choice string function)
  :group 'org-reverse-datetree)

(defcustom org-reverse-datetree-find-function
  'org-reverse-datetree--find-or-insert
  "Function used to find a location of a date tree or insert it."
  :type '(choice (symbol org-reverse-datetree--find-or-insert)
                 (symbol org-reverse-datetree--find-or-prepend))
  :group 'org-reverse-datetree)

(defcustom org-reverse-datetree-level-formats nil
  "List of formats for date trees.

This setting affects the behavior of
`org-reverse-datetree-goto-date-in-file' and
`org-reverse-datetree-goto-read-date-in-file'.

Each item in this variable corresponds to each level in date
trees.  Note that this variable is buffer-local, so you can also
set it either as a file-local variable or as a directory-local
variable.

If this variable is non-nil, it take precedence over the settings
in the Org header."
  :type '(repeat (choice string
                         function))
  :group 'org-reverse-datetree
  :safe nil)

(make-variable-buffer-local 'org-reverse-datetree-level-formats)

(defvar-local org-reverse-datetree--file-headers nil
  "Alist of headers of the buffer.")

(defvar-local org-reverse-datetree-non-reverse nil
  "If non-nil, creates a non-reverse date tree.")

(cl-defun org-reverse-datetree--find-or-prepend (level text
                                                       &key append-newline
                                                       &allow-other-keys)
  "Find or create a heading at a given LEVEL with TEXT.

If APPEND-NEWLINE is non-nil, a newline is appended to the
inserted text.

If a new tree is created, non-nil is returned."
  (declare (indent 1))
  (let ((prefix (concat (make-string (org-get-valid-level level) ?*) " "))
        (bound (unless (= level 1)
                 (save-excursion (org-end-of-subtree)))))
    (unless (re-search-forward (concat "^" (regexp-quote prefix) text)
                               bound t)
      (if (re-search-forward (concat "^" prefix) bound t)
          (end-of-line 0)
        (end-of-line 1))
      (insert (concat "\n" prefix text
                      (when append-newline
                        "\n")))
      text)))

(defun org-reverse-datetree--apply-format (format time)
  "Apply date FORMAT to TIME to produce a string.

The format can be either a function or a string."
  (cl-etypecase format
    (string (format-time-string format time))
    (function (funcall format time))))

;;;###autoload
(cl-defun org-reverse-datetree-2 (time level-formats return-type
                                       &key asc)
  "Jump to the specified date in a reverse date tree.

TIME is the date to be inserted.  If omitted, it will be today.

LEVEL-FORMATS is a list of formats.
See `org-reverse-datetree-level-formats' for the data type.

Depending on the value of RETURN-TYPE, this function returns the
following values:

\"'marker\":
  Returns the marker of the subtree.

\"point\"
  Returns point of subtree.

\"rfloc\"
  Returns a refile location spec that can be used as the third
  argument of `org-refile' function.

\"created\"
  Returns non-nil if and only if a new tree is created.

If ASC is non-nil, it creates a non-reverse date tree."
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (save-restriction
    (widen)
    (org-save-outline-visibility t
      (outline-show-all)
      (goto-char (point-min))
      (cl-loop for (level . format) in (-zip (number-sequence 1 (length level-formats))
                                             (-butlast level-formats))
               do (funcall org-reverse-datetree-find-function
                           level
                           (org-reverse-datetree--apply-format format time)
                           :asc asc))
      (let ((new (funcall org-reverse-datetree-find-function (length level-formats)
                          (org-reverse-datetree--apply-format (-last-item level-formats) time)
                          :asc asc)))
        (cl-case return-type
          ('marker (point-marker))
          ('point (point))
          ('rfloc (list (nth 4 (org-heading-components))
                        (buffer-file-name (or (org-base-buffer (current-buffer))
                                              (current-buffer)))
                        nil
                        (point)))
          ('created new))))))

;;;###autoload
(cl-defun org-reverse-datetree-1 (&optional time
                                            &key
                                            week-tree
                                            return)
  "Jump to the specified date in a reverse date tree.

This function is deprecated.
Use `org-reverse-datetree-2' instead.

A reverse date tree is a reversed version of the date tree in
`org-capture', i.e. a date tree where the newest date is the first.
This is especially useful for a notes archive, because the latest
entry on a particular topic is displayed at the top in
a command like `helm-org-rifle'.

`org-reverse-datetree-find-function' is used to find or insert trees.

TIME is the date to be inserted.  If omitted, it will be today.

If WEEK-TREE is non-nil, it creates week trees.  Otherwise, it
creates month trees.

For RETURN, see the documentation of `org-reverse-datetree-2'."
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (let ((time (or time (current-time)))
        (level-formats (org-reverse-datetree--level-formats
                        (if week-tree
                            'week
                          'month))))
    (org-reverse-datetree-2 time level-formats return)))

(make-obsolete 'org-reverse-datetree-1 'org-reverse-datetree-2 "0.3.0")

(defun org-reverse-datetree--level-formats (tree-type)
  "Build `org-reverse-datetree-level-formats' for TREE-TYPE."
  (cl-ecase tree-type
    (month
     (list org-reverse-datetree-year-format
           org-reverse-datetree-month-format
           org-reverse-datetree-date-format))
    (week
     (list org-reverse-datetree-year-format
           org-reverse-datetree-week-format
           org-reverse-datetree-date-format))
    (month-and-week
     (list org-reverse-datetree-year-format
           org-reverse-datetree-month-format
           org-reverse-datetree-week-format
           org-reverse-datetree-date-format))))

(defun org-reverse-datetree--get-level-formats ()
  "Return a list of outline formats for the current buffer."
  (or org-reverse-datetree-level-formats
      (progn
        (org-reverse-datetree--get-file-headers)
        (let* ((type (org-reverse-datetree--lookup-type-header-1))
               (org-reverse-datetree-year-format
                (org-reverse-datetree--lookup-format-header
                 "REVERSE_DATETREE_YEAR_FORMAT"
                 "Year format: "
                 org-reverse-datetree-year-format))
               (org-reverse-datetree-month-format
                (when (memq type '(month month-and-week))
                  (org-reverse-datetree--lookup-format-header
                   "REVERSE_DATETREE_MONTH_FORMAT"
                   "Month format: "
                   org-reverse-datetree-month-format)))
               (org-reverse-datetree-week-format
                (when (memq type '(week month-and-week))
                  (org-reverse-datetree--lookup-format-header
                   "REVERSE_DATETREE_WEEK_FORMAT"
                   "Week format: "
                   org-reverse-datetree-week-format)))
               (org-reverse-datetree-date-format
                (org-reverse-datetree--lookup-format-header
                 "REVERSE_DATETREE_DATE_FORMAT"
                 "Date format: "
                 org-reverse-datetree-date-format))
               (org-reverse-datetree-level-formats))
          (org-reverse-datetree--level-formats type)))))

(cl-defun org-reverse-datetree--find-or-insert (level text
                                                      &key asc
                                                      &allow-other-keys)
  "Find or create a heading with the given text at the given level.

LEVEL is the level of a tree, and TEXT is a heading of the tree.

This function uses string comparison to compare the dates in two
trees.  Therefore your date format must be alphabetically ordered,
e.g. beginning with YYYY(-MM(-DD)).

If a new tree is created, non-nil is returned.

If ASC is non-nil, it creates a date tree in ascending
order i.e. non-reverse datetree."
  (declare (indent 1))
  (let* ((prefix (concat (make-string (org-get-valid-level level) ?*) " "))
         (bounds (delq nil (list (save-excursion
                                   (when (re-search-forward
                                          (rx bol "# Local Variables:")
                                          nil t)
                                     (line-end-position)))
                                 (unless (= level 1)
                                   (save-excursion
                                     (org-end-of-subtree))))))
         (bound (when bounds (-min bounds)))
         created
         found)
    (catch 'search
      (while (and (or (not bound)
                      (> bound (point)))
                  (re-search-forward (concat "^" (regexp-quote prefix))
                                     bound t))
        (let ((here (nth 4 (org-heading-components))))
          (cond
           ((string-equal here text) (progn
                                       (end-of-line 1)
                                       (setq found t)
                                       (throw 'search t)))
           ((if asc
                (string> here text)
              (string< here text))
            (progn
              (end-of-line 0)
              (org-reverse-datetree--insert-heading
               prefix text)
              (setq created t
                    found t)
              (throw 'search t)))))))
    (unless found
      (goto-char (or bound (point-max)))
      (org-reverse-datetree--insert-heading
       prefix text)
      (setq created t))
    created))

(defun org-reverse-datetree--insert-heading (prefix text)
  "Insert a heading at a particular level into the point.

This function inserts a heading smartly depending on empty lines
around the point.

PREFIX is a prefix of the heading which consists of one or more
asterisks and a space.

TEXT is a heading text."
  ;; If the point is not at bol
  (unless (looking-at (rx bol))
    ;; If there is a blank line after the point
    (if (looking-at (rx (>= 2 "\n")))
        ;; Go to the bol immediately after the point
        (forward-char 1)
      ;; Ensure a new line is inserted
      (insert "\n")))
  (insert (if (org--blank-before-heading-p)
              "\n"
            "")
          prefix text))

;;;; Retrieving configuration from the file header

(defun org-reverse-datetree--get-file-headers ()
  "Get the file headers of the current Org buffer."
  (require 'org-element)
  (let ((buffer-ast (org-with-wide-buffer (org-element-parse-buffer))))
    (setq org-reverse-datetree--file-headers
          (or (org-element-map buffer-ast 'keyword
                (lambda (keyword)
                  (cons (org-element-property :key keyword)
                        (org-element-property :value keyword))))
              ;; If the file has no header, set the value to a
              ;; meaningless item to indicate that the headers have
              ;; already been read.
              '(("" . t))))))

(defun org-reverse-datetree--insert-header (key value)
  "Insert a pair of KEY and VALUE into the file header."
  (org-with-wide-buffer
   (goto-char (point-min))
   (if (re-search-forward (concat (rx bol "#+")
                                  (regexp-quote key)
                                  (rx ":" (1+ space)))
                          (save-excursion
                            (re-search-forward (rx bol "*") nil t)
                            (point))
                          t)
       (progn
         (kill-line)
         (insert value))
     (when (string-prefix-p "#" (thing-at-point 'line))
       (forward-line))
     (insert "#+" key ": " value "\n")
     ;; Update the cached value stored as a buffer-local variable
     (let ((pair (assoc key org-reverse-datetree--file-headers)))
       (if pair
           (setcdr pair value)
         (push (cons key value) org-reverse-datetree--file-headers))))))

(defun org-reverse-datetree--lookup-header (key)
  "Look up KEY from the file headers stored as a local variable."
  ;; First read the headers if it has not yet.
  (unless org-reverse-datetree--file-headers
    (org-reverse-datetree--get-file-headers))
  (cdr (assoc key org-reverse-datetree--file-headers)))

(defun org-reverse-datetree--lookup-type-header-1 ()
  "Look up a boolean file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT, inserts the value
into the header, and returns the value."
  (let ((header "REVERSE_DATETREE_USE_WEEK_TREE"))
    (pcase (org-reverse-datetree--lookup-header header)
      ("month-and-week" 'month-and-week)
      ("t" 'week)
      ("nil" 'month)
      ('nil (let* ((char (read-char-choice "Choose a datetree type ([y/w] week, [n/m] month, [b] week and month): "
                                           (string-to-list "ywnmb")))
                   (value (cl-case char
                            ((?y ?w) 'week)
                            ((?n ?m) 'month)
                            ((?b) 'month-and-week))))
              (org-reverse-datetree--insert-header header
                                                   (cl-case value
                                                     (week "t")
                                                     (month "nil")
                                                     (month-and-week "month-and-week")))
              value)))))

(defun org-reverse-datetree--parse-format (raw)
  "Parse a RAW time format string in the header.

If the first character of the string is either a single quotation
or an open parenthesis, it is read as a function.  Otherwise, it
is a string passed to `format-time-string' as the first argument."
  (unless (stringp raw)
    (user-error "Must be a string: %s" raw))
  (cond
   ((string-match (rx bol (any "'(")) raw)
    (read raw))
   (t
    raw)))

(defun org-reverse-datetree--lookup-format-header (key prompt initial)
  "Look up a string file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT with INITIAL
as the default value, inserts the value, and returns the value."
  (if-let ((value (org-reverse-datetree--lookup-header key)))
      (org-reverse-datetree--parse-format (string-trim value))
    (let* ((raw (read-string prompt initial))
           (ret (org-reverse-datetree--parse-format raw)))
      (org-reverse-datetree--insert-header key raw)
      ret)))

(defun org-reverse-datetree--lookup-string-header (key prompt initial)
  "Look up a string file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT with INITIAL
as the default value, inserts the value, and returns the value."
  (if-let ((value (org-reverse-datetree--lookup-header key)))
      (string-trim value)
    (let ((ret (read-string prompt initial)))
      (org-reverse-datetree--insert-header key ret)
      ret)))

(cl-defun org-reverse-datetree--lookup-file-name-header (key prompt
                                                             &key
                                                             abbreviate)
  "Look up a file name file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT, inserts the
value, and returns the value.

If ABBREVIATE is non-nil, abbreviate the file name."
  (if-let ((value (org-reverse-datetree--lookup-header key)))
      (string-trim value)
    (let ((ret (read-file-name prompt)))
      (org-reverse-datetree--insert-header
       key (org-reverse-datetree--relative-file ret abbreviate))
      ret)))

(defun org-reverse-datetree--relative-file (dest src)
  "Return the relative file name of DEST from SRC or abbreviate DEST."
  (let* ((project-a (and (featurep 'project)
                         (project-current nil (file-name-directory dest))))
         (project-b (and (featurep 'project)
                         (project-current nil (file-name-directory src)))))
    (if (or (and project-a
                 project-b
                 (file-equal-p (car (project-roots project-a))
                               (car (project-roots project-b))))
            (and (not project-a)
                 (not project-b)
                 (file-equal-p (file-name-directory dest)
                               (file-name-directory src))))
        (file-relative-name dest (file-name-directory src))
      (abbreviate-file-name dest))))

;;;; Navigational commands

;;;###autoload
(cl-defun org-reverse-datetree-goto-date-in-file (&optional time
                                                            &key return)
  "Find or create a heading as configured in the file headers.

This function finds an entry at TIME in a date tree as configured
by file headers of the buffer.  If there is no such configuration,
ask the user for a new configuration.  If TIME is omitted, it is
the current date.  RETURN is the same as in `org-reverse-datetree-1'.

When this function is called interactively, it asks for TIME using
`org-read-date' and go to an entry of the date."
  (interactive (list (org-read-date nil t nil)
                     :return nil))
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (org-reverse-datetree-2 time (org-reverse-datetree--get-level-formats)
                          return
                          :asc org-reverse-datetree-non-reverse))

;;;###autoload
(cl-defun org-reverse-datetree-goto-read-date-in-file (&rest args)
  "Find or create a heading as configured in the file headers.

This function is like `org-reverse-datetree-goto-date-in-file',
but it always asks for a date even if it is called non-interactively.

ARGS is the arguments to `org-reverse-datetree-goto-date-in-file'
after the time."
  (interactive)
  (apply #'org-reverse-datetree-goto-date-in-file
         (org-read-date nil t nil)
         (cdr args)))

(defun org-reverse-datetree--timestamp-to-time (s)
  "Convert timestamp string S into internal time."
  (apply #'encode-time (org-parse-time-string s)))

(cl-defun org-reverse-datetree--get-entry-time (&key ask-always
                                                     (prefer '("CLOSED")))
  "Get an Emacs time for the current Org entry.

This function retrieves a timestamp from a property of the entry.
By default, it checks for the closed date of the entry.
If there is no value set as the property, it asks for a date using
`org-read-date' unless if ASK-ALWAYS is non-nil.

You can specify properties to retrieve a timestamp from by
setting PREFER.  It can be a string or a list of strings.
If it is a list, the first existing property property is used.

This function returns an Emacs time."
  (let ((attempt (-some (lambda (property)
                          (org-entry-get nil property))
                        (cl-typecase prefer
                          (list prefer)
                          (t (list prefer))))))
    (cond
     (ask-always
      (org-read-date nil t nil nil
                     (org-reverse-datetree--timestamp-to-time attempt)))
     (attempt
      (org-reverse-datetree--timestamp-to-time attempt))
     (t (org-read-date nil t nil nil)))))

(cl-defun org-reverse-datetree--refile-to-file (file &optional time
                                                     &key ask-always prefer)
  "Refile the current single Org entry.

This is used inside `org-reverse-datetree-refile-to-file' to
refile a single tree.
FILE, TIME, ASK-ALWAYS, and PREFER are the same as in the function.

Return a string describing the operation."
  (let* ((time (or time
                   (org-reverse-datetree--get-entry-time
                    :ask-always ask-always
                    :prefer prefer)))
         (rfloc (with-current-buffer
                    (or (find-buffer-visiting file)
                        (find-file-noselect file))
                  (save-excursion
                    (org-reverse-datetree-goto-date-in-file
                     time :return 'rfloc))))
         (heading (nth 4 (org-heading-components))))
    (org-refile nil nil rfloc)
    (format "\"%s\" -> %s" heading (car rfloc))))

;;;###autoload
(cl-defun org-reverse-datetree-refile-to-file (file &optional time
                                                    &key ask-always prefer)
  "Refile the current Org entry into a configured date tree in a file.

This function refiles the current entry into a date tree in FILE
configured in the headers of the file.  The same configuration as
`org-reverse-datetree-goto-date-in-file' is used.

The location in the date tree is specified by TIME, which is an
Emacs time.  If TIME is not set, a timestamp is retrieved from
properties of the current entry using
`org-reverse-datetree--get-entry-time' with ASK-ALWAYS and PREFER
as arguments."
  ;; NOTE: Based on org 9.3. Maybe needs updating in the future
  (pcase (derived-mode-p 'org-mode 'org-agenda-mode)
    ('org-mode
     (if (org-region-active-p)
         (let ((region-start (region-beginning))
               (region-end (region-end))
               (org-refile-active-region-within-subtree nil)
               subtree-end
               msgs)
           (org-with-wide-buffer
            (when (file-equal-p file (buffer-file-name))
              (user-error "Can't refile to the same file"))
            (deactivate-mark)
            (goto-char region-start)
            (org-back-to-heading)
            (setq region-start (point))
            (while region-start
              (unless (org-at-heading-p)
                (org-next-visible-heading 1))
              (setq subtree-end (save-excursion
                                  (org-end-of-subtree)))
              (push (org-reverse-datetree--refile-to-file
                     file time :ask-always ask-always :prefer prefer)
                    msgs)
              (if (<= region-end subtree-end)
                  (setq region-start nil)
                (let ((len (- subtree-end region-start)))
                  (setq region-end (- region-end len))
                  (goto-char region-start)))))
           (let ((message-log-max nil))
             (message "Refiled to %s:\n%s"
                      file
                      (string-join (nreverse msgs) "\n"))))
       (org-reverse-datetree--refile-to-file
        file time :ask-always ask-always :prefer prefer)))
    ('org-agenda-mode
     (if org-agenda-bulk-marked-entries
         (dolist (group (seq-group-by #'marker-buffer
                                      org-agenda-bulk-marked-entries))
           (let ((processed 0)
                 (skipped 0)
                 (d 0)
                 msgs)
             (dolist (e (cl-sort (cdr group) (lambda (a b)
                                               (< (marker-position a)
                                                  (marker-position b)))))
               (let ((pos (text-property-any (point-min) (point-max) 'org-hd-marker e))
                     org-loop-over-headlines-in-active-region)
                 (if (not pos)
                     (progn
                       (message "Skipped removed entry")
                       (cl-incf skipped))
                   (goto-char pos)
                   (let* ((marker (or (org-get-at-bol 'org-hd-marker)
                                      (org-agenda-error))))
                     (with-current-buffer (marker-buffer marker)
                       (org-with-wide-buffer
                        (goto-char (- (marker-position marker) d))
                        (setq d (+ d (- (save-excursion
                                          (org-end-of-subtree))
                                        (point))))
                        (push (org-reverse-datetree--refile-to-file
                               file time :ask-always ask-always :prefer prefer)
                              msgs))))
                   ;; `post-command-hook' is not run yet.  We make sure any
                   ;; pending log note is processed.
                   (when (or (memq 'org-add-log-note (default-value 'post-command-hook))
                             (memq 'org-add-log-note post-command-hook))
                     (org-add-log-note))
                   (cl-incf processed))))
             (unless org-agenda-persistent-marks (org-agenda-bulk-unmark-all))
             (org-agenda-redo)
             (message "Refiled %d entries to %s%s\n%s"
                      processed file
                      (if (= skipped 0)
                          ""
                        (format ", skipped %d" skipped))
                      (string-join (nreverse msgs) "\n"))))
       (let* ((buffer-orig (buffer-name))
              (marker (or (org-get-at-bol 'org-hd-marker)
                          (org-agenda-error))))
         (with-current-buffer (marker-buffer marker)
           (org-with-wide-buffer
            (goto-char (marker-position marker))
            (let* (lexical-binding
                   (org-agenda-buffer-name buffer-orig))
              (org-remove-subtree-entries-from-agenda))
            (org-reverse-datetree--refile-to-file
             file time :ask-always ask-always :prefer prefer))))))
    (_ (user-error "Not in org-mode or org-agenda-mode"))))

;;;; Archiving

;; Based on `org-archive-subtree' in org-archive.el 9.4-dev
;;;###autoload
(defun org-reverse-datetree-archive-subtree (&optional find-done)
  "An org-reverse-datetree equivalent to `org-archive-subtree'.

A prefix argument FIND-DONE should be treated as in
`org-archive-subtree'."
  (interactive "P")
  (require 'org-archive)
  (unless (fboundp 'org-show-all)
    (user-error "This function requires `org-show-all' but it is unavailable"))
  (if (and (org-region-active-p) org-loop-over-headlines-in-active-region)
      (let ((cl (if (eq org-loop-over-headlines-in-active-region 'start-level)
        	    'region-start-level 'region))
            org-loop-over-headlines-in-active-region)
        (org-map-entries
         `(progn (setq org-map-continue-from (progn (org-back-to-heading) (point)))
        	 (org-reverse-datetree-archive-subtree ,find-done))
         org-loop-over-headlines-in-active-region
         cl (if (org-invisible-p) (org-end-of-subtree nil t))))
    (cond
     ((equal find-done '(4))  (error "FIXME: Not implemented for prefix"))
     ((equal find-done '(16)) (error "FIXME: Not implemented for prefix"))
     (t
      ;; Save all relevant TODO keyword-related variables.
      (let* ((tr-org-todo-keywords-1 org-todo-keywords-1)
             (tr-org-todo-kwd-alist org-todo-kwd-alist)
             (tr-org-done-keywords org-done-keywords)
             (tr-org-todo-regexp org-todo-regexp)
             (tr-org-todo-line-regexp org-todo-line-regexp)
             (tr-org-odd-levels-only org-odd-levels-only)
             (this-buffer (current-buffer))
             (current-time (current-time))
             (time (format-time-string
                    (substring (cdr org-time-stamp-formats) 1 -1)
                    current-time))
             (file (or (buffer-file-name (buffer-base-buffer))
                       (error "No file associated to buffer")))
             (afile (org-reverse-datetree--archive-file file))
             (infile-p (file-equal-p file afile))
             (newfile-p (and (org-string-nw-p afile)
                             (not (file-exists-p afile))))
             (buffer (cond ((not (org-string-nw-p afile)) this-buffer)
                           ((find-buffer-visiting afile))
                           ((find-file-noselect afile))
                           (t (error "Cannot access file \"%s\"" afile))))
             (archive-time (apply #'encode-time
                                  (org-parse-time-string
                                   (or (org-entry-get nil "CLOSED" t) time)))))
        (save-excursion
          (org-back-to-heading t)
          ;; Get context information that will be lost by moving the
          ;; tree.  See `org-archive-save-context-info'.
          (let* ((all-tags (org-get-tags))
                 (local-tags
                  (cl-remove-if (lambda (tag)
                                  (get-text-property 0 'inherited tag))
                                all-tags))
                 (inherited-tags
                  (cl-remove-if-not (lambda (tag)
                                      (get-text-property 0 'inherited tag))
                                    all-tags))
                 (context
                  `((category . ,(org-get-category nil 'force-refresh))
                    (file . ,file)
                    (itags . ,(mapconcat #'identity inherited-tags " "))
                    (ltags . ,(mapconcat #'identity local-tags " "))
                    (olpath . ,(mapconcat #'identity
                                          (org-get-outline-path)
                                          "/"))
                    (time . ,time)
                    (todo . ,(org-entry-get (point) "TODO")))))
            ;; We first only copy, in case something goes wrong
            ;; we need to protect `this-command', to avoid kill-region sets it,
            ;; which would lead to duplication of subtrees
            (let (this-command) (org-copy-subtree 1 nil t))
            (set-buffer buffer)
            ;; Enforce Org mode for the archive buffer
            (if (not (derived-mode-p 'org-mode))
                ;; Force the mode for future visits.
                (let ((org-insert-mode-line-in-empty-file t)
                      (org-inhibit-startup t))
                  (call-interactively #'org-mode)))
            (when (and newfile-p org-archive-file-header-format)
              (goto-char (point-max))
              (insert (format org-archive-file-header-format
                              (buffer-file-name this-buffer))))
            (org-reverse-datetree-goto-date-in-file archive-time)
            (org-narrow-to-subtree)
            ;; Force the TODO keywords of the original buffer
            (let ((org-todo-line-regexp tr-org-todo-line-regexp)
                  (org-todo-keywords-1 tr-org-todo-keywords-1)
                  (org-todo-kwd-alist tr-org-todo-kwd-alist)
                  (org-done-keywords tr-org-done-keywords)
                  (org-todo-regexp tr-org-todo-regexp)
                  (org-todo-line-regexp tr-org-todo-line-regexp)
                  (org-odd-levels-only
                   (if (local-variable-p 'org-odd-levels-only (current-buffer))
                       org-odd-levels-only
                     tr-org-odd-levels-only)))
              (goto-char (point-min))
              ;; TODO: Find an alternative to `org-show-all'.
              ;; org-show-all is unavailable in the Org shipped with
              ;; Emacs 26.3.
              (org-show-all '(headings blocks))
              ;; Paste
              ;; Append to the date tree
              (org-end-of-subtree)
              ;; Go to the beginning of the line
              (forward-line 1)
              (org-paste-subtree (org-get-valid-level
                                  (1+ (length (org-reverse-datetree--get-level-formats)))))
              ;; Shall we append inherited tags?
              (and inherited-tags
                   (or (and (eq org-archive-subtree-add-inherited-tags 'infile)
                            infile-p)
                       (eq org-archive-subtree-add-inherited-tags t))
                   (org-set-tags all-tags))
              ;; Mark the entry as done
              (when (and org-archive-mark-done
                         (let ((case-fold-search nil))
                           (looking-at org-todo-line-regexp))
                         (or (not (match-end 2))
                             (not (member (match-string 2) org-done-keywords))))
                (let (org-log-done org-todo-log-states)
                  (org-todo
                   (car (or (member org-archive-mark-done org-done-keywords)
                            org-done-keywords)))))

              ;; Add the context info.
              (dolist (item org-archive-save-context-info)
                (let ((value (cdr (assq item context))))
                  (when (org-string-nw-p value)
                    (org-entry-put
                     (point)
                     (concat "ARCHIVE_" (upcase (symbol-name item)))
                     value))))
              ;; Save and kill the buffer, if it is not the same
              ;; buffer and depending on `org-archive-subtree-save-file-p'
              (unless (eq this-buffer buffer)
                (when (or (eq org-archive-subtree-save-file-p t)
                          (and (boundp 'org-archive-from-agenda)
                               (eq org-archive-subtree-save-file-p 'from-agenda)))
                  (save-buffer)))
              (widen))))
        ;; Here we are back in the original buffer.  Everything seems
        ;; to have worked.  So now run hooks, cut the tree and finish
        ;; up.
        (run-hooks 'org-archive-hook)
        (let (this-command) (org-cut-subtree))
        (when (featurep 'org-inlinetask)
          (org-inlinetask-remove-END-maybe))
        (setq org-markers-to-move nil)
        (when org-provide-todo-statistics
          (save-excursion
            ;; Go to parent, even if no children exist.
            (org-up-heading-safe)
            ;; Update cookie of parent.
            (org-update-statistics-cookies nil)))
        (message "Subtree archived %s"
                 ;; (if (eq this-buffer buffer)
                 ;;     (concat "under heading: " heading)
                 ;;   (concat "in file: " (abbreviate-file-name afile)))
                 (concat "in file: " (abbreviate-file-name afile))))))
    (org-reveal)
    (if (looking-at "^[ \t]*$")
	(outline-next-visible-heading 1))))

(defun org-reverse-datetree--archive-file (origin-file)
  "Retrieve the name of the archive file, relative from ORIGIN-FILE."
  (let ((pname "REVERSE_DATETREE_ARCHIVE_FILE"))
    (or (org-entry-get-with-inheritance pname)
        (org-reverse-datetree--lookup-file-name-header
         pname "Select an archive file: " :abbreviate origin-file))))

;;;###autoload
(defun org-reverse-datetree-agenda-archive ()
  "Archive the entry or subtree belonging to the current agenda entry."
  (interactive)
  (funcall-interactively
   #'org-agenda-archive-with 'org-reverse-datetree-archive-subtree))

;;;; Utility functions for defining formats
(defun org-reverse-datetree-monday (&optional time)
  "Get Monday in the same week as TIME."
  (org-reverse-datetree-last-dow 1 time))

(defun org-reverse-datetree-sunday (&optional time)
  "Get Sunday in the same week as TIME."
  (org-reverse-datetree-last-dow 0 time))

(defun org-reverse-datetree-last-dow (n &optional time)
  "Get the date on N th day of week in the same week as TIME."
  (let* ((time (or time (current-time)))
         (x (- (org-reverse-datetree--dow time) n)))
    (time-add time (- (* 86400 (if (>= x 0) x (+ x 7)))))))

(defun org-reverse-datetree--dow (time)
  "Get the day of week of TIME."
  (nth 6 (decode-time time)))

;;;; Maintenance commands

;;;###autoload
(cl-defun org-reverse-datetree-cleanup-empty-dates (&key noconfirm
                                                         ancestors)
  "Delete empty date entries in the buffer.

If NOCONFIRM is non-nil, leaf nodes are deleted without
confirmation. In non-interactive mode, you have to explicitly set
this argument.

If both NOCONFIRM and ANCESTORS are non-nil, upper level nodes
are deleted without confirmation as well."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (let ((levels (length (org-reverse-datetree--get-level-formats)))
        count)
    (org-save-outline-visibility t
      (outline-hide-sublevels (1+ levels))
      (when (and (not noninteractive)
                 (not (org-before-first-heading-p))
                 (yes-or-no-p "Start from the beginning?"))
        (goto-char (point-min)))
      (catch 'abort
        (while (> levels 0)
          (setq count 0)
          (while (re-search-forward
                  (rx-to-string `(and bol
                                      (group (= ,levels "*")
                                             (+ " ")
                                             (*? nonl)
                                             (+ "\n"))
                                      (or string-end
                                          (and (** 1 ,levels "*")
                                               " "))))
                  nil t)
            (let ((begin (match-beginning 1))
                  (end (match-end 1)))
              (cond
               (noconfirm
                (delete-region begin end)
                (cl-incf count)
                (goto-char begin))
               ((not noninteractive)
                (goto-char begin)
                (push-mark end)
                (setq mark-active t)
                (when (yes-or-no-p "Delete this empty entry?")
                  (call-interactively #'delete-region)
                  (cl-incf count)
                  (goto-char begin))))))
          (when (= count 0)
            (message "No trees were deleted. Aborting")
            (throw 'abort t))
          (if (and (> levels 1)
                   (or (and ancestors (or noninteractive noconfirm))
                       (yes-or-no-p "Clean up the upper level as well?")))
              (progn
                (cl-decf levels)
                (goto-char (point-min)))
            (throw 'abort t)))))))

(provide 'org-reverse-datetree)
;;; org-reverse-datetree.el ends here
