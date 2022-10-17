;;; ob-raku.el --- Provides raku support for org-babel

;; Copyright (C) 2020 Tim Van den Langenbergh,
;;               2022 Kay Rhodes (a.k.a masukomi)

;; Author: Tim Van den Langenbergh https://github.com/tmtvl
;; Keywords: literate programming, reproducible research, languages
;; Package-Version: 20221013.1938
;; Package-Commit: 21aa77a0ca70b7bef0ecf7d4d9c5272d71f0210c
;; Homepage: https://github.com/masukomi/ob-raku
;; Package-Requires: ((emacs "24.1"))
;;
;;
;; Version: 1.0.0
;; News: 1.0.1 --- minor correction to line that became uncommented
;; 	 1.0.0 --- Applied package-lint suggestions. Switched to Semantic Versioning.
;;       0.05 --- Added initial support for parentheses and commas in strings
;; in lists without breaking the lists on return.
;;       0.04 --- Added square brackets to list splitting, so as to split
;; embedded arrays as well as lists.
;;       0.03 --- Removed the double execution, simplified the formatting of
;; the Raku output, fixed hline support.
;;       0.02 --- Added support for tables, removed unneeded require
;; statements, error when trying to use a session.
;;       0.01 --- Initial release. Accept inputs, support for output and value
;; results.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;;; Commentary:

;; Bindings for org-babel support for Raku (née Perl6).

;;; Requirements:

;; Requires a working Raku interpreter to be installed.
;; (Optionally) requires Perl6 mode to be installed.

;;; Code:

(require 'ob)
(require 'ob-eval)
(require 'ob-ref)

(add-to-list 'org-babel-tangle-lang-exts '("raku" . "raku"))

(defvar org-babel-default-header-args:raku '())

(defvar ob-raku-command "raku"
  "Command to run Raku.")

(defun org-babel-expand-body:raku (body params &optional processed-params)
  "Expand BODY according to the header arguments specified in PARAMS.
Use the PROCESSED-PARAMS if defined."
  (let ((vars
         (delq nil
               (mapcar
                (lambda (pair)
                  (when (eq (car pair) :var) (cdr pair)))
                (or processed-params (org-babel-process-params params))))))
    (concat
     (mapconcat
      (lambda (pair)
        (format
         "my %s%s = %s;"
         (if (listp (cdr pair))
             "@"
           "$")
         (car pair)
         (ob-raku-var-to-raku (cdr pair))))
      vars
      "\n")
     "\n" body "\n")))

(defun org-babel-execute:raku (body params)
  "Execute the BODY of Raku code processing it according to PARAMS."
  (let* ((processed-params (org-babel-process-params params))
         (session (cdr (assoc :session params)))
         (result-type (cdr (assoc :result-type params)))
         (result-params (cdr (assoc :result-params params)))
         (full-body (org-babel-expand-body:raku body params processed-params)))
    (org-babel-reassemble-table
     (ob-raku-evaluate full-body session result-type)
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))

(defun org-babel-prep-session:raku (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "Sessions are not supported for Raku"))

(defun ob-raku-var-to-raku (var)
  "Convert an elisp value VAR to a Raku definition of the same value."
  (if (listp var)
      (concat
       "("
       (mapconcat
        #'ob-raku-var-to-raku
        var
        ", ")
       ")")
    (if (equal var 'hline)
        "\"HLINE\""
      (format "%S" var))))

(defun ob-raku-escape-nested-list-delimiters (list)
  "Escapes any commas or parentheses found in strings contained in the given LIST."
  (let ((in-string nil))
    (mapconcat
           (lambda (string)
             (cond
              ((string= string "\"")
               (setq in-string (not in-string))
               string)
              ((and
                in-string
                (or
                 (string= string "(")
                 (string= string ")")
                 (string= string "[")
                 (string= string "]")
                 (string= string ",")))
               (concat "\\" string))
              (t string)))
           (split-string list "" t)
           "")))

(defun ob-raku-unescape-parens-and-commas (string)
  "Unescapes parentheses and commas in STRING."
  ;;(replace-regexp-in-string "\\\\\([][(),]\)" "\1" string)
  ;; This doesn't work.
  (let ((index (string-match "\\\\[][(),]" string)))
    (if index
        (concat
         (substring string 0 index)
         (ob-raku-unescape-parens-and-commas
          (substring string (+ index 1))))
      string)))

(defun ob-raku-split-list (list)
  "Split LIST on a comma or parentheses, ignoring those in a string."
  (mapcar
   (lambda (pairstring)
     (mapcar
      (lambda (string)
        (ob-raku-unescape-parens-and-commas string))
      (split-string pairstring "[^\\], " t)))
   (split-string (ob-raku-escape-nested-list-delimiters (substring list
2 -2))
                 "[^\\][][()]"
                 t)))

(defun ob-raku-sanitize-table (table)
  "Recursively sanitize the values in the given TABLE."
  (if (listp table)
      (let ((sanitized-table (mapcar #'ob-raku-sanitize-table table)))
        (if (and (stringp (car sanitized-table))
                 (string= (car sanitized-table) "HLINE"))
            'hline
          sanitized-table))
    (org-babel-script-escape table)))

(defun ob-raku-table-or-string (results)
  "If RESULTS look like a table, then convert them into an elisp table.
Otherwise return RESULTS as a string."
  (cond
   ((or (string-prefix-p "$[" results)
        (string-prefix-p "$(" results))
    (ob-raku-sanitize-table
     (ob-raku-split-list results)))
   ((string-prefix-p "{" results)
    (ob-raku-sanitize-table
     (mapcar
      (lambda (pairstring)
        (split-string pairstring " => " t))
      (split-string
       (substring results 1 -2)
       ", "
       t))))
   (t (org-babel-script-escape results))))

(defun ob-raku-initiate-session (&optional session)
  "If there is not a current inferior-process-buffer in SESSION then create.
Return the initialized SESSION."
  (unless (string= session "none")
    (if session (error "Sessions are not supported for Raku"))))

(defun ob-raku-evaluate (body &optional session result-type)
  "Evaluate the BODY with Raku.
If SESSION is not provided, evaluate in an external process.
If RESULT-TYPE is not provided, assume \"value\"."
  (ob-raku-table-or-string
   (if (and session (not (string= session
"none")))
    (ob-raku-evaluate-session session body result-type)
    (ob-raku-evaluate-external body result-type))))

(defconst ob-raku-wrapper
  "sub _MAIN {
%s
}

sub _FORMATTER ($result) {
return $result.gist if $result.WHAT ~~ Hash;
$result.raku
}

\"%s\".IO.spurt(\"{ _FORMATTER(_MAIN()) }\\n\");"
  "Wrapper for grabbing the final value from Raku code.")

(defun ob-raku-evaluate-external (body &optional result-type)
  "Evaluate the BODY with an external Raku process.
If RESULT-TYPE is not provided, assume \"value\"."
  (if (and result-type (string= result-type "output"))
      (org-babel-eval ob-raku-command body)
    (let ((temp-file (org-babel-temp-file "raku-" ".raku")))
      (org-babel-eval
       ob-raku-command
       (format
        ob-raku-wrapper
        body
        (org-babel-process-file-name temp-file 'noquote)))
      (org-babel-eval-read-file temp-file))))

(defun ob-raku-evaluate-session (session body &optional result-type)
  "Evaluate the BODY with the Raku process running in SESSION.
If RESULT-TYPE is not provided, assume \"value\"."
  (error "Sessions are not supported for Raku"))

(provide 'ob-raku)
;;; ob-raku.el ends here
