;;; charmap.el --- Unicode table for Emacs

;; Author: Daehyub Kim <lateau@gmail.com>
;; Created: 25 Mar 2013
;; Keywords: unicode character ucs
;; Package-Version: 20131020.458
;; Package-Commit: 165193d91ef96f563ae8366ed4c1a2df5a4eaed2
;; Version: 0.0.1
;; URL: https://github.com/lateau/charmap

;; How to use:
;;   * M-x charmap to display a unicode block.
;;   * M-x charmap-all to display entire unicode blocks but it's slow.
;;   * C-f / C-b / C-n / C-p to navigate the characters.
;;   * RET will copy a character on current cursor to kill-ring.

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(defgroup charmap nil
  "charmap"
  :prefix "charmap-"
  :group 'applications)

(defcustom charmap-enable-simple nil
  "Display a result in minibuffer"
  :type 'symbol
  :group 'charmap)

(defcustom charmap-text-scale-adjust 4
  "Text scale."
  :type 'integer
  :group 'charmap)

(defface charmap-face '((t (:family "dejavu sans" :weight normal :slant normal :underline nil)))
  "Font lock face used to *charmap* buffer."
  :group 'charmap)

(defvar charmap-bufname "*charmap*")

(defconst charmap-describe-char-bufname "*Help*")

(defconst charmap-usage "Usage: C-f / C-b / C-n / C-p / RET: killring / q: quit")

(defconst charmap-char-map
  '(Aegean_Numbers (#x10100 #x1013F)
    Alchemical_Symbols (#x1F700 #x1F77F)
    Alphabetic_Presentation_Forms (#xFB00 #xFB4F)
    Ancient_Greek_Musical_Notation (#x1D200 #x1D24F)
    Ancient_Greek_Numbers (#x10140 #x1018F)
    Ancient_Symbols (#x10190 #x101CF)
    Arabic (#x0600 #x06FF)
    Arabic_Extended-A (#x08A0 #x08FF)
    Arabic_Mathematical_Alphabetic_Symbols (#x1EE00 #x1EEFF)
    Arabic_Presentation_Forms-A (#xFB50 #xFDFF)
    Arabic_Presentation_Forms-B (#xFE70 #xFEFF)
    Arabic_Supplement (#x0750 #x077F)
    Armenian (#x0530 #x058F)
    Arrows (#x2190 #x21FF)
    Avestan (#x10B00 #x10B3F)
    Balinese (#x1B00 #x1B7F)
    Bamum (#xA6A0 #xA6FF)
    Bamum_Supplement (#x16800 #x16A3F)
    Basic_Latin (#x0000 #x007F)
    Batak (#x1BC0 #x1BFF)
    Bengali (#x0980 #x09FF)
    Block_Elements (#x2580 #x259F)
    Bopomofo (#x3100 #x312F)
    Bopomofo_Extended (#x31A0 #x31BF)
    Box_Drawing (#x2500 #x257F)
    Brahmi (#x11000 #x1107F)
    Braille_Patterns (#x2800 #x28FF)
    Buginese (#x1A00 #x1A1F)
    Buhid (#x1740 #x175F)
    Byzantine_Musical_Symbols (#x1D000 #x1D0FF)
    CJK_Compatibility (#x3300 #x33FF)
    CJK_Compatibility_Forms (#xFE30 #xFE4F)
    CJK_Compatibility_Ideographs (#xF900 #xFAFF)
    CJK_Compatibility_Ideographs_Supplement (#x2F800 #x2FA1F)
    CJK_Radicals_Supplement (#x2E80 #x2EFF)
    CJK_Strokes (#x31C0 #x31EF)
    CJK_Symbols_and_Punctuation (#x3000 #x303F)
    CJK_Unified_Ideographs (#x4E00 #x9FFF)
    CJK_Unified_Ideographs_Extension_A (#x3400 #x4DBF)
    CJK_Unified_Ideographs_Extension_B (#x20000 #x2A6DF)
    CJK_Unified_Ideographs_Extension_C (#x2A700 #x2B73F)
    CJK_Unified_Ideographs_Extension_D (#x2B740 #x2B81F)
    Carian (#x102A0 #x102DF)
    Chakma (#x11100 #x1114F)
    Cham (#xAA00 #xAA5F)
    Cherokee (#x13A0 #x13FF)
    Combining_Diacritical_Marks (#x0300 #x036F)
    Combining_Diacritical_Marks_Supplement (#x1DC0 #x1DFF)
    Combining_Diacritical_Marks_for_Symbols (#x20D0 #x20FF)
    Combining_Half_Marks (#xFE20 #xFE2F)
    Common_Indic_Number_Forms (#xA830 #xA83F)
    Control_Pictures (#x2400 #x243F)
    Coptic (#x2C80 #x2CFF)
    Counting_Rod_Numerals (#x1D360 #x1D37F)
    Cuneiform (#x12000 #x123FF)
    Cuneiform_Numbers_and_Punctuation (#x12400 #x1247F)
    Currency_Symbols (#x20A0 #x20CF)
    Cypriot_Syllabary (#x10800 #x1083F)
    Cyrillic (#x0400 #x04FF)
    Cyrillic_Extended-A (#x2DE0 #x2DFF)
    Cyrillic_Extended-B (#xA640 #xA69F)
    Cyrillic_Supplement (#x0500 #x052F)
    Deseret (#x10400 #x1044F)
    Devanagari (#x0900 #x097F)
    Devanagari_Extended (#xA8E0 #xA8FF)
    Dingbats (#x2700 #x27BF)
    Domino_Tiles (#x1F030 #x1F09F)
    Egyptian_Hieroglyphs (#x13000 #x1342F)
    Emoticons (#x1F600 #x1F64F)
    Enclosed_Alphanumeric_Supplement (#x1F100 #x1F1FF)
    Enclosed_Alphanumerics (#x2460 #x24FF)
    Enclosed_CJK_Letters_and_Months (#x3200 #x32FF)
    Enclosed_Ideographic_Supplement (#x1F200 #x1F2FF)
    Ethiopic (#x1200 #x137F)
    Ethiopic_Extended (#x2D80 #x2DDF)
    Ethiopic_Extended-A (#xAB00 #xAB2F)
    Ethiopic_Supplement (#x1380 #x139F)
    General_Punctuation (#x2000 #x206F)
    Geometric_Shapes (#x25A0 #x25FF)
    Georgian (#x10A0 #x10FF)
    Georgian_Supplement (#x2D00 #x2D2F)
    Glagolitic (#x2C00 #x2C5F)
    Gothic (#x10330 #x1034F)
    Greek_Extended (#x1F00 #x1FFF)
    Greek_and_Coptic (#x0370 #x03FF)
    Gujarati (#x0A80 #x0AFF)
    Gurmukhi (#x0A00 #x0A7F)
    Halfwidth_and_Fullwidth_Forms (#xFF00 #xFFEF)
    Hangul_Compatibility_Jamo (#x3130 #x318F)
    Hangul_Jamo (#x1100 #x11FF)
    Hangul_Jamo_Extended-A (#xA960 #xA97F)
    Hangul_Jamo_Extended-B (#xD7B0 #xD7FF)
    Hangul_Syllables (#xAC00 #xD7AF)
    Hanunoo (#x1720 #x173F)
    Hebrew (#x0590 #x05FF)
    High_Private_Use_Surrogates (#xDB80 #xDBFF)
    High_Surrogates (#xD800 #xDB7F)
    Hiragana (#x3040 #x309F)
    IPA_Extensions (#x0250 #x02AF)
    Ideographic_Description_Characters (#x2FF0 #x2FFF)
    Imperial_Aramaic (#x10840 #x1085F)
    Inscriptional_Pahlavi (#x10B60 #x10B7F)
    Inscriptional_Parthian (#x10B40 #x10B5F)
    Javanese (#xA980 #xA9DF)
    Kaithi (#x11080 #x110CF)
    Kana_Supplement (#x1B000 #x1B0FF)
    Kanbun (#x3190 #x319F)
    Kangxi_Radicals (#x2F00 #x2FDF)
    Kannada (#x0C80 #x0CFF)
    Katakana (#x30A0 #x30FF)
    Katakana_Phonetic_Extensions (#x31F0 #x31FF)
    Kayah_Li (#xA900 #xA92F)
    Kharoshthi (#x10A00 #x10A5F)
    Khmer (#x1780 #x17FF)
    Khmer_Symbols (#x19E0 #x19FF)
    Lao (#x0E80 #x0EFF)
    Latin_Extended_Additional (#x1E00 #x1EFF)
    Latin_Extended-A (#x0100 #x017F)
    Latin_Extended-B (#x0180 #x024F)
    Latin_Extended-C (#x2C60 #x2C7F)
    Latin_Extended-D (#xA720 #xA7FF)
    Latin-1_Supplement (#x0080 #x00FF)
    Lepcha (#x1C00 #x1C4F)
    Letterlike_Symbols (#x2100 #x214F)
    Limbu (#x1900 #x194F)
    Linear_B_Ideograms (#x10080 #x100FF)
    Linear_B_Syllabary (#x10000 #x1007F)
    Lisu (#xA4D0 #xA4FF)
    Low_Surrogates (#xDC00 #xDFFF)
    Lycian (#x10280 #x1029F)
    Lydian (#x10920 #x1093F)
    Mahjong_Tiles (#x1F000 #x1F02F)
    Malayalam (#x0D00 #x0D7F)
    Mandaic (#x0840 #x085F)
    Mathematical_Alphanumeric_Symbols (#x1D400 #x1D7FF)
    Mathematical_Operators (#x2200 #x22FF)
    Meetei_Mayek (#xABC0 #xABFF)
    Meetei_Mayek_Extensions (#xAAE0 #xAAFF)
    Meroitic_Cursive (#x109A0 #x109FF)
    Meroitic_Hieroglyphs (#x10980 #x1099F)
    Miao (#x16F00 #x16F9F)
    Miscellaneous_Mathematical_Symbols-A (#x27C0 #x27EF)
    Miscellaneous_Mathematical_Symbols-B (#x2980 #x29FF)
    Miscellaneous_Symbols (#x2600 #x26FF)
    Miscellaneous_Symbols_And_Pictographs (#x1F300 #x1F5FF)
    Miscellaneous_Symbols_and_Arrows (#x2B00 #x2BFF)
    Miscellaneous_Technical (#x2300 #x23FF)
    Modifier_Tone_Letters (#xA700 #xA71F)
    Mongolian (#x1800 #x18AF)
    Musical_Symbols (#x1D100 #x1D1FF)
    Myanmar (#x1000 #x109F)
    Myanmar_Extended-A (#xAA60 #xAA7F)
    NKo (#x07C0 #x07FF)
    New_Tai_Lue (#x1980 #x19DF)
    Number_Forms (#x2150 #x218F)
    Ogham (#x1680 #x169F)
    Ol_Chiki (#x1C50 #x1C7F)
    Old_Italic (#x10300 #x1032F)
    Old_Persian (#x103A0 #x103DF)
    Old_South_Arabian (#x10A60 #x10A7F)
    Old_Turkic (#x10C00 #x10C4F)
    Optical_Character_Recognition (#x2440 #x245F)
    Oriya (#x0B00 #x0B7F)
    Osmanya (#x10480 #x104AF)
    Phags-pa (#xA840 #xA87F)
    Phaistos_Disc (#x101D0 #x101FF)
    Phoenician (#x10900 #x1091F)
    Phonetic_Extensions (#x1D00 #x1D7F)
    Phonetic_Extensions_Supplement (#x1D80 #x1DBF)
    Playing_Cards (#x1F0A0 #x1F0FF)
    Private_Use_Area (#xE000 #xF8FF)
    Rejang (#xA930 #xA95F)
    Rumi_Numeral_Symbols (#x10E60 #x10E7F)
    Runic (#x16A0 #x16FF)
    Samaritan (#x0800 #x083F)
    Saurashtra (#xA880 #xA8DF)
    Sharada (#x11180 #x111DF)
    Shavian (#x10450 #x1047F)
    Sinhala (#x0D80 #x0DFF)
    Small_Form_Variants (#xFE50 #xFE6F)
    Sora_Sompeng (#x110D0 #x110FF)
    Spacing_Modifier_Letters (#x02B0 #x02FF)
    Specials (#xFFF0 #xFFFF)
    Sundanese (#x1B80 #x1BBF)
    Sundanese_Supplement (#x1CC0 #x1CCF)
    Superscripts_and_Subscripts (#x2070 #x209F)
    Supplemental_Arrows-A (#x27F0 #x27FF)
    Supplemental_Arrows-B (#x2900 #x297F)
    Supplemental_Mathematical_Operators (#x2A00 #x2AFF)
    Supplemental_Punctuation (#x2E00 #x2E7F)
    Supplementary_Private_Use_Area-A (#xF0000 #xFFFFF)
    Supplementary_Private_Use_Area-B (#x100000 #x10FFFF)
    Syloti_Nagri (#xA800 #xA82F)
    Syriac (#x0700 #x074F)
    Tagalog (#x1700 #x171F)
    Tagbanwa (#x1760 #x177F)
    Tags (#xE0000 #xE007F)
    Tai_Le (#x1950 #x197F)
    Tai_Tham (#x1A20 #x1AAF)
    Tai_Viet (#xAA80 #xAADF)
    Tai_Xuan_Jing_Symbols (#x1D300 #x1D35F)
    Takri (#x11680 #x116CF)
    Tamil (#x0B80 #x0BFF)
    Telugu (#x0C00 #x0C7F)
    Thaana (#x0780 #x07BF)
    Thai (#x0E00 #x0E7F)
    Tibetan (#x0F00 #x0FFF)
    Tifinagh (#x2D30 #x2D7F)
    Transport_And_Map_Symbols (#x1F680 #x1F6FF)
    Ugaritic (#x10380 #x1039F)
    Unified_Canadian_Aboriginal_Syllabics (#x1400 #x167F)
    Unified_Canadian_Aboriginal_Syllabics_Extended (#x18B0 #x18FF)
    Vai (#xA500 #xA63F)
    Variation_Selectors (#xFE00 #xFE0F)
    Variation_Selectors_Supplement (#xE0100 #xE01EF)
    Vedic_Extensions (#x1CD0 #x1CFF)
    Vertical_Forms (#xFE10 #xFE1F)
    Yi_Radicals (#xA490 #xA4CF)
    Yi_Syllables (#xA000 #xA48F)
    Yijing_Hexagram_Symbols (#x4DC0 #x4DFF)))

(defun charmap-forward ()
  "Move to forward then display a character description."
  (interactive)
  (forward-char 1)
  (charmap-describe-char))

(defun charmap-backward ()
  "Move to backward."
  (interactive)
  (backward-char 1)
  (charmap-describe-char))

(defun charmap-next-line ()
  (interactive)
  (next-line)
  (charmap-describe-char))

(defun charmap-prev-line ()
  (interactive)
  (previous-line)
  (charmap-describe-char))

(defun charmap-describe-char ()
  "Display description of a character at current point."
  (describe-char (point))
  (if (equal (current-buffer) (get-buffer charmap-describe-char-bufname))
      (other-window -1)))

(defun charmap-copy-char ()
  "Copy a character on current point."
  (interactive)
  (kill-ring-save (point) (+ (point) 1))
  (message "Copied to kill-ring"))

(defun charmap-delete-buffers ()
  (interactive)
  (and (get-buffer-window charmap-describe-char-bufname)
       (delete-window (get-buffer-window charmap-describe-char-bufname)))
  (and (get-buffer-window charmap-bufname)
       (delete-window (get-buffer-window charmap-bufname))))

(defvar charmap-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-f") 'charmap-forward)
    (define-key map (kbd "C-b") 'charmap-backward)
    (define-key map (kbd "C-n") 'charmap-next-line)
    (define-key map (kbd "C-p") 'charmap-prev-line)
    (define-key map (kbd "RET") 'charmap-copy-char)
    (define-key map (kbd "s") 'charmap-search)
    (define-key map (kbd "q") 'charmap-delete-buffers)
    map))

(defun charmap-get-blocks ()
  "Retrieve all usable unicode blocks."
  (remove nil (map 'list #'(lambda (x) (and (symbolp x) x)) charmap-char-map)))

(defmacro charmap-print-chars (start end)
  "Print characters from start to end."
  `(do ((c ,start (+ c 1))
        (i 1 (+ i 1)))
       ((> c ,end) nil)
     (insert-char c 1)))

(defun charmap-print (unicode-block)
  "Retrieve a unicode block and prepare for printing the block to buffer."
  (let ((data (plist-get charmap-char-map unicode-block)))
    (and data
         (charmap-print-chars (first data) (second data)))))

(defmacro with-charmap-buffer (&rest body)
  `(let ((buf (get-buffer-create charmap-bufname))
         (bufname charmap-bufname))
     (with-current-buffer bufname
       (delete-other-windows)
       (split-window)
       (other-window -1)
       (switch-to-buffer bufname)
       (setq buffer-read-only nil)
       (set (make-local-variable 'bidi-display-reordering) nil)
       (erase-buffer)
       (text-scale-set charmap-text-scale-adjust)
       (setq buffer-face-mode-face 'charmap-face)
       (buffer-face-mode)
       ,@body
       (beginning-of-buffer)
       (setq buffer-read-only t)
       (use-local-map charmap-keymap)
       (font-lock-mode t)
       (message charmap-usage))))

(defun charmap ()
  "Display a specified unicode block."
  (interactive)
  (let ((unicode-block (intern (substitute ?_ ?\s (completing-read "Select a unicode block: " (map 'list #'(lambda(x) (substitute ?\s ?_ (symbol-name x))) (charmap-get-blocks)))))))
    (if (plist-get charmap-char-map unicode-block)
        (with-charmap-buffer
         (charmap-print unicode-block))
      (error (format "Unicode block '%s' couldn't be found." (symbol-name unicode-block))))))

(defun charmap-all ()
  "Display entire unicode table."
  (interactive)
  (with-charmap-buffer
   (dolist (unicode-block (charmap-get-blocks))
     (charmap-print unicode-block)
     (delete-backward-char 1)
     (insert "\n\n"))))

;;;###autoload

(provide 'charmap)

;;; charmap.el ends here
