;;; alt-codes.el --- Insert alt codes using meta key  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-06-23 00:27:18

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Insert alt codes using meta key.
;; Keyword: alt codes insertion meta
;; Version: 0.0.5
;; Package-Version: 20200723.1037
;; Package-Commit: fb8550cb690b0ec954968afc7e8e953fd6859cdb
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/alt-codes

;; This file is NOT part of GNU Emacs.

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
;;
;; Insert alt codes using meta key.
;;

;;; Code:

(require 'subr-x)

(defgroup alt-codes nil
  "Insert alt codes using meta key."
  :prefix "alt-codes-"
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/alt-codes"))

(defvar alt-codes--list
  '(("1" "☺") ("2" "☻") ("3" "♥") ("4" "♦") ("5" "♣") ("6" "♠")
    ("7" "•") ("8" "◘") ("9" "○") ("10" "◙") ("11" "♂") ("12" "♀")
    ("13" "♪") ("14" "♫") ("15" "☼") ("16" "►") ("17" "◄") ("18" "↕")
    ("19" "‼") ("20" "¶") ("21" "§") ("22" "▬") ("23" "↨") ("24" "↑")
    ("25" "↓") ("26" "→") ("27" "←") ("28" "∟") ("29" "↔") ("30" "▲")
    ("31" "▼") ("32" "spc") ("33" "!") ("34" "\"") ("35" "#") ("36" "$")
    ("37" "%") ("38" "&") ("39" "'") ("40" "(") ("41" ")") ("42" "*")
    ("43" "+") ("44" ",") ("45" "-") ("46" ".") ("47" "/") ("48" "0")
    ("49" "1") ("50" "2") ("51" "3") ("52" "4") ("53" "5") ("54" "6")
    ("55" "7") ("56" "8") ("57" "9") ("58" ":") ("59" ";") ("60" "<")
    ("61" "=") ("62" ">") ("63" "?") ("64" "@") ("65" "A") ("66" "B")
    ("67" "C") ("68" "D") ("69" "E") ("70" "F") ("71" "G") ("72" "H")
    ("73" "I") ("74" "J") ("75" "K") ("76" "L") ("77" "M") ("78" "N")
    ("79" "O") ("80" "P") ("81" "Q") ("82" "R") ("83" "S") ("84" "T")
    ("85" "U") ("86" "V") ("87" "W") ("88" "X") ("89" "Y") ("90" "Z")
    ("91" "[") ("92" "\\") ("93" "]") ("94" "^") ("95" "_") ("96" "`")
    ("97" "a") ("98" "b") ("99" "c") ("100" "d") ("101" "e") ("102" "f")
    ("103" "g") ("104" "h") ("105" "i") ("106" "j") ("107" "k") ("108" "l")
    ("109" "m") ("110" "n") ("111" "o") ("112" "p") ("113" "q") ("114" "r")
    ("115" "s") ("116" "t") ("117" "u") ("118" "v") ("119" "w") ("120" "x")
    ("121" "y") ("122" "z") ("123" "{") ("124" "|") ("125" "}") ("126" "~")
    ("127" "⌂") ("128" "Ç") ("129" "ü") ("130" "é") ("131" "â") ("132" "ä")
    ("133" "à") ("134" "å") ("135" "ç") ("136" "ê") ("137" "ë") ("138" "è")
    ("139" "ï") ("140" "î") ("141" "ì") ("142" "Ä") ("143" "Å") ("144" "É")
    ("145" "æ") ("146" "Æ") ("147" "ô") ("148" "ö") ("149" "ò") ("150" "û")
    ("151" "ù") ("152" "ÿ") ("153" "Ö") ("154" "Ü") ("155" "¢") ("156" "£")
    ("157" "¥") ("158" "₧") ("159" "ƒ") ("160" "á") ("161" "í") ("162" "ó")
    ("163" "ú") ("164" "ñ") ("165" "Ñ") ("166" "ª") ("167" "º") ("168" "¿")
    ("169" "⌐") ("170" "¬") ("171" "½") ("172" "¼") ("173" "¡") ("174" "«")
    ("175" "»") ("176" "░") ("177" "▒") ("178" "▓") ("179" "│") ("180" "┤")
    ("181" "╡") ("182" "╢") ("183" "╖") ("184" "╕") ("185" "╣") ("186" "║")
    ("187" "╗") ("188" "╝") ("189" "") ("190" "╛") ("191" "┐") ("192" "└")
    ("193" "┴") ("194" "┬") ("195" "├") ("196" "─") ("197" "┼") ("198" "╞")
    ("199" "╟") ("200" "╚") ("201" "╔") ("202" "╩") ("203" "╦") ("204" "╠")
    ("205" "═") ("206" "╬") ("207" "╧") ("208" "╨") ("209" "╤") ("210" "╥")
    ("211" "╙") ("212" "╘") ("213" "╒") ("214" "╓") ("215" "╫") ("216" "╪")
    ("217" "┘") ("218" "┌") ("219" "█") ("220" "▄") ("221" "▌") ("222" "▐")
    ("223" "▀") ("224" "α") ("225" "ß") ("226" "Γ") ("227" "π") ("228" "Σ")
    ("229" "σ") ("230" "µ") ("231" "τ") ("232" "Φ") ("233" "Θ") ("234" "Ω")
    ("235" "δ") ("236" "∞") ("237" "φ") ("238" "ε") ("239" "∩") ("240" "≡")
    ("241" "±") ("242" "≥") ("243" "≤") ("244" "⌠") ("245" "⌡") ("246" "÷")
    ("247" "≈") ("248" "°") ("249" "∙") ("250" "·") ("251" "√") ("252" "ⁿ")
    ("253" "²") ("254" "■") ("255" "spc") ("0128" "€") ("0129" "") ("0130" "‚")
    ("0131" "ƒ") ("0132" "„") ("0133" "…") ("0134" "†") ("0135" "‡") ("0136" "ˆ")
    ("0137" "‰") ("0138" "Š") ("0139" "‹") ("0140" "Œ") ("0141" "") ("0142" "Ž")
    ("0143" "") ("0144" "") ("0145" "‘") ("0146" "’") ("0147" "“") ("0148" "”")
    ("0149" "•") ("0150" "–") ("0151" "—") ("0152" "˜") ("0153" "™") ("0154" "š")
    ("0155" "›") ("0156" "œ") ("0157" "") ("0158" "ž") ("0159" "Ÿ") ("0160" "spc")
    ("0161" "¡") ("0162" "¢") ("0163" "£") ("0164" "¤") ("0165" "¥") ("0166" "¦")
    ("0167" "§") ("0168" "¨") ("0169" "©") ("0170" "ª") ("0171" "«") ("0172" "¬")
    ("0173" "") ("0174" "®") ("0175" "¯") ("0176" "°") ("0177" "±") ("0178" "²")
    ("0179" "³") ("0180" "´") ("0181" "µ") ("0182" "¶") ("0183" "·") ("0184" "¸")
    ("0185" "¹") ("0186" "º") ("0187" "»") ("0188" "¼") ("0189" "½") ("0190" "¾")
    ("0191" "¿") ("0192" "À") ("0193" "Á") ("0194" "Â") ("0195" "Ã") ("0196" "Ä")
    ("0197" "Å") ("0198" "Æ") ("0199" "Ç") ("0200" "È") ("0201" "É") ("0202" "Ê")
    ("0203" "Ë") ("0204" "Ì") ("0205" "Í") ("0206" "Î") ("0207" "Ï") ("0208" "Ð")
    ("0209" "Ñ") ("0210" "Ò") ("0211" "Ó") ("0212" "Ô") ("0213" "Õ") ("0214" "Ö")
    ("0215" "×") ("0216" "Ø") ("0217" "Ù") ("0218" "Ú") ("0219" "Û") ("0220" "Ü")
    ("0221" "Ý") ("0222" "Þ") ("0223" "ß") ("0224" "à") ("0225" "á") ("0226" "â")
    ("0227" "ã") ("0228" "ä") ("0229" "å") ("0230" "æ") ("0231" "ç") ("0232" "è")
    ("0233" "é") ("0234" "ê") ("0235" "ë") ("0236" "ì") ("0237" "í") ("0238" "î")
    ("0239" "ï") ("0240" "ð") ("0241" "ñ") ("0242" "ò") ("0243" "ó") ("0244" "ô")
    ("0245" "õ") ("0246" "ö") ("0247" "÷") ("0248" "ø") ("0249" "ù") ("0250" "ú")
    ("0251" "û") ("0252" "ü") ("0253" "ý") ("0254" "þ") ("0255" "ÿ"))
  "Map between Windows-style alt-codes and output characters.")

(defvar-local alt-codes--code ""
  "Recording current key code.")

;;; Core

(defun alt-codes--pre-command-hook ()
  "Hook run before every command."
  (when (symbolp last-input-event)
    (let* ((lie-str (symbol-name last-input-event))
           (key-id "")
           (insert-it nil))
      (if (and (stringp lie-str)
               (string-match-p "M-kp-" lie-str))
          (progn
            (setq key-id (substring lie-str (1- (length lie-str)) (length lie-str)))
            (if (string-match-p "[0-9]+" key-id)
                (progn
                  (setq-local alt-codes--code (concat alt-codes--code key-id))
                  (message "[Alt Code]: %s" alt-codes--code))
              (setq insert-it t)))
        (setq insert-it t))
      (when (and insert-it
                 (not (string= alt-codes--code "")))
        (let ((code (alt-codes--get-symbol alt-codes--code)))
          (when code
            (insert code)))
        (setq-local alt-codes--code "")))))

(defun alt-codes--get-symbol (code)
  "Return the alt code by CODE."
  (eval (cons 'pcase (cons code alt-codes--list))))

;;;###autoload
(defun alt-codes-insert ()
  "Insert the alt-code by string."
  (interactive)
  (let* ((code (string-trim (read-string "Insert Alt-Code: ")))
         (alt-code (alt-codes--get-symbol code)))
    (if alt-code
        (insert alt-code)
      (user-error "Invalid Alt Code, please input the valid one"))))

;;; Entry

(defun alt-codes--enable ()
  "Enable 'alt-codes-mode'."
  (add-hook 'pre-command-hook #'alt-codes--pre-command-hook nil t))

(defun alt-codes--disable ()
  "Disable 'alt-codes-mode'."
  (remove-hook 'pre-command-hook #'alt-codes--pre-command-hook t))

;;;###autoload
(define-minor-mode alt-codes-mode
  "Minor mode for inserting `alt-codes'."
  :lighter " alt-codes"
  :group alt-codes
  (if alt-codes-mode
      (alt-codes--enable)
    (alt-codes--disable)))

(defun alt-codes-turn-on-alt-codes-mode ()
  "Turn on the 'alt-codes-mode'."
  (alt-codes-mode 1))

;;;###autoload
(define-globalized-minor-mode global-alt-codes-mode
  alt-codes-mode alt-codes-turn-on-alt-codes-mode
  :require 'alt-codes)

(provide 'alt-codes)
;;; alt-codes.el ends here
