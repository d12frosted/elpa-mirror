;;; units-mode.el --- Mode for conversion between different units -*- lexical-binding: t -*-

;; Copyright (C) 2022

;; Author: Gaurav Atreya <allmanpride@gmail.com>
;; Maintainer:
;; URL: https://github.com/Atreyagaurav/units-mode
;; Package-Version: 20221027.303
;; Package-Commit: 10c8de24180f87b1a8a3b0a9b3fbb29eec925417
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; Homepage: https://github.com/Atreyagaurav/units-mode
;; Keywords: units,unit-conversion,convenience


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; This is Emacs interface to gnu units program <https://www.gnu.org/software/units/units.html>.

;; For detailed help visit github page:
;; https://github.com/Atreyagaurav/units-mode

;;; Code:
(eval-when-compile (require 'subr-x))
(require 'cl-lib)

(defcustom units-binary-path "units"
  "Path to the units binary." :group 'units :type 'string)

(defvar units-default-args "-t"
  "Default args to add to units command.")

(defcustom units-user-args ""
  "Extra args for user to add to units command."
  :group 'units :type 'string)

(defcustom units-insert-separator " = "
  "Separator to insert before inserting the `units' outputs."
  :group 'units :type 'string)

(defun units-command (args)
  "Run the units command with ARGS and return the output."
  (string-trim-right
   (shell-command-to-string
    (format "%s %s %s %s"
	    units-binary-path
	    units-default-args
	    units-user-args
	    (mapconcat
	     #'shell-quote-argument
	     args " ")))))


(defun units-convert (value to-unit)
  "Convert VALUE to TO-UNIT unit."
  (let ((out-lines (split-string
		     (units-command (list value to-unit)) "\n")))
    (if (and (= (length out-lines) 1)
	     (string-match-p "^[0-9.e;]+$"
			     (car out-lines)))
	(car out-lines)
      (user-error "%s" (string-join out-lines "\n")))))

(defun units-convert-single (value from-unit to-unit)
  "Convert a single VALUE from FROM-UNIT to TO-UNIT."
  (units-convert (format "%s %s" value from-unit) to-unit))

(defun units-convert-simple (value from-unit to-unit)
  "Convert a single VALUE from FROM-UNIT to TO-UNIT."
  (read
   (units-convert
    (format "%s %s" value from-unit) to-unit)))

(defun units-convert-formatted (value to-unit)
  "Convert VALUE to TO-UNIT and format the output."
  (let ((converted (units-convert value to-unit)))
    (if (cl-search ";" to-unit)
	(let ((values (split-string converted ";"))
	      (units (split-string to-unit ";")))
	  (string-join
	   (cl-loop for val in values
		    for unt in units
		    if (> (string-to-number val) 0)
		    collect (format "%s %s" val unt)) " + "))
      (format "%s %s" converted to-unit))))


(defun units-conformable-list (value)
  "Conformable units list related to VALUE."
  (let ((output (units-command `("--conformable"
				 ,value))))
    (if (not (string-match-p "Unknown unit" output))
	      (split-string output
	       "\n")
      (user-error output))))


(defun units-get-interactive-args ()
  "Get Args for interactive input of REGION-TEXT and TO-UNITS."
  (let ((region-text
	  (buffer-substring-no-properties
	   (region-beginning) (region-end))))
      (list region-text
	    (completing-read
	     "Convert to: "
	     (units-conformable-list region-text)))))

(defun units-convert-region (region-text to-unit)
  "Convert the marked REGION-TEXT to TO-UNIT."
  (interactive (units-get-interactive-args))
  (message "%s" (units-convert-formatted region-text to-unit)))

(defun units-reduce (value)
  "Reduce the VALUE to standard units."
  (message "%s" (units-command `(,value))))

(defun units-reduce-region (beg end)
  "Reduce the region (BEG to END) to standard units."
  (interactive "r")
  (message "%s" (units-reduce
		 (buffer-substring-no-properties beg end))))

(defun units-reduce-region-and-insert (beg end)
  "Reduce the region (BEG to END) to standard units and insert the results."
  (interactive "r")
  (goto-char end)
  (insert units-insert-separator
	  (units-reduce-region beg end)))

(defun units-convert-region-and-insert (region-text to-unit)
  "Convert REGION-TEXT to TO-UNIT and insert the results."
  (interactive (units-get-interactive-args))
  (goto-char (region-end))
  (insert units-insert-separator
	  (units-convert-region region-text to-unit)))

(defun units-quick-convert (ins expression unit)
  "quicky convert EXPRESSION to UNIT. Insert if INS not nil."
  (interactive (let ((expression (read-string "Expression: ")))
		 (list current-prefix-arg
		       expression
		       (completing-read
			"Convert to: "
			(units-conformable-list expression)))))
  (let ((expr (message "%s %s" (units-convert expression unit) unit)))
    (if ins (insert expr))))

(defun units-quick-reduce (ins expression)
  "Quickly reduce EXPRESSION to SI units, insert if INS not nil."
  (interactive "P\nsExpression: ")
  (let ((expr (units-reduce expression)))
    (if ins (insert expr))))

(defun units-read (value &optional convert-to)
  "Read the numeric value from VALUE optionally convert it to CONVERT-TO unit."
  (if convert-to
      (read (units-convert value convert-to))
    (if (string-match "\\([0-9.]+\\)" value)
	(read (match-string 1 value))
      (error "No values to read"))))

(defun units-ignore (value unit)
  "Read the numeric value from VALUE and ignore UNIT."
  (ignore unit)
  value)

;; Molecular weight related

;; list copied from: https://www.periodictable.one/elements/
(setq units-all-elements
      (list
       '("H" . "hydrogen")
       '("He" . "helium")
       '("Li" . "lithium")
       '("Be" . "beryllium")
       '("B" . "boron")
       '("C" . "carbon")
       '("N" . "nitrogen")
       '("O" . "oxygen")
       '("F" . "fluorine")
       '("Ne" . "neon")
       '("Na" . "sodium")
       '("Mg" . "magnesium")
       '("Al" . "aluminium")
       '("Si" . "silicon")
       '("P" . "phosphorus")
       '("S" . "sulfur")
       '("Cl" . "chlorine")
       '("Ar" . "argon")
       '("K" . "potassium")
       '("Ca" . "calcium")
       '("Sc" . "scandium")
       '("Ti" . "titanium")
       '("V" . "vanadium")
       '("Cr" . "chromium")
       '("Mn" . "manganese")
       '("Fe" . "iron")
       '("Co" . "cobalt")
       '("Ni" . "nickel")
       '("Cu" . "copper")
       '("Zn" . "zinc")
       '("Ga" . "gallium")
       '("Ge" . "germanium")
       '("As" . "arsenic")
       '("Se" . "selenium")
       '("Br" . "bromine")
       '("Kr" . "krypton")
       '("Rb" . "rubidium")
       '("Sr" . "strontium")
       '("Y" . "yttrium")
       '("Zr" . "zirconium")
       '("Nb" . "niobium")
       '("Mo" . "molybdenum")
       '("Tc" . "technetium")
       '("Ru" . "ruthenium")
       '("Rh" . "rhodium")
       '("Pd" . "palladium")
       '("Ag" . "silver")
       '("Cd" . "cadmium")
       '("In" . "indium")
       '("Sn" . "tin")
       '("Sb" . "antimony")
       '("Te" . "tellurium")
       '("I" . "iodine")
       '("Xe" . "xenon")
       '("Cs" . "cesium")
       '("Ba" . "barium")
       '("La" . "lanthanum")
       '("Ce" . "cerium")
       '("Pr" . "praseodymium")
       '("Nd" . "neodymium")
       '("Pm" . "promethium")
       '("Sm" . "samarium")
       '("Eu" . "europium")
       '("Gd" . "gadolinium")
       '("Tb" . "terbium")
       '("Dy" . "dysprosium")
       '("Ho" . "holmium")
       '("Er" . "erbium")
       '("Tm" . "thulium")
       '("Yb" . "ytterbium")
       '("Lu" . "lutetium")
       '("Hf" . "hafnium")
       '("Ta" . "tantalum")
       '("W" . "tungsten")
       '("Re" . "rhenium")
       '("Os" . "osmium")
       '("Ir" . "iridium")
       '("Pt" . "platinum")
       '("Au" . "gold")
       '("Hg" . "mercury")
       '("Tl" . "thallium")
       '("Pb" . "lead")
       '("Bi" . "bismuth")
       '("Po" . "polonium")
       '("At" . "astatine")
       '("Rn" . "radon")
       '("Fr" . "francium")
       '("Ra" . "radium")
       '("Ac" . "actinium")
       '("Th" . "thorium")
       '("Pa" . "protactinium")
       '("U" . "uranium")
       '("Np" . "neptunium")
       '("Pu" . "plutonium")
       '("Am" . "americium")
       '("Cm" . "curium")
       '("Bk" . "berkelium")
       '("Cf" . "californium")
       '("Es" . "einsteinium")
       '("Fm" . "fermium")
       '("Md" . "mendelevium")
       '("No" . "nobelium")
       '("Lr" . "lawrencium")
       '("Rf" . "rutherfordium")
       '("Db" . "dubnium")
       '("Sg" . "seaborgium")
       '("Bh" . "bohrium")
       '("Hs" . "hassium")
       '("Mt" . "meitnerium")
       '("Ds" . "darmstadtium")
       '("Rg" . "roentgenium")
       '("Cn" . "copernicium")
       '("Nh" . "nihonium")
       '("Fl" . "flerovium")
       '("Mc" . "moscovium")
       '("Lv" . "livermorium")
       '("Ts" . "tennessine")
       '("Og" . "oganesson")))

(defun units-atomic-weight (element)
  "Calculate the atomic weight of an ELEMENT."
  (interactive "sElement: ")
  (let ((ele (assoc element units-all-elements)))
    (string-to-number
     (units-convert (if ele
			(cdr ele)
		      element) ""))))

(defun units-compound-composition-single (formula)
  "Give the chemical composition of single FORMULA that gnu units can read."
  (string-join
   (let ((st -1)
	 (case-fold-search nil))
     (cl-loop while (setq st
			  (string-match
			   "\\(?1:[A-Z][a-z]*\\)\\(?2:[0-9]*\\)[+-]*"
			   formula
			   (1+ st)))
	      do (setq element (cdr (assoc (match-string 1 formula)
					   units-all-elements))
		       coeff (match-string 2 formula))
	      if (string=  coeff "") collect element
	      else collect (format "%s %s" element coeff)))
   " + "))

(defun units-compound-composition (formula)
  "Give the chemical composition of FORMULA that gnu units can read."
  (string-join
     (let ((parts (mapcar #'string-trim (split-string formula "[.]"))))
       (cl-loop for part in parts
		if (string-match-p "^[0-9]+.*" part)
		collect (format "%d (%s)"
				(string-to-number part)
				(units-compound-composition-single
				 (string-trim-left part "[0-9]+ *")))
		else collect (units-compound-composition-single part)))
     " + "))

(defun units-molar-weight (compound)
  "Calculate the molar weight of COMPOUND given formula."
  (interactive "sMolecular Formula: ")
  (let ((mw (units-convert
	     (units-compound-composition compound)
	     "")))
    (if (called-interactively-p 'any)
	(message mw)
      (string-to-number mw))))


(define-minor-mode units-mode
  "Minor mode for Calculations related to units.")

(provide 'units-mode)

;;; units-mode.el ends here
