;;; ob-julia-vterm.el --- Babel Functions for Julia in VTerm -*- lexical-binding: t -*-

;; Copyright (C) 2020 Shigeaki Nishina

;; Author: Shigeaki Nishina
;; Maintainer: Shigeaki Nishina
;; Created: October 31, 2020
;; URL: https://github.com/shg/ob-julia-vterm.el
;; Package-Version: 20220511.116
;; Package-Commit: 11f857a9eb7c003906b5b524064b8f42842b99b1
;; Package-Requires: ((emacs "26.1") (julia-vterm "0.16"))
;; Version: 0.2a
;; Keywords: julia, org, outlines, literate programming, reproducible research

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses/.

;;; Commentary:

;; Org-Babel support for Julia source code block using julia-vterm.

;;; Requirements:

;; This package uses julia-vterm to run Julia code.
;;
;; - https://github.com/shg/julia-vterm.el
;;
;; See https://github.com/shg/ob-julia-vterm.el for installation
;; instructions.

;;; Code:

(require 'ob)
(require 'queue)
(require 'filenotify)
(require 'julia-vterm)

(defun org-babel-julia-vterm--wrap-body (session body)
  "Make Julia code that execute-s BODY and obtains the results, depending on SESSION."
  (concat
   (if session "" "let\n")
   body
   (if session "" "\nend\n")))

(defun org-babel-julia-vterm--make-str-to-run (uuid result-type src-file out-file)
  "Make Julia code that execute-s the code in SRC-FILE depending on RESULT-TYPE.
The results are saved in OUT-FILE.  UUID is a unique id assigned
to the evaluation."
  (format
   (pcase result-type
     ('output "\
#OB-JULIA-VTERM_BEGIN %s
using Logging: Logging; let
    out_file = \"%s\"
    open(out_file, \"w\") do io
        logger = Logging.ConsoleLogger(io)
        redirect_stdout(io) do
            try
                include(\"%s\")
            catch e
                Logging.with_logger(logger) do
                    @error e
                end
            end
        end
    end
    result = open(io -> println(read(io, String)), out_file)
    if result == nothing
        open(out_file, \"a\") do io
            print(io, \"\n\")
        end
    else
        result
    end
end #OB-JULIA-VTERM_END\n")
     ('value "\
#OB-JULIA-VTERM_BEGIN %s
using Logging: Logging; open(\"%s\", \"w\") do io
    logger = Logging.ConsoleLogger(io)
    try
        result = include(\"%s\")
        if result == \"\"
            result = \"\n\"
        end
        print(io, result)
        result
    catch e
        Logging.with_logger(logger) do
            @error e
        end
        e
    end
end #OB-JULIA-VTERM_END\n"))
   (substring uuid 0 8) out-file src-file))

(defun org-babel-execute:julia-vterm (body params)
  "Execute a block of Julia code with Babel.
This function is called by `org-babel-execute-src-block'.
BODY is the contents and PARAMS are header arguments of the code block."
  (let* ((session-name (cdr (assq :session params)))
	 (session (pcase session-name ('nil "main") ("none" nil) (_ session-name)))
	 (var-lines (org-babel-variable-assignments:julia-vterm params))
	 (result-params (cdr (assq :result-params params))))
    (with-current-buffer (julia-vterm-repl-buffer session)
      (add-hook 'julia-vterm-repl-filter-functions #'org-babel-julia-vterm--output-filter))
    (org-babel-julia-vterm-evaluate (current-buffer)
				    session
				    (org-babel-expand-body:generic body params var-lines)
				    params)))

(defun org-babel-variable-assignments:julia-vterm (params)
  "Return list of Julia statements assigning variables based on variable-value pairs in PARAMS."
  (mapcar
   (lambda (pair)
     (format "%s = %s"
	     (car pair) (org-babel-julia-vterm--value-to-julia (cdr pair))))
   (org-babel--get-vars params)))

(defun org-babel-julia-vterm--escape-string (str)
  "Escape special characters in STR for Julia variable assignments."
  (let* ((str (replace-regexp-in-string "\"" "\\\\\"" str)))
    str))

(defun org-babel-julia-vterm--value-to-julia (value)
  "Convert an emacs-lisp VALUE to a string of julia code for the value."
  (cond
   ((listp value)
    (format "\"%s\"" value))
   ((numberp value) value)
   ((stringp value) (or (org-babel--string-to-number value)
			(concat "\"" (org-babel-julia-vterm--escape-string value) "\"")))
   ((symbolp value) (org-babel-julia-vterm--escape-string (symbol-name value)))
   (t value)))

(defun org-babel-julia-vterm--check-long-line (str)
  "Return t if STR is too long for stable output for org-babel result."
  (catch 'loop
    (dolist (line (split-string str "\n"))
      (if (> (length line) 12000)
	  (throw 'loop t)))))

(defvar-local org-babel-julia-vterm--evaluation-queue nil)
(defvar-local org-babel-julia-vterm--evaluation-watches nil)

(defun org-babel-julia-vterm--add-evaluation-to-evaluation-queue (session evaluation)
  "Add an EVALUATION of a source block to SESSION's evaluation queue."
  (with-current-buffer (julia-vterm-repl-buffer session)
    (if (not (queue-p org-babel-julia-vterm--evaluation-queue))
	(setq org-babel-julia-vterm--evaluation-queue (queue-create)))
    (queue-append org-babel-julia-vterm--evaluation-queue evaluation)))

(defun org-babel-julia-vterm--evaluation-completed-callback-func (session)
  "Return a callback function to be called when the first evaluation for SESSION is completed."
  (lambda (event)
    (with-current-buffer (julia-vterm-repl-buffer session)
      (if (and (queue-p org-babel-julia-vterm--evaluation-queue)
	       (> (queue-length org-babel-julia-vterm--evaluation-queue) 0))
	  (let-alist (queue-first org-babel-julia-vterm--evaluation-queue)
	    (with-current-buffer .buf
	      (save-excursion
		(goto-char .src-block-begin)
		(if (and (not (equal .src-block-begin .src-block-end))
			 (or (eq (org-element-type (org-element-context)) 'src-block)
			     (eq (org-element-type (org-element-context)) 'inline-src-block)))
		    (let ((bs (with-temp-buffer
				(insert-file-contents .out-file)
				(buffer-string)))
			  (result-params (cdr (assq :result-params .params))))
		      (cond ((member "file" result-params)
			     (org-redisplay-inline-images))
			    ((not (member "none" result-params))
			     (org-babel-insert-result
			      (if (org-babel-julia-vterm--check-long-line bs)
				  "Output suppressed (line too long)"
				(org-babel-result-cond result-params
				  bs
				  (org-babel-reassemble-table
				   bs
				   (org-babel-pick-name (cdr (assq :colname-names .params))
							(cdr (assq :colnames .params)))
				   (org-babel-pick-name (cdr (assq :rowname-names .params))
							(cdr (assq :rownames .params))))))
			      result-params
			      (org-babel-get-src-block-info t))))))))
	    (queue-dequeue org-babel-julia-vterm--evaluation-queue)
	    (setq org-babel-julia-vterm--evaluation-watches
		  (delete (assoc .uuid org-babel-julia-vterm--evaluation-watches)
			  org-babel-julia-vterm--evaluation-watches))
	    (org-babel-julia-vterm--process-evaluation-queue .session t))))))

(defun org-babel-julia-vterm--clear-evaluation-queue (session)
  "Clear the evaluation queue and watches for SESSION."
  (with-current-buffer (julia-vterm-repl-buffer session)
    (if (queue-p org-babel-julia-vterm--evaluation-queue)
	(queue-clear org-babel-julia-vterm--evaluation-queue))
    (setq org-babel-julia-vterm--evaluation-watches '())))

(defvar-local org-babel-julia-vterm--output-suppress-state nil)

(defun org-babel-julia-vterm--output-filter (str)
  "Remove the pasted julia code from STR."
  (let ((begin (string-match "#OB-JULIA-VTERM_BEGIN" str))
	(end (string-match "#OB-JULIA-VTERM_END" str))
	(state org-babel-julia-vterm--output-suppress-state))
    (if begin (setq org-babel-julia-vterm--output-suppress-state t))
    (if end (setq org-babel-julia-vterm--output-suppress-state nil))
    (let* ((str (replace-regexp-in-string
		 "#OB-JULIA-VTERM_BEGIN \\([0-9a-z]*\\)\\(.*?\n\\)*.*" "Executing... \\1" str))
	   (str (replace-regexp-in-string
		 "\\(.*?\n\\)*.*#OB-JULIA-VTERM_END" "" str)))
      (if (or begin end)
	  str
	(if state "" str)))))

(defun org-babel-julia-vterm--process-one-evaluation (session)
  "Execute the first evaluation in SESSION's queue synchronously.
Return the result."
  (with-current-buffer (julia-vterm-repl-buffer session)
    (if (not (eq (julia-vterm-repl-buffer-status) :julia))
	"REPL is not ready"
      (let-alist (queue-first org-babel-julia-vterm--evaluation-queue)
	(julia-vterm-paste-string
	 (org-babel-julia-vterm--make-str-to-run .uuid (cdr (assq :result-type .params))
						 .src-file .out-file)
	 .session)
	(let ((c 0))
	  (while (and (< c 100) (= 0 (file-attribute-size (file-attributes .out-file))))
	    (sit-for 0.1)
	    (setq c (1+ c))))
	(queue-dequeue org-babel-julia-vterm--evaluation-queue)
	(with-temp-buffer
	  (insert-file-contents .out-file)
	  (let ((bs (buffer-string)))
	    (if (catch 'loop
		  (dolist (line (split-string bs "\n"))
		    (if (> (length line) 12000)
			(throw 'loop t))))
		"Output suppressed (line too long)"
	      bs)))))))

(defun org-babel-julia-vterm--process-one-evaluation-async (session)
  "Execute the first evaluation in SESSION's queue asynchronously.
Always return nil."
  (with-current-buffer (julia-vterm-repl-buffer session)
    (if (eq (julia-vterm-repl-buffer-status) :julia)
	(let-alist (queue-first org-babel-julia-vterm--evaluation-queue)
	  (unless (assoc .uuid org-babel-julia-vterm--evaluation-watches)
	    (let ((desc (file-notify-add-watch
			 .out-file '(change)
			 (org-babel-julia-vterm--evaluation-completed-callback-func session))))
	      (push (cons .uuid desc) org-babel-julia-vterm--evaluation-watches))
	    (julia-vterm-paste-string
	     (org-babel-julia-vterm--make-str-to-run .uuid (cdr (assq :result-type .params))
						     .src-file .out-file)
	     .session)))
      (run-at-time 0.1 nil #'org-babel-julia-vterm--process-evaluation-queue session t)))
  nil)

(defun org-babel-julia-vterm--process-evaluation-queue (session async)
  "Process the evaluation queue for SESSION.
If ASYNC is non-nil, the next evaluation will be executed asynchronously."
  (with-current-buffer (julia-vterm-repl-buffer session)
    (if (and (queue-p org-babel-julia-vterm--evaluation-queue)
	     (not (queue-empty org-babel-julia-vterm--evaluation-queue)))
	(if async
	    (org-babel-julia-vterm--process-one-evaluation-async session)
	  (org-babel-julia-vterm--process-one-evaluation session)))))

(defun org-babel-julia-vterm-evaluate (buf session body params)
  "Evaluate a Julia code block in BUF in a julia-vterm REPL specified with SESSION.
BODY contains the source code to be evaluated, and PARAMS contains header arguments."
  (let ((uuid (org-id-uuid))
	(src-file (org-babel-temp-file "julia-vterm-src-"))
	(out-file (org-babel-temp-file "julia-vterm-out-"))
	(src (org-babel-julia-vterm--wrap-body session body))
	(async (not (member "silent" (cdr (assq :result-params params))))))
    (with-temp-file src-file (insert src))
    (let ((elm (org-element-context))
	  (src-block-begin (make-marker))
	  (src-block-end (make-marker)))
      (set-marker src-block-begin (org-element-property :begin elm))
      (set-marker src-block-end (org-element-property :end elm))
      (org-babel-julia-vterm--add-evaluation-to-evaluation-queue
       session
       (list (cons 'uuid uuid)
	     (cons 'buf buf)
	     (cons 'session session)
	     (cons 'params params)
	     (cons 'src-file src-file)
	     (cons 'out-file out-file)
	     (cons 'src-block-begin src-block-begin)
	     (cons 'src-block-end src-block-end))))
    (or (org-babel-julia-vterm--process-evaluation-queue session async)
	(concat "Executing... " (substring uuid 0 8)))))

(add-to-list 'org-src-lang-modes '("julia-vterm" . "julia"))

(provide 'ob-julia-vterm)

;;; ob-julia-vterm.el ends here
