;;; russian-techwriter.el --- Input methods for Russian technical writers

;; This input method based on GNU EMACS russian-computer input method

;; Author: Maxim Dunaevskii <dunmaksim@yandex.ru>
;; Maintainer: Maxim Dunaevskii
;; Created: Dec 15, 2022
;; Keywords: multilingual, input method, Cyrillic, i18n
;; Package-Version: 20221229.822
;; Package-Commit: 1d86134d04ecf2305969c7546ead7ad425cd7243
;; Version: 0.0.2
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://github.com/dunmaksim/emacs-russian-techwriter-input-method

;; This file is not a part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; This input method optimized for fast text input with inserting some
;; characters without using (insert-char) function.
;; See the README.md for details.

;;; Code:

(require 'quail)

(defconst russian-techwriter-version "0.0.2"
  "Input method for russian technical writers.

Based on GNU EMACS russian-computer input method")

;; Метод ввода для технических писателей
(quail-define-package
 "russian-techwriter" "Russian" "RUT" nil
 "ЙЦУКЕН Russian layout for technical writers"
 nil t t t t nil nil nil nil nil t)

;;  1! 2" 3№ 4; 5% 6: 7? 8* 9( 0) -_ =+ \/ ёЁ
;;   Й  Ц  У  К  Е  Н  Г  Ш  Щ  З  Х  Ъ
;;    Ф  Ы  В  А  П  Р  О  Л  Д  Ж  Э
;;     Я  Ч  С  М  И  Т  Ь  Б  Ю  .,

(quail-define-rules
 ("1" ?1)
 ("2" ?2)
 ("3" ?3)
 ("4" ?4)
 ("5" ?5)
 ("6" ?6)
 ("7" ?7)
 ("8" ?8)
 ("9" ?9)
 ("0" ?0)
 ("-" ?-)
 ("=" ?=)
 ("|" ?/)
 ("`" ?ё)
 ("q" ?й)
 ("w" ?ц)
 ("e" ?у)
 ("r" ?к)
 ("t" ?е)
 ("y" ?н)
 ("u" ?г)
 ("i" ?ш)
 ("o" ?щ)
 ("p" ?з)
 ("[" ?х)
 ("]" ?ъ)
 ("a" ?ф)
 ("s" ?ы)
 ("d" ?в)
 ("f" ?а)
 ("g" ?п)
 ("h" ?р)
 ("j" ?о)
 ("k" ?л)
 ("l" ?д)
 (";" ?ж)
 ("'" ?э)
 ("\\" ?\\)
 ("z" ?я)
 ("x" ?ч)
 ("c" ?с)
 ("v" ?м)
 ("b" ?и)
 ("n" ?т)
 ("m" ?ь)
 ("," ?б)
 ("." ?ю)
 ("/" ?.)
 ("!" ?!)
 ("@" ?\")
 ("#" ?№)
 ("$" ?\;)
 ("%" ?%)
 ("^" ?:)
 ("&" ??)
 ("*" ?*)
 ("(" ?\()
 (")" ?\))
 ("_" ?_)
 ("+" ?+)
 ("~" ?Ё)
 ("Q" ?Й)
 ("W" ?Ц)
 ("E" ?У)
 ("R" ?К)
 ("T" ?Е)
 ("Y" ?Н)
 ("U" ?Г)
 ("I" ?Ш)
 ("O" ?Щ)
 ("P" ?З)
 ("{" ?Х)
 ("}" ?Ъ)
 ("A" ?Ф)
 ("S" ?Ы)
 ("D" ?В)
 ("F" ?А)
 ("G" ?П)
 ("H" ?Р)
 ("J" ?О)
 ("K" ?Л)
 ("L" ?Д)
 (":" ?Ж)
 ("\"" ?Э)
 ("|" ?|)
 ("Z" ?Я)
 ("X" ?Ч)
 ("C" ?С)
 ("V" ?М)
 ("B" ?И)
 ("N" ?Т)
 ("M" ?Ь)
 ("<" ?Б)
 (">" ?Ю)
 ("?" ?,)

 ;; Составные символы
 ("/-" ?–)  ;; Короткое тире (EN DASH)
 ("/--" ?‒)  ;; Цифровое тире (EM DASH)
 ("/---" ?—) ;; Длинное тире
 ("/*" ?•)   ;; Пуля (BULLET)
 ("/." ?․)   ;; ONE DOT LEADER
 ("/.." ?‥)  ;; TWO DOT LEADER
 ("/..." ?…) ;; Многоточие (HORIZONTAL ELLIPSIS)
 ("/,," ?„)  ;; DOUBLE LOW-9 QUOTATION MARK
 ("/," ?‚)   ;; SINGLE LOW-9 QUOTATION MARK
 ("/''" ?”)  ;; Правая двойная кавычка (RIGHT DOUBLE QUOTATION MARK)
 ("/'" ?’)   ;; RIGHT SINGLE QUOTATION MARK
 ("/``" ?“)  ;; Левая двойная кавычка (LEFT DOUBLE QUOTATION MARK)
 ("/`" ?‘)   ;; LEFT SINGLE QUOTATION MARK
 ("/<<" ?«)  ;; LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
 ("/>>" ?»)  ;; RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK

 ("/&" ?§)
 ("/ab" ?§)  ;; _аб_зац
 ("/pa" ?§)  ;; _pa_ragraph
 ("/#" ?№)
 ("/no" ?№)  ;; _но_мер

 ("/c" ?©)
 ("/tm" ?™)
 ("/reg" ?®)
 ("/eu" ?€)
 ("/ru" ?₽)
 ("/ce"  ?¢)
 ("/te" ?₸)

 ;; fractions
 ("/78" ?⅞)
 ("/58" ?⅝)
 ("/38" ?⅜)
 ("/18" ?⅛)
 ("/56" ?⅚)
 ("/16" ?⅙)
 ("/45" ?⅘)
 ("/35" ?⅗)
 ("/25" ?⅖)
 ("/15" ?⅕)
 ("/23" ?⅔)
 ("/13" ?⅓)
 ("/34" ?¾)
 ("/12" ?½)
 ("/14" ?¼)

 ;; Римские цифры (Romanian)
 ;; Верхний регистр
 ("/RI" ?Ⅰ)
 ("/RII" ?Ⅱ)
 ("/RIII" ?Ⅲ)
 ("/RIV" ?Ⅳ)
 ("/RV" ?Ⅴ)
 ("/RVI" ?Ⅵ)
 ("/RVII" ?Ⅶ)
 ("/RVIII" ?Ⅷ)
 ("/RIX" ?Ⅸ)
 ("/RX" ?Ⅹ)
 ("/RXI" ?Ⅺ)
 ("/RXII" ?Ⅻ)

 ;; Нижний регистр
 ("/ri" ?ⅰ)
 ("/rii" ?ⅱ)
 ("/riii" ?ⅲ)
 ("/riv" ?ⅳ)
 ("/rv" ?ⅴ)
 ("/rvi" ?ⅵ)
 ("/rvii" ?ⅶ)
 ("/rviii" ?ⅷ)
 ("/rix" ?ⅸ)
 ("/rx" ?ⅹ)
 ("/rxi" ?ⅺ)
 ("/rxii" ?ⅻ))


(register-input-method
 "russian-techwriter" "Russian" 'quail-use-package
 "RUTW" "ЙЦУКЕН Russian techwriter layout."
 "quail/cyrillic")

;; Local Variables:
;; coding: utf-8
;; End:

(provide 'russian-techwriter)

;;; russian-techwriter.el ends here
