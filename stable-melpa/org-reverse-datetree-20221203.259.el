;;; org-reverse-datetree.el --- Create reverse date trees in org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020,2021,2022 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.4.2
;; Package-Version: 20221203.259
;; Package-Commit: fca95cd22ed29653f3217034c71ec0ab0a7c7734
;; Package-Requires: ((emacs "28.1") (dash "2.19") (org "9.5"))
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
(declare-function org-element-clock-parser "ext:org-element")
(declare-function org-element-type "ext:org-element")
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
(defvar org-read-date-prefer-future)
(declare-function project-roots "ext:project")
(declare-function project-current "ext:project")
(declare-function org-inlinetask-remove-END-maybe "ext:org-inlinetask")

(defgroup org-reverse-datetree nil
  "Reverse date trees for Org mode."
  :group 'org
  :prefix "org-reverse-datetree-")

(defface org-reverse-datetree-calendar-date-face
  '((((class color) (min-colors 88) (background dark))
     :background "#481260" :foreground "#ffffff" :bold t)
    (((class color) (min-colors 88) (background light))
     :background  "#eeaeee" :foreground "#000000" :bold t)
    (t (:background "#cd5b45")))
  "Face for calendar dates."
  :group 'calendar-faces)

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

(defcustom org-reverse-datetree-entry-time '((property "CLOSED")
                                             (clock latest)
                                             (match :type inactive))
  "How to determine the entry time unless explicitly specified.

This is a list of patterns, and the first pattern takes
precedence over the others.

Each pattern takes one of the following expressions:

  * (property PROPERTY...)

    Return one of the property values, if available.

    PROPERTY is a string for the name of a property in the entry.

    You can specify, for example, \"CLOSED\".

    You can specify multiple values.

  * (clock ORDER)

    Return a timestamp from one of the clock entries in the logbook.

    ORDER can be either \\='latest or \\='earliest, which means the
    latest and earliest timestamp is returned respectively.

  * (match PLIST)

    Return the first match of a timestamp in the entry.

    PLIST can specify options."
  :type '(repeat
          (choice (cons :tag "Property"
                        (const property)
                        (repeat string))
                  (list :tag "Clock entry in the drawer"
                        (const clock)
                        (choice (const latest)
                                (const earliest)))
                  (cons :tag "First regexp match of timestamp"
                        (const match)
                        (plist :tag "Properties"
                               :option
                               ((list :tag "Type of timestamp"
                                      (const :type)
                                      (choice (const :tag "Inactive timestamps (default)"
                                                     inactive)
                                              (const :tag "Active timestamps"
                                                     active)
                                              (const :tag "Active and inactive timestamps"
                                                     any))))))))
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

