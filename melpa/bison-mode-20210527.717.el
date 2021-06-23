;;; bison-mode.el --- Major mode for editing bison, yacc and lex files.

;; Copyright (C) 1998 Eric Beuscher
;;
;; Author:   Eric Beuscher <beuscher@eecs.tulane.edu>
;; Created:  2 Feb 1998
;; Version:  0.4
;; Keywords: bison-mode, yacc-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;;;; I wrote this since I saw one mode for yacc files out there roaming the
;;;; world.     I was daunted by the fact the it was written in 1990, and Emacs
;;;; has evolved so much since then (this I assume based on its evolution since
;;;; i started using it).     So I figured if i wanted one, I should make it
;;;; myself.     Please excuse idiosyncrasies, as this was my first major mode
;;;; of this kind.     The indentation code may be a bit weird, I am not sure,
;;;; it was my first go at doing Emacs indentation, so I look at how other
;;;; modes did it, but then basically did what I thought was right

;;;; I hope this is useful to other hackers, and happy Bison/Yacc hacking
;;;; If you have ideas/suggestions/problems with this code, I can be reached at
;;;; beuscher@eecs.tulane.edu

;;;; Eric --- Sat Mar  7 1:40:20 CDT 1998

;;;; Bison Sections:
;;;; there are five sections to a bison file (if you include the area above the
;;;; C declarations section.     most everything in this file either does
;;;; actions based on which section you are deemed to be in, or based on an
;;;; assumption that the function will only be called from certain sections.
;;;; the function `bison--section-p' is the section parser

;;;; Indentation:
;;;; indentations are done based on the section of code you are in.    there is
;;;; a procedure `bison--within-braced-c-expression-p' that checks for being in
;;;; C code.    if you are within c-code, indentations should occur based on
;;;; how you have your C indentation set up.     i am pretty sure this is the
;;;; case.
;;;; there are four variables, which control bison indentation within either
;;;; the bison declarations section or the bison grammar section
;;;; `bison-rule-separator-column'
;;;; `bison-rule-separator-column'
;;;; `bison-decl-type-column'
;;;; `bison-decl-token-column'

;;;; flaw: indentation works on a per-line basis, unless within braced C sexp,
;;;; i should fix this someday
;;;; and to make matters worse, i never took out c-indent-region, so that is
;;;; still the state of the `indent-region-function' variable

;;;; Electricity:
;;;; by default, there are electric -colon, -pipe, -open-brace, -close-brace,
;;;; -semicolon, -percent, -less-than, -greater-than
;;;; the indentation caused by these work closely with the 4 indentation
;;;; variables mentioned above.
;;;; any of these can be turned off individually by setting the appropriate
;;;; `bison-electric-...' variable.     or all of them can be turned off by
;;;; setting `bison-all-electricity-off'

;;;; todo:  should make available a way to use C-electricity if in C sexps

;;; Code:

(require 'cc-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.y\\'" . bison-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.l\\'" . flex-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jison\\'" . jison-mode))

;; *************** internal vars ***************

(defvar bison--declarers '("%union" "%token" "%type"
			   "%left" "%right" "%nonassoc")
  "commands which can declare a token or state type")

(defvar bison--word-constituent-re "\\(\\sw\\|_\\)")
(defvar bison--production-re
  (concat "^" bison--word-constituent-re "+:"))

(defvar bison--pre-c-decls-section 0
  "section before c-declarations-section, if that section exists")
(defvar bison--c-decls-section 1
  "section denoted by %{ and $} for c-declarations at the top of a bison file")
(defvar bison--bison-decls-section 2
  "section before the rules section")
(defvar bison--grammar-rules-section 3
  "section delimited by %%'s where productions and rules are enumerated")
(defvar bison--c-code-section 4
  "section after the second %% where c-code can be placed")

(defvar bison--c-decls-section-opener "%{")
(defvar bison--c-decls-section-closer "%}")
(defvar bison--grammar-rules-section-delimeter "%%")


;; *************** user-definable vars ***************

(defgroup bison-mode nil
  "Bison Mode Control."
  :group 'c)

(defcustom bison-rule-separator-column 8
  "Column for rule and production separators \"|\" and \";\"."
  :group 'bison-mode
  :type 'integer
  :safe #'integerp)
(defcustom bison-rule-enumeration-column 16
  "Column for beginning enumeration of a production's rules."
  :group 'bison-mode
  :type 'integer
  :safe #'integerp)
(defcustom bison-decl-type-column 8
  "Column in which tokens' and states' types should be when declared."
  :group 'bison-mode
  :type 'integer
  :safe #'integerp)
(defcustom bison-decl-token-column 24
  "Column in which tokens and states are listed when declared,
as with %token, %type, ..."
  :group 'bison-mode
  :type 'integer
  :safe #'integerp)
(defcustom bison-all-electricity-off nil
  "non-nil means all electric keys will be disabled,
nil means that a bison-electric-* key will be on or off based on the individual
key's electric variable"
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)

;;; i know lisp has the dual name spaces, but i find it more aesthetically
;;; pleasing to not take advantage of that
(defcustom bison-electric-colon-v t
  "Non-nil means use an electric colon."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-pipe-v t
  "Non-nil means use an electric pipe."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-open-brace-v t
  "Non-nil means use an electric open-brace."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-close-brace-v t
  "Non-nil means use an electric close-brace."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-semicolon-v t
  "Non-nil means use an electric semicolon."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-percent-v t
  "Non-nil means use an electric percent."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-less-than-v t
  "Non-nil means use an electric less-than."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)
(defcustom bison-electric-greater-than-v t
  "Non-nil means use an electric greater-than."
  :group 'bison-mode
  :type 'boolean
  :safe #'booleanp)


(defconst bison-font-lock-keywords
  (append
   (list
    (cons (concat "^\\(" (regexp-opt bison--declarers) "\\)")
	  '(1 font-lock-keyword-face))
    )
   c-font-lock-keywords)
  "Default expressions to highlight in Bison mode")

;; *************** utilities ***************

(defun bison--just-no-space ()
  "Delete all spaces and tabs around point, leaving no spaces."
  (interactive "*")
  (skip-chars-backward " \t")
  (delete-region (point) (progn (skip-chars-forward " \t") (point)))
  t)

(defun bison--previous-white-space-p ()
  "return t if there is whitespace between the beginning of the line and the
current (point)"
  (save-excursion
    (let ((current-point (point)))
      (beginning-of-line)
      (if (re-search-forward "\\s " current-point t)
	  t
	nil))))

(defun bison--previous-non-ws-p ()
  "return t if there are non-whitespace characters between beginning of line
and \(point\)"
  (save-excursion
    (let ((current-point (point)))
      (beginning-of-line)
    (re-search-forward "[^ \t]" current-point t)
    )))

(defun bison--following-non-ws-p ()
  "return t if there are non-whitespace characters on the line"
  (save-excursion
    (let ((current-point (point)))
      (end-of-line)
      (re-search-backward "[^ \t]+" current-point t)
      )))

(defun bison--line-of-whitespace-p ()
  "return t if the line consists of nothiing but whitespace, nil otherwise"
  (save-excursion
    (let ((eol (progn (end-of-line) (point))))
      (beginning-of-line)	;; should already be there anyway
      (not (re-search-forward "[^ \t\n]" eol t)))))

;; *************** bison-mode ***************

;;;###autoload
(define-derived-mode bison-mode c-mode "Bison"
  "Major mode for editing bison/yacc files."

  ;; try to set the indentation correctly
  (setq c-basic-offset 4)

  (c-set-offset 'knr-argdecl-intro 0)

  ;; remove auto and hungry anything
  (c-toggle-auto-hungry-state -1)
  (c-toggle-auto-newline -1)
  (c-toggle-hungry-state -1)

  (use-local-map bison-mode-map)

  (define-key bison-mode-map ":" 'bison-electric-colon)
  (define-key bison-mode-map "|" 'bison-electric-pipe)
  (define-key bison-mode-map "{" 'bison-electric-open-brace)
  (define-key bison-mode-map "}" 'bison-electric-close-brace)
  (define-key bison-mode-map ";" 'bison-electric-semicolon)
  (define-key bison-mode-map "%" 'bison-electric-percent)
  (define-key bison-mode-map "<" 'bison-electric-less-than)
  (define-key bison-mode-map ">" 'bison-electric-greater-than)

  (define-key bison-mode-map [tab] 'bison-indent-line)

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'bison-indent-new-line)
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-end)
  (setq comment-start "/*"
	comment-end "*/")
  (make-local-variable 'font-lock-keywords)
  (setq font-lock-keywords nil)
  (set (make-local-variable 'font-lock-defaults) '(bison-font-lock-keywords)))


;; *************** section parsers ***************

(defun bison--section-p ()
  "Return the section that user is currently in"
  (save-excursion
    (let ((bound (point)))
      (goto-char (point-min))
      (bison--section-p-helper bound))))

(defun bison--section-p-helper (bound)
  (if (re-search-forward
       (concat "^" bison--c-decls-section-opener)
       bound t)
      (if (re-search-forward
		(concat "^" bison--c-decls-section-closer)
		bound t)
	  (if (re-search-forward
	       (concat "^" bison--grammar-rules-section-delimeter)
	       bound t)
	      (if (re-search-forward
		   (concat "^" bison--grammar-rules-section-delimeter)
		   bound t)
		  bison--c-code-section
		bison--grammar-rules-section)
	    bison--bison-decls-section)
	bison--c-decls-section)
    (if (re-search-forward
	    (concat "^" bison--grammar-rules-section-delimeter)
	    bound t)
	(if (re-search-forward
	     (concat "^" bison--grammar-rules-section-delimeter)
	     bound t)
	    bison--c-code-section
	  bison--grammar-rules-section)
      (if (re-search-forward
	   (concat "^" bison--c-decls-section-opener)
	   nil t)
	  bison--pre-c-decls-section
	(if (re-search-forward
	     (concat "^" bison--grammar-rules-section-delimeter)
	     nil t)
	    bison--bison-decls-section
	  bison--pre-c-decls-section)))))


;; *************** syntax parsers ***************

(defun bison--production-p ()
  "return t if the \(point\) rests immediately after a production"
  (save-excursion
    (let ((current-point (point)))
      (beginning-of-line)
      (let ((position (re-search-forward
		       bison--production-re current-point t)))
	(and position
	     (not (bison--previous-white-space-p))
	     (= position current-point))))))

(defun bison--find-production-opener ()
  "return and goto the point of the nearest production opener above \(point\)"
  (re-search-backward bison--production-re nil t))


(defun bison--find-next-production ()
  "return the position of the beginning of the next production,
or nil if there isnt one"
  (save-excursion
    (if (re-search-forward bison--production-re nil t)
	(progn
	  (beginning-of-line)
	  (point))
      nil)))

(defun bison--find-grammar-end ()
  "return the position of the end of the grammar rules (assuming we are within
the grammar rules section), or nil if there isnt one"
  (save-excursion
    (if (re-search-forward
	 (concat "^" bison--grammar-rules-section-delimeter)
	 nil t)
	(progn
	  (beginning-of-line)
	  (point))
      nil)))

(defun bison--find-grammar-begin ()
  "return the position of the beginning of the grammar rules (assuming we are
within the grammar rules section), or nil if there isnt one"
  (save-excursion
    (if (re-search-backward
	 (concat "^" bison--grammar-rules-section-delimeter)
	 nil t)
	(point)
      nil)))

(defun bison--within-started-production-p ()
  "is used by bison-electric-* functions to determine actions
return t if within a production, nil if not

a point is within a production if there is some non whitespace text before
either the beginnings of another production or the end of the grammar rules"
  (save-excursion
    (let ((bound (cond ((bison--find-next-production))
		       ((bison--find-grammar-end))
		       (t nil))))
      (if bound
	  (let ((sval (re-search-forward
		       (concat "\\(\\s \\|" ;; whitespace or
					    ;; comments
			       (regexp-quote comment-start)
			       "\\(.\\|\n\\)*" ;; comment body
			       (regexp-quote comment-end)
			       "\\)+")	;; end or
		       bound t)))
	    (if sval
		(not (= sval bound))
	      nil))
	nil))))

(defun bison--within-some-sexp-p (starter ender)
  "return t if the \(point\) is within the sexp marked by the re's STARTER and
ENDER"
  (save-excursion
    (let ((current-point (point)))
      (if (re-search-backward starter nil t) ;; find nearest starter
	  ;; look for ender, if found, then not within sexp
	  (progn
	    (goto-char (match-end 0))
	    (not (re-search-forward ender current-point t)))))))

(defun bison--within-c-comment-p ()
  "return t if the point is within a c comment delimited by \"/*\" \"*/\""
  (bison--within-some-sexp-p (regexp-quote comment-start)
			     (regexp-quote comment-end)))


(defun bison--within-string-p (&optional point)
  "
start from the beginning of the buffer and toggle state as un-escaped \"'s are
found."
  (let ((point (or point (point)))
	(in-p nil))
    (save-excursion
      (goto-char (point-min))

      (while (re-search-forward "[^\\]\"" point t)
	(setq in-p (not in-p)))

      in-p)))

;;; bison--within-braced-c-expression-p
;;; new and improved, no more recursion, does not break when literal strings
;;; contain un-matched braces
(defun bison--within-braced-c-expression-p (section)
  "return t if the point is within an sexp delimited by braces \({,}\)
"
  (save-excursion
    (bison--within-braced-c-expression-p-h section (point))))

(defun bison--within-braced-c-expression-p-h (section low-pt)
  "
Notes:
save excursion is done higher up, so i dont concern myself here.
"
  (cond ((= section bison--pre-c-decls-section) nil)
	((= section bison--c-decls-section)
	 (let ((opener (save-excursion (search-backward "%{"))))
	   (bison--within-braced-c-expression-p-h-h opener low-pt)))
	((= section bison--bison-decls-section)
	 (let ((opener (save-excursion
			 (or (search-backward "%}" nil t)
			     (point-min)))))
	   (bison--within-braced-c-expression-p-h-h opener low-pt)))
	((= section bison--grammar-rules-section)
	 (let ((opener (save-excursion (bison--find-production-opener))))
	   (if opener
	       (bison--within-braced-c-expression-p-h-h opener low-pt)
	     nil)))
	((= section bison--c-code-section)
	 t)))

(defun bison--within-braced-c-expression-p-h-h (high-pt low-pt)
  "
Notes:
HIGH-PT goes toward (point-min), LOW-PT goes toward (point-max)
save excursion is done higher up, so i dont concern myself here.
"
  (let ((pt (point)))
    (let ((success nil) (count 1) (done nil))
      ;; loop until open brace found, that is not in comment or string literal
      (while (and (not done)
		  (re-search-backward "[^%]{" high-pt t count)) ;find nearest
							        ;starter
	(goto-char (match-end 0))
	(if (or (bison--within-c-comment-p)
		(bison--within-string-p))

	    (setq count (+ count 1))
	  (progn
	    (setq success t)
	    (setq done t))))

      (if success
	  (let ((end-pt
		 (condition-case nil
		     (progn
                       (backward-char)
                       (forward-sexp)
                       (point))
		   (error nil))))
	    (if end-pt
		(if (> end-pt low-pt)
		    t			; then in braced-c-exp
		  nil)
	      t))			; if no sexp close brace, then w/in
	nil))))


(defun bison--bison-decl-opener-p (bol eol)
  "return t if the current line is a bison declaration starter
\(i.e. has a %type, %token, %right, ...\)"
  (save-excursion
    (goto-char bol)
    (re-search-forward
     (concat "^" (regexp-opt (copy-sequence bison--declarers))) eol t)))

(defun bison--production-opener-p (bol eol)
  "return t if the current line is a line that introduces a new production"
  (save-excursion
    (goto-char bol)
    (re-search-forward bison--production-re eol t)))

(defun bison--find-bison-semicolon ()
  "return the position of next semicolon not within braces, nil otherwise"
  (save-excursion
    (if (search-forward ";" nil t)
	(if (not (bison--within-braced-c-expression-p (bison--section-p)))
	    (point)
	  (bison--find-bison-semicolon))
      nil)))

(defun bison--within-production-body-p (section)
  "return t if the \(point\) is within the body of a production

this procedure will fail if it is in a production header"
  (save-excursion
    (if (= section bison--grammar-rules-section)
	(let ((current-point (point)))
	  (if (re-search-backward bison--production-re nil t)
	      t
	    nil))
      nil)))

(defun bison--production-alternative-p (bol eol section)
  "return t if the current line contains a \"|\" used to designate a rule
alternative"
  (save-excursion
    (goto-char bol)
    (if (search-forward "|" eol t)
	(not (bison--within-braced-c-expression-p section))
      nil)))


;; *************** indent functions ***************

(defun bison--handle-indent-c-sexp (section indent-column bol)
  (let* ((o-brace (re-search-backward "[^%]{" bol t))
	 )
    (if o-brace
	(if (save-excursion
	      (goto-char o-brace)
	      (bison--within-braced-c-expression-p section))
	    (c-indent-line)
	  (if (= (current-indentation) o-brace)	;; if o-brace is first char
	      (if (not (= o-brace indent-column)) ;; but not in right spot
		  (progn
		    (back-to-indentation)
		    (bison--just-no-space)
		    (indent-to-column indent-column))
		;; else all is good
		)
	    ;; else, non-ws before o-brace, leave it alone
	    ))
      (c-indent-line))))

(defun bison-indent-new-line (&optional c-sexp)
  "Indent a fresh line of bison code

assumes indenting a new line, i.e. at column 0
"
  (interactive)

  (let* ((section (bison--section-p))
	 (c-sexp (or c-sexp (bison--within-braced-c-expression-p section)))
	 )
    (cond
     (c-sexp
      (cond
       ((= section bison--grammar-rules-section)
	(c-indent-line
	 (save-excursion
	   (forward-line -1)
	   (let ((bol (save-excursion (beginning-of-line) (point)))
		 (eol (save-excursion (end-of-line) (point))))
	     (if (bison--production-opener-p bol eol)
		 (list
		  (cons 'defun-block-intro
			(progn
			  (re-search-forward bison--production-re) ; SIGERR
			  (- (re-search-forward "[^ \t]") ; SIGERR
			     1))))
	       nil)))))
      (t (c-indent-line))))
     ((= section bison--pre-c-decls-section)
      (c-indent-line))
     ((= section bison--bison-decls-section)
      (indent-to-column bison-decl-token-column))
     ((= section bison--grammar-rules-section)
      (indent-to-column
       (save-excursion
	 (let* ((bound (or (save-excursion (bison--find-production-opener))
			   (bison--find-grammar-begin)))
		(prev-semi (search-backward ";" bound t))
		)
	   (if prev-semi
	       (if (bison--within-braced-c-expression-p section) ; CRACK
		   bison-rule-enumeration-column
		 0)
	     (if (save-excursion (bison--find-production-opener))
		 bison-rule-enumeration-column
	       0))))))
     ((= section bison--c-code-section)) ;;leave-alone
     )))

(defun bison-indent-line ()
  "Indent a line of bison code."
  (interactive)

  (let* ((pos (- (point-max) (point)))
	 (reset-pt (function (lambda ()
			       (if (> (- (point-max) pos) (point))
				   (goto-char (- (point-max) pos))))))
	 (bol (save-excursion (beginning-of-line) (point)))
	 (eol (save-excursion (end-of-line) (point)))
	 )
    (let* ((section (bison--section-p))
	   (c-sexp (bison--within-braced-c-expression-p section))
	   (ws-line (bison--line-of-whitespace-p))
	   )
      (cond
       ;; if you are a line of whitespace, let indent-new-line take care of it
       (ws-line
	(bison-indent-new-line c-sexp))

       ((= section bison--pre-c-decls-section)
	;; leave things alone
	)

       ((= section bison--c-decls-section)
	(if c-sexp
	    (bison--handle-indent-c-sexp section 0 bol)
	  (if (not (= (current-indentation) 0))
	      (progn
		(back-to-indentation)
		(bison--just-no-space)
		(funcall reset-pt)))))

       ((= section bison--bison-decls-section)
	(let ((opener (bison--bison-decl-opener-p bol eol)))
	  (cond
	   (opener
	    (goto-char opener)
	    (skip-chars-forward " \t" eol)
	    (if (looking-at "{")
		(save-excursion
		  (if (bison--following-non-ws-p)
		      (progn
			(forward-char 1)
			(bison--just-no-space)
			(newline)
			(bison-indent-new-line t))))
	      (let ((complete-type t))
		(if (looking-at "<")
		    (progn
		      (setq complete-type nil)
		      (if (not (= (current-column) bison-decl-type-column))
			  (progn
			    (bison--just-no-space)
			    (indent-to-column bison-decl-type-column))
			(and (re-search-forward
			      (concat "<" bison--word-constituent-re "+>")
			      eol t)
			     (setq complete-type t)))))
		(and complete-type
		     (skip-chars-forward " \t" eol)
		     (looking-at
		      (concat "\\(" bison--word-constituent-re "\\|'\\)"))
		     (if (not (= (current-column) bison-decl-token-column))
			 (progn
			   (bison--just-no-space)
			   (indent-to-column bison-decl-token-column))))))
	    (funcall reset-pt))
	   (c-sexp
	    (bison--handle-indent-c-sexp section 0 bol))
	   (t
	    (back-to-indentation)
	    ;; only tab in names, leave comments alone
	    (cond (;; put word-constiuents in bison-decl-token-column
		   (looking-at bison--word-constituent-re)
		   (if (not (= (current-column) bison-decl-token-column))
		       (progn
			 (bison--just-no-space)
			 (indent-to-column bison-decl-token-column))))
		  ;; put/keep close-brace in the 0 column
		  ((looking-at "}")
		   (if (not (= (current-column) 0))
		       (bison--just-no-space)))
		  ;; leave comments alone
		  ((looking-at (regexp-quote comment-start)) nil)
		  ;; else do nothing
		  )
	    (funcall reset-pt)))))
       ((= section bison--grammar-rules-section)
	(cond
	 ((bison--production-opener-p bol eol)
	  (beginning-of-line)
	  (re-search-forward bison--production-re);; SIGERR
	  (if (bison--following-non-ws-p)
	      (if (> (current-column) bison-rule-enumeration-column)
		  (progn
		    (bison--just-no-space)
		    (newline)
		    (indent-to-column bison-rule-enumeration-column))
		(save-excursion
		  (re-search-forward bison--word-constituent-re);; SIGERR
		  (let ((col (current-column)))
		    (cond ((> col (+ 1 bison-rule-enumeration-column))
			   (forward-char -1)
			   (bison--just-no-space)
			   (indent-to-column bison-rule-enumeration-column))
			  ((< col (+ 1 bison-rule-enumeration-column))
			   (forward-char -1)
			   (indent-to-column
			    bison-rule-enumeration-column)))))))
	  (funcall reset-pt))
	 ((bison--production-alternative-p bol eol section)
	  (back-to-indentation);; should put point on "|"
	  (if (not (= (current-column) bison-rule-separator-column))
	      (progn
		(bison--just-no-space)
		(indent-to-column bison-rule-separator-column)))
	  (forward-char 1)
	  (if (bison--following-non-ws-p)
	      (save-excursion
		(re-search-forward bison--word-constituent-re);; SIGERR
		(let ((col (current-column)))
		  (cond ((> col (+ 1 bison-rule-enumeration-column))
			 (forward-char -1)
			 (bison--just-no-space)
			 (indent-to-column bison-rule-enumeration-column))
			((< col (+ 1 bison-rule-enumeration-column))
			 (forward-char -1)
			 (indent-to-column
			  bison-rule-enumeration-column))))))
	  (funcall reset-pt))
	 (c-sexp
	  (bison--handle-indent-c-sexp
	   section bison-rule-enumeration-column bol)
	  (funcall reset-pt))
	 ((bison--within-production-body-p section)
	  (back-to-indentation)
	  (if (not (= (current-column) bison-rule-enumeration-column))
	      (progn
		(bison--just-no-space)
		(indent-to-column
		 bison-rule-enumeration-column)))
	  (funcall reset-pt))
	 (t
	  (let ((cur-ind (current-indentation)))
	    (if (eq (save-excursion (search-backward "}" bol t))
		    cur-ind)
		(if (not (= cur-ind bison-rule-enumeration-column))
		    (progn
		      (back-to-indentation)
		      (bison--just-no-space)
		      (indent-to-column bison-rule-enumeration-column)
		      (funcall reset-pt)))
	      ;; else leave alone
	      )))))
       ((= section bison--c-code-section)
	(c-indent-line))
       ))))

;; *************** electric-functions ***************

(defun bison-electric-colon (arg)
  "If the colon <:> delineates a production,
   then insert a semicolon on the next line in the BISON-RULE-SEPARATOR-COLUMN,
	put the cursor in the BISON-RULE-ENUMERATION-COLUMN for the beginning
	of the rule
   else just run self-insert-command
A colon delineates a production by the fact that it is immediately preceded by
a word(alphanumerics or '_''s), and there is no previous white space.
"
  (interactive "P")

  (self-insert-command (prefix-numeric-value arg))
  (if (and bison-electric-colon-v
	   (not bison-all-electricity-off))
      (if (and (= bison--grammar-rules-section (bison--section-p))
	       (bison--production-p)
	       (not (bison--within-started-production-p)))
	  (progn
	    (save-excursion		; put in a closing semicolon
	      (newline)
	      (indent-to-column bison-rule-separator-column)
	      (insert ";"))
	    (save-excursion		; remove opening whitespace
	      (if (re-search-backward
		   "\\s "
		   (save-excursion (beginning-of-line) (point))
		   t)
		  (bison--just-no-space)))
	    (if (not (< (current-column) bison-rule-enumeration-column))
		(newline))
	    (indent-to-column bison-rule-enumeration-column)))))

(defun bison-electric-pipe (arg)
  "If the pipe <|> is used as a rule separator within a production,
   then move it into BISON-RULE-SEPARATOR-COLUMN
	indent to BISON-RULE-ENUMERATION-COLUMN on the same line
   else just run self-insert-command
"
  (interactive "P")

  (if (and bison-electric-pipe-v
	   (not bison-all-electricity-off)
	   (= bison--grammar-rules-section (bison--section-p))
	   (bison--line-of-whitespace-p)
	   )
      (progn
	(beginning-of-line)
	(bison--just-no-space)
	(indent-to-column bison-rule-separator-column)
	(self-insert-command (prefix-numeric-value arg))
	(indent-to-column bison-rule-enumeration-column)
	)
    (self-insert-command (prefix-numeric-value arg))))

(defun bison-electric-open-brace (arg)
  "used for the opening brace of a C action definition for production rules,
if there is only whitespace before \(point\), then put open-brace in
bison-rule-enumeration-column"
  (interactive "P")

  (if (and bison-electric-open-brace-v
	   (not bison-all-electricity-off))
      (let ((section (bison--section-p)))
	(cond ((and (= section bison--grammar-rules-section)
		    (not (bison--within-braced-c-expression-p section))
		    (not (bison--previous-non-ws-p)))
	       (if (not (= (current-column) bison-rule-enumeration-column))
		   (progn
		     (bison--just-no-space)
		     (indent-to-column bison-rule-enumeration-column))))
	      ((and (= section bison--bison-decls-section)
		    (not (bison--within-braced-c-expression-p section))
		    (not (bison--previous-non-ws-p)))
	       (if (not (= (current-column) 0))
		   (progn
		     (bison--just-no-space)
		     (indent-to-column 0)))))))

  (self-insert-command (prefix-numeric-value arg)))


(defun bison-electric-close-brace (arg)
  "If the close-brace \"}\" is used as the c-declarations section closer
in \"%}\", then make sure the \"%}\" indents to the beginning of the line"
  (interactive "P")

  (self-insert-command (prefix-numeric-value arg))

  (if (and bison-electric-close-brace-v
	   (not bison-all-electricity-off))
      (cond ((search-backward "%}" (- (point) 2) t)
	     (if (= (bison--section-p) bison--c-decls-section)
		 (progn
		   (bison--just-no-space)
		   (forward-char 2))	; for "%}"
	       (forward-char 1)))
	    )))

(defun bison-electric-semicolon (arg)
  "if the semicolon is used to end a production, then place it in
bison-rule-separator-column

a semicolon is deemed to be used for ending a production if it is not found
within braces

this is just self-insert-command as i have yet to write the actual
bison-electric-semicolon function yet
"
  (interactive "P")

  (self-insert-command (prefix-numeric-value arg)))

(defun bison-electric-percent (arg)
  "If the percent is a declarer in the bison declaration's section,
then put it in the 0 column."
  (interactive "P")

  (if (and bison-electric-percent-v
	   (not bison-all-electricity-off))
      (let ((section (bison--section-p)))
	(if (and (= section bison--bison-decls-section)
		 (not (bison--within-braced-c-expression-p section))
		 (not (bison--previous-non-ws-p))
		 (not (= (current-column) 0)))
	    (bison--just-no-space))))

  (self-insert-command (prefix-numeric-value arg)))

(defun bison-electric-less-than (arg)
  "If the less-than is a type declarer opener for tokens in the bison
declaration section, then put it in the bison-decl-type-column column."
  (interactive "P")

  (if (and bison-electric-less-than-v
	   (not bison-all-electricity-off))
      (if (and (= (bison--section-p) bison--bison-decls-section)
	       (bison--bison-decl-opener-p
		(save-excursion (beginning-of-line) (point))
		(point)))
	  (progn
	    (bison--just-no-space)
	    (indent-to-column bison-decl-type-column))))

  (self-insert-command (prefix-numeric-value arg)))

(defun bison-electric-greater-than (arg)
  "If the greater-than is a type declarer closer for tokens in the bison
declaration section, then indent to bison-decl-token-column."
  (interactive "P")

  (self-insert-command (prefix-numeric-value arg))

  (if (and bison-electric-greater-than-v
	   (not bison-all-electricity-off))
      (let ((current-pt (point))
	    (bol (save-excursion (beginning-of-line) (point))))
	(if (and (= (bison--section-p) bison--bison-decls-section)
		 (bison--bison-decl-opener-p bol (point)))
	    (if (search-backward "<" bol t)
		(if (re-search-forward
		     (concat "<" bison--word-constituent-re "+>")
		     current-pt t)
		    (if (not (bison--following-non-ws-p))
			(progn
			  (bison--just-no-space)
			  (indent-to-column bison-decl-token-column)))))))))

;;;###autoload
(define-derived-mode jison-mode bison-mode "jison"
  "Major mode for editing jison files.")
;;;###autoload
(define-derived-mode flex-mode bison-mode "flex"
  "Major mode for editing flex files. (bison-mode by any other name)")

(provide 'bison-mode)
(provide 'jison-mode)
(provide 'flex-mode)

;;; bison-mode.el ends here
