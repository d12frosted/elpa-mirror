;;; cp5022x.el --- cp50220, cp50221, cp50222 coding system

;; Copyright (C) 2008  ARISAWA Akihiro

;; Author: ARISAWA Akihiro <ari@mbf.ocn.ne.jp>
;; Keywords: languages, cp50220, cp50221, cp50222, cp51932, cp932

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
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

;; This program requires Mule-6.0 or later.

;;; Code:

;; http://unicode.org/reports/tr30/datafiles/WidthFolding.txt
(define-translation-table
  'cp50220-jisx0201-katakana-to-zenkaku
  '(;; Half-width to generic width (singletons)
    (#xFF61 . #x3002) ;; ｡ → 。	HALFWIDTH IDEOGRAPHIC FULL STOP → IDEOGRAPHIC FULL STOP
    (#xFF62 . #x300C) ;; ｢ → 「	HALFWIDTH LEFT CORNER BRACKET → LEFT CORNER BRACKET
    (#xFF63 . #x300D) ;; ｣ → 」	HALFWIDTH RIGHT CORNER BRACKET → RIGHT CORNER BRACKET
    (#xFF64 . #x3001) ;; ､ → 、	HALFWIDTH IDEOGRAPHIC COMMA → IDEOGRAPHIC COMMA
    ;; Half-witdh to generic Katakana (singletons)
    (#xFF65 . #x30FB) ;; ･ → ・	HALFWIDTH KATAKANA MIDDLE DOT → KATAKANA MIDDLE DOT
    (#xFF66 . #x30F2) ;; ｦ → ヲ	HALFWIDTH KATAKANA LETTER WO → KATAKANA LETTER WO
    (#xFF67 . #x30A1) ;; ｧ → ァ	HALFWIDTH KATAKANA LETTER SMALL A → KATAKANA LETTER SMALL A
    (#xFF68 . #x30A3) ;; ｨ → ィ	HALFWIDTH KATAKANA LETTER SMALL I → KATAKANA LETTER SMALL I
    (#xFF69 . #x30A5) ;; ｩ → ゥ	HALFWIDTH KATAKANA LETTER SMALL U → KATAKANA LETTER SMALL U
    (#xFF6A . #x30A7) ;; ｪ → ェ	HALFWIDTH KATAKANA LETTER SMALL E → KATAKANA LETTER SMALL E
    (#xFF6B . #x30A9) ;; ｫ → ォ	HALFWIDTH KATAKANA LETTER SMALL O → KATAKANA LETTER SMALL O
    (#xFF6C . #x30E3) ;; ｬ → ャ	HALFWIDTH KATAKANA LETTER SMALL YA → KATAKANA LETTER SMALL YA
    (#xFF6D . #x30E5) ;; ｭ → ュ	HALFWIDTH KATAKANA LETTER SMALL YU → KATAKANA LETTER SMALL YU
    (#xFF6E . #x30E7) ;; ｮ → ョ	HALFWIDTH KATAKANA LETTER SMALL YO → KATAKANA LETTER SMALL YO
    (#xFF6F . #x30C3) ;; ｯ → ッ	HALFWIDTH KATAKANA LETTER SMALL TU → KATAKANA LETTER SMALL TU
    (#xFF70 . #x30FC) ;; ｰ → ー	HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK → KATAKANA-HIRAGANA PROLONGED SOUND MARK
    (#xFF71 . #x30A2) ;; ｱ → ア	HALFWIDTH KATAKANA LETTER A → KATAKANA LETTER A
    (#xFF72 . #x30A4) ;; ｲ → イ	HALFWIDTH KATAKANA LETTER I → KATAKANA LETTER I
    (#xFF73 . #x30A6) ;; ｳ → ウ	HALFWIDTH KATAKANA LETTER U → KATAKANA LETTER U
    (#xFF74 . #x30A8) ;; ｴ → エ	HALFWIDTH KATAKANA LETTER E → KATAKANA LETTER E
    (#xFF75 . #x30AA) ;; ｵ → オ	HALFWIDTH KATAKANA LETTER O → KATAKANA LETTER O
    (#xFF76 . #x30AB) ;; ｶ → カ	HALFWIDTH KATAKANA LETTER KA → KATAKANA LETTER KA
    (#xFF77 . #x30AD) ;; ｷ → キ	HALFWIDTH KATAKANA LETTER KI → KATAKANA LETTER KI
    (#xFF78 . #x30AF) ;; ｸ → ク	HALFWIDTH KATAKANA LETTER KU → KATAKANA LETTER KU
    (#xFF79 . #x30B1) ;; ｹ → ケ	HALFWIDTH KATAKANA LETTER KE → KATAKANA LETTER KE
    (#xFF7A . #x30B3) ;; ｺ → コ	HALFWIDTH KATAKANA LETTER KO → KATAKANA LETTER KO
    (#xFF7B . #x30B5) ;; ｻ → サ	HALFWIDTH KATAKANA LETTER SA → KATAKANA LETTER SA
    (#xFF7C . #x30B7) ;; ｼ → シ	HALFWIDTH KATAKANA LETTER SI → KATAKANA LETTER SI
    (#xFF7D . #x30B9) ;; ｽ → ス	HALFWIDTH KATAKANA LETTER SU → KATAKANA LETTER SU
    (#xFF7E . #x30BB) ;; ｾ → セ	HALFWIDTH KATAKANA LETTER SE → KATAKANA LETTER SE
    (#xFF7F . #x30BD) ;; ｿ → ソ	HALFWIDTH KATAKANA LETTER SO → KATAKANA LETTER SO
    (#xFF80 . #x30BF) ;; ﾀ → タ	HALFWIDTH KATAKANA LETTER TA → KATAKANA LETTER TA
    (#xFF81 . #x30C1) ;; ﾁ → チ	HALFWIDTH KATAKANA LETTER TI → KATAKANA LETTER TI
    (#xFF82 . #x30C4) ;; ﾂ → ツ	HALFWIDTH KATAKANA LETTER TU → KATAKANA LETTER TU
    (#xFF83 . #x30C6) ;; ﾃ → テ	HALFWIDTH KATAKANA LETTER TE → KATAKANA LETTER TE
    (#xFF84 . #x30C8) ;; ﾄ → ト	HALFWIDTH KATAKANA LETTER TO → KATAKANA LETTER TO
    (#xFF85 . #x30CA) ;; ﾅ → ナ	HALFWIDTH KATAKANA LETTER NA → KATAKANA LETTER NA
    (#xFF86 . #x30CB) ;; ﾆ → ニ	HALFWIDTH KATAKANA LETTER NI → KATAKANA LETTER NI
    (#xFF87 . #x30CC) ;; ﾇ → ヌ	HALFWIDTH KATAKANA LETTER NU → KATAKANA LETTER NU
    (#xFF88 . #x30CD) ;; ﾈ → ネ	HALFWIDTH KATAKANA LETTER NE → KATAKANA LETTER NE
    (#xFF89 . #x30CE) ;; ﾉ → ノ	HALFWIDTH KATAKANA LETTER NO → KATAKANA LETTER NO
    (#xFF8A . #x30CF) ;; ﾊ → ハ	HALFWIDTH KATAKANA LETTER HA → KATAKANA LETTER HA
    (#xFF8B . #x30D2) ;; ﾋ → ヒ	HALFWIDTH KATAKANA LETTER HI → KATAKANA LETTER HI
    (#xFF8C . #x30D5) ;; ﾌ → フ	HALFWIDTH KATAKANA LETTER HU → KATAKANA LETTER HU
    (#xFF8D . #x30D8) ;; ﾍ → ヘ	HALFWIDTH KATAKANA LETTER HE → KATAKANA LETTER HE
    (#xFF8E . #x30DB) ;; ﾎ → ホ	HALFWIDTH KATAKANA LETTER HO → KATAKANA LETTER HO
    (#xFF8F . #x30DE) ;; ﾏ → マ	HALFWIDTH KATAKANA LETTER MA → KATAKANA LETTER MA
    (#xFF90 . #x30DF) ;; ﾐ → ミ	HALFWIDTH KATAKANA LETTER MI → KATAKANA LETTER MI
    (#xFF91 . #x30E0) ;; ﾑ → ム	HALFWIDTH KATAKANA LETTER MU → KATAKANA LETTER MU
    (#xFF92 . #x30E1) ;; ﾒ → メ	HALFWIDTH KATAKANA LETTER ME → KATAKANA LETTER ME
    (#xFF93 . #x30E2) ;; ﾓ → モ	HALFWIDTH KATAKANA LETTER MO → KATAKANA LETTER MO
    (#xFF94 . #x30E4) ;; ﾔ → ヤ	HALFWIDTH KATAKANA LETTER YA → KATAKANA LETTER YA
    (#xFF95 . #x30E6) ;; ﾕ → ユ	HALFWIDTH KATAKANA LETTER YU → KATAKANA LETTER YU
    (#xFF96 . #x30E8) ;; ﾖ → ヨ	HALFWIDTH KATAKANA LETTER YO → KATAKANA LETTER YO
    (#xFF97 . #x30E9) ;; ﾗ → ラ	HALFWIDTH KATAKANA LETTER RA → KATAKANA LETTER RA
    (#xFF98 . #x30EA) ;; ﾘ → リ	HALFWIDTH KATAKANA LETTER RI → KATAKANA LETTER RI
    (#xFF99 . #x30EB) ;; ﾙ → ル	HALFWIDTH KATAKANA LETTER RU → KATAKANA LETTER RU
    (#xFF9A . #x30EC) ;; ﾚ → レ	HALFWIDTH KATAKANA LETTER RE → KATAKANA LETTER RE
    (#xFF9B . #x30ED) ;; ﾛ → ロ	HALFWIDTH KATAKANA LETTER RO → KATAKANA LETTER RO
    (#xFF9C . #x30EF) ;; ﾜ → ワ	HALFWIDTH KATAKANA LETTER WA → KATAKANA LETTER WA
    (#xFF9D . #x30F3) ;; ﾝ → ン	HALFWIDTH KATAKANA LETTER N → KATAKANA LETTER N
;    (#xFF9E . #x3099) ;; ﾞ → ゙	HALFWIDTH KATAKANA VOICED SOUND MARK → COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
;    (#xFF9F . #x309A) ;; ﾟ → ゚	HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK → COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    (#xFF9E . #x309B) ;; ﾞ → ゛	HALFWIDTH KATAKANA VOICED SOUND MARK → KATAKANA-HIRAGANA VOICED SOUND MARK
    (#xFF9F . #x309C) ;; ﾟ → ゜	HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK → KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    ))

(define-coding-system 'cp50220
  "CP50220 (Microsoft iso-2022-jp for mail)"
  :coding-type 'iso-2022
  :mnemonic ?J
  :designation [(ascii japanese-jisx0208-1978 japanese-jisx0208
		       latin-jisx0201 katakana-jisx0201)
		nil nil nil]
  :flags '(short ascii-at-eol ascii-at-cntl 7-bit designation)
  :charset-list '(ascii japanese-jisx0208
			japanese-jisx0208-1978 latin-jisx0201
			katakana-jisx0201)
  :decode-translation-table '(cp51932-decode japanese-ucs-jis-to-cp932-map)
  :encode-translation-table '(cp50220-jisx0201-katakana-to-zenkaku
			      cp51932-encode japanese-ucs-cp932-to-jis-map))

(define-coding-system 'cp50221
  "CP50221 (Microsoft iso-2022-jp)"
  :coding-type 'iso-2022
  :mnemonic ?J
  :designation [(ascii japanese-jisx0208-1978 japanese-jisx0208
		       latin-jisx0201 katakana-jisx0201)
		nil nil nil]
  :flags '(short ascii-at-eol ascii-at-cntl 7-bit designation)
  :charset-list '(ascii japanese-jisx0208
			japanese-jisx0208-1978 latin-jisx0201
			katakana-jisx0201)
  :decode-translation-table '(cp51932-decode japanese-ucs-jis-to-cp932-map)
  :encode-translation-table '(cp51932-encode japanese-ucs-cp932-to-jis-map))

(define-coding-system 'cp50222
  "CP50222 (Microsoft iso-2022-jp)"
  :coding-type 'iso-2022
  :mnemonic ?J
  :designation [(ascii japanese-jisx0208-1978 japanese-jisx0208
		       latin-jisx0201)
		 katakana-jisx0201 nil nil]
  :flags '(short ascii-at-eol ascii-at-cntl 7-bit designation)
  :charset-list '(ascii japanese-jisx0208
			japanese-jisx0208-1978 latin-jisx0201
			katakana-jisx0201)
  :decode-translation-table '(cp51932-decode japanese-ucs-jis-to-cp932-map)
  :encode-translation-table '(cp51932-encode japanese-ucs-cp932-to-jis-map))

(define-coding-system 'cp51932
  "CP51932 (Microsoft euc-jp)"
  :coding-type 'iso-2022
  :mnemonic ?E
  :designation [ascii japanese-jisx0208 katakana-jisx0201 nil]
  :flags '(short ascii-at-eol ascii-at-cntl single-shift)
  :charset-list '(ascii latin-jisx0201 japanese-jisx0208
			katakana-jisx0201)
  :decode-translation-table '(cp51932-decode japanese-ucs-jis-to-cp932-map)
  :encode-translation-table '(cp51932-encode japanese-ucs-cp932-to-jis-map))

(provide 'cp5022x)
;;; cp5022x.el ends here
