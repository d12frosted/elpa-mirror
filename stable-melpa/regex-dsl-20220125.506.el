;;; regex-dsl.el --- lisp syntax for regexps

;; Copyright (C) 2007,2010  Aliaksey Kandratsenka

;; Author: Aliaksey Kandratsenka <alk@tut.by>
;; Keywords: 
;; Package-Version: 20220125.506
;; Package-Commit: 8802555ecdab8b50bb64181798497c10cdb5034b

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; 

;;; Code:

(defconst redsl-precedence '((group . 0)
			     (cap-group . 0)
			     (\? . 1)
			     (* . 2)
			     (+ . 2)
			     (repeat-= . 2)
			     (repeat . 2)
			     (*\? . 2)
			     (+\? . 2)
			     (\?\? . 2)
			     (char-set . 0)
			     (word-char . 0)
			     (non-word-char . 0)
			     (char-class . 0)
			     (neg-char-set . 0)
			     (line-begin . 0)
			     (line-end . 0)
			     (match-start . 0)
			     (match-end . 0)
			     (point . 0)
			     (word-bound . 0)
			     (non-word-bound . 0)
			     (word-start . 0)
			     (word-end . 0)
			     (sym-start . 0)
			     (sym-end . 0)
			     (backref . 0)
			     (whitespace . 0)
			     (literal . 0)
			     (anychar . 0)
			     (concat . 5)
			     (or . 10)))

(defun redsl-find-precedence (re)
  (let* (car
	 cadr
	 (found (and (consp re) (assoc (setq car (car re)) redsl-precedence))))
    (unless found
      (error "Given re %S is invalid redsl" re))
    (if (and (eq car 'concat)
	     (stringp (setq cadr (cadr re)))
	     (null (cddr re))
	     (= (length cadr) 1))
	0
	(cdr found))))

(defun redsl-complex-p (re)
  (or (memq (car re) '(group cap-group \? * + repeat-= repeat *\? ?\? +\? or))
      (and (eq 'concat (car re))
	   (not (and (stringp (cadr re))
		     (null (cddr re)))))))

(defun redsl-put-parenteses (re &optional parent-precedence)
  (let* ((my-precedence (redsl-find-precedence re))
	 (precedence-for-child (if (memq (car re) '(cap-group group))
				   1000
				 my-precedence))
	 (myself re))
    (setq parent-precedence (or parent-precedence 1000))
    (when (redsl-complex-p re)
      (let ((childs (if (memq (car re) '(repeat repeat-=))
			(list* (redsl-put-parenteses (cadr re) precedence-for-child) (cddr re))
		      (mapcar (lambda (child) (redsl-put-parenteses child precedence-for-child))
			      (cdr re)))))
	(setq myself (cons (car re) childs))))
    (if (<= my-precedence parent-precedence)
	myself
      (list 'group myself))))

(defun redsl-process-literals (re)
  (cond ((consp re)
	 (if (redsl-complex-p re)
	     (if (memq (car re) '(repeat-= repeat))
		 (list* (car re) (redsl-process-literals (cadr re)) (cddr re))
	       (cons (car re) (mapcar #'redsl-process-literals (cdr re))))
	   re))
	((stringp re)
	 (list 'concat re))
	((symbolp re)
	 (list 'concat (prin1-to-string re)))
	(t
	 (error "Given object (%S) is not RE" re))))

(defun redsl-to-regexp-repeat (re from-count to-count)
  (if (= from-count 0)
      (cond ((null to-count)
	     (concat re "*"))
	    ((= to-count 1)
	     (concat re "?"))
	    (t
	     (format "%s\\{,%d\\}" re to-count)))
    (cond ((null to-count)
	   (if (= from-count 1)
	       (concat re "+")
	     (format "%s\\{%d,\\}" re from-count)))
	  ((= to-count from-count)
	   (if (= to-count 1)
	       re
	     (format "%s\\{%d\\}" re to-count)))
	  (t
	   (format "%s\\{%d,%d\\}" re from-count to-count)))))

(defun redsl-to-regexp-char-set (positive chars)
  (format (if positive
	      "[%s]"
	    "[^%s]")
	  chars))

(defun redsl-to-regexp-rec (re)
  (cl-case (car re)
    (group
     (format "\\(?:%s\\)" (redsl-to-regexp-rec (cadr re))))
    (cap-group
     (format "\\(%s\\)" (redsl-to-regexp-rec (cadr re))))
    (\?
     (redsl-to-regexp-rec (list 'repeat (cadr re) 0 1)))
    (*
     (redsl-to-regexp-rec (list 'repeat (cadr re) 0 nil)))
    (+
     (redsl-to-regexp-rec (list 'repeat (cadr re) 1 nil)))
    (repeat-=
     (let ((subre (cadr re))
	   (arg (caddr re)))
       (redsl-to-regexp-rec (list 'repeat subre arg arg))))
    (repeat
     (apply #'redsl-to-regexp-repeat (redsl-to-regexp-rec (cadr re)) (cddr re)))
    (*\?
     (concat (redsl-to-regexp-rec (list* '* (cdr re))) "?"))
    (+\?
     (concat (redsl-to-regexp-rec (list* '+ (cdr re))) "?"))
    (\?\?
     (concat (redsl-to-regexp-rec (list* '? (cdr re))) "?"))
    (char-set
     (apply #'redsl-to-regexp-char-set t (cdr re)))
    (word-char
     "\\w")
    (non-word-char
     "\\W")
    (char-class
     (format "[[%s:]]" (cadr re)))
    (neg-char-set
     (apply #'redsl-to-regexp-char-set nil (cdr re)))
    (line-begin "^")
    (line-end "$")
    (match-start "\\`")
    (match-end "\\'")
    (point "\\=")
    (anychar ".")
    (word-bound "\\b")
    (non-word-bound "\\B")
    (word-start "\\<")
    (word-end "\\>")
    (sym-start "\\_<")
    (sym-end "\\_>")
    (backref (format "\\%d" (cadr re)))
    (whitespace "\\s-")
    (literal (cadr re))
    (concat
     (if (redsl-complex-p re)
	 (apply #'concat (mapcar #'redsl-to-regexp-rec (cdr re)))
       (regexp-quote (cadr re))))
    (or
     (let ((list (list (redsl-to-regexp-rec (cadr re)))))
       (dolist (item (cddr re))
	 (setq list (list* (redsl-to-regexp-rec item) "\\|" list)))
       (apply #'concat (nreverse list))))))

(defun redsl-pre-process (re)
  (redsl-put-parenteses (redsl-process-literals re)))

(defun redsl-to-regexp (re)
  (redsl-to-regexp-rec (redsl-pre-process re)))

(provide 'regex-dsl)
;;; regex-dsl.el ends here