(defcustom org-reverse-datetree-show-context-detail
  '((default . ancestors))
  "Alist that defines how to show the context of the date entry.

This is a list of (RETURN-TYPE . DETAIL) items where RETURN-TYPE
is an argument of `org-reverse-datetree-2' and DETAIL is a
visibility span as used in `org-show-context-detail'. When there
is no entry matching the return type of no return type is given,
`default' will be used.

Depending on the return type, the context is shown after jumping
to a date tree.

If this variable is nil, no explicit operation to show the
context is performed, which is faster. It would be useful to
temporarily set the variable to nil in scripting, e.g. for
refiling many entries to a single file."
  :group 'org-reverse-datetree
  :type '(alist :key-type (choice (const marker)
                                  (const point)
                                  (const rfloc)
                                  (const created)
                                  (const default))
                :value-type (choice (const minimal)
                                    (const local)
                                    (const ancestors)
                                    (const lineage)
                                    (const tree)
                                    (const canonical))))

(defcustom org-reverse-datetree-prefer-future 'default
  "Whether to assume a future date for incomplete date input.

This variable overrides `org-read-date-prefer-future' inside the
package.

When the user enters an incomplete date, e.g. a month and a day
but without a year, it may be either a future or a past date. If
this variable is t, the package assumes it is a future date (in
the next month or in the next year). If this variable is nil, the
package assumes it is a past date (in this month or year).

If the user uses the package archiving, nil value is recommended.

A special value \\='default it uses the current value
of `org-read-date-prefer-future'."
  :type '(choice (const :tag "Future (check month and day)" t)
                 (const :tag "Past (never)" nil)
                 (const :tag "Use `org-read-date-prefer-future'" default)))

(defvar-local org-reverse-datetree--file-headers nil
  "Alist of headers of the buffer.")

(defvar-local org-reverse-datetree-non-reverse nil
  "If non-nil, creates a non-reverse date tree.")

(defvar-local org-reverse-datetree-num-levels nil)

(eval-and-compile
  (if (version< emacs-version "27")
      (defun org-reverse-datetree--encode-time (time)
        "Encode TIME using `encode-time'."
        (apply #'encode-time time))
    (defalias 'org-reverse-datetree--encode-time #'encode-time)))

;;;; Common utilities

(defun org-reverse-datetree--read-date ()
  "Wrap `org-read-date' for the package."
  (let ((org-read-date-prefer-future
         (if (eq org-reverse-datetree-prefer-future 'default)
             org-read-date-prefer-future
           org-reverse-datetree-prefer-future)))
    (org-read-date nil t)))

;;;; Basics

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

(defun org-reverse-datetree--effective-time ()
  (let ((org-use-last-clock-out-time-as-effective-time nil))
    (org-current-effective-time)))

(defun org-reverse-datetree--to-effective-time (time)
  "Return an effective time for TIME."
  (if org-use-effective-time
      (let ((decoded (decode-time time)))
        (if (and org-extend-today-until
                 (< (nth 2 decoded) org-extend-today-until))
            (progn
              (setf (nth 2 decoded) 23)
              (setf (nth 1 decoded) 59)
              (setf (nth 0 decoded) 0)
              (cl-decf (nth 3 decoded))
              (org-reverse-datetree--encode-time decoded))
          time))
    time))

;;;###autoload
(cl-defun org-reverse-datetree-2 (time level-formats
                                       &optional return-type
                                       &key asc olp)
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

If ASC is non-nil, it creates a non-reverse date tree.

If OLP is a string or a list of strings, it specifies the parent
tree of the date tree, like a file+olp+datetree target of
`org-capture'."
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (save-restriction
    (widen)
    (prog1
        (org-save-outline-visibility t
          (outline-show-all)
          (if olp
              (org-reverse-datetree--olp (cl-etypecase olp
                                           (string (list olp))
                                           (list olp)))
            (goto-char (point-min)))
          (let ((parent-level (length olp)))
            (cl-loop for (level . format) in (-zip (number-sequence
                                                    (+ parent-level 1)
                                                    (+ parent-level (length level-formats)))
                                                   (-butlast level-formats))
                     do (funcall org-reverse-datetree-find-function
                                 level
                                 (org-reverse-datetree--apply-format format time)
                                 :asc asc))
            (let ((new (funcall org-reverse-datetree-find-function (+ parent-level
                                                                      (length level-formats))
                                (org-reverse-datetree--apply-format (-last-item level-formats) time)
                                :asc asc)))
              (cl-case return-type
                (marker (point-marker))
                (point (point))
                (rfloc (list (nth 4 (org-heading-components))
                             (buffer-file-name (or (org-base-buffer (current-buffer))
                                                   (current-buffer)))
                             nil
                             (point)))
                (created new)))))
      (when-let (visibility (or (cdr (assq (or return-type 'default)
                                           org-reverse-datetree-show-context-detail))
                                (when (not (eq return-type 'default))
                                  (cdr (assq 'default
                                             org-reverse-datetree-show-context-detail)))))
        (org-fold-show-set-visibility visibility)))))

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
  (let ((time (or time (org-reverse-datetree--effective-time)))
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

(defun org-reverse-datetree--get-level-formats (&optional allow-failure)
  "Return a list of outline formats for the current buffer.

If ALLOW-FAILURE is non-nil, it returns nil if the buffer does
not have a datetree format configured."
  (or org-reverse-datetree-level-formats
      (progn
        (setq org-reverse-datetree-num-levels nil)
        (org-reverse-datetree--get-file-headers)
        (catch 'datetree-format
          (let* ((type (org-reverse-datetree--lookup-type-header-1
                        allow-failure))
                 (org-reverse-datetree-year-format
                  (or (org-reverse-datetree--lookup-format-header
                       "REVERSE_DATETREE_YEAR_FORMAT"
                       "Year format: "
                       org-reverse-datetree-year-format
                       allow-failure)
                      (throw 'datetree-format nil)))
                 (org-reverse-datetree-month-format
                  (when (memq type '(month month-and-week))
                    (or (org-reverse-datetree--lookup-format-header
                         "REVERSE_DATETREE_MONTH_FORMAT"
                         "Month format: "
                         org-reverse-datetree-month-format
                         allow-failure)
                        (throw 'datetree-format nil))))
                 (org-reverse-datetree-week-format
                  (when (memq type '(week month-and-week))
                    (or (org-reverse-datetree--lookup-format-header
                         "REVERSE_DATETREE_WEEK_FORMAT"
                         "Week format: "
                         org-reverse-datetree-week-format
                         allow-failure)
                        (throw 'datetree-format nil))))
                 (org-reverse-datetree-date-format
                  (or (org-reverse-datetree--lookup-format-header
                       "REVERSE_DATETREE_DATE_FORMAT"
                       "Date format: "
                       org-reverse-datetree-date-format
                       allow-failure)
                      (throw 'datetree-format nil)))
                 (org-reverse-datetree-level-formats))
            (org-reverse-datetree--level-formats type))))))

(defun org-reverse-datetree-configured-p ()
  "Return non-nil if the buffer has a datetree."
  (when (org-reverse-datetree--get-level-formats t)
    t))

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
  (let ((buffer-ast (org-with-wide-buffer
                     (goto-char (point-min))
                     (save-match-data
                       (when (re-search-forward org-heading-regexp nil t)
                         (narrow-to-region (point-min) (point))))
                     (org-element-parse-buffer))))
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
   (when (looking-at org-property-drawer-re)
     (goto-char (match-end 0))
     (beginning-of-line 2))
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

(defun org-reverse-datetree--lookup-type-header-1 (&optional fail-if-missing)
  "Look up a boolean file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT, inserts the value
into the header, and returns the value.

If FAIL-IF-MISSING is non-nil and the key does not exist, this
function returns nil."
  (let ((header "REVERSE_DATETREE_USE_WEEK_TREE"))
    (pcase (org-reverse-datetree--lookup-header header)
      ("month-and-week" 'month-and-week)
      ("t" 'week)
      ("nil" 'month)
      ('nil (unless fail-if-missing
              (let* ((char (read-char-choice
                            "Choose a datetree type ([y/w] week, [n/m] month, [b] week and month): "
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
                value))))))

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

(defun org-reverse-datetree--lookup-format-header (key prompt initial
                                                       &optional fail-if-missing)
  "Look up a string file header or ask for a value.

This function looks up KEY from the file headers.  If the key is
not contained, it asks for a new value with PROMPT with INITIAL
as the default value, inserts the value, and returns the value.

If FAIL-IF-MISSING is non-nil and the key does not exist, this
function returns nil."
  (if-let ((value (org-reverse-datetree--lookup-header key)))
      (org-reverse-datetree--parse-format (string-trim value))
    (unless fail-if-missing
      (let* ((raw (read-string prompt initial))
             (ret (org-reverse-datetree--parse-format raw)))
        (org-reverse-datetree--insert-header key raw)
        ret))))

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
                                                            &key return olp)
  "Find or create a heading as configured in the file headers.

This function finds an entry at TIME in a date tree as configured
by file headers of the buffer.  If there is no such configuration,
ask the user for a new configuration.  If TIME is omitted, it is
the current date.

RETURN and OLP are the same as in `org-reverse-datetree-2', which
see.

When this function is called interactively, it asks for TIME using
`org-read-date' and go to an entry of the date."
  (interactive (list (org-reverse-datetree--read-date)
                     :return nil))
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (org-reverse-datetree-2 time (org-reverse-datetree--get-level-formats)
                          return
                          :asc org-reverse-datetree-non-reverse
                          :olp olp))

;;;###autoload
(cl-defun org-reverse-datetree-goto-read-date-in-file (&rest args)
  "Find or create a heading as configured in the file headers.

This function is like `org-reverse-datetree-goto-date-in-file',
but it always asks for a date even if it is called non-interactively.

ARGS are the arguments to
`org-reverse-datetree-goto-date-in-file' without the time, which
see."
  (interactive)
  (apply #'org-reverse-datetree-goto-date-in-file
         (org-reverse-datetree--read-date)
         (cdr args)))

(defun org-reverse-datetree--timestamp-to-time (s)
  "Convert timestamp string S into internal time."
  (org-reverse-datetree--encode-time (org-parse-time-string s)))

(defun org-reverse-datetree--olp (olp)
  "Go to an outline path in the current buffer or create it.

OLP must be a list of strings."
  (let ((existing (copy-sequence olp))
        marker)
    (while (and existing
                (not (setq marker (ignore-errors (org-find-olp existing t)))))
      (setq existing (nbutlast existing 1)))
    (if marker
        (goto-char marker)
      (goto-char (point-min)))
    (pcase-dolist
        (`(,level . ,text)
         (-drop (length existing)
                (-zip (number-sequence 1 (length olp))
                      olp)))
      (funcall org-reverse-datetree-find-function
               level text :asc t))))

(defun org-reverse-datetree--entry-time-2 (&optional time)
  "Return an Emacs time for the current Org entry.

TIME can take the same value as
`org-reverse-datetree-refile-to-file', which see."
  (pcase time
    (`nil
     (if org-reverse-datetree-entry-time
         (org-reverse-datetree--entry-time-2 org-reverse-datetree-entry-time)
       (org-reverse-datetree--read-date)))
    ((guard (ignore-errors (float-time time)))
     time)
    ((or `t '(4))
     (org-reverse-datetree--read-date))
    ((pred consp)
     (catch 'entry-time
       (dolist (x (copy-sequence time))
         (pcase x
           (`(property . ,props)
            (when-let (times (-some (lambda (property)
                                      (org-entry-get nil property))
                                    props))
              (throw 'entry-time (org-reverse-datetree--to-effective-time
                                  (org-reverse-datetree--timestamp-to-time times)))))
           (`(clock ,order)
            (when-let (clocks (org-reverse-datetree--clocks))
              (throw 'entry-time (when-let (time
                                            (cl-ecase order
                                              (latest (car (-sort (-not #'time-less-p) clocks)))
                                              (earliest (car (-sort #'time-less-p clocks)))))
                                   (org-reverse-datetree--to-effective-time time)))))
           (`(match . ,plist)
            (let ((regexp (pcase (plist-get plist :type)
                            ('any org-ts-regexp-both)
                            ('active org-ts-regexp)
                            (_ org-ts-regexp-inactive)))
                  (bound (save-excursion
                           (org-entry-end-position))))
              (save-excursion
                (org-back-to-heading)
                (when (re-search-forward regexp bound t)
                  (throw 'entry-time (org-reverse-datetree--to-effective-time
                                      (org-reverse-datetree--timestamp-to-time
                                       (match-string 1))))))))
           (_ (error "Unknown pattern: %s" x))))
       (org-reverse-datetree--read-date)))
    (_
     (error "Unsupported pattern: %s" time))))

