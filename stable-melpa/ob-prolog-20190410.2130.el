;;; ob-prolog.el --- org-babel functions for prolog evaluation.

;; Copyright (C) Bjarte Johansen

;; Author: Bjarte Johansen
;; Keywords: literate programming, reproducible research
;; Package-Version: 20190410.2130
;; Package-Commit: 331899cfe345c934026c70b78352d320f7d8e239
;; URL: https://github.com/ljos/ob-prolog
;; Version: 1.0.2

;; This file is NOT part of GNU Emacs.

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
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Org-babel support for prolog.
;;
;; To activate ob-prolog add the following to your init.el file:
;;
;;  (add-to-list 'load-path "/path/to/ob-prolog-dir")
;;  (org-babel-do-load-languages
;;    'org-babel-load-languages
;;    '((prolog . t)))
;;
;; It is unnecessary to add the directory to the load path if you
;; install using the package manager.
;;
;; In addition to the normal header arguments ob-prolog also supports
;; the :goal argument.  :goal is the goal that prolog will run when
;; executing the source block.  Prolog needs a goal to know what it is
;; going to execute.
;;

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 'prolog)


(add-to-list 'org-babel-tangle-lang-exts '("prolog" . "pl"))

(defvar org-babel-prolog-command  (prolog-find-value-by-system prolog-program-name)
  "Name of the prolog executable command.")

(defconst org-babel-header-args:prolog
  '((:goal . :any))
  "Prolog-specific header arguments.")


(defvar org-babel-default-header-args:prolog
  `((:goal . nil)))

(defun org-babel-prolog--elisp-to-pl (value)
  "Convert the Emacs Lisp VALUE to equivalent Prolog."
  (cond ((stringp value)
         (format "'%s'"
                 (replace-regexp-in-string
                  "'" "\\'" value)))
        ((listp value)
         (format "[%s]"
		 (mapconcat #'org-babel-prolog--elisp-to-pl
			    value
			    ", ")))
        (t (prin1-to-string value))))

(defun org-babel-prolog--variable-assignment (pair)
  "Return a string of a recorda/2 assertion of (cdr PAIR) under (car PAIR).

The Emacs Lisp value of the car of PAIR is used as the Key argument to
recorda/2 without modification.  The cdr of PAIR is converted to
equivalent Prolog before being provided as the Term argument to
recorda/2."
  (format ":- recorda('%s', %s)."
          (car pair)
          (org-babel-prolog--elisp-to-pl (cdr pair))))

(defun org-babel-variable-assignments:prolog (params)
  "Return the babel variable assignments in PARAMS.

PARAMS is a quasi-alist of header args, which may contain
multiple entries for the key `:var'.  This function returns a
list of the cdr of all the `:var' entries."
  (let (vars)
    (dolist (param params vars)
      (when (eq :var (car param))
        (let ((var (org-babel-prolog--variable-assignment (cdr param))))
          (setq vars (cons var vars)))))))

(defun org-babel-prolog--parse-goal (goal)
  "Evaluate the inline Emacs Lisp in GOAL.

Example:
      append(=(+ 2 3), =(quote a), B)
   => append(5, a, B)"
  (when goal
    (with-temp-buffer
      (insert goal)
      (while (search-backward "=" nil t)
	(delete-char 1 t)
	(let ((value (eval
                      (read
                       (thing-at-point 'sexp)))))
	  (kill-sexp)
	  (insert (format "%S" value))))
      (buffer-string))))

(defun org-babel-execute:prolog (body params)
  "Execute the Prolog in BODY according to the block's header PARAMS.

This function is called by `org-babel-execute-src-block.'"
  (message "executing Prolog source code block")
  (let* ((result-params (cdr (assq :result-params params)))
         (session (cdr (assq :session params)))
         (goal (org-babel-prolog--parse-goal
                (cdr (assq :goal params))))
         (vars (org-babel-variable-assignments:prolog params))
         (full-body (org-babel-expand-body:generic body params vars))
	 (results (if (string= "none" session)
		      (org-babel-prolog-evaluate-external-process
		       goal full-body)
		    (org-babel-prolog-evaluate-session
		     session goal full-body))))
    (unless (string= "" results)
      (org-babel-reassemble-table
       (org-babel-result-cond result-params
	 results
	 (let ((tmp (org-babel-temp-file "prolog-results-")))
	   (with-temp-file tmp (insert results))
	   (org-babel-import-elisp-from-file tmp)))
       (org-babel-pick-name (cdr (assq :colname-names params))
			    (cdr (assq :colnames params)))
       (org-babel-pick-name (cdr (assq :rowname-names params))
			    (cdr (assq :rownames params)))))))

(defun org-babel-prep-session:prolog (session params)
  (let ((var-lines (org-babel-variable-assignments:prolog params)))
    (org-babel-prolog--session-load-clauses session var-lines)
    session))

(defun org-babel-load-session:prolog (session body params)
  "Load the BODY into the SESSION given the PARAMS."
  (let* ((params (org-babel-process-params params))
         (goal (org-babel-prolog--parse-goal (cdr (assq :goal params))))
         (session (org-babel-prolog-initiate-session session)))
    (org-babel-prep-session:prolog session params)
    (org-babel-prolog-evaluate-session session goal body)
    (with-current-buffer session
      (goto-char (point-max)))
    session))

(defun org-babel-prolog-evaluate-external-process (goal body)
  "Evaluate the GOAL given the BODY in an external Prolog process.

If no GOAL is given, the GOAL is replaced with HALT.  This results in
running just the body through the Prolog process."
  (let* ((tmp-file (org-babel-temp-file "prolog-"))
         (command (format "%s --quiet -l %s -g \"%s\" -t 'halt'"
			  org-babel-prolog-command
			  tmp-file
			  (replace-regexp-in-string
			   "\"" "\\\"" (or goal "halt")))))
    (with-temp-file tmp-file
	(insert (org-babel-chomp body)))
    (or (org-babel-eval command "") "")))

(defun org-babel-prolog--session-load-clauses (session clauses)
  (with-current-buffer session
    (setq comint-prompt-regexp "^|: *"))
  (org-babel-comint-input-command session "consult(user).\n")
  (org-babel-comint-with-output (session "\n")
    (setq comint-prompt-regexp (prolog-prompt-regexp))
    (dolist (line clauses)
      (insert line)
      (comint-send-input nil t)
      (accept-process-output
       (get-buffer-process session)))
    (comint-send-eof)))

(defun org-babel-prolog-evaluate-session (session goal body)
  "In SESSION, evaluate GOAL given the BODY of the Prolog block.

Create SESSION if it does not already exist."
  (let* ((session (org-babel-prolog-initiate-session session))
         (body (split-string (org-babel-trim body) "\n")))
    (with-temp-buffer
      (apply #'insert (org-babel-prolog--session-load-clauses session body))
      (if (save-excursion
            (search-backward "ERROR: " nil t))
          (progn
            (save-excursion
              (while (search-backward "|: " nil t)
                (replace-match "" nil t)))
            (search-backward "true." nil t)
            (kill-whole-line)
            (org-babel-eval-error-notify -1 (buffer-string))
            (buffer-string))
        (when goal
          (kill-region (point-min) (point-max))
          (apply #'insert
                 (org-babel-comint-with-output (session "")
                   (insert (concat goal ", !."))
                   (comint-send-input nil t))))
        (if (not (save-excursion
                   (search-backward "ERROR: " nil t)))
            (let ((delete-trailing-lines t))
              (delete-trailing-whitespace (point-min))
              (org-babel-trim (buffer-string)))
          ;;(search-backward "?-" nil t)
          ;;(kill-whole-line)
          (org-babel-eval-error-notify -1 (buffer-string))
          (org-babel-trim (buffer-string)))))))

(defun org-babel-prolog--answer-correction (string)
  "If STRING is Prolog's \"Correct to:\" prompt, send a refusal."
  (when (string-match-p "Correct to: \".*\"\\?" string)
    (comint-send-input nil t)))

(defun org-babel-prolog--exit-debug (string)
  "If STRING indicates an exception, continue Prolog execution in no debug mode."
  (when (string-match-p "\\(.\\|\n\\)*Exception.* \\? $" string)
    (comint-send-input nil t)))

(defun org-babel-prolog-initiate-session (&optional session)
  "Return SESSION with a current inferior-process-buffer.

Initialize SESSION if it has not already been initialized."
  (unless  (equal "none" session)
    (let ((session (get-buffer-create (or session "*prolog*"))))
      (unless (comint-check-proc session)
        (with-current-buffer session
          (kill-region (point-min) (point-max))
          (prolog-inferior-mode)
          (apply #'make-comint-in-buffer
                 "prolog"
                 (current-buffer)
                 org-babel-prolog-command
                 nil
                 (cons "-q" (prolog-program-switches)))
          (add-hook 'comint-output-filter-functions
                    #'org-babel-prolog--answer-correction nil t)
          (add-hook 'comint-output-filter-functions
                    #'org-babel-prolog--exit-debug nil t)
          (add-hook 'comint-preoutput-filter-functions
                    #'ansi-color-apply nil t)
          (while (progn
                   (goto-char comint-last-input-end)
                   (not (save-excursion
                          (re-search-forward comint-prompt-regexp nil t))))
            (accept-process-output
             (get-buffer-process session)))))
      session)))

(provide 'ob-prolog)
;;; ob-prolog.el ends here
