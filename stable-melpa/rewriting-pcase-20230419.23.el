;;; rewriting-pcase.el --- Support for rewriting sexps in source code   -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Onnie Winebarger

;; Author: Onnie Winebarger
;; Copyright (C) 2023 by Onnie Lynn Winebarger <owinebar@gmail.com>
;; Keywords: extensions, lisp
;; Package-Version: 20230419.23
;; Package-Commit: 3a2efb79bfc68629bd20a8bc1770c8f6d24575fa
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/owinebar/emacs-rewriting-pcase

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This code supports rewriting s-expressions in source with minimal disturbance
;; of surrounding text.

;;; Code:


(define-error 'rewriting-pcase-replace-sexpr "Bad sexpr parse")
(define-error 'rewriting-pcase-unrecognized-read-syntax
  "Unrecognized read syntax")


(defun rewriting-pcase--next-sexpr-start ()
  "Find the start of the *next* sexpr.
It may begin at point but no earlier."
  (save-excursion
    (save-restriction
      (narrow-to-region (point) (point-max))
      (forward-sexp)
      (backward-sexp)
      (point))))

(defun rewriting-pcase--this-sexpr-start (&optional min-start)
  "Find the start of the sexpr which point follows or is in.
Subject to lower bound of MIN-START."
  (save-excursion
    (save-restriction
      (when min-start
	(narrow-to-region min-start (point-max)))
      (condition-case nil
	  (forward-sexp -1)
	(error (goto-char min-start)))
      (point))))

;; assumes parse-sexp-ignore-comments is t
(defun rewriting-pcase--back-sexpr (v p0 &optional p2)
  "Go back one sexpr corresponding to V.
Arguments:
  V - a value produced using `read' on the region between p0 and p2
  P0 is the end of the previous sexpr.
  P2 is a position either at the end of the current sexpr on inside it.
     Default value is point."
  (unless p2
    (setq p2 (point)))
  (let (p1)
    ;; check for named unicode character that is not handled well by
    ;; emacs-lisp-mode (forward-sexp -1)
    (when (and (char-or-string-p v)
	       (not (stringp v))
	       (eq (preceding-char) ?\}))
      ;; assume a unicode character name cannot contain a comment
      (save-excursion
	(setq p1 (search-backward "{" p0 t))
	(when p1
	  ;; this is only valid if it occured as a named unicode character
	  (setq p1 nil)
	  (and (looking-back "\\?\\\\N" p0)
	       (forward-char -3)
	       (setq p1 (point))))))
    ;; (forward-sexp -1) also does not deal well with ## (the empty symbol)
    (unless (or p1 (not (and (symbolp v) (eq (preceding-char) ?\#))))
      (forward-char -1)
      (and (> (point) p0)
	   (eq (preceding-char) ?\#)
	   (setq p1 (rewriting-pcase--this-sexpr-start p0))))
    ;; #N# references are dealt with directly when read error is detected
    ;; assume other cases fairly well-behaved
    (unless p1
      (goto-char (rewriting-pcase--this-sexpr-start p0))
      (cond
       ((recordp v)
	(when (and (>= (point) (+ p0 2))
		   (eq (preceding-char) ?s)
		   (eq (char-before (- (point) 1)) ?\#))
	  (forward-char -2)))
       (t nil))
      (setq p1 (point)))
    (goto-char p1)
    p1))
       
(defun rewriting-pcase--replace-text-in-region (start end new)
  "Replace text in region using value NEW.
Arguments:
  START start of region to replace
  END end of region to replace
  NEW Lisp value to write into the region."
  (if (and (< (point) end) (> (point) start))
      (goto-char end))
  (save-excursion
    (goto-char end)
    (delete-region start end)
    (prin1 new (current-buffer))))

;; assumes preceding character is \#
(defun rewriting-pcase--check-invalid-read-graph-occurence (pos0)
  "Check if reader failed due to encountering bare #N# at postion POS0."
  (let ((N nil)
	p0 p1 retval)
    (save-excursion
      (forward-char -1)
      (setq p1 (point))
      (search-backward "#" pos0 t)
      (when (< (point) p1)
	(setq p0 (point))
	(forward-char 1)
	(ignore-error error
	    (setq N (read (current-buffer))))
	(when (and N (natnump N) (>= (point) p1))
	  (setq retval p0))))
    retval))

;; assumes preceding character is either \) or \]
(defun rewriting-pcase--check-invalid-non-atomic (pos0)
  "Check reader failure on `#N#' syntax.
Arguments:
  POS0 - position at which failed `read' operation was called."
  (let ((p2 (point))
	(close (preceding-char))
	open p1)
    (setq open
	  (if (eq close ?\])
	      "["
	    "("))
    (save-excursion
      (setq p1 (rewriting-pcase--back-sexpr nil pos0))
      ;; This is not at all correct.  Code such a ` , ' , ' (foo) is
      ;; completely legal (if unusual) and will massively fail with
      ;; this implementation
      ;; Will have to bite the bullet and search from pos0 for the
      ;; first non-comment character.
      (unless (search-forward open p2 t)
	(setq p1 nil))
      p1)))