(defun org-reverse-datetree--clocks ()
  "Collect clocks for the current entry."
  (require 'org-element)
  (save-excursion
    (org-back-to-heading)
    (end-of-line 1)
    (let* ((entry-end (org-entry-end-position))
           (logbook-end (save-excursion
                          (re-search-forward org-logbook-drawer-re entry-end t))))
      (when logbook-end
        (let (entries)
          (while (re-search-forward org-clock-line-re logbook-end t)
            (let ((clock (org-element-clock-parser (line-end-position))))
              (when (and (eq 'clock (org-element-type clock))
                         (eq 'closed (org-element-property :status clock)))
                (let ((timestamp (org-element-property :value clock)))
                  (push (org-reverse-datetree--encode-time
                         (list 0
                               (org-element-property :minute-start timestamp)
                               (org-element-property :hour-start timestamp)
                               (org-element-property :day-start timestamp)
                               (org-element-property :month-start timestamp)
                               (org-element-property :year-start timestamp)
                               nil nil nil))
                        entries)
                  (push (org-reverse-datetree--encode-time
                         (list 0
                               (org-element-property :minute-end timestamp)
                               (org-element-property :hour-end timestamp)
                               (org-element-property :day-end timestamp)
                               (org-element-property :month-end timestamp)
                               (org-element-property :year-end timestamp)
                               nil nil nil))
                        entries)))))
          entries)))))

(cl-defun org-reverse-datetree--refile-to-file (file &optional time
                                                     &key ask-always prefer)
  "Refile the current single Org entry.

This is used inside `org-reverse-datetree-refile-to-file' to
refile a single tree. FILE, TIME, ASK-ALWAYS, and PREFER are the
same as in the function. ASK-ALWAYS and PREFER should be removed
in the future.

Return the effective time of the target headline."
  (let* ((time (org-reverse-datetree--entry-time-2
                (cond
                 (time time)
                 (ask-always t)
                 (prefer `(property ,@(cl-typecase prefer
                                        (list prefer)
                                        (t (list prefer))))))))
         (rfloc (with-current-buffer
                    (or (find-buffer-visiting file)
                        (find-file-noselect file))
                  (save-excursion
                    (org-reverse-datetree-goto-date-in-file
                     time :return 'rfloc))))
         (heading (nth 4 (org-heading-components))))
    (org-refile nil nil rfloc)
    (message (format "\"%s\" -> %s" heading (car rfloc)))
    time))

(defun org-reverse-datetree-default-entry-time ()
  "Return the default expected date of the entry."
  (org-reverse-datetree--entry-time-2))

;;;###autoload
(cl-defun org-reverse-datetree-refile-to-file (file &optional time
                                                    &key ask-always prefer)
  "Refile the current Org entry into a configured date tree in a file.

This function refiles the current entry into a date tree in FILE
configured in the headers of the file.  The same configuration as
`org-reverse-datetree-goto-date-in-file' is used.

This function retrieves a timestamp from from the entry. Unless
TIME is specified, `org-reverse-datetree-entry-time' determines
how to pick a timestamp. If the argument is specified, it can
take the same format (i.e. a list of patterns) as
`org-reverse-datetree-entry-time' variable.

Alternatively, you can set TIME to t, in which case a prompt is
shown to let the user choose a date explicitly.

ASK-ALWAYS and PREFER are deprecated.

Unless a region is active in `org-mode' or the bulk mode is
active in `org-agenda-mode', this function returns the effective
time of the destination entry. If either mode is effective, nil
is returned."
  ;; NOTE: Based on org 9.3. Maybe needs updating in the future
  (pcase (derived-mode-p 'org-mode 'org-agenda-mode)
    ('org-mode
     (if (org-region-active-p)
         (let ((region-start (region-beginning))
               (region-end (region-end))
               (org-refile-active-region-within-subtree nil)
               subtree-end)
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
              (org-reverse-datetree--refile-to-file
               file time :ask-always ask-always :prefer prefer)
              (if (<= region-end subtree-end)
                  (setq region-start nil)
                (let ((len (- subtree-end region-start)))
                  (setq region-end (- region-end len))
                  (goto-char region-start)))))
           (let ((message-log-max nil))
             (message "Refiled to %s" file))
           nil)
       (org-reverse-datetree--refile-to-file
        file time :ask-always ask-always :prefer prefer)))
    ('org-agenda-mode
     (if org-agenda-bulk-marked-entries
         (dolist (group (seq-group-by #'marker-buffer
                                      org-agenda-bulk-marked-entries))
           (let ((processed 0)
                 (skipped 0)
                 (d 0))
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
                        (org-reverse-datetree--refile-to-file
                         file time :ask-always ask-always :prefer prefer))))
                   ;; `post-command-hook' is not run yet.  We make sure any
                   ;; pending log note is processed.
                   (when (or (memq 'org-add-log-note (default-value 'post-command-hook))
                             (memq 'org-add-log-note post-command-hook))
                     (org-add-log-note))
                   (cl-incf processed))))
             (unless org-agenda-persistent-marks (org-agenda-bulk-unmark-all))
             (org-agenda-redo)
             (message "Refiled %d entries to %s%s"
                      processed file
                      (if (= skipped 0)
                          ""
                        (format ", skipped %d" skipped)))
             nil))
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
  (unless (fboundp 'org-fold-show-all)
    (user-error "This function requires `org-fold-show-all' but it is unavailable"))
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
             (current-time (org-reverse-datetree--effective-time))
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
             (closed (org-entry-get nil "CLOSED" t))
             (archive-time (if closed
                               (and (string-match org-ts-regexp-inactive closed)
                                    (org-reverse-datetree--encode-time
                                     (org-parse-time-string (match-string 1 closed))))
                             current-time)))
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
                    (time . ,(format-time-string
                              (thread-last
                                (org-time-stamp-format t)
                                (string-remove-prefix "<")
                                (string-remove-suffix ">"))
                              current-time))
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
              ;; TODO: Find an alternative to `org-fold-show-all'.
              ;; org-fold-show-all is unavailable in the Org shipped with
              ;; Emacs 26.3.
              (org-fold-show-all '(headings blocks))
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
  (let* ((time (or time (org-reverse-datetree--effective-time)))
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

If NOCONFIRM is non-nil, nodes are deleted without confirmation.
In non-interactive mode, you have to explicitly set this
argument.

If both NOCONFIRM and ANCESTORS are non-nil, upper level nodes
are deleted without confirmation as well."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (when (and (or noninteractive
                 (not (called-interactively-p 'any)))
             (not noconfirm))
    (error "Please set NOCONFIRM when called non-interactively"))
  (let ((levels (length (org-reverse-datetree--get-level-formats t)))
        count)
    (when (> levels 0)
      (org-save-outline-visibility t
        (outline-hide-sublevels (1+ levels))
        (when (or noconfirm
                  (and (not (org-before-first-heading-p))
                       (yes-or-no-p "Start from the beginning?")))
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
                     (or (and ancestors
                              noconfirm)
                         (and (not noninteractive)
                              (called-interactively-p 'any)
                              (yes-or-no-p "Clean up the upper level as well?"))))
                (progn
                  (cl-decf levels)
                  (goto-char (point-min)))
              (throw 'abort t))))))))


;;;; Calendar integration

(defvar org-reverse-datetree-calendar-file nil)

(defun org-reverse-datetree-calendar ()
  "Display calendar with dates in the current file highlighted.

If the point is on a date in the date tree, go to the date in the
calendar."
  (interactive)
  (require 'calendar)
  (org-reverse-datetree-link-calendar)
  (let ((date (org-reverse-datetree-guess-date :decoded t)))
    (calendar)
    (when date
      (calendar-goto-date (org-reverse-datetree--to-calendar-date date)))))

(defun org-reverse-datetree-link-calendar (&optional file)
  "Associate FILE with the calendar."
  (unless (derived-mode-p 'org-mode)
    (user-error "Run this command in org-mode"))
  (setq org-reverse-datetree-calendar-file
        (or file (buffer-file-name)))
  (add-hook 'calendar-today-visible-hook
            #'org-reverse-datetree-mark-calendar)
  (add-hook 'calendar-today-invisible-hook
            #'org-reverse-datetree-mark-calendar))

(defun org-reverse-datetree-unlink-calendar ()
  "Unassociate the file from the calendar."
  (interactive)
  (setq org-reverse-datetree-calendar-file nil)
  (remove-hook 'calendar-today-visible-hook
               #'org-reverse-datetree-mark-calendar)
  (remove-hook 'calendar-today-invisible-hook
               #'org-reverse-datetree-mark-calendar))

(defun org-reverse-datetree-display-entry ()
  "Display the Org entry for the date at point in the calendar."
  (interactive)
  (let ((date (calendar-cursor-to-date))
        (file org-reverse-datetree-calendar-file))
    (with-current-buffer (or (find-buffer-visiting file)
                             (find-file-noselect file))
      (pop-to-buffer (current-buffer))
      (org-reverse-datetree-goto-date-in-file
       (org-reverse-datetree--encode-time
        (list 0 0 0 (nth 1 date) (nth 0 date) (nth 2 date)
              nil nil (car (current-time-zone)))))
      (org-beginning-of-line))))

(defun org-reverse-datetree-calendar-next (&optional backward)
  "Go to the next date that has an entry."
  (interactive)
  (let ((calendar-date (calendar-cursor-to-date))
        (file org-reverse-datetree-calendar-file))
    (when-let (date (with-current-buffer (or (find-buffer-visiting file)
                                             (find-file-noselect file))
                      (cl-labels
                          ((compare-dates (date1 date2)
                             (- (calendar-absolute-from-gregorian date1)
                                (calendar-absolute-from-gregorian date2)))
                           (test-pred (entry-date)
                             (if backward
                                 (< (compare-dates entry-date calendar-date) 0)
                               (> (compare-dates entry-date calendar-date) 0)))
                           (sort-pred (date1 date2)
                             (if backward
                                 (> (compare-dates date1 date2) 0)
                               (< (compare-dates date1 date2) 0))))
                        (thread-last
                          (org-reverse-datetree-dates :decoded t)
                          (mapcar (pcase-lambda (`(,_ ,_ ,_ ,day ,month ,year . ,_))
                                    (list month day year)))
                          (seq-filter #'test-pred)
                          (-sort #'sort-pred)
                          (car)))))
      (calendar-goto-date date))))

