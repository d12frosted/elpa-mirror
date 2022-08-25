;;; indian-ext.el --- Extension to Indian language utilities -*- lexical-binding: t -*-

;; Copyright (C) 2015-2019 Patrick McAllister

;; Author: Patrick McAllister <pma@rdorte.org>
;; Keywords: i18n, tools, wp, indian, devanagari, encoding
;; Package-Version: 20190424.1547
;; Package-Commit: a5450fe467393194bc2458c0d5e0a06c91bf117a
;; URL: https://github.com/paddymcall/indian-ext
;; Package-Requires: ((emacs "24"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides extensions to the standard Emacs ind-util.el
;; functions.

;; It is currently focused on providing methods for Sanskrit, but that
;; might (and hopefully will) change in the future.

;; It defines the following extra decode/encode functions:


;; between Velthuis and Devanāgarī:
;; `indian-ext-dev-velthuis-encode-region'
;; `indian-ext-dev-velthuis-decode-region'
;; between SLP1 and Devanāgarī:
;; `indian-ext-dev-slp1-encode-region'
;; `indian-ext-dev-slp1-decode-region'
;; between IAST and Devanāgarī.
;; `indian-ext-dev-iast-encode-region'
;; `indian-ext-dev-iast-decode-region'

;; IAST and Velthuis encodings are not case sensitive.

;; This package also defines an additional input method, sanskrit-iast
;; (use with `M-x set-input-method').

;; You can find other input methods here:

;; including Karoṣṭhī: http://stefanbaums.com/unicode/sanskrit.el
;; requires login: http://indica-et-buddhica.org/repositorium/software/emacs-utf8-input-framework

;;; Code:

(require 'quail)
(require 'ind-util)

(eval-and-compile
  
  (defvar indian-ext-velthuis-table
    '(;; for encode/decode
      (;; vowel
       ("a" "A")   ("aa" "Aa" "AA")  ("i" "I")   ("ii" "Ii" "II")  ("u" "U")   ("uu" "Uu" "UU")
       (".r" ".R")  (".l" ".L")   nil   nil  ("e" "E")   ("ai" "Ai" "AI")
       nil   nil   ("o" "O")   ("au" "Au" "AU")  (".R" ".R")  (".L" ".L"))
      (;; consonant
       ("k" "K")   ("kh" "Kh" "KH")  ("g" "G")   ("gh" "Gh" "GH")  ("\"n" "\"N")
       ("c" "C")   ("ch" "Ch" "CH")  ("j" "J")   ("jh" "Jh" "JH")  ("~n" "~N")
       (".t" ".T")  (".th" ".Th" ".TH") (".d" ".D")  (".dh" ".Dh" ".DH") (".n" ".N")
       ("t" "T")   ("th" "Th" "TH")  ("d" "D")   ("dh" "Dh" "DH")  ("n" "N")   nil
       ("p" "P")   ("ph" "Ph" "PH")  ("b" "B")   ("bh" "Bh" "BH")  ("m" "M")
       ("y" "Y")   ("r" "R")   nil   ("l" "L")   nil  nil  ("v" "V")
       ("\"s" "\"S")  (".s" ".S")  ("s" "S")   ("h" "H")
       nil   nil   nil   nil   nil   nil   nil   nil
       nil   nil)
      (;; misc
       "/"   (".m" ".M")  (".h" ".H")  "'"   "&"   (".o" ".O") ".")
      (;; Digits (10)
       "0" "1" "2" "3" "4" "5" "6" "7" "8" "9")))
  
  (defvar indian-ext-iast-table
    '(;; for encode/decode
      (;; vowel
       ("a" "A")   ("ā" "Ā")  ("i" "I")   ("ī" "Ī") ("u" "U")   ("ū" "Ū")
       ("ṛ" "Ṛ")   ("ḷ" "Ḷ")  nil   nil   ("e" "E")   ("ai" "Ai" "AI")
       nil   nil   ("o" "O")   ("au" "Au" "AU")  ("ṝ" "Ṝ") ("ḹ" "Ḹ"))
      (;; consonant
       ("k" "K")   ("kh" "Kh" "KH")  ("g" "G")   ("gh" "Gh" "GH")  ("ṅ" "Ṅ")
       ("c" "C")   ("ch" "Ch" "CH")  ("j" "J")   ("jh" "Jh" "JH")  ("ñ" "Ñ")
       ("ṭ" "Ṭ")   ("ṭh" "Ṭh" "ṬH")  ("ḍ" "Ḍ")   ("ḍh" "Ḍh" "ḌH")  ("ṇ" "Ṇ")
       ("t" "T")   ("th" "Th" "TH")  ("d" "D")   ("dh" "Dh" "DH")  ("n" "N")   nil
       ("p" "P")   ("ph" "Ph" "PH")  ("b" "B")   ("bh" "Bh" "BH")  ("m" "M")
       ("y" "Y")   ("r" "R")   nil   ("l" "L")   ("L" "L")   nil   ("v" "V")
       ("ś" "Ś") ("ṣ" "Ṣ")   ("s" "S")   ("h" "H")
       nil   nil   nil   nil   nil   nil   nil   nil
       nil   nil)
      (;; misc
       nil   ("ṃ" "Ṃ")   ("ḥ" "Ḥ")   "'"   nil   ("OM") ".")))

  (defvar indian-ext-slp1-table
    '(;; for encode/decode
      (;; vowel
       "a"   "A"  "i"   "I" "u"   "U"
       "f"   "x"  "e~"   "e1"   "e"   "E" ;; not sure about the e~ and e1;
       "o~"   "o1"   "o"   "O"  "F" "X")  ;; same for
      (;; consonant
       "k"   "K"  "g"   "G"  "N"
       "c"   "C"  "j"   "J"  "Y"
       "w"   "W"  "q"   "Q"  "R"
       "t"   "T"  "d"   "D"  "n"  nil
       "p"   "P"  "b"   "B"  "m"
       "y"   "r"   nil   "l"   "L"  nil   "v"
       "S" "z"   "s"   "h"
       nil   nil   nil   nil   nil   nil   nil   nil ;; NUKTAS; dunno.
       "jY"   "kz")
      (;; misc
       "~"   "M"   "H"   "'"  nil "ॐ" ".")
      (;; Digits (10)
       0 1 2 3 4 5 6 7 8 9)
      (;; Inscript-extra (4)  (#, $, ^, *, ])
       "#" "$" "^" "*" "]"))
    "See http://www.sanskritlibrary.org/Sanskrit/pub/lies_sl.pdf.")

  (defvar indian-ext-dev-iast-hash
    (indian-make-hash indian-dev-base-table
		      indian-ext-iast-table))
  
  (defvar indian-ext-dev-slp1-hash
    (indian-make-hash indian-dev-base-table
		      indian-ext-slp1-table))
  
  (defvar indian-ext-dev-velthuis-hash
    (indian-make-hash indian-dev-base-table
		      indian-ext-velthuis-table)))

(defun indian-ext-dev-velthuis-encode-region (from to)
  "In region FROM to TO, encode Devanāgarī as Velthuis."
  (interactive "r")
  (indian-translate-region
   from to indian-ext-dev-velthuis-hash t))

(defun indian-ext-dev-velthuis-encode-string (string)
  "Encode STRING in Devanāgarī to Velthuis."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-velthuis-encode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun indian-ext-dev-velthuis-decode-region (from to)
  "In region FROM to TO, decode Velthuis to Devanāgarī."
  (interactive "r")
  (indian-translate-region
   from to indian-ext-dev-velthuis-hash nil))

(defun indian-ext-dev-velthuis-decode-string (string)
  "Decode STRING in Velthuis to Devanāgarī."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-velthuis-decode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun indian-ext-dev-slp1-encode-region (from to)
  "In region FROM to TO, encode Devanāgarī as SLP1."
  (interactive "r")
  (let ((case-fold-search nil))
    (indian-translate-region
     from to indian-ext-dev-slp1-hash t)))

(defun indian-ext-dev-slp1-encode-string (string)
  "Encode STRING in Devanāgarī to SLP1."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-slp1-encode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun indian-ext-dev-slp1-decode-region (from to)
  "In region FROM to TO, decode SLP1 to Devanāgarī."
  (interactive "r")
  (let ((case-fold-search nil))
    (indian-translate-region
     from to indian-ext-dev-slp1-hash nil)))

(defun indian-ext-dev-slp1-decode-string (string)
  "Decode STRING in SLP1 to Devanāgarī."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-slp1-decode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun indian-ext-dev-iast-encode-region (from to)
  "In region FROM to TO, encode Devanāgarī as IAST."
  (interactive "r")
  (indian-translate-region
   from to indian-ext-dev-iast-hash t))

(defun indian-ext-dev-iast-encode-string (string)
  "Encode STRING in Devanāgarī to IAST."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-iast-encode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun indian-ext-dev-iast-decode-region (from to)
  "In region FROM to TO, decode IAST to Devanāgarī."
  (interactive "r")
  (indian-translate-region
   from to indian-ext-dev-iast-hash nil))

(defun indian-ext-dev-iast-decode-string (string)
  "Decode STRING in IAST to Devanāgarī."
  (with-temp-buffer
    (insert string)
    (indian-ext-dev-iast-decode-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

;;; Set up an IAST input method

(quail-define-package
 "sanskrit-iast" "Sanskrit" "IAST" t
 "Latin character input method with postfix modifiers.

This is based on the Emacs standard input method
latin-alt-postfix. It is extended with a few items for writing
Sanskrit in IAST encoding, mainly dot below and \"ng\" for ṅ.

             | postfix | examples
 ------------+---------+----------
  acute      |    \\='    | a\\=' -> á
  grave      |    \\=`    | a\\=` -> à
  circumflex |    ^    | a^ -> â
  diaeresis  |    \"    | a\" -> ä
  tilde      |    ~    | a~ -> ã
  cedilla    |    /\\=`   | c/ -> ç   c\\=` -> ç
  ogonek     |    \\=`    | a\\=` -> ą
  breve      |    ~    | a~ -> ă
  caron      |    ~    | c~ -> č
  dbl. acute |    :    | o: -> ő
  ring       |    \\=`    | u\\=` -> ů
  dot        |    \\=`    | z\\=` -> ż
  dot below  |    .    | n. -> ṇ
  stroke     |    /    | d/ -> đ
  nordic     |    /    | d/ -> ð   t/ -> þ   a/ -> å   e/ -> æ   o/ -> ø
  others     |   /<>   | s/ -> ß   ?/ -> ¿   !/ -> ¡
             | various | << -> «   >> -> »   o_ -> º   a_ -> ª


Doubling the postfix separates the letter and postfix: e.g. a\\='\\=' -> a\\='"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 (" _" ? )
 ("!/" ?¡)
 ("//" ?°)
 ("<<" ?«)
 (">>" ?»)
 ("?/" ?¿)
 ("$/" ?£)
 ("$/" ?¤)
 ("A'" ?Á)
 ("A-" ?Ā)
 ("A/" ?Å)
 ("A\"" ?Ä)
 ("A^" ?Â)
 ("A`" ?À)
 ("A`" ?Ą)
 ("A~" ?Ã)
 ("A~" ?Ă)
 ("C'" ?Ć)
 ("C/" ?Ç)
 ("C/" ?Ċ)
 ("C^" ?Ĉ)
 ("C`" ?Ç)
 ("C~" ?Č)
 ("D/" ?Ð)
 ("D/" ?Đ)
 ("D~" ?Ď)
 ("E'" ?É)
 ("E-" ?Ē)
 ("E/" ?Æ)
 ("E\"" ?Ë)
 ("E^" ?Ê)
 ("E`" ?È)
 ("E`" ?Ę)
 ("E~" ?Ė)
 ("E~" ?Ě)
 ("G/" ?Ġ)
 ("G^" ?Ĝ)
 ("G`" ?Ģ)
 ("G~" ?Ğ)
 ("H/" ?Ħ)
 ("H^" ?Ĥ)
 ("I'" ?Í)
 ("I-" ?Ī)
 ("I/" ?İ)
 ("I\"" ?Ï)
 ("I^" ?Î)
 ("I`" ?Ì)
 ("I`" ?Į)
 ("I~" ?Ĩ)
 ("J^" ?Ĵ)
 ("K`" ?Ķ)
 ("L'" ?Ĺ)
 ("L/" ?Ł)
 ("L`" ?Ļ)
 ("L~" ?Ľ)
 ("N'" ?Ń)
 ("N/" ?Ŋ)
 ("N`" ?Ņ)
 ("N~" ?Ñ)
 ("N~" ?Ň)
 ("O'" ?Ó)
 ("O-" ?Ō)
 ("O/" ?Ø)
 ("O/" ?Œ)
 ("O:" ?Ő)
 ("O\"" ?Ö)
 ("O^" ?Ô)
 ("O`" ?Ò)
 ("O~" ?Õ)
 ("R'" ?Ŕ)
 ("R`" ?Ŗ)
 ("R~" ?Ř)
 ("S'" ?Ś)
 ("S^" ?Ŝ)
 ("S`" ?Ş)
 ("S~" ?Š)
 ("T/" ?Þ)
 ("T/" ?Ŧ)
 ("T`" ?Ţ)
 ("T~" ?Ť)
 ("U'" ?Ú)
 ("U-" ?Ū)
 ("U:" ?Ű)
 ("U\"" ?Ü)
 ("U^" ?Û)
 ("U`" ?Ù)
 ("U`" ?Ů)
 ("U`" ?Ų)
 ("U~" ?Ũ)
 ("U~" ?Ŭ)
 ("Y'" ?Ý)
 ("Y\"" ?Ÿ)
 ("Y=" ?¥)
 ("Z'" ?Ź)
 ("Z/" ?Ż)
 ("Z`" ?Ż)
 ("Z~" ?Ž)
 ("a'" ?á)
 ("a-" ?ā)
 ("a/" ?å)
 ("a\"" ?ä)
 ("a^" ?â)
 ("a_" ?ª)
 ("a`" ?à)
 ("a`" ?ą)
 ("a~" ?ã)
 ("a~" ?ă)
 ("c'" ?ć)
 ("c/" ?ç)
 ("c/" ?ċ)
 ("c/" ?¢)
 ("c^" ?ĉ)
 ("c`" ?ç)
 ("c~" ?č)
 ("d/" ?ð)
 ("d/" ?đ)
 ("d~" ?ď)
 ("e'" ?é)
 ("e-" ?ē)
 ("e/" ?æ)
 ("e\"" ?ë)
 ("e^" ?ê)
 ("e`" ?è)
 ("e`" ?ę)
 ("e~" ?ė)
 ("e~" ?ě)
 ("e=" ?€)
 ("g/" ?ġ)
 ("g^" ?ĝ)
 ("g`" ?ģ)
 ("g~" ?ğ)
 ("h/" ?ħ)
 ("h^" ?ĥ)
 ("i'" ?í)
 ("i-" ?ī)
 ("i/" ?ı)
 ("i\"" ?ï)
 ("i^" ?î)
 ("i`" ?ì)
 ("i`" ?į)
 ("i~" ?ĩ)
 ("j^" ?ĵ)
 ("k/" ?ĸ)
 ("k`" ?ķ)
 ("l'" ?ĺ)
 ("l/" ?ł)
 ("l`" ?ļ)
 ("l~" ?ľ)
 ("n'" ?ń)
 ("n/" ?ŋ)
 ("n`" ?ņ)
 ("n~" ?ñ)
 ("n~" ?ň)
 ("o'" ?ó)
 ("o-" ?ō)
 ("o/" ?ø)
 ("o/" ?œ)
 ("o:" ?ő)
 ("o\"" ?ö)
 ("o^" ?ô)
 ("o_" ?º)
 ("o`" ?ò)
 ("o~" ?õ)
 ("r'" ?ŕ)
 ("r`" ?ŗ)
 ("r~" ?ř)
 ("s'" ?ś)
 ("s/" ?ß)
 ("s^" ?ŝ)
 ("s`" ?ş)
 ("s~" ?š)
 ("t/" ?þ)
 ("t/" ?ŧ)
 ("t`" ?ţ)
 ("t~" ?ť)
 ("u'" ?ú)
 ("u-" ?ū)
 ("u:" ?ű)
 ("u\"" ?ü)
 ("u^" ?û)
 ("u`" ?ù)
 ("u`" ?ů)
 ("u`" ?ų)
 ("u~" ?ũ)
 ("u~" ?ŭ)
 ("y'" ?ý)
 ("y\"" ?ÿ)
 ("z'" ?ź)
 ("z/" ?ż)
 ("z`" ?ż)
 ("z~" ?ž)

 ;;; IAST extensions
 ;; capitals
 ("R." ?Ṛ)
 ("R.-" ?Ṝ)
 ("L." ?Ḷ)
 ("L.-" ?Ḹ)
 ("M." ?Ṃ)
 ("Ng" ?Ṅ)
 ("T." ?Ṭ)
 ("D." ?Ḍ)
 ("N." ?Ṇ)
 ("S." ?Ṣ)
 ("H." ?Ḥ)
 ;; escapes
 ("R.." ["R."])
 ("R.--" ["Ṛ-"])
 ("L.." ["L."])
 ("L.--" ["Ḷ-"])
 ("M.." ["M."])
 ("Ngg" ["Ng"])
 ("T.." ["T."])
 ("D.." ["D."])
 ("N.." ["N."])
 ("S.." ["S."])
 ("H.." ["H."])

 ;; small caps
 ("r." ?ṛ)
 ("r.-" ?ṝ)
 ("l." ?ḷ)
 ("l.-" ?ḹ)
 ("m." ?ṃ)
 ("ng" ?ṅ)
 ("t." ?ṭ)
 ("d." ?ḍ)
 ("n." ?ṇ)
 ("s." ?ṣ)
 ("h." ?ḥ)
 ;; escapes
 ("r.." ["r."])
 ("r.--" ["ṛ."])
 ("l.." ["l."])
 ("l.--" ["ḷ."])
 ("m.." ["m."])
 ("ngg" ["n."])
 ("t.." ["t."])
 ("d.." ["d."])
 ("n.." ["n."])
 ("s.." ["s."])
 ("h.." ["h."])
 
 (" __" [" _"])
 ("!//" ["!/"])
 ("<<<" ["<<"])
 (">>>" [">>"])
 ("?//" ["?/"])
 ("///" ["//"])
 ("$//" ["$/"])
 ("A''" ["A'"])
 ("A--" ["A-"])
 ("A//" ["A/"])
 ("A\"\"" ["A\""])
 ("A^^" ["A^"])
 ("A``" ["A`"])
 ("A~~" ["A~"])
 ("C''" ["C'"])
 ("C//" ["C/"])
 ("C^^" ["C^"])
 ("C``" ["C`"])
 ("C~~" ["C~"])
 ("D//" ["D/"])
 ("D~~" ["D~"])
 ("E''" ["E'"])
 ("E--" ["E-"])
 ("E//" ["E/"])
 ("E\"\"" ["E\""])
 ("E^^" ["E^"])
 ("E``" ["E`"])
 ("E~~" ["E~"])
 ("G//" ["G/"])
 ("G^^" ["G^"])
 ("G``" ["G`"])
 ("G~~" ["G~"])
 ("H//" ["H/"])
 ("H^^" ["H^"])
 ("I''" ["I'"])
 ("I--" ["I-"])
 ("I//" ["I/"])
 ("I\"\"" ["I\""])
 ("I^^" ["I^"])
 ("I``" ["I`"])
 ("I~~" ["I~"])
 ("J^^" ["J^"])
 ("K``" ["K`"])
 ("L''" ["L'"])
 ("L//" ["L/"])
 ("L``" ["L`"])
 ("L~~" ["L~"])
 ("N''" ["N'"])
 ("N//" ["N/"])
 ("N``" ["N`"])
 ("N~~" ["N~"])
 ("O''" ["O'"])
 ("O--" ["O-"])
 ("O//" ["O/"])
 ("O::" ["O:"])
 ("O\"\"" ["O\""])
 ("O^^" ["O^"])
 ("O``" ["O`"])
 ("O~~" ["O~"])
 ("R''" ["R'"])
 ("R``" ["R`"])
 ("R~~" ["R~"])
 ("S''" ["S'"])
 ("S^^" ["S^"])
 ("S``" ["S`"])
 ("S~~" ["S~"])
 ("T//" ["T/"])
 ("T``" ["T`"])
 ("T~~" ["T~"])
 ("U''" ["U'"])
 ("U--" ["U-"])
 ("U::" ["U:"])
 ("U\"\"" ["U\""])
 ("U^^" ["U^"])
 ("U``" ["U`"])
 ("U~~" ["U~"])
 ("Y''" ["Y'"])
 ("Z''" ["Z'"])
 ("Z//" ["Z/"])
 ("Z``" ["Z`"])
 ("Z~~" ["Z~"])
 ("a''" ["a'"])
 ("a--" ["a-"])
 ("a//" ["a/"])
 ("a\"\"" ["a\""])
 ("a^^" ["a^"])
 ("a__" ["a_"])
 ("a``" ["a`"])
 ("a~~" ["a~"])
 ("c''" ["c'"])
 ("c//" ["c/"])
 ("c^^" ["c^"])
 ("c``" ["c`"])
 ("c~~" ["c~"])
 ("d//" ["d/"])
 ("d~~" ["d~"])
 ("e''" ["e'"])
 ("e--" ["e-"])
 ("e//" ["e/"])
 ("e\"\"" ["e\""])
 ("e^^" ["e^"])
 ("e``" ["e`"])
 ("e~~" ["e~"])
 ("e==" ["e="])
 ("g//" ["g/"])
 ("g^^" ["g^"])
 ("g``" ["g`"])
 ("g~~" ["g~"])
 ("h//" ["h/"])
 ("h^^" ["h^"])
 ("i''" ["i'"])
 ("i--" ["i-"])
 ("i//" ["i/"])
 ("i\"\"" ["i\""])
 ("i^^" ["i^"])
 ("i``" ["i`"])
 ("i~~" ["i~"])
 ("j^^" ["j^"])
 ("k//" ["k/"])
 ("k``" ["k`"])
 ("l''" ["l'"])
 ("l//" ["l/"])
 ("l``" ["l`"])
 ("l~~" ["l~"])
 ("n''" ["n'"])
 ("n//" ["n/"])
 ("n``" ["n`"])
 ("n~~" ["n~"])
 ("o''" ["o'"])
 ("o--" ["o-"])
 ("o//" ["o/"])
 ("o::" ["o:"])
 ("o\"\"" ["o\""])
 ("o^^" ["o^"])
 ("o__" ["o_"])
 ("o``" ["o`"])
 ("o~~" ["o~"])
 ("r''" ["r'"])
 ("r``" ["r`"])
 ("r~~" ["r~"])
 ("s''" ["s'"])
 ("s//" ["s/"])
 ("s^^" ["s^"])
 ("s``" ["s`"])
 ("s~~" ["s~"])
 ("t//" ["t/"])
 ("t``" ["t`"])
 ("t~~" ["t~"])
 ("u''" ["u'"])
 ("u--" ["u-"])
 ("u::" ["u:"])
 ("u\"\"" ["u\""])
 ("u^^" ["u^"])
 ("u``" ["u`"])
 ("u~~" ["u~"])
 ("y''" ["y'"])
 ("y\"\"" ["y\""])
 ("z''" ["z'"])
 ("z//" ["z/"])
 ("z``" ["z`"])
 ("z~~" ["z~"])
 )

(provide 'indian-ext)

;;; indian-ext.el ends here
