;;; molar-mass.el --- Calculates molar mass of a molecule
;; -*- coding: utf-8 -*-
;;
;; Copyright 2021 by Sergi Ruiz Trepat
;;
;; Author: Sergi Ruiz Trepat
;; Created: 2021
;; Version: 1.0
;; Package-Version: 20210519.1342
;; Package-Commit: 838db1486a2dc5a3774eb195d62fbcdef71a63f7
;; Keywords: convenience, chemistry
;; Homepage: https://github.com/sergiruiztrepat/molar-mass.el
;; Package-Requires: ((emacs "24.3"))
;;
;; Molar-mass is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;;; Commentary:
;; After installing the package (or copying it to your load-path), add this
;; to your init file:
;;
;; (require 'molar-mass)
;;
;; It works interactively (entering your formula at the minibuffer) and
;; also with region.
;;
;; M-x molar-mass => goes to the minibuffer.  Enter formula
;; (Ex.  KMnO4)
;;
;; It returns:
;;
;; => Molar mass of KMnO4  : 158.034 g/mol (uma)
;;
;; You can mark a region with a formula and it will give you its molar
;; mass.
;;
;; Example:
;;
;; Mark region : H2O
;; Call M-x molar-mass
;;
;; => Molar mass of H2O : 18.015 g/mol (uma)
;;
;; Molar-mass supports formulas with parentheses (Ex: Fe(OH)2), and it
;; works in LaTeX sintax (Ex: Fe(OH)_{2}).
;;
;; You can customize the result's significant decimals (default is 3):
;; M-x customize-variable > molar-mass-significant-decimals
;;
;;; Code:

(defconst molar-mass-elements-mass
  '(("H" 1.00797)
    ("He" 4.002602)
    ("Li" 6.941)
    ("Be" 9.012182)
    ("B" 10.811)
    ("C" 12.0107)
    ("N" 14.0067)
    ("O" 15.9994)
    ("F" 18.9984032)
    ("Ne" 20.1797)
    ("Na" 22.98976928)
    ("Mg" 24.305)
    ("Al" 26.9815386)
    ("Si" 28.0855)
    ("P" 30.973762)
    ("S" 32.065)
    ("Cl" 35.453)
    ("Ar" 39.948)
    ("K" 39.0983)
    ("Ca" 40.078)
    ("Sc" 44.955912)
    ("Ti" 47.867)
    ("V" 50.9415)
    ("Cr" 51.9961)
    ("Mn" 54.938045)
    ("Fe" 55.845)
    ("Ni" 58.6934)
    ("Co" 58.9332)
    ("Cu" 63.546)
    ("Zn" 65.409)
    ("Ga" 69.723)
    ("Ge" 72.64)
    ("As" 74.9216)
    ("Se" 78.96)
    ("Br" 79.904)
    ("Kr" 83.798)
    ("Rb" 85.4678)
    ("Sr" 87.62)
    ("Y" 88.90585)
    ("Zr" 91.224)
    ("Nb" 92.90638)
    ("Mo" 95.94)
    ("Tc" 98.00)
    ("Ru" 101.07)
    ("Rh" 102.9055)
    ("Pd" 106.42)
    ("Ag" 107.8682)
    ("Cd" 112.411)
    ("In" 114.818)
    ("Sn" 118.71)
    ("Sb" 121.76)
    ("Te" 127.6)
    ("I" 126.90447)
    ("Xe" 131.293)
    ("Cs" 132.9054519)
    ("Ba" 137.327)
    ("La" 138.90547)
    ("Ce" 140.116)
    ("Pr" 140.90765)
    ("Nd" 144.242)
    ("Pm" 145.00)
    ("Sm" 150.36)
    ("Eu" 151.964)
    ("Gd" 157.25)
    ("Tb" 158.92535)
    ("Dy" 162.5)
    ("Ho" 164.93032)
    ("Er" 167.259)
    ("Tm" 168.93421)
    ("Yb" 173.04)
    ("Lu" 174.967)
    ("Hf" 178.49)
    ("Ta" 180.94788)
    ("W" 183.84)
    ("Re" 186.207)
    ("Os" 190.23)
    ("Ir" 192.217)
    ("Pt" 195.084)
    ("Au" 196.966569)
    ("Hg" 200.59)
    ("Tl" 204.3833)
    ("Pb" 207.2)
    ("Bi" 208.9804)
    ("Po" 209.00)
    ("At" 210.00)
    ("Rn" 222.00)
    ("Fr" 223.00)
    ("Ra" 226.00)
    ("Ac" 227.00)
    ("Th" 232.03806)
    ("Pa" 231.03588)
    ("U" 238.02891)
    ("Np" 237.00)
    ("Am" 243.00)
    ("Pu" 244.00)
    ("Cm" 247.00)
    ("Bk" 247.00)
    ("Cf" 251.00)
    ("Es" 252.00)
    ("Fm" 257.00)
    ("Md" 258.00)
    ("No" 259.00)
    ("Lr" 262.00)
    ("Rf" 261.00)
    ("Db" 262.00)
    ("Sg" 266.00)
    ("Bh" 264.00)
    ("Hs" 277.00)
    ("Mt" 268.00)
    ("Ds" 281.00)
    ("Rg" 272.00)
    ("Cn" 285.00)
    ("Nh" 286.00)
    ("Fl" 289.00)
    ("Mc" 290.00)
    ("Lv" 292.00)
    ("Ts" 294.00)
    ("Og" 294.00)))

