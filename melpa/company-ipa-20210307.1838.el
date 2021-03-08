;;; company-ipa.el --- IPA backend for company -*- lexical-binding: t -*-

;; Copyright (C) Matías Guzmán Naranjo.

;; Author: Matías Guzmán Naranjo <mguzmann89@gmail.com>
;; Keywords: convenience, company, IPA
;; Package-Version: 20210307.1838
;; Package-Commit: 8634021cac885f53f3274ef6dcce7eab19321046
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

;; This package adds an easy way of inserting IPA (International Phonetic Alphabet) into a document

;; Usage
;; =====

;; To install clone this package directly and load it (load-file "PATH/company-ipa.el")

;; To activate: (add-to-list 'company-backends 'company-ipa-symbols-unicode)

;; To use: type '~pp' and you should get completions

;; To change the prefix, execute:
;; (company-ipa-set-trigger-prefix "¬")

;; For best performance you should use this with company-flx:
;; (company-flx-mode +1)

(require 'company)
(require 'cl-lib)

;;; Code:

(defgroup company-ipa nil
  "Completion back-ends for IPA symbols Unicode."
  :group 'company
  :prefix "company-ipa-")

(defcustom company-ipa-symbol-list-basic
  '(("a" "[vowel]" "open back unrounded" 593 "ɑ")
    ("a" "[vowel]" "open-mid schwa" 592 "ɐ")
    ("a" "[vowel]" "open back rounded" 594 "ɒ")
    ("a" "[vowel]" "raised open front unrounded" 230 "æ")
    ("o" "[vowel]" "open-mid back rounded" 596 "ɔ")
    ("e" "[vowel]" "schwa" 601 "ə")
    ("e" "[vowel]" "close-mid schwa" 600 "ɘ")
    ("e" "[vowel]" "rhotacized schwa" 602 "ɚ")
    ("e" "[vowel]" "open-mid front unrounded" 603 "ɛ")
    ("e" "[vowel]" "open-mid central" 604 "ɜ")
    ("e" "[vowel]" "rhotacized open-mid central" 605 "ɝ")
    ("o" "[vowel]" "open-mid central rounded" 606 "ɞ")
    ("i" "[vowel]" "close central unrounded" 616 "ɨ")
    ("i" "[vowel]" "lax close front unrounded" 618 "ɪ")
    ("o" "[vowel]" "front close-mid rounded" 248 "ø")
    ("o" "[vowel]" "rounded schwa" 629 "ɵ")
    ("o" "[vowel]" "front open-mid rounded" 339 "œ")
    ("o" "[vowel]" "front open rounded" 630 "ɶ")
    ("u" "[vowel]" "close central rounded" 649 "ʉ")
    ("u" "[vowel]" "lax close back rounded" 650 "ʊ")
    ("o" "[vowel]" "open-mid back unrounded" 652 "ʌ")

    ("b" "[cons]" "vd bilabial implosive" 595 "ɓ")
    ("b" "[cons]" "vd bilabial trill" 665 "ʙ")
    ("b" "[cons]" "vd bilabial fricative" 946 "β")
    ("c" "[cons]" "vl alveolopalatal fricative" 597 "ɕ")
    ("c" "[cons]" "vl palatal fricative" 231 "ç")
    ("d" "[cons]" "vd alveolar implosive" 599 "ɗ")
    ("d" "[cons]" "vd retroflex plosive" 598 "ɖ")
    ("d" "[cons]" "vd dental fricative" 240 "ð")
    ("d" "[cons]" "vd postalveolar affricate" 676 "ʤ")
    ("j" "[cons]" "vd palatal plosive" 607 "ɟ")
    ("j" "[cons]" "vd palatal implosive" 644 "ʄ")
    ("g" "[cons]" "vd velar plosive" 609 "ɡ")
    ("g" "[cons]" "vd velar implosive" 608 "ɠ")
    ("g" "[cons]" "vd uvular plosive" 610 "ɢ")
    ("g" "[cons]" "vd uvular implosive" 667 "ʛ")
    ("h" "[cons]" "vd glottal fricative" 614 "ɦ")
    ("h" "[cons]" "vl multiple-place fricative" 615 "ɧ")
    ("h" "[cons]" "vl pharyngeal fricative" 295 "ħ")
    ("h" "[cons]" "labial-palatal approximant" 613 "ɥ")
    ("h" "[cons]" "vl epiglottal fricative" 668 "ʜ")
    ("j" "[cons]" "vd palatal fricative" 669 "ʝ")
    ("l" "[cons]" "vd retroflex lateral" 621 "ɭ")
    ("l" "[cons]" "vl alveolar lateral fricative" 620 "ɬ")
    ("l" "[cons]" "velarized vd alveolar lateral" 619 "ɫ")
    ("l" "[cons]" "vd alveolar lateral fricative" 622 "ɮ")
    ("l" "[cons]" "vd velar lateral" 671 "ʟ")
    ("m" "[cons]" "vd labiodental nasal" 625 "ɱ")
    ("w" "[cons]" "close back unrounded" 623 "ɯ")
    ("w" "[cons]" "velar approximant" 624 "ɰ")
    ("n" "[cons]" "vd velar nasal" 331 "ŋ")
    ("n" "[cons]" "vd retroflex nasal" 627 "ɳ")
    ("n" "[cons]" "vd palatal nasal" 626 "ɲ")
    ("n" "[cons]" "vd uvular nasal" 628 "ɴ")
    ("f" "[cons]" "vl bilabial fricative" 632 "ɸ")
    ("t" "[cons]" "vl dental fricative" 952 "θ")
    ("r" "[cons]" "vd (post)alveolar approximant" 633 "ɹ")
    ("r" "[cons]" "vd alveolar lateral flap" 634 "ɺ")
    ("r" "[cons]" "vd alveolar tap" 638 "ɾ")
    ("r" "[cons]" "vd retroflex approximant" 635 "ɻ")
    ("r" "[cons]" "vd uvular trill" 640 "ʀ")
    ("r" "[cons]" "vd uvular fricative" 641 "ʁ")
    ("r" "[cons]" "vd retroflex flap" 637 "ɽ")
    ("s" "[cons]" "vl retroflex fricative" 642 "ʂ")
    ("s" "[cons]" "vl postalveolar fricative" 643 "ʃ")
    ("t" "[cons]" "vl retroflex plosive" 648 "ʈ")
    ("t" "[cons]" "vl postalveolar affricate" 679 "ʧ")
    ("v" "[cons]" "vd labiodental approximant" 651 "ʋ")
    ("v" "[cons]" "voiced labiodental flap" 11377 "ⱱ")
    ("g" "[cons]" "vd velar fricative" 611 "ɣ")
    ("g" "[cons]" "close-mid back unrounded" 612 "ɤ")
    ("m" "[cons]" "vl labial-velar fricative" 653 "ʍ")
    ("x" "[cons]" "vl uvular fricative" 967 "χ")
    ("l" "[cons]" "vd palatal lateral" 654 "ʎ")
    ("y" "[cons]" "lax close front rounded" 655 "ʏ")
    ("z" "[cons]" "vd alveolopalatal fricative" 657 "ʑ")
    ("z" "[cons]" "vd retroflex fricative" 656 "ʐ")
    ("z" "[cons]" "vd postalveolar fricative" 658 "ʒ")
    ("?" "[cons]" "glottal plosive" 660  "ʔ")
    ("?" "[cons]" "vd epiglottal plosive" 673  "ʡ")
    ("?" "[cons]" "vd pharyngeal fricative" 661  "ʕ")
    ("?" "[cons]" "vd epiglottal fricative" 674  "ʢ")

    ("|" "[click]" "dental click" 448  "ǀ")
    ("|" "[click]" "alveolar lateral click" 449  "ǁ")
    ("|" "[click]" "alveolar click" 450  "ǂ")
    ("|" "[click]" "retroflex click" 451  "ǃ")
    ("|" "[click]" "bilabial click" 664 "ʘ")

    ("'" "[diac]" "(primary) stress mark" 712 "ˈ")
    ("'" "[diac]" "secondary stress" 716 "ˌ")
    ("'" "[diac]" "length mark" 720 "ː")
    ("'" "[diac]" "half-length" 721 "ˑ")
    ("'" "[diac]" "ejective" 700 "ʼ")
    ("'" "[diac]" "rhotacized" 692 "ʴ")
    ("'" "[diac]" "aspirated" 688 "ʰ")
    ("'" "[diac]" "breathy-voice-aspirated" 689 "ʱ")
    ("'" "[diac]" "palatalized" 690 "ʲ")
    ("'" "[diac]" "labialized" 695 "ʷ")
    ("'" "[diac]" "velarized" 736 "ˠ")
    ("'" "[diac]" "pharyngealized" 740 "ˤ")
    ("'" "[diac]" "rhotacized" 734 "˞")

    ("_" "[sub]" "voiceless" 805 "n̥")
    ("^" "[sup]" "voiceless" 778 "ŋ̊")
    ("_" "[sub]" "breathy voiced" 804 "b̤")
    ("_" "[sub]" "dental" 810 "t̪")
    ("_" "[sub]" "voiced" 812 "s̬")
    ("_" "[sub]" "creaky voiced" 816 "b̰")
    ("_" "[sub]" "apical" 826 "t̺")
    ("_" "[sub]" "linguolabial" 828 "t̼")
    ("_" "[sub]" "laminal" 827 "t̻")
    ("_" "[sub]" "not audibly released" 794 "t̚")
    ("_" "[sub]" "more rounded" 825 "ɔ̹")
    ("^" "[sup]" "nasalized" 771 "ẽ")
    ("_" "[sub]" "less rounded" 796 "ɔ̜")
    ("_" "[sub]" "advanced" 799 "u̟")
    ("_" "[sub]" "retracted" 800 "e̠")

    ("^" "[sup]" "centralized" 776 "ë")
    ("_" "[sub]" "velarized or pharyngealized" 820 "l̴")
    ("^" "[sup]" "mid-centralized" 829 "e̽")
    ("_" "[sub]" "raised" 797 "e̝")
    ("_" "[sub]" "syllabic" 809 "m̩")
    ("_" "[sub]" "lowered" 798 "e̞")
    ("_" "[sub]" "non-syllabic" 815 "e̯")
    ("_" "[sub]" "advanced tongue root" 792 "e̘")
    ("^" "[sub]" "retracted tongue root" 793 "e̙")
    ("^" "[sup]" "extra-short" 774 "ĕ")
    ("^" "[sup]" "extra high tone" 779 "e̋")
    ("^" "[sup]" "high tone" 769 "é")
    ("^" "[sup]" "mid tone" 772 "ē")
    ("^" "[sup]" "low tone" 768 "è")
    ("^" "[sup]" "extra low tone" 783  "ȅ")
    ("^" "[sub]" "tie bar below" 860  "x͜x")
    ("^" "[sup]" "tie bar above " 865  "x͡x"))
  "List of basic IPA symbols.
Each item in this list is itself a list, consisting of the following elements:

- a category character
- a label
- a description
- the character code
- the display symbol

The character code determines the character that is inserted in
the buffer.  All other elements are used to construe the string
that is shown during completion and can be modified freely.  If
you use `company-flx', this string consists of the category
character, the label and the description.  If you do not use
`company-flx', only the category character and the description
are used, and spaces in the description are replaced with
underscores."
  :group 'company-ipa
  :type '(repeat :tag "Character"
                 (list (string :tag "Category")
                       (string :tag "Category character")
                       (string :tag "Label")
                       (string :tag "Description")
                       (integer :tag "Character code")
                       (string :tag "Display symbol"))))

