;;; ob-dsq.el --- Babel functions for the `dsq` CLI tool by Multiprocess Labs -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/ob-dsq
;; Package-Version: 20220324.2029
;; Package-Commit: 55433631458dd57ae890b2665f8f15b2df2f71e8
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: data, tools

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Org-Babel support for evaluating queries in the `dsq` CLI tool by Multiprocess Labs.

;;; Code:

(require 'subr-x)
(require 'mule-util)

(require 'ob)
(require 'ob-sql)
(require 'org-src)
(require 'org-table)

(defvar org-babel-header-args:dsq
  '((:input . :any)
    (:header . :any)
    (:null-value . :any)
    (:false-value . :any))
  "Additional header arguments specific to evaluating a query.")

(defvar org-babel-default-header-args:dsq
  '((:header . "yes")
    (:null-value . nil)
    (:false-value . "false")
    (:results . "table"))
  "Default header arguments for evaluating a query.")

(defvar org-babel-dsq-pre-execute-hook nil
  "Hook for functions to be called on the query before it is executed.

The functions are expected to take the QUERY and Org babel PARAMS
as arguments and to return the updated query.")

(defvar org-babel-dsq-post-execute-hook nil
  "Hook for functions to be called on the result of the query.

The functions are run in a temporary buffer that contains the
query result.")

(defvar org-babel-dsq-command "dsq"
  "Name of the command to execute.")

(defvar org-babel-dsq-format-separator "%"
  "Separator to use when definining an :input header argument's data format.

Example: `:input employees%json` uses data from the `employee`
Org reference's output and treats it as JSON.")

(defvar org-babel-dsq-immediately-delete-temp-files t
  "If non-nil, delete temporary data files right after evaluating the query.

Otherwise, they'll be deleted when Emacs exits.")

(defvar org-babel-dsq-debug nil
  "If non-nil, print debug messages.")

(defun org-babel-expand-body:dsq (body params)
  "Expand the query in BODY using PARAMS."
  (org-babel-sql-expand-vars
   body (org-babel--get-vars params)))

(defun org-babel-execute:dsq (body params)
  "Execute the query in BODY using PARAMS."
  (let* ((params (org-babel-process-params params))
         (null-value-param (cdr (assq :null-value params)))
         (false-value-param (cdr (assq :false-value params)))
         (result-params (split-string (or (cdr (assq :results params)) "")))
         (input-params (org-babel-dsq--get-inputs params))
         (inputs (mapcar #'org-babel-dsq--process-input-param input-params)) ;; (path . (list of flags))
         (file-args (mapconcat #'org-babel-dsq--file-arg-from-input inputs " ")))

    (with-temp-buffer
      (let ((processed-body (run-hook-with-args-until-success 'org-babel-dsq-pre-execute-hook body params)))
        (when processed-body
          (setq body processed-body)))

      (let* ((body (org-babel-expand-body:dsq body params))
             (body (org-babel-dsq--escape-quotes body))
             (command (format "%s %s \"%s\"" org-babel-dsq-command file-args body)))
        (when org-babel-dsq-debug
          (message "[dsq] running command: %s" command))
        (let ((result (or (org-babel-eval command "") "[]")))
          (when org-babel-dsq-debug
            (message "[dsq] result (first 100 chars): %s" (truncate-string-to-width result 100)))
          (insert result)))

      (when org-babel-dsq-immediately-delete-temp-files
        (mapc #'org-babel-dsq--delete-if-temp-file inputs))

      (run-hooks 'org-babel-dsq-post-execute-hook)

      (org-babel-result-cond result-params
        (buffer-string)
        (goto-char (point-min))
        (org-babel-dsq--parsed-json-to-elisp-table
         (json-parse-buffer
          :array-type 'list
          :object-type 'plist
          :null-object null-value-param
          :false-object false-value-param)
         params)))))

(defun org-babel-dsq--parsed-json-to-elisp-table (parsed-json params)
  "Convert PARSED-JSON into an Org babel elisp data table using PARAMS."
  (let* ((colnames (org-babel-dsq--colnames-from-parsed-json parsed-json))
         (result-params (split-string (or (cdr (assq :results params)) "")))
         (header-p (equal "yes" (cdr (assq :header params))))
         (table-p (or (member "table" result-params) (member "vector" result-params)))
         (hlines-p (equal "yes" (cdr (assq :hlines params))))
         (rows (list 'head))) ;; temporary initial content for `nconc'; there must be a better way to do this.

    (mapc
     (lambda (row)
       (nconc rows (list (mapcar (lambda (colname) (plist-get row colname)) colnames)))
       (when (and table-p hlines-p) (nconc rows (list 'hline))))
     parsed-json)

    ;; remove trailing hline
    (when (and table-p hlines-p)
      (nbutlast rows))

    ;; pop 'head
    (pop rows)

    ;; add header
    (when header-p
      (when table-p (push 'hline rows))
      (push (mapcar (lambda (colname) (substring (symbol-name colname) 1)) colnames) rows))

    rows))

(defun org-babel-dsq--colnames-from-parsed-json (parsed-json)
  "Determine table column names (symbols) in PARSED-JSON."
  (let ((first-row (car parsed-json))
        colnames)
    (while (and (keywordp (car-safe first-row))
                (consp (cdr first-row))
                (push (car first-row) colnames)
                (setq first-row (cddr first-row))))
    (reverse colnames)))

(defun org-babel-dsq--delete-if-temp-file (input)
  "Delete INPUT file if it was created as a temporary file for query evaluation."
  (let ((file (car input))
        (flags (cdr input)))
    (when (member 'temp-file flags)
      (when org-babel-dsq-debug
        (message "[dsq] deleting temp file: %s" file))
      (delete-file file))))

(defun org-babel-dsq--get-inputs (params)
  "Extract a list of inputs from PARAMS."
  (let* ((inputs (cdr (assq :input params)))
         (inputs (if (stringp inputs) (split-string inputs " ") inputs))
         (inputs (if (listp inputs) inputs (list inputs))))
    inputs))

(defun org-babel-dsq--process-input-param (input-param)
  "Resolve INPUT-PARAM to (cons file flag)."
  (cond
   ((and (stringp input-param) (file-exists-p (expand-file-name input-param)))
    (cons input-param nil))
   ((or (stringp input-param) (symbolp input-param))
    (let* ((input-param (if (symbolp input-param) (symbol-name input-param) input-param))
           (reference (split-string input-param org-babel-dsq-format-separator)))
      (cons (org-babel-dsq--reference-to-temp-file (car reference) (cadr reference)) (list 'temp-file))))
   (t (error "Don't know how to handle input %s: file or reference expected" input-param))))

(defun org-babel-dsq--reference-to-temp-file (reference fmt)
  "Resolve Org REFERENCE and write it to a temporary FMT file."
  (let ((content (org-babel-ref-resolve reference)))
    (unless content
      (error "Resolving input reference %s yielded no content" reference))

    (when (listp content)
      (if (not (or (null fmt) (string= fmt "csv")))
          (error "Tabular/list data in input reference %s requires csv format, but %s requested" reference fmt)
        (setq fmt "csv")
        (setq content (orgtbl-to-csv content nil))))

    (when (and (null fmt) (stringp content))
      (setq fmt (org-babel-dsq--detect-format-from-content-fragment
                 (substring content 0 (min 1000 (length content))))))

    (when (null fmt)
      (error "Cannot defer format for input reference %s; use '%s:<format>'" reference reference))

    (let ((temp-file (org-babel-temp-file "dsq-" (concat "." fmt))))
      (with-temp-file temp-file
        (insert content))
      temp-file)))

(defun org-babel-dsq--detect-format-from-content-fragment (fragment)
  "Detect format of content FRAGMENT."
  (cond
   ((string-match "\\`\\(^[[:space:]]*\\(#.*\\)?\n\\)*[[:space:]]*[{\\[]" fragment) "json")
   ((string-match "\\`\\(^[[:space:]]*\n\\)*[^\n]*," fragment) "csv")))

(defun org-babel-dsq--file-arg-from-input (input)
  "Map INPUT to a file name suitable to use as an argument for `dsq`."
  (concat "\"" (expand-file-name (car input)) "\""))

(defun org-babel-dsq--escape-quotes (body)
  "Escape quotes in BODY.

Note that Emacs 28 introduces `string-replace'; however, I don't
want to depend on that version for just a single convenience
function."
  (let ((start 0))
    (while (setq start (string-match "\"" body start))
      (setq body (replace-match "\\\"" t t body))
      (setq start (+ 2 start))))
  body)

(add-to-list 'org-src-lang-modes '("dsq" . sql))

(provide 'ob-dsq)
;;; ob-dsq.el ends here
