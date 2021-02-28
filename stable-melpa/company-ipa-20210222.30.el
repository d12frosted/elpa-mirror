;;; company-ipa.el --- Ipa backend for company -*- lexical-binding: t -*-

;; Copyright (C) Matías Guzmán Naranjo.

;; Author: Matías Guzmán Naranjo <mguzmann89@gmail.com>
;; Keywords: convenience, company, ipa
;; Package-Version: 20210222.30
;; Package-Commit: e9d919e0d15d3f986471d9d6cb46b67519f5088f
;; Version: 20201003
;; URL: https://github.com/mguzmann/company-ipa
;; Package-Requires: ((emacs "24.3") (company "0.8.12"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package adds an easy way of inserting ipa into a document

;; Usage
;; =====

;; To install clone this package directly and load it (load-file "PATH/company-ipa.el")

;; To activate: (add-to-list 'company-backends 'company-ipa-symbols-unicode)

;; To use: type '~pp' and you should get completions

;; To change the prefix, execute:
;; (setq company-ipa-set-trigger-prefix "¬")

;; For best performance you should use this with company-flx:
;; (company-flx-mode +1)

(require 'company)
(require 'cl-lib)

;;; Code:

(defgroup company-ipa nil
  "Completion back-ends for ipa symbols Unicode."
  :group 'company
  :prefix "company-ipa-")

(defvar company-ipa-symbol-list-basic
  '(("vowel" " a [vowel] open back unrounded" 593 "ɑ")
    ("vowel" " a [vowel] open-mid schwa" 592 "ɐ")
    ("vowel" " a [vowel] open back rounded" 594 "ɒ")
    ("vowel" " a [vowel] raised open front unrounded" 230 "æ")
    ("vowel" " o [vowel] open-mid back rounded" 596 "ɔ")
    ("vowel" " e [vowel] schwa" 601 "ə")
    ("vowel" " e [vowel] close-mid schwa" 600 "ɘ")
    ("vowel" " e [vowel] rhotacized schwa" 602 "ɚ")
    ("vowel" " e [vowel] open-mid front unrounded" 603 "ɛ")
    ("vowel" " e [vowel] open-mid central" 604 "ɜ")
    ("vowel" " e [vowel] rhotacized open-mid central" 605 "ɝ")
    ("vowel" " o [vowel] open-mid central rounded" 606 "ɞ")
    ("vowel" " i [vowel] close central unrounded" 616 "ɨ")
    ("vowel" " i [vowel] lax close front unrounded" 618 "ɪ")
    ("vowel" " o [vowel] front close-mid rounded" 248 "ø")
    ("vowel" " o [vowel] rounded schwa" 629 "ɵ")
    ("vowel" " o [vowel] front open-mid rounded" 339 "œ")
    ("vowel" " o [vowel] front open rounded" 630 "ɶ")
    ("vowel" " u [vowel] close central rounded" 649 "ʉ")
    ("vowel" " u [vowel] lax close back rounded" 650 "ʊ")
    ("vowel" " o [vowel] open-mid back unrounded" 652 "ʌ")
    ("cons" " b [cons] vd bilabial implosive" 595 "ɓ")
    ("cons" " b [cons] vd bilabial trill" 665 "ʙ")
    ("cons" " b [cons] vd bilabial fricative" 946 "β")
    ("cons" " c [cons] vl alveolopalatal fricative" 597 "ɕ")
    ("cons" " c [cons] vl palatal fricative" 231 "ç")
    ("cons" " d [cons] vd alveolar implosive" 599 "ɗ")
    ("cons" " d [cons] vd retroflex plosive" 598 "ɖ")
    ("cons" " d [cons] vd dental fricative" 240 "ð")
    ("cons" " d [cons] vd postalveolar affricate" 676 "ʤ")
    ("cons" " j [cons] vd palatal plosive" 607 "ɟ")
    ("cons" " j [cons] vd palatal implosive" 644 "ʄ")
    ("cons" " g [cons] vd velar plosive" 609 "ɡ")
    ("cons" " g [cons] vd velar implosive" 608 "ɠ")
    ("cons" " g [cons] vd uvular plosive" 610 "ɢ")
    ("cons" " g [cons] vd uvular implosive" 667 "ʛ")
    ("cons" " h [cons] vd glottal fricative" 614 "ɦ")
    ("cons" " h [cons] vl multiple-place fricative" 615 "ɧ")
    ("cons" " h [cons] vl pharyngeal fricative" 295 "ħ")
    ("cons" " h [cons] labial-palatal approximant" 613 "ɥ")
    ("cons" " h [cons] vl epiglottal fricative" 668 "ʜ")
    ("cons" " j [cons] vd palatal fricative" 669 "ʝ")
    ("cons" " l [cons] vd retroflex lateral" 621 "ɭ")
    ("cons" " l [cons] vl alveolar lateral fricative" 620 "ɬ")
    ("cons" " l [cons] velarized vd alveolar lateral" 619 "ɫ")
    ("cons" " l [cons] vd alveolar lateral fricative" 622 "ɮ")
    ("cons" " l [cons] vd velar lateral" 671 "ʟ")
    ("cons" " m [cons] vd labiodental nasal" 625 "ɱ")
    ("cons" " w [cons] close back unrounded" 623 "ɯ")
    ("cons" " w [cons] velar approximant" 624 "ɰ")
    ("cons" " n [cons] vd velar nasal" 331 "ŋ")
    ("cons" " n [cons] vd retroflex nasal" 627 "ɳ")
    ("cons" " ñ [cons] vd palatal nasal" 626 "ɲ")
    ("cons" " n [cons] vd uvular nasal" 628 "ɴ")
    ("cons" " f [cons] vl bilabial fricative" 632 "ɸ")
    ("cons" " th [cons] vl dental fricative" 952 "θ")
    ("cons" " r [cons] vd (post)alveolar approximant" 633 "ɹ")
    ("cons" " r [cons] vd alveolar lateral flap" 634 "ɺ")
    ("cons" " r [cons] vd alveolar tap" 638 "ɾ")
    ("cons" " r [cons] vd retroflex approximant" 635 "ɻ")
    ("cons" " r [cons] vd uvular trill" 640 "ʀ")
    ("cons" " r [cons] vd uvular fricative" 641 "ʁ")
    ("cons" " r [cons] vd retroflex flap" 637 "ɽ")
    ("cons" " s [cons] vl retroflex fricative" 642 "ʂ")
    ("cons" " s [cons] vl postalveolar fricative" 643 "ʃ")
    ("cons" " t [cons] vl retroflex plosive" 648 "ʈ")
    ("cons" " t [cons] vl postalveolar affricate" 679 "ʧ")
    ("cons" " v [cons] vd labiodental approximant" 651 "ʋ")
    ("cons" " v [cons] voiced labiodental flap" 11377 "ⱱ")
    ("cons" " g [cons] vd velar fricative" 611 "ɣ")
    ("cons" " g [cons] close-mid back unrounded" 612 "ɤ")
    ("cons" " m [cons] vl labial-velar fricative" 653 "ʍ")
    ("cons" " x [cons] vl uvular fricative" 967 "χ")
    ("cons" " l [cons] vd palatal lateral" 654 "ʎ")
    ("cons" " y [cons] lax close front rounded" 655 "ʏ")
    ("cons" " z [cons] vd alveolopalatal fricative" 657 "ʑ")
    ("cons" " z [cons] vd retroflex fricative" 656 "ʐ")
    ("cons" " z [cons] vd postalveolar fricative" 658 "ʒ")
    ("cons" " ? [cons] glottal plosive" 660  "ʔ")
    ("cons" " ? [cons] vd epiglottal plosive" 673  "ʡ")
    ("cons" " ? [cons] vd pharyngeal fricative" 661  "ʕ")
    ("cons" " ? [cons] vd epiglottal fricative" 674  "ʢ")
    ("cons" " [click] dental click" 448  "ǀ")
    ("cons" " [click] alveolar lateral click" 449  "ǁ")
    ("cons" " [click] alveolar click" 450  "ǂ")
    ("cons" " [click] retroflex click" 451  "ǃ")
    ("cons" " [click] bilabial click" 664 "ʘ")
    ("diac" " [diac] (primary) stress mark" 712 "ˈ")
    ("diac" " [diac] secondary stress" 716 "ˌ")
    ("diac" " [diac] length mark" 720 "ː")
    ("diac" " [diac] half-length" 721 "ˑ")
    ("diac" " [diac] ejective" 700 "ʼ")
    ("diac" " [diac] rhotacized" 692 "ʴ")
    ("diac" " [diac] aspirated" 688 "ʰ")
    ("diac" " [diac] breathy-voice-aspirated" 689 "ʱ")
    ("diac" " [diac] palatalized" 690 "ʲ")
    ("diac" " [diac] labialized" 695 "ʷ")
    ("diac" " [diac] velarized" 736 "ˠ")
    ("diac" " [diac] pharyngealized" 740 "ˤ")
    ("diac" " [diac] rhotacized" 734 "˞")
    ("diac" " [sub] voiceless" 805 "n̥")
    ("diac" " [sup] voiceless" 778 "ŋ̊")
    ("diac" " [sub] breathy voiced" 804 "b̤")
    ("diac" " [sub] dental" 810 "t̪")
    ("diac" " [sub] voiced" 812 "s̬")
    ("diac" " [sub] creaky voiced" 816 "b̰")
    ("diac" " [sub] apical" 826 "t̺")
    ("diac" " [sub] linguolabial" 828 "t̼")
    ("diac" " [sub] laminal" 827 "t̻")
    ("diac" " [sub] not audibly released" 794 "t̚")
    ("diac" " [sub] more rounded" 825 "ɔ̹")
    ("diac" " [sup] nasalized" 771 "ẽ")
    ("diac" " [sub] less rounded" 796 "ɔ̜")
    ("diac" " [sub] advanced" 799 "u̟")
    ("diac" " [sub] retracted" 800 "e̠")
    ("diac" " [sup] centralized" 776 "ë")
    ("diac" " [sub] velarized or pharyngealized" 820 "l̴")
    ("diac" " [sup] mid-centralized" 829 "e̽")
    ("diac" " [sub] raised" 797 "e̝")
    ("diac" " [sub] syllabic" 809 "m̩")
    ("diac" " [sub] lowered" 798 "e̞")
    ("diac" " [sub] non-syllabic" 815 "e̯")
    ("diac" " [sub] advanced tongue root" 792 "e̘")
    ("diac" " [sub] retracted tongue root" 793 "e̙")
    ("diac" " [sup] extra-short" 774 "ĕ")
    ("diac" " [sup] extra high tone" 779 "e̋")
    ("diac" " [sup] high tone" 769 "é")
    ("diac" " [sup] mid tone" 772 "ē")
    ("diac" " [sup] low tone" 768 "è")
    ("diac" " [sup] extra low tone" 783  "ȅ")
    ("diac" " [sub] tie bar below" 860  "x͜x")
    ("diac" " [sup] tie bar above " 865  "x͡x"))
  "List of basic IPA symbols.")

(defcustom company-ipa-symbol-prefix "~pp"
  "Prefix for ipa insertion."
  :group 'company-ipa
  :type 'string)

(defvar company-ipa--unicode-prefix-regexp
  (concat (regexp-quote company-ipa-symbol-prefix)
          "[^ \t\n]*"))

;;; INTERNALS

(defun company-ipa--make-candidates (alist)
  "Build a list of ipa symbols ready to be used in a company backend.
Argument ALIST an alist of ipa symboles."
  (delq nil
        (mapcar
         (lambda (el)
           (let* ((tex (concat company-ipa-symbol-prefix (nth 1 el)))
                  (ch (and (nth 2 el) (decode-char 'ucs (nth 2 el))))
                  (symb (and ch (char-to-string ch)))
                  (symb-d (nth 3 el)))
             (propertize tex :symbol symb :displ symb-d)))
         alist)))

(defconst company-ipa--symbols
  (company-ipa--make-candidates company-ipa-symbol-list-basic))

(defun company-ipa--prefix (regexp)
  "Response to company prefix command.
Argument REGEXP REGEXP for matching prefix."
  (save-excursion
    (let* ((ppss (syntax-ppss))
           (min-point (if (nth 3 ppss)
                          (max (nth 8 ppss) (point-at-bol))
                        (point-at-bol))))
      (when (looking-back regexp min-point 'greedy)
        (match-string 0)))))

(defun company-ipa--substitute-unicode (symbol)
  "Substitute preceding latex command with with SYMBOL."
  (let ((pos (point))
        (inhibit-point-motion-hooks t))
    (when (re-search-backward (regexp-quote company-ipa-symbol-prefix)) ; should always match
      (goto-char (match-beginning 0))
      ;; allow subsups to start with \
      (let ((start (max (point-min) (- (point) (length company-ipa-symbol-prefix)))))
	(when (string= (buffer-substring-no-properties start (point))
                       company-ipa-symbol-prefix)
          (goto-char start)))
      (delete-region (point) pos)
      (insert symbol))))

(defun company-ipa-set-trigger-prefix (prefix)
  "Change the trigger prefix for company ipa."
  (setq company-ipa-symbol-prefix prefix)
  (setq company-ipa--unicode-prefix-regexp
	(concat (regexp-quote company-ipa-symbol-prefix)
		"[^ \t\n]*"))
  (setq company-ipa--symbols
	(company-ipa--make-candidates company-ipa-symbol-list-basic)))

;;; BACKENDS

;;;###autoload
(defun company-ipa-symbols-unicode (command &optional arg &rest _ignored)
  "Company backend for insertion of Unicode ipa symbols.
Argument COMMAND Matching command.
Optional argument ARG ARG for company."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-ipa-symbols-unicode))
    (prefix (company-ipa--prefix company-ipa--unicode-prefix-regexp))
    (annotation (concat " " (get-text-property 0 :displ arg)))
    (candidates (delq nil
		      (mapcar (lambda (candidate)
				(when (get-text-property 0 :symbol candidate)
				  (concat candidate " ")))
			      company-ipa--symbols)))
    (post-completion (company-ipa--substitute-unicode
		      (get-text-property 0 :symbol arg)))))

(provide 'company-ipa)
;;; company-ipa.el ends here