(defun org-reverse-datetree-calendar-previous ()
  "Go to the previous date that has an entry."
  (interactive)
  (org-reverse-datetree-calendar-next t))

(defun org-reverse-datetree-mark-calendar ()
  "Mark the calendar entry."
  (when org-reverse-datetree-calendar-file
    (let ((file org-reverse-datetree-calendar-file))
      (dolist (date (with-current-buffer
                        (or (find-buffer-visiting file)
                            (find-file-noselect file))
                      (mapcar #'org-reverse-datetree--to-calendar-date
                              (org-reverse-datetree-dates :decoded t))))
        (when (calendar-date-is-visible-p date)
          (calendar-mark-visible-date date 'org-reverse-datetree-calendar-date-face))))))

(defun org-reverse-datetree--to-calendar-date (decoded-time)
  "Convert DECODED-TIME to a calendar date (month day year)."
  (list (nth 4 decoded-time)
        (nth 3 decoded-time)
        (nth 5 decoded-time)))

;;;; Other public functions for convenience

(cl-defun org-reverse-datetree-map-entries (func &key date-regexp)
  "Call a function at each child of date entries.

This is like `org-map-entries', but for the datetree. Instead of
calling a function at each headline in the buffer, it is called
at each direct child of date entries.

FUNC is called with the date as an argument.

If DATE-REGEXP is a string, it is used to match against the
headline text, and the matched text is given as the argument. The
entire date is skipped if the regular expression does not match.

If DATE-REGEXP is nil, if matches all the headings at a certain
level. The entire headline of the parent date entry will be
passed to FUNC.

It returns a list of results returned by the function."
  (let* ((formats (org-reverse-datetree--get-level-formats t))
         (heading-regexp (rx-to-string `(and bol
                                             ,(make-string (length formats) ?\*)
                                             (+ blank)
                                             ,@(when date-regexp
                                                 `((group (regexp ,date-regexp)))))))
         result)
    (when formats
      (while (re-search-forward heading-regexp nil t)
        (let ((date (if date-regexp
                        (match-string-no-properties 1)
                      (substring-no-properties (org-get-heading t t t t))))
              (level (org-get-valid-level (1+ (org-outline-level))))
              (bound (save-excursion
                       (org-end-of-subtree))))
          (while (re-search-forward org-heading-regexp bound t)
            (when (= (org-outline-level) level)
              (beginning-of-line)
              (push (save-excursion
                      (funcall func date))
                    result))
            (end-of-line)))))
    (nreverse result)))

(cl-defun org-reverse-datetree-dates (&key decoded)
  "Return a list of date tree dates in the buffer.

Unless DECODED is non-nil, the returned date is an encoded time,
so it can be passed to other functions in `org-reverse-datetree'
package. The encoded time will be the midnight in the day."
  (org-with-wide-buffer
   (let ((level (org-reverse-datetree-num-levels))
         dates)
     (goto-char (point-min))
     (save-match-data
       (while (re-search-forward org-complex-heading-regexp nil t)
         (when (= (- (match-end 1) (match-beginning 1))
                  level)
           (when-let (decoded-time (org-reverse-datetree--date
                                    (match-string-no-properties 4)))
             (org-end-of-subtree)
             (push (if decoded
                       decoded-time
                     (org-reverse-datetree--encode-date decoded-time))
                   dates))))
       dates))))

(cl-defun org-reverse-datetree-guess-date (&key decoded)
  "Return the date of the current entry in the date tree, if any.

Note that this function may not work properly when
`org-odd-levels-only' is non-nil or the date heading is
unparsable with `parse-time-string'.

Unless DECODED is non-nil, the returned date is an encoded time,
so it can be passed to other functions in `org-reverse-datetree'
package. The encoded time will be the midnight in the day."
  (unless (org-before-first-heading-p)
    (let ((level (org-reverse-datetree-num-levels))
          (current-level (org-outline-level)))
      (when (and level
                 (>= current-level level))
        (org-with-wide-buffer
         (when (> current-level level)
           (org-up-heading-all (- current-level level)))
         (when-let (decoded-time (org-reverse-datetree--date))
           (if decoded
               decoded-time
             (org-reverse-datetree--encode-date decoded-time))))))))

(defun org-reverse-datetree-date-child-p ()
  "Return non-nil if the entry is a direct child of a date entry."
  (unless (org-before-first-heading-p)
    (when-let (level (org-reverse-datetree-num-levels))
      (when (= (org-outline-level)
               (1+ level))
        (save-excursion
          (org-up-heading-all 1)
          (and (org-reverse-datetree--date) t))))))

(defun org-reverse-datetree--date (&optional heading)
  "Return the date of the heading, if any.

This function parses the date of the heading. The date string
must contain year, month, and day of month, but the other fields
are optional.

You can optionally give an explicit HEADING as an argument.
Otherwise, it is taken from the current Org heading."
  (let ((decoded-time (ignore-errors
                        (parse-time-string
                         (or heading (org-get-heading t t t t))))))
    ;; `parse-time-string' can return a decoded time that contain no date
    ;; fields.
    (when (and (nth 3 decoded-time)
               (nth 4 decoded-time)
               (nth 5 decoded-time))
      decoded-time)))

(defun org-reverse-datetree--encode-date (decoded-time)
  "Return the encoded time of midnight on the date of DECODED-TIME."
  ;; It may be better to add the offset of the current time zone. In
  ;; that case, I would use `time-add' and `current-time-zone'.
  (org-reverse-datetree--encode-time
   (append '(0 0 0) (seq-drop decoded-time 3))))

(defun org-reverse-datetree-num-levels ()
  "Return the number of outline levels of datetree entries.

If the file does not contain a datetree configured, it returns
nil.

This uses a cached value whenever available, so it is faster than
calling `org-reverse-datetree--get-level-formats'."
  (if org-reverse-datetree-level-formats
      (length org-reverse-datetree-level-formats)
    (let ((levels (or org-reverse-datetree-num-levels
                      (setq org-reverse-datetree-num-levels
                            (length (org-reverse-datetree--get-level-formats t))))))
      ;; If the file contains no datetree, the cached value is set to zero,
      (unless (= 0 levels)
        levels))))

(provide 'org-reverse-datetree)
;;; org-reverse-datetree.el ends here
