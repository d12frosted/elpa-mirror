;;; chembalance.el --- Balance chemical equations -*- lexical-binding: t -*-
;; -*- coding: utf-8 -*-
;;
;; Copyright 2021 by Sergi Ruiz Trepat
;;
;; Author: Sergi Ruiz Trepat
;; Created: 2021
;; Version: 1.0
;; Package-Version: 20210601.1653
;; Package-Commit: ae36c823ca151f1dc6144ec96b2f5e98181c0dbb
;; Keywords: convenience, chemistry
;; Homepage: https://github.com/sergiruiztrepat/chembalance
;; Package-Requires: ((emacs "24.4"))
;;
;; Chembalance is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;;; Commentary:
;;
;; Balance chemical equations.
;;
;; Installation:
;;
;; After installing the package (or copying it to your load-path), add this
;; to your init file:
;;
;; (require 'chembalance)
;;
;; It works interactively (entering your equation at the minibuffer) and
;; also with region.
;;
;; M-x chembalance => goes to the minibuffer.  Enter equation.
;; (Ex.  FeS + O2 => Fe2O3 + SO2)
;;
;; It returns:
;;
;; => Balanced reaction : 4 FeS + 7 O2 => 2 Fe2O3 + 4 SO2
;;
;; You can also use it to check if a reaction is already balanced.
;;
;; You can mark a region with a chemical equation and then M-x
;; chembalance.  It will give you the balanced equation.
;;
;; Chembalance supports formulas with parentheses (Ex: Fe(OH)2)
;;
;; Customize:
;; 
;; To customize chembalance, do M-x customize-group RET chembalance.
;;
;; There are two custom variables:
;;
;; chembalance-arrow-syntax (list of accepted arrows).
;;
;; chembalance-insert-string (if non-nil, when you call chembalance with
;; selected region, chembalance will kill that region and insert the
;; balanced reaction).
;;
;; Please, email me your comments, bugs, improvements or opinions on
;; this package to sergi.ruiz.trepat@gmail.com
;;
;;; Code:

(require 'calc-ext)
(require 'cl-lib)
(require 'subr-x)

(defvar calc-command-flags)

(defconst chembalance-elements
  '("H" "He" "Li" "Be" "B" "C" "N" "O" "F" "Ne"
 "Na" "Mg" "Al" "Si" "P" "S" "Cl" "Ar" "K" "Ca"
 "Sc" "Ti" "V" "Cr" "Mn" "Fe" "Ni" "Co" "Cu" "Zn"
 "Ga" "Ge" "As" "Se" "Br" "Kr" "Rb" "Sr" "Y" "Zr"
 "Nb" "Mo" "Tc" "Ru" "Rh" "Pd" "Ag" "Cd" "In"
 "Sn" "Sb" "Te" "I" "Xe" "Cs" "Ba" "La" "Ce" "Pr"
 "Nd" "Pm" "Sm" "Eu" "Gd" "Tb" "Dy" "Ho" "Er"
 "Tm" "Yb" "Lu" "Hf" "Ta" "W" "Re" "Os" "Ir"
 "Pt" "Au" "Hg" "Tl" "Pb" "Bi" "Po" "At" "Rn"
 "Fr" "Ra" "Ac" "Th" "Pa" "U" "Np" "Am" "Pu" "Cm"
 "Bk" "Cf" "Es" "Fm" "Md" "No" "Lr" "Rf" "Db"
 "Sg" "Bh" "Hs" "Mt" "Ds" "Rg" "Cn" "Nh" "Fl"
 "Mc" "Lv" "Ts" "Og"))

(defcustom chembalance-insert-string t
  "If non-nil, insert balanced reaction in place of region active."
  :type 'boolean
  :group 'chembalance)

(defcustom chembalance-arrow-syntax '("=" "=>" "→")
  "Types of accepted arrows.  If = or > are in, they must be before =>."
  :type 'list
  :group 'chembalance)

(defun chembalance-arrow (data)
  "Return the arrow in DATA when it is in custom arrow-syntax."
  (let (arrow)
    (dolist (arrow-try chembalance-arrow-syntax)
      (when (string-match arrow-try data)
	(setq arrow arrow-try)))
      (unless arrow
	(user-error "There is no arrow in equation or it is not in arrow-syntax.\nPlease M-x customize-variable RET arrow-syntax"))
    arrow))
;;
;; Main function
;;

;;;###autoload
(defun chembalance (&optional data)
  "Balance reaction in string DATA."
  (interactive)
  (let* ((data (if data
		   data
		 (if (region-active-p)
		     (buffer-substring-no-properties
		      (region-beginning)
		      (region-end))
		   (read-string "Reaction: "))))
	 (arrow (chembalance-arrow data))
	 reactives
	 products
	 reactives-coeficients
	 products-coeficients
	 reactives-hash
	 products-hash
	 process-matrix
	 results
	 reactives-process
	 products-process
	 output)
		    
    (setq reactives (car (split-string data arrow)))
    (setq products (cadr (split-string data arrow)))
    (setq reactives-coeficients (mapcar #'string-to-number
					(car (chembalance-coeficients reactives))))
    (setq products-coeficients (mapcar #'string-to-number
				       (car (chembalance-coeficients products))))
    (setq reactives (cadr (chembalance-coeficients reactives)))
    (setq products (cadr (chembalance-coeficients products)))

;;    process strings to their parts
    
    (setq reactives-process (mapcar #'chembalance-process-compound-string
				    reactives))
    (setq products-process (mapcar #'chembalance-process-compound-string
				  products))
    ;;Is balanced?
    (if	(chembalance-is-balanced
	 (chembalance-total-with-coeficients reactives-process
					 reactives-coeficients)
	 (chembalance-total-with-coeficients  products-process
					  products-coeficients))
	(message "Reaction is balanced.")
      
      ;; Is not balanced:
      (setq reactives-hash (chembalance-total-by-element
			   reactives-process))
      (setq products-hash (chembalance-total-by-element
			  products-process))
      (setq process-matrix (chembalance-process-matrix
			    (chembalance-matrix reactives-process
					    reactives-hash)
			    (chembalance-matrix products-process
					    products-hash)))
            
      (unless (chembalance-check-reaction reactives-hash products-hash)
	(user-error "Error: reactives and products elements are not the same? "))
      ;; Calculation
      (calc nil nil nil)
      (let ((calc-prefer-frac t))
	(setq results (chembalance-to-integers
		       (chembalance-calc-results process-matrix))))
      (calc nil nil nil)
      
    ;; Output string
    (when results
      (setq output
	    (chembalance-concat-results reactives products results
				    arrow)))
    (if (and chembalance-insert-string
	     (region-active-p)
	     (not buffer-read-only))
	(progn
	  (kill-region (region-beginning) (region-end))
	  (insert output)
	  (message "Balanced reaction: %s" output))
      (message "Balanced reaction: %s" output)))))
    
;;
;;Functions to check reaction
;;

(defun chembalance-check-reaction (reactives-hash products-hash)
  "Return t if elements in REACTIVES-HASH and PRODUCTS-HASH are the same."

  (let ((reactive-elements (hash-table-keys reactives-hash))
	(product-elements (hash-table-keys products-hash)))

    (equal (sort reactive-elements #'string<)
	(sort product-elements #'string<))))

;;
;; Functions to get last output string
;;

(defun chembalance-concat-results (reactives products coeficients arrow)
  "Concat REACTIVES and PRODUCTS with COEFICIENTS, joining then with ARROW."
  (let (output coef)
    (while reactives
      (setq coef (car coeficients))
      (when (equal coef "1")
	(setq coef nil))
      (setq output (concat output coef " " (pop reactives) " + "))
      (setq coeficients (cdr coeficients)))
    
    (setq output (concat (substring output 0 -2) arrow " "))
    
    (while products
      (setq coef (car coeficients))
      (when (equal coef "1")
	(setq coef nil))
      (setq output (concat output coef " " (pop products) " + "))
      (setq coeficients (cdr coeficients)))
			   
    (substring output 0 -3)))

;;
;; Functions to process matrix
;;

(defun chembalance-matrix (compounds hash)
  "Convert COMPOUNDS to a matrix, HASH is only used to get its keys."
  (let (elements row matrix)
    (setq elements (hash-table-keys hash))
    (setq elements (sort elements #'string<))
    (dolist (elt elements)
      (dolist (compound compounds)
	(if (not (member elt compound))
	    (push 0 row)
	  (while compound
	    (when (equal elt (car compound))
	      (push (cadr compound) row))
	    (setq compound (cdr compound)))))
      (push (reverse row) matrix)
      (setq row '()))
    (reverse matrix)))

(defun chembalance-process-matrix (m1 m2)
  "Process matrix M1 and M2 to prepare them to lineal algebra.
M1 comes from (chembalance-matrix reactives-process reactives-hash).
M2 comes from (chembalance-matrix products-process products-hash)."
  (let (matneg   ;; part of m2 which will append to M1
	aux1     ;; auxiliar list
	aux2     ;; auxiliar list
	matrix)  ;; result matrix
    (setq matneg (mapcar (lambda (x) (butlast x 1)) m2))
    (dolist (row matneg)
      (cl-mapcar (lambda (x) (push (- x) aux1)) row)
      (push (reverse aux1) aux2)
      (setq aux1 '()))
    (setq matneg (reverse aux2))
    (setq m1 (cl-mapcar (lambda (x y) (append x y)) m1 matneg))
    (setq m2 (cl-mapcan #'last m2))
    (push m2 matrix)
    (push m1 matrix)
    matrix))

;;
;; Functions to know if reaction is balanced
;;

(defun chembalance-is-balanced (reactives products)
  "Compare total of hash-tables REACTIVES and PRODUCTS.
Thanks to RNA."
  (and (= (hash-table-count reactives)
          (hash-table-count products))
       (catch 'flag (maphash (lambda (x y)
                               (or (equal (gethash x products) y)
                                   (throw 'flag nil)))
                             reactives)
              (throw 'flag t))))

(defun chembalance-total-with-coeficients (compounds coeficients)
  "Return hash table of COMPOUNDS times COEFICIENTS to know if reaction is balanced."
  (let ((hash (make-hash-table :test 'equal))
	coef
	value)
    (dolist (compound compounds)

      (setq coef (car coeficients))
      (while compound
	(setq value (cadr compound))
	(if (gethash (car compound) hash)
	    (puthash (car compound) (+ (* coef value)
				       (gethash (car compound) hash)) hash)
	  (puthash (car compound) (* coef value) hash))
	(setq compound (cddr compound)))
      (setq coeficients (cdr coeficients)))
    hash))

(defun chembalance-total-by-element (compounds)
  "Return hash-table with each element in COMPOUNDS and its total value."
  (let ((compound-hash (make-hash-table :test 'equal)) element val)
    (dolist (elt compounds)
      (while elt
	(setq element (car elt))
	(if (not (gethash element compound-hash))
	    (puthash element (cadr elt) compound-hash)
	  (setq val (gethash element compound-hash))
	  (puthash element (+ val (cadr elt)) compound-hash))
	(setq elt (cddr elt))))
    compound-hash))

;;
;; Functions to process string equation
;;

(defun chembalance-process-compound-string (compound)
  "Process input string COMPOUND and return a list ready to calculate."
  (setq compound (mapcar #'char-to-string compound))
  (setq compound (chembalance-subst-numbers
		  (chembalance-insert-1
		   (chembalance-join-numbers
		    (chembalance-join-letters
		     (chembalance-clean-special-chars compound))))))
  
  ;; paren error
  (when (and (member ")" compound)
	     (not (member "(" compound)))
    (user-error "Error: lacks opening parentheses in formula? "))
  
  ;; handle parens
  (when (member "(" compound)
    (unless (member ")" compound)
      (user-error "Error: lacks closing parentheses in formula? "))
    (setq compound (chembalance-cancel-parens compound)))
  
  (dolist (c compound)
    (when (and (stringp c)
	       (not (chembalance-number-p c))
	       (not (member c chembalance-elements)))
      (user-error "Error: %s is not an element" c)))
  compound)

(defun chembalance-clean-special-chars (elements)
  "Clean list ELEMENTS of special characters like dashes or spaces."
  (let (elements-aux)
    (while elements
      (unless (member (car elements) '(" " "-" "_" "{" "}"))
	  (push (car elements) elements-aux))
      (setq elements (cdr elements)))
    (reverse elements-aux)))
  
(defun chembalance-join-letters (elements)
  "Join upcase and downcase letters in list ELEMENTS."
  (let (first second elements-aux)
    (while elements
      (setq first (car elements))
      (setq second (cadr elements))
      (if (and
	   (chembalance-upcase-p first)
	   (chembalance-downcase-p second))
	  (progn
	    (setq elements-aux (cons (concat first second) elements-aux))
	    (setq elements (cddr elements)))
	(setq elements-aux (cons first elements-aux))
	(setq elements (cdr elements))))
    (reverse elements-aux)))

(defun chembalance-join-numbers (elements)
  "Join numbers when there are two of them one after another in list ELEMENTS."
  (let (first second elements-aux)
    (while elements
      (setq first (car elements))
      (setq second (cadr elements))
      (if (and
	   (chembalance-number-p first)
	   (chembalance-number-p second))
	  (progn
	    (setq elements-aux (cons (concat first second) elements-aux))
	    (setq elements (cddr elements)))
	(setq elements-aux (cons first elements-aux))
	(setq elements (cdr elements))))
    (reverse elements-aux)))

(defun chembalance-insert-1 (elements)
  "Insert number 1 when an element has no coeficient in list ELEMENTS."
  (let (first second elements-aux)
    (while elements
      (setq first (car elements))
      (setq second (cadr elements))
      (if (and
	   (not (chembalance-number-p first))
	   (not (chembalance-paren-p first))
	   (not (chembalance-number-p second)))
	  (progn
	    (setq elements-aux (cons first elements-aux))
	    (setq elements-aux (cons "1" elements-aux))
	    (setq elements (cdr elements)))
	(setq elements-aux (cons first elements-aux))
	(setq elements (cdr elements))))
    (reverse elements-aux)))

(defun chembalance-subst-numbers (elements)
  "Substitute number-strings for integers in list ELEMENTS."
  (let (item elements-aux)
    (dolist (item elements elements-aux)
      (if (chembalance-number-p item)
	  (push (string-to-number item) elements-aux)
	(push item elements-aux)))
    (reverse elements-aux)))

;;
;;Handle coeficients before each compound
;;

(defun chembalance-coeficients (compounds-string)
  "Extract coeficients from COMPOUNDS-STRING.
And return a list which car is coeficients and cdr is a list of
strings without coeficients."
  (let (coeficients char coef compound compounds rest)
    
    (setq compounds-string (replace-regexp-in-string " " ""
						     compounds-string))
    (setq compounds (split-string compounds-string "+"))
    (while compounds
      (setq compound (car compounds))
      (setq char (substring compound 0 1))
      (while (chembalance-number-p char)
	(setq coef (concat coef char))
	(setq compound (substring compound 1))
	(setq char (substring compound 0 1)))
    
      (if (not coef)
	  (progn
	    (push "1" coeficients)
	    (push compound rest))
	(push coef coeficients)
	(push (substring (car compounds)
			 (string-match-p char (car compounds))) rest))
	
      (setq coef nil)
      (setq compounds (cdr compounds)))
    (append (list (reverse coeficients))
	    (list (reverse rest)))))

;;
;; Functions to handle parenthesis
;;

(defun chembalance-cut-list-in (list first last)
  "Cut LIST and return another list with elements between FIRST and LAST."
  (let ((cut-list '())) ;; list to return
    (setq list (cdr (member first list)))
    (while (and list (not (equal (car list) last)))
      (push (car list) cut-list)
      (setq list (cdr list)))
    (reverse cut-list)))

(defun chembalance-cut-list-out (list first last)
  "Cut LIST and return another list with elements not between FIRST and LAST."
  (let ((cut-list '()))
    (while (not (equal (car list) first))
      (push (car list) cut-list)
      (setq list (cdr list)))

    (while (not (equal (car list) last))
      (pop list))
    
    (setq list (cddr list)) ;;jumps over coeficient
    (while list
      (push (car list) cut-list)
      (setq list (cdr list)))
    (reverse cut-list)))

(defun chembalance-coeficient (compound)
  "Return coeficient after closing parenthesis in COMPOUND."
  (cadr (member ")" compound)))

(defun chembalance-cancel-parens (compound)
  "Cancel parenthesis in COMPOUND by multiplying with coeficient."
  (let ((inside (chembalance-cut-list-in compound "(" ")"))
	(outside (chembalance-cut-list-out compound "(" ")"))
	(coeficient (chembalance-coeficient compound))
	(inside-hash (make-hash-table :test 'equal))
	value          ;; value of element inside paren
	hash-value     ;; value of recorded element in hash-table
	element)
    
    (while inside
      (setq element (car inside))
      (setq value (cadr inside))
      (if (not (gethash element inside-hash))
	  (puthash element (* value coeficient) inside-hash)
	(setq hash-value (gethash element inside-hash))
	(puthash element (+ hash-value (* value coeficient)) inside-hash))
      (setq inside (cddr inside)))
    
    (while outside
      (setq element (car outside))
      (setq value (cadr outside))
      (if (gethash element inside-hash)
	  (puthash element (+ value
			      (gethash element inside-hash)) inside-hash)
	(puthash element value inside-hash))
      (setq outside (cddr outside)))
    
    (maphash (lambda (elt val)
	       (push val outside)
	       (push elt outside)) inside-hash)
   outside))

;;
;;Functions to prepare matrix
;;

(defun chembalance-string-to-calc (matrix)
  "Make string to ‘calc-eval’ from MATRIX.
MATRIX comes from (chembalance-process-matrix m1 m2)."
  (let ((m1 (car matrix))
	(m2 (cadr matrix))
	str  ;; string to return
	aux) ;; auxiliar list
    (dotimes (count (length m2))
      (push (mapcar #'int-to-string (nth count m1)) str))
    (setq aux (reverse str))
    (setq str "[")
    (dolist (s1 aux)
      (setq str (concat str "["))
      (dolist (s s1)
	(setq str (concat str " " s)))
      (setq str (concat str "]")))
    (setq str (concat str "]^-1*["))
    (setq m2 (mapcar #'int-to-string m2))
    (dolist (s m2)
      (setq str (concat str " "s)))
    (setq str (concat str "]"))
    str))

(defun chembalance-square-matrix (matrix)
  "Return a square matrix from MATRIX."
  (let ((rows (length (car matrix)))
	(cols (length (caar matrix)))
	(matrix-incognits (car matrix))
	(independents (cadr matrix))
	new-matrix
	new-independents)

    (if (/= rows cols)
	(progn
	  (dotimes (x cols)
	    (push (nth x matrix-incognits) new-matrix)
	    (push (nth x independents) new-independents))
	  (append (list (reverse new-matrix))
		  (list (reverse new-independents))))
      matrix)))

(defun chembalance-calc-results (matrix)
  "Return results in fractions of MATRIX."
  (let (square-matrix
	string-to-calc
	results)
    (while (or (not results)
	       (string-match "\\[\\[" results)) ; no solution
      (setq square-matrix (chembalance-square-matrix matrix))
      (setq string-to-calc (chembalance-string-to-calc square-matrix))
      (setq results (calc-eval string-to-calc))
      ;; new square matrix
      (setq matrix (append (list (cdar matrix))
			   (list (cdadr matrix)))))
    
    results))

;; Functions to calculate final coeficients

(defun chembalance-lcm (results)
  "Return lcm of RESULTS (string coming from calc-eval in frac-mode)."
  (let (numbers divisors)
    (setq numbers (split-string (substring results 1 -1) ", "))
    (dolist (x numbers)
      (if (string-match ":" x)
	  (push (substring x (1+ (string-match ":" x))) divisors)))
;;	(push x divisors))) ;;;; point
    
    (setq divisors (mapcar #'string-to-number divisors))
    (apply #'cl-lcm divisors)))

(defun chembalance-to-integers (solutions)
  "Convert SOLUTIONS from fractions to integers.
Using lcm of their denominators"
  (let ((lcm (number-to-string (chembalance-lcm solutions)))
	numbers
	string-to-calc
	results)
    (setq numbers (split-string (substring solutions 1 -1) ", "))
    (setq numbers (append numbers (list "1"))) ;; last is always 1
    (dolist (num numbers)
      (setq string-to-calc (concat num " * " lcm))
      (push (calc-eval string-to-calc) results))
    
    (reverse results)))

;;
;; Predicate functions
;;

(defun chembalance-upcase-p (char)
  "Return t if CHAR is upcase, nil if not."
  (let ((case-fold-search nil))
    (and char (string-match-p "[A-Z]" char))))

(defun chembalance-downcase-p (char)
  "Return t if CHAR is downcase, nil if not."
  (let ((case-fold-search nil))
    (and char (string-match-p "[a-z]" char))))
      
(defun chembalance-number-p (char)
  "Return t if CHAR is a number, nil if not."
  (and char (string-match-p "[0-9]" char) t))

(defun chembalance-paren-p (char)
  "Return t if CHAR is parentheses, nil if not."
  (and char (string-match-p "[()]" char) t))

(provide 'chembalance)
;;; chembalance.el ends here