(defun rewriting-pcase--check-invalid-read (pos0)
  "Check for different causes of invalid read error at POS0."
  (let (p1)
    (cond
     ((eq (preceding-char) ?\#) ; check for #N#
      (setq p1 (rewriting-pcase--check-invalid-read-graph-occurence pos0)))
     ((or (eq (preceding-char) ?\))
	  (eq (preceding-char) ?\])) ; check for non-atomic
      (setq p1 (rewriting-pcase--check-invalid-non-atomic pos0))))
    p1))

(defun rewriting-pcase--symbol-read-syntax (sym)
  "Return special read syntax associated with SYM."
  (pcase sym
    ('quote "'")
    ('function "#'")
    ('\` "`")
    ('\, ",")
    ('\,@ ",@")
    (_ nil)))
     
;; this handles situations where the reader returns a list but
;; the character at point is not a left parenthesis
(defun rewriting-pcase--read-syntax-end (pos1 sym)
  "Find the starting position of the textual sexp preceded by special syntax.
Arguments:
  POS1 - location `backward-sexp' indicates is the start of the sexp just read
  SYM - a symbol that may be represented using special reader syntax."
  (let ((s (rewriting-pcase--symbol-read-syntax sym))
	p)
    (when s
      (setq p (+ pos1 (length s)))
      (unless (string= (buffer-substring-no-properties pos1 p) s)
	;; there can be whitespace between the special symbol and the
	;; rest of the sexp, in which case (forward-sexp -1) misses
	;; the special read syntax
	(setq p pos1)))
    (unless p
      (signal 'rewriting-pcase-unrecognized-read-syntax
	      `(,(current-buffer) ,pos1 ,sym)))
    p))

;;  rewriting-pcase--pcase-replace-next-sexpr calls read from point to skip
;;  any comments and get the value represented by the text for
;;  testing.
;;  It then attempts to identify the beginning of the textual
;;  representation using rewriting-pcase--back-sexpr before testing for
;;  replacement.
;;  We assume the (possibly narrowed) current buffer contains a valid
;;  elisp program. Given that, read will still signal an error in two
;;  cases:
;;  1) When the EOF is reached - read has no other mechanism for
;;     indicating all expressions have been read
;;  2) Due to syntax that is valid as a subexpression of some sexpr,
;;     but not as a stand-alone expression.
;;     a) Graph notation #N# represents an *occurrence* of an object
;;        represented elsewhere.  Hence we treat the traversal of this
;;        notation as a successful reading of the corresponding
;;        expression, although this prevents pcase testing from being
;;        performed on any containing sexpr
;;     b) Graph notation #N= defining a graph object.  In this case we
;;        attempt to read the following object since the #N= does not
;;        itself correspond to any object occurrence.
;;     c) The dot in a dotted pair representation of a cons cell. In
;;        this case we attempt to read the following sexpr as the dot
;;        does not correspond to any constructed object.
;;     d) Any non-atomic object failing due to containing an undefined
;;        #N# notation, though such a definition must have occurred if
;;        the top-level expression was successfully read.
;;  Note the lack of recording graph notation values means that pcase
;;  testing is not truly done *inside* circular objects in the elisp
;;  source code.
;;
;;  In this implementation, there are 3 main positions of concern:
;;  position 0 - the initial value of point before calling read
;;  position 2 - the position immediately following the last character
;;               of an expression
;;  position 1 - the position immediately preceding the first
;;               character of the text representing the value which is
;;               going to be tested and possibly replaced
;;
;;  Every position 0 is either the beginning of the buffer or position
;;  2 of some processed value.