(defcustom company-ipa-symbol-prefix "~pp"
  "Prefix for IPA insertion."
  :group 'company-ipa
  :type 'string)

(defvar company-ipa--unicode-prefix-regexp
  (concat (regexp-quote company-ipa-symbol-prefix)
          "[^ \t\n]*"))

;;; INTERNALS

(defun company-ipa--make-candidates (alist)
  "Build a list of IPA symbols ready to be used in a company backend.
Argument ALIST an alist of IPA symboles."
  (delq nil
        (mapcar
         (lambda (el)
           (let* ((tex (concat company-ipa-symbol-prefix (company-ipa--make-description (nth 0 el) (nth 1 el) (nth 2 el))))
                  (ch (and (nth 3 el) (decode-char 'ucs (nth 3 el))))
                  (symb (and ch (char-to-string ch)))
                  (symb-d (nth 4 el)))
             (propertize tex :symbol symb :displ symb-d)))
         alist)))

(defun company-ipa--make-description (sym cat desc)
  "Create a description for the completion list.
SYM is a category symbol, CAT a description of the category, DESC
a string describing the IPA character.  They should correspond to
the first, second and third elements in the entries in
`company-ipa-symbol-list-basic'."
  (if (bound-and-true-p company-flx-mode)
      (format " %s %s %s" sym cat desc)
    (format "%s_%s" sym (replace-regexp-in-string " " "_" desc))))

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
  "Change the trigger prefix for company IPA."
  (setq company-ipa-symbol-prefix prefix)
  (setq company-ipa--unicode-prefix-regexp
	(concat (regexp-quote company-ipa-symbol-prefix)
		"[^ \t\n]*"))
  (setq company-ipa--symbols
	(company-ipa--make-candidates company-ipa-symbol-list-basic)))

;;; BACKENDS

;;;###autoload
(defun company-ipa-symbols-unicode (command &optional arg &rest _ignored)
  "Company backend for insertion of Unicode IPA symbols.
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