(defcustom molar-mass-significant-decimals 3
  "Number of significant decimals of the result of molar mass."
  :type '(integer)
  :group 'molar-mass)

;;;###autoload
(defun molar-mass ()
  "Calculates molar mass of a molecule."
  (interactive)
  (let* ((data (if (region-active-p)
		   (buffer-substring-no-properties
		    (region-beginning)
		    (region-end))
		 (read-string "Formula: ")))
	 (elements (mapcar #'char-to-string data))
	 (result-string-format
	  (concat "Molar mass of %s: %."
		  (int-to-string molar-mass-significant-decimals)
		  "f g/mol (uma)"))
	 (elements-aux '()))   ;; auxiliar list to clean blanks and
                               ;; dashes in the next while
    
    (while elements
      (if (not (member (car elements) '(" " "-" "_" "{" "}")))
	  (push (car elements) elements-aux))
      (setq elements (cdr elements)))
    (setq elements (reverse elements-aux))

    (if (molar-mass-missing-paren elements)
	(molar-mass-error-lacks-paren))
    
    (setq elements (molar-mass-join-letters elements))
    (setq elements (molar-mass-join-numbers elements))
    (setq elements (molar-mass-insert-1 elements))
    (setq elements (molar-mass-subst-numbers elements))
    (setq elements (molar-mass-subst-values elements))
        
    (message result-string-format
	     data
	     (molar-mass-calculate elements))))

;;
;; Functions to process string formula
;; 

(defun molar-mass-join-letters (elem)
  "Join upcase and downcase letters in list ELEM."
  (let (first second elem-aux)
    (while elem
      (setq first (car elem))
      (setq second (cadr elem))
      (if (and
	   (molar-mass-upcase-p first)
	   (molar-mass-downcase-p second))
	  (progn
	    (setq elem-aux (cons (concat first second) elem-aux))
	    (setq elem (cddr elem)))
	(setq elem-aux (cons first elem-aux))
	(setq elem (cdr elem))))
    (reverse elem-aux)))

(defun molar-mass-join-numbers (elem)
  "Join numbers when there are two of them one after another in list ELEM."
  (let (first second elem-aux)
    (while elem
      (setq first (car elem))
      (setq second (cadr elem))
      (if (and
	   (molar-mass-number-p first)
	   (molar-mass-number-p second))
	  (progn
	    (setq elem-aux (cons (concat first second) elem-aux))
	    (setq elem (cddr elem)))
	(setq elem-aux (cons first elem-aux))
	(setq elem (cdr elem))))
    (reverse elem-aux)))

(defun molar-mass-insert-1 (elem)
  "Insert number 1 when an element has no coeficient in list ELEM."
  (let (first second elem-aux)
    (while elem
      (setq first (car elem))
      (setq second (cadr elem))
      (if (and
	   (not (molar-mass-number-p first))
	   (not (molar-mass-paren-p first))
	   (not (molar-mass-number-p second)))
	  (progn
	    (setq elem-aux (cons first elem-aux))
	    (setq elem-aux (cons "1" elem-aux))
	    (setq elem (cdr elem)))
	(setq elem-aux (cons first elem-aux))
	(setq elem (cdr elem))))
    (reverse elem-aux)))

(defun molar-mass-subst-numbers (elem)
  "Substitute number-strings for integers in list ELEM."
  (let (item elem-aux)
    (dolist (item elem elem-aux)
      (if (molar-mass-number-p item)
	  (push (string-to-number item) elem-aux)
	(push item elem-aux)))
    (reverse elem-aux)))

(defun molar-mass-subst-values (elem)
  "Substitutes the name of an element for its molar mass in list ELEM."
  (let (item elem-aux)
    (dolist (item elem elem-aux)
      (if (and (stringp item)
	       (not (molar-mass-paren-p item)))
	  (if (not (cadr (assoc item molar-mass-elements-mass)))
	      (molar-mass-error-non-valid-element item)
	    (push (cadr (assoc item molar-mass-elements-mass)) elem-aux))
	(push item elem-aux)))
    (reverse elem-aux)))

;;
;; Main calculation function
;;

(defun molar-mass-calculate (elem)
  "Calculate molar mass of data in list ELEM."
  (let ((total 0) first second)
    (while elem
      (if (equal (car elem) "(")
	  (progn
	    (setq first (molar-mass-calculate
			 (molar-mass-cut-list-in elem "(" ")")))
	    (setq elem (molar-mass-cut-list-out elem "(" ")"))
	    (if (integerp (car elem))
		(setq second (car elem))
	      (molar-mass-error-lacks-number)))
	(setq first (car elem))
	(setq second (cadr elem)))
      (setq total (+ total (* first second)))
      (setq elem (cddr elem)))
    total))

;;
;; Cut list functions (to handle parenthesis)
;;
(defun molar-mass-cut-list-in (list first last)
  "Cut LIST and return another list with elements between FIRST and LAST."
  (let ((cut-list '())) ;; list to return
    (setq list (cdr (member first list)))
    (while (and list (not (equal (car list) last)))
      (push (car list) cut-list)
      (setq list (cdr list)))
    (reverse cut-list)))

(defun molar-mass-cut-list-out (list first last)
  "Cut LIST and return another list with elements not between FIRST and LAST."
  (let ((cut-list '()))
    (while (not (equal (car list) first))
      (push (car list) cut-list)
      (setq list (cdr list)))

    (while (not (equal (car list) last))
      (pop list))
    
    (setq list (cdr list))
    (while list
      (push (car list) cut-list)
      (setq list (cdr list)))
    (reverse cut-list)))

;;
;; Predicate functions
;;

(defun molar-mass-upcase-p (char)
  "Return t if CHAR is upcase, nil if not."
  (let ((case-fold-search nil))
    (and char (string-match-p "[A-Z]" char))))

(defun molar-mass-downcase-p (char)
  "Return t if CHAR is downcase, nil if not."
  (let ((case-fold-search nil))
    (and char (string-match-p "[a-z]" char))))
      
(defun molar-mass-number-p (char)
  "Return t if CHAR is a number, nil if not."
  (and char (string-match-p "[0-9]" char) t))

(defun molar-mass-paren-p (char)
  "Return t if CHAR is parentheses, nil if not."
  (and char (string-match-p "[()]" char) t))

(defun molar-mass-missing-paren (elem)
  "Return t if there is missing paren in list ELEM."
  (or (and
       (member "(" elem) (not (member ")" elem)))
      (and
       (member ")" elem) (not (member "(" elem)))))

;;
;; Error functions
;;

(defun molar-mass-error-lacks-number ()
  "Error function when lacks a number after parentheses."
  (user-error "Error: Lacks a number after closing parentheses"))

(defun molar-mass-error-lacks-paren ()
  "Error function when lacks parentheses."
  (user-error "Error: Lacks parentheses"))

(defun molar-mass-error-non-valid-element (error-data)
  "ERROR-DATA provides the letter not corresponding to an element."
  (user-error "Error: %s is not a valid element" error-data))

(provide 'molar-mass)

;;; molar-mass.el ends here
