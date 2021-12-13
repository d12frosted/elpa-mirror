;;; purty-mode.el --- Safely pretty-print greek letters, mathematical symbols, or anything else.
;; Package-Version: 20131004.2259
;; Package-Commit: 8eef77317a3bab07ade212353a50fbd3f20f365a

;; Author: James Atwood <jatwood@cs.umass.edu>

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
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; purty-mode is a minor mode which swaps whatever-regexp-you-want for
;; whatever-symbol-you-want on the fly.  Given that the text itself is
;; left untouched, purty-mode can safely be used when writing code or
;; latex or org or whatever.

;;; Setup:

;; If installed from source (rather than a package.el archive such as
;; MELPA), then place purty-mode.el somewhere on your load path, and add
;; (require 'purty-mode) to your .emacs.

;;; Customization:

;; Substitutions can be added to purty via the purty-add-pair function.
;;    (purty-add-pair '("Xi" . "Ξ"))

;;; Acknowledgements:

;; This source is essentially an extension of Mark Trigg's lambda-mode.el.

;;; Code:
(defvar purty-regexp-symbol-pairs nil
  "List of (regexp . string) pairs to be substituted when
purty-mode is active.  Substitutions can be added via the
purty-add-pair function.

  (purty-add-pair '(\"Xi\" . \"Ξ\"))")


	
  
(defun purty-enhance-pair (pair)
  "Enhances the provided (regexp . symbol) pair so that the
  regexp plays nicely with its surroundings.  An enhanced pair will not
  clobber words that contain the regexp, will not be tripped up by
  line endings, will still replace when surrounded by non
  alphabetic characters, and will not suck up additional characters
  upon replacement."
  (let ((reg (car pair))
	(sym (cdr pair)))
;; good god, what was I thinking here
;;    (let ((leading-char (substring reg 0 1)))
;;      (if (not (or (string= leading-char "_")
;;		   (string= (substring reg 0 2) "\\^")))
;;	  (cons (concat "\\(?:^\\|[^A-Za-z]\\)[^A-Za-z]*\\("
;;			reg
;;			"\\)[^A-Za-z]*\\(?:[^A-Za-z]*\\|$\\)")
;;		sym)
;;	(cons (concat "\\(" reg "\\)") sym)))))
    ;; place word boundary around regexps and make them a group
    (cons (concat "\\(\\b" reg "\\b\\)") sym)))

(setq purty-regexp-symbol-pairs
  (mapcar #'purty-enhance-pair
  '(;; greek symbols
        ("alpha"	. "α")
	("beta"		. "β")
	("chi"		. "χ")
	("delta"	. "̣δ")
	("eta"		. "η")
	("gamma"	. "γ")
	("kappa"	. "κ")
	("epsilon"	. "ε")
	("lambda"	. "λ")
	("Lambda"	. "Λ")
	("mu"		. "μ")
	("omega"	. "ω")
	("phi"		. "φ")
	("pi"		. "π")
	("psi"		. "ψ")
	("Psi"		. "Ψ")
	("rho"		. "ρ")
	("sigma"	. "σ")
	("Sigma"	. "Σ")
	("tau"		. "τ")
	("theta"	. "θ")
	("Theta"	. "Θ")
	("xi"		. "ξ")
	("zeta"		. "ζ")
	
    ;; math
	
	("[Ss]um"		. "Σ")
	("[Pp]roduct"		. "Π")
	("[\\]prod"		. "Π")
			 
	("[\\]approx"		. "≈")
	("[\\]cap"		. "∩")
	("[\\]intersect"	. "∩")
	("[\\]cup"		. "∪")
	("[\\]union"		. "∪")
	("[Ee]lement"		. "∈")
	("[\\]in"		. "∈")
	("[\\]notin"		. "∉")
	("[\\]forall"		. "∀")
	("[\\]geq"		. "≥")
	("[\\]leq"		. "≤")
	("[\\]defs"		. "≙")
	("[\\]equiv"		. "≡")
	("[\\]emptyset"		. "∅")
	("[\\]partial"		. "∂")
	("[\\]pm"		. "±")
	("[\\]nabla"		. "∇")
	("[\\]infty"		. "∞")
	("[\\]int"		. "∫")
	("[\\]indep"		. "⊥")
	("[\\]neq"		. "≠")
	("[\\]subset"		. "⊂")
	("[\\]subseteq"		. "⊆")
	("[\\]iff" . "⇔")
	 

    ;; sub/super
    ;; these don't seem to be rendering, unsure what is up
    ;; tried TeX input and Unicode character codes, no luck
	;;("_0" . "₀")
	;;("_1" . "₁")
	;;("_2" . "₂")
	;;("_3" . "₃")
	;;("_4" . "₄")
	;;("_5" . "₅")
	;;("_6" . "₆")
	;;("_7" . "₇")
	;;("_8" . "₈")
	;;("_9" . "₉")	
	;;
	;;("\\^0" . "")
	;;("\\^1" . "¹")
	;;("\\^2" . "²")
	;;("\\^3" . "³")
	;;("\\^4" . "⁴")
	;;("\\^5" . "⁵")
	;;("\\^6" . "⁶")
	;;("\\^7" . "⁷")
	;;("\\^8" . "⁸")
	;;("\\^9" . "⁹")

	)))

(defun purty-add-pair (pair)
  "Adds a (regexp . symbol) pair to purty's replacement table."
  (setq purty-regexp-symbol-pairs (cons pair purty-regexp-symbol-pairs)))

(defun purty-fontify (beg end)
  (save-excursion
    (purty-unfontify beg end)
    (purty-fontify-symbols beg end purty-regexp-symbol-pairs)))
      

(defun purty-fontify-symbols (beg end regexp-symbol-pairs)
  (cond ((not regexp-symbol-pairs) t)
	(t (purty-fontify-symbol beg end (car regexp-symbol-pairs))
	   (purty-fontify-symbols beg end (cdr regexp-symbol-pairs)))))



(defun purty-fontify-symbol (beg end regexp-symbol-pair)
  (save-excursion
    (goto-char beg)
    (let ((reg (car regexp-symbol-pair))
	  (sym (cdr regexp-symbol-pair)))
      (while (re-search-forward reg end t)
	(let ((o (car (overlays-at (match-beginning 0)))))
	  (unless (and o (eq (overlay-get o 'type) 'purty))
	    (let ((overlay (make-overlay (match-beginning 1) (match-end 1))))
	      (overlay-put overlay 'type 'purty)
	      (overlay-put overlay 'evaporate t)
	      (overlay-put overlay 'display sym))))))))

(defun purty-unfontify (beg end)
  (mapc #'(lambda (o)
            (when (eq (overlay-get o 'type) 'purty)
              (delete-overlay o)))
        (overlays-in beg end)))

;;;###autoload
(define-minor-mode purty-mode
  "Purty up your buffer."
  nil " purty" nil
  (cond ((not purty-mode)
         (jit-lock-unregister 'purty-fontify)
         (purty-unfontify (point-min) (point-max))
	 (set-syntax-table (standard-syntax-table)))
        (t (let ((table (make-syntax-table)))
	     ;; it is ok to clobber (alpha) -> (α)
	     ;; but not music -> μsic
	     ;; set syntax table accordingly
	     (modify-syntax-entry ?\( ".") 
	     (modify-syntax-entry ?\) ".")
	     (set-syntax-table table)
	     (purty-fontify (point-min) (point-max))
	     (jit-lock-register 'purty-fontify)))))


(provide 'purty-mode)
;;; purty-mode.el ends here
