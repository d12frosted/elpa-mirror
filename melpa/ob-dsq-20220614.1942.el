;;; ob-dsq.el --- Babel functions for the `dsq` CLI tool by Multiprocess Labs -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/ob-dsq
;; Package-Version: 20220614.1942
;; Package-Commit: 45a1e4a24bc89a23912478479b9afb162dd768a3
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

(require 'mule-util)
(require 'seq)
(require 'subr-x)

(require 'ob)
(require 'ob-sql)
(require 'org-src)
(require 'org-table)

(defvar org-babel-header-args:dsq
  '((:input . :any)
    (:header . :any)
    (:null-value . :any)
    (:false-value . :any)
    (:cache . :any)
    (:convert-numbers . :any))
  "Additional header arguments specific to evaluating a query.")

(defvar org-babel-default-header-args:dsq
  '((:header . "yes")
    (:null-value . nil)
    (:false-value . "false")
    (:cache . nil)
    (:convert-numbers . "yes")
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
  "If non-nil, delete temporary Org data files after running the query.

Otherwise, they'll be deleted when Emacs exits.")

(defvar org-babel-dsq-debug nil
  "If non-nil, print debug messages.")

(defvar org-babel-dsq-preprocess-vars-functions
  '(org-babel-dsq-preprocess-vars)
  "List of functions to call to preprocess vars before expansion of the body.

Each function is expected to take a list of vars as an argument,
and to return a copy of the vars that were further preprocessed
for expansion of the body.")

(defun org-babel-expand-body:dsq (body params)
  "Expand the query in BODY using PARAMS."
  (let* ((vars
          (org-babel--get-vars params))
         (preprocessed-vars
          (seq-reduce
           (lambda (vars f) (funcall f vars))
           org-babel-dsq-preprocess-vars-functions
           vars)))
    (when org-babel-dsq-debug
      (message "[dsq] preprocessed vars: %S -> %S" vars preprocessed-vars))
    (org-babel-sql-expand-vars body preprocessed-vars)))

(defun org-babel-dsq-preprocess-vars (vars)
  "Preprocess VARS before expansion of the body."
  (mapcar #'org-babel-dsq--preprocess-var vars))

(defun org-babel-dsq--preprocess-var (var)
  "Preprocess a single VAR before expansion of the body."
  (let ((var-value (cdr var)))
    (cons
     (car var)
     (if (listp var-value)
         (string-join
          (mapcar
           (lambda (it)
             (org-babel-dsq--var-value-as-joinable-string
              (org-babel-dsq--preprocess-var-value it)))
           var-value)
          ",")
       (org-babel-dsq--preprocess-var-value var-value)))))

(defun org-babel-dsq--preprocess-var-value (value)
  "Preprocess a single var's VALUE before expansion of the body."
  (cond
   ((stringp value) (string-trim value)) ;; trim trailing newlines in source block results
   ((numberp value) value)
   ((listp value) (org-babel-dsq--preprocess-var-value (car value)))
   (t (org-babel-dsq--preprocess-var-value (format "%S" value)))))

(defun org-babel-dsq--var-value-as-joinable-string (value)
  "Format VALUE to be joined into a list with other variable values."
  (if (stringp value)
      (if (and (string-prefix-p "'" value) (string-suffix-p "'" value))
          value ;; quoted string, nothing to do
        (format "'%s'" value)) ;; quote string
    (format "%s" value)))

(defun org-babel-execute:dsq (body params)
  "Execute the query in BODY using PARAMS."
  (let* ((params (org-babel-process-params params))
         (null-value-param (cdr (assq :null-value params)))
         (false-value-param (cdr (assq :false-value params)))
         (cache-param (cdr (assq :cache params)))
         (convert-numbers-param (cdr (assq :convert-numbers params)))
         (result-params (split-string (or (cdr (assq :results params)) "")))
         (input-params (org-babel-dsq--get-inputs params))
         (inputs (mapcar #'org-babel-dsq--process-input-param input-params)) ;; (path . (list of file flags))
         (flags nil)
         (dsq-version (org-babel-dsq--dsq-version)))

    (when (equal "yes" cache-param)
      (if (org-babel-dsq--dsq-version< dsq-version "0.15.0")
          (message ":cache requires dsq version \"0.15.0\" or higher; found \"%s\"" dsq-version)
        (push "--cache" flags)))

    (when (equal "yes" convert-numbers-param)
      (if (org-babel-dsq--dsq-version< dsq-version "0.19.0")
          (message ":convert-numbers requires dsq version \"0.19.0\" or higher; found \"%s\"" dsq-version)
        (push "--convert-numbers" flags)))

    (with-temp-buffer
      (let ((processed-body (run-hook-with-args-until-success 'org-babel-dsq-pre-execute-hook body params)))
        (when processed-body
          (setq body processed-body)))

      (let* ((flags (string-join flags " "))
             (file-args (mapconcat #'org-babel-dsq--file-arg-from-input inputs " "))
             (body (org-babel-expand-body:dsq body params)) ;; expand body
             (body (org-babel-dsq--string-replace "\"" "\\\"" body)) ;; escape quotes in body
             (body (concat "\"" body "\"")) ;; quote body
             (command (string-join (list org-babel-dsq-command flags file-args body) " ")))
        (when org-babel-dsq-debug
          (message "[dsq] running command: %s" command))
        (let ((result (or (org-babel-eval command "") "[]")))
          (when org-babel-dsq-debug
            (message "[dsq] result (first 100 chars): %s" (string-trim (truncate-string-to-width result 100))))
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
   ((listp input-param)
    (cons (org-babel-dsq--write-temp-file (orgtbl-to-csv input-param nil) "csv") (list 'temp-file)))
   (t (error "Don't know how to handle input %s: file or reference expected" input-param))))

(defun org-babel-dsq--reference-to-temp-file (reference fmt)
  "Resolve Org REFERENCE and write it to a temporary FMT file."
  (let ((data (org-babel-ref-resolve reference)))
    (unless data
      (error "Resolving input reference %s yielded no data" reference))

    (when (listp data)
      (if (not (or (null fmt) (string= fmt "csv")))
          (error "Tabular/list data in input reference %s requires csv format, but %s requested" reference fmt)
        (setq fmt "csv")
        (setq data (orgtbl-to-csv data nil))))

    (when (and (null fmt) (stringp data))
      (setq fmt (org-babel-dsq--detect-format-from-data-fragment
                 (substring data 0 (min 1000 (length data))))))

    (when (null fmt)
      (error "Cannot defer format for input reference %s; use '%s:<format>'" reference reference))

    (org-babel-dsq--write-temp-file data fmt)))

(defun org-babel-dsq--write-temp-file (data fmt)
  "Write DATA to a temporary FMT file."
  (let ((temp-file (org-babel-temp-file "dsq-" (concat "." fmt))))
    (with-temp-file temp-file
      (insert data))
    temp-file))

(defun org-babel-dsq--detect-format-from-data-fragment (fragment)
  "Detect format of data FRAGMENT."
  (cond
   ((string-match "\\`\\(^[[:space:]]*\\(#.*\\)?\n\\)*[[:space:]]*[{\\[]" fragment) "json")
   ((string-match "\\`\\(^[[:space:]]*\n\\)*[^\n]*," fragment) "csv")))

(defun org-babel-dsq--file-arg-from-input (input)
  "Map INPUT to a file name suitable to use as an argument for `dsq`."
  (concat "\"" (expand-file-name (car input)) "\""))

(defun org-babel-dsq--string-replace (from to in)
  "Replace FROM with TO in IN each time it occurs.

Note that Emacs 28 introduces `string-replace'; however, I don't
want to depend on that version for just a single convenience
function, so am back-porting it here."
  (let ((start 0))
    (while (setq start (string-match from in start))
      (setq in (replace-match to t t in))
      (setq start (+ (length to) start))))
  in)

(defun org-babel-dsq--dsq-version ()
  "Retrieve version of `dsq`."
  (or
  (when-let ((dsq-version-string (shell-command-to-string (format "%s --version" org-babel-dsq-command))))
    (and (string-match "^dsq \\(.*\\)$" dsq-version-string)
         (match-string 1 dsq-version-string)))
  (error "Cannot determine version of `dsq`")))

(defun org-babel-dsq--dsq-version< (required-version dsq-version)
  "Return t if REQUIRED-VERSION is lower (older) than DSQ-VERSION, nil otherwise."
  (or
   (string= dsq-version "latest")
   (version< required-version dsq-version)))

(add-to-list 'org-src-lang-modes '("dsq" . sql))

(provide 'ob-dsq)
;;; ob-dsq.el ends here