;;  FIXME - deal with quote, unquote and unquote-append syntaxes
;;          correctly, since they produce lists of length two
;;          Current implementation jumps into cadar of that pair
;;          but traverses that value assuming it is a sequence of
;;          length two.
;;          *** Should be fixed
(defun rewriting-pcase--pcase-replace-next-sexpr (sexpr-pred)
  "Replace the next sexpr when `(SEXPR-PRED sexp)' produces a non-nil value.
SEXPR-PRED must return a singleton list.  The text corresponding to
the next sexp will be replaced with text for which the reader will
construct an object equal to the element of the list."
  (let ((pos0 (point))
	(read-attempts 0)
	eof pos1 pos2 v m)
    (while (and (not pos2) (not eof) (< read-attempts 2))
      (condition-case nil
	  ;; this will error if there are no additional expressions found
	  (setq v (read (current-buffer))
		pos2 (point))
	(invalid-read-syntax
	 (let ((p1 (rewriting-pcase--check-invalid-read pos0)))
	   (when p1
	     (setq pos1 p1
		   pos2 (point)))))
	(error (setq eof t)))
      (cl-incf read-attempts))
    (when (and pos2 (not pos1))
      ;; could push this into the cond clause for a successful
      ;; match *if* matcher was guaranteed to have no side-effects
      (setq pos1 (rewriting-pcase--back-sexpr v pos0 pos2)
            ;; m (rewriting-pcase--pcase-replace-matching-sexpr v))
	    m (funcall sexpr-pred v))
      (goto-char pos2)
      (cond
       (m (rewriting-pcase--replace-text-in-region pos1 pos2 (car m)))
       ((atom v) nil)
       ((and (not (member (char-after pos1) '(?\( ?\[)))
	     (consp v)
	     (consp (cdr v))
	     (null (cddr v))
	     (symbolp (car  v)))
	(save-excursion
	  (goto-char (rewriting-pcase--read-syntax-end pos1 (car v)))
	  (rewriting-pcase--pcase-replace-next-sexpr sexpr-pred)))
       ((or (recordp v) (arrayp v))
	(save-excursion
	  (goto-char (scan-lists pos1 1 -1))
	  (rewriting-pcase--pcase-replace-in-seq sexpr-pred 0 (length v))
	  (when (<= (point) pos1)
	    (signal 'rewriting-pcase-replace-sexpr `[,v ,pos0 ,pos1 ,pos2 ,(point)]))))
       ((consp v)
	(save-excursion
	  (goto-char (scan-lists pos1 1 -1))
	  (let ((ls v))
	    (while (consp ls)
	      (rewriting-pcase--pcase-replace-next-sexpr sexpr-pred)
	      (pop ls))
	    (when ls
	      (rewriting-pcase--pcase-replace-next-sexpr sexpr-pred)))
	  (when (<= (point) pos1)
	    (signal 'rewriting-pcase-replace-sexpr `[,v ,pos0 ,pos1 ,pos2 ,(point)]))))))
    (not eof)))

(defun rewriting-pcase--pcase-replace-in-seq (sexpr-pred i n)
  "Replace sexprs in a sequence.
Arguments:
  SEXPR-PRED - rewriting predicate
  I - index of current sexp in sequence
  N - total number of elements in sequence produced by reader"
  (while (< i n)
    (rewriting-pcase--pcase-replace-next-sexpr sexpr-pred)
    (cl-incf i)))

;; search text in current buffer for sexprs matching one of a supplied set of pcase patterns
;; if a match is found, replace the text with corresponding sexpr value
;; Replacement should not disturb relative position of the text surrounding the text
;; that produced the sexpr matching the supplied pcase pattern
(defun rewriting-pcase--pcase-replace-sexpr (sexpr-pred)
  "Search and replace textual sexprs in current buffer.
Arguments:
  SEXPR-PRED - rewriting predicate"
  (emacs-lisp-mode)
  (let ((parse-sexp-ignore-comments t))
    (save-excursion
      (goto-char (point-min))
      (while (rewriting-pcase--pcase-replace-next-sexpr sexpr-pred)))))


(provide 'rewriting-pcase)

;;; rewriting-pcase.el ends here

;; Local Variables:
;; read-symbol-shorthands: (("rp-" . "rewriting-pcase-"))
;; End:
;; 
