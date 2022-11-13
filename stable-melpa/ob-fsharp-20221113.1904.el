;;; ob-fsharp.el --- Org-Babel F# -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2022  Jürgen Hötzel
;; Author: Jürgen Hötzel <juergen@archlinux.org>
;; Url: https://github.com/juergenhoetzel/ob-fsharp
;; Package-Version: 20221113.1904
;; Package-Commit: a5e893a88d47bd8ea01cf456331ce54910321b47
;; Version: 0.1
;; Package-Requires: ((emacs "25") (fsharp-mode "1.9.8") (seq "2.22"))
;; Keywords: literate programming, reproducible research

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:

;; Org-Babel support for evaluating F# source code.

;; For now lets only allow evaluation using the F# Interactive.

;;; Code:
(require 'ob-ocaml)			;Can reuse some OCaml functions

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("fsharp" . "fsx"))

(defvar org-babel-default-header-args:fsharp '())

(defvar ob-fsharp-eoe-indicator "\"ob-fsharp-eoe\";;")
(defvar ob-fsharp-eoe-output "ob-fsharp-eoe")

(defun org-babel-execute:fsharp (body params)
  "Execute BODY according to PARAMS with Babel."
  (let* ((full-body (org-babel-expand-body:generic
		     body params
		     (org-babel-variable-assignments:fsharp params)))
         (session (org-babel-prep-session:fsharp
		   (cdr (assq :session params)) params))
         (raw (org-babel-comint-with-output
		  (session ob-fsharp-eoe-output nil full-body)
		(insert
		 (concat
		  (org-babel-chomp full-body) ";;\n"
		  ob-fsharp-eoe-indicator))
		(comint-send-input)))
	 (clean
	  (nth 1 (seq-drop-while (lambda (line)
				   (not (string-match (regexp-quote ob-fsharp-eoe-output) line)))
				 (mapcar #'org-trim (reverse raw)))))
	 (raw (org-trim clean))
	 (result-params (cdr (assq :result-params params))))
    ;; ob failes to remove body lines, even when using REMOVE-ECHO
    ;; Because output is interleaved wich echoed prompt
    (when (string-prefix-p body raw)
      (setq raw (substring raw ( + (length ";;\n") (length body)))))
    (string-match
     "\\(\\(.*\n\\)*\\)[^:\n]+ : \\([^=\n]+\\) =\\(\n\\| \\)\\(.+\\)$"
     raw)
    (let ((output (match-string 1 raw))
	  (type (match-string 3 raw))
	  (value (match-string 5 raw)))
      (org-babel-reassemble-table
       (org-babel-result-cond result-params
	 (cond
	  ((member "verbatim" result-params) raw)
	  ((member "output" result-params) output)
	  (t raw))
	 (if (and value type)
	     (org-babel-ocaml-parse-output value type)
	   raw))
       (org-babel-pick-name
	(cdr (assq :colname-names params)) (cdr (assq :colnames params)))
       (org-babel-pick-name
	(cdr (assq :rowname-names params)) (cdr (assq :rownames params)))))))

(defvar inferior-fsharp-buffer-name)

(defun org-babel-prep-session:fsharp (session _params)
  "Prepare SESSION according to the header arguments in PARAMS."
  (require 'inf-fsharp-mode)
  (let ((inferior-fsharp-buffer-name (if (and (not (string= session "none"))
					      (not (string= session "default"))
					      (stringp session))
					 session
				       inferior-fsharp-buffer-name)))
    (save-window-excursion (fsharp-run-process-if-needed inferior-fsharp-program))
    (get-buffer inferior-fsharp-buffer-name)))

(defun org-babel-variable-assignments:fsharp (params)
  "Return statements assigning the variables in PARAMS."
  (org-babel-variable-assignments:ocaml params))

(provide 'ob-fsharp)
;;; ob-fsharp.el ends here
