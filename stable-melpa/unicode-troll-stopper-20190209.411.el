;;; unicode-troll-stopper.el --- Minor mode for Highlighting Unicode homoglyphs -*- coding: utf-8; -*-
;; Copyright (C) 2015 Cam Saül

;; Author: Cam Saül <cammsaul@gmail.com>
;; Maintainer: Cam Saül <cammsaul@gmail.com>
;; URL: https://github.com/camsaul/emacs-unicode-troll-stopper
;; Created: 23rd October 2015
;; Version: 1.0
;; Keywords: unicode

;;; Commentary:

;; Replace a semicolon (;) with a greek question mark (;) in your friend's
;; C# code and watch them pull their hair out over the syntax error
;;
;; — Peter Ritchie (@peterritchie) November 16, 2014
;;
;; In recent times, a vicious beast known only as the "Unicode troll" has risen
;; from the abyss, wielding his fearsome tool, the Unicode homoglyph. Looking
;; nearly identical to common ASCII characters, the homoglyphs hide in code,
;; lying in wait for an unsuspecting programmer to devour whole without warning.
;;
;; Don't be the next victim. Enable `unicode-troll-stopper-mode' and force these
;; vicious beasts from the shadows in which they lurk.
;;
;;     (add-hook 'some-major-mode-hook #'unicode-troll-stopper-mode)

;;; Code:

(defconst unicode-troll-stopper--keywords
  `((,(regexp-opt '(" " " " " " " " " " " " " " " " " " " " " " " "
                    " " " " "！" "ǃ" "ⵑ" "︕" "﹗" "＂" "＃" "﹟" "＄" "﹩"
                    "％" "٪" "⁒" "﹪" "＆" "﹠" "＇" "ʹ" "ʹ" "（" "﹙" "）"
                    "﹚" "＊" "⋆" "﹡" "＋" "᛭" "﹢" "，" "ˏ" "ᛧ" "‚" "－"
                    "˗" "−" "⎼" "╴" "﹣" "．" "․" "／" "᜵" "⁄" "∕" "⧸"
                    "ᒿ" "Ʒ" "ℨ" "Ꮞ" "Ꮾ" "Ꮽ" "：" "ː" "˸" "։" "፡" "᛬"
                    "⁚" "∶" "⠆" "︓" "﹕" "；" ";" "︔" "﹔" "＜" "˂" "‹"
                    "≺" "❮" "ⵦ" "﹤" "＝" "═" "⚌" "﹦" "＞" "˃" "›" "≻"
                    "❯" "﹥" "？" "︖" "﹖" "＠" "﹫" "Α" "А" "Ꭺ" "Β" "В"
                    "Ᏼ" "ᗷ" "Ⲃ" "Ϲ" "С" "Ꮯ" "Ⅽ" "Ⲥ" "Ꭰ" "ᗪ" "Ⅾ" "Ε"
                    "Е" "Ꭼ" "ᖴ" "Ԍ" "Ꮐ" "Η" "Н" "ዘ" "Ꮋ" "ᕼ" "Ⲏ" "Ι"
                    "І" "Ⅰ" "Ј" "Ꭻ" "ᒍ" "Κ" "Ꮶ" "ᛕ" "K" "Ⲕ" "Ꮮ" "ᒪ"
                    "Ⅼ" "Μ" "Ϻ" "М" "Ꮇ" "Ⅿ" "Ν" "Ⲛ" "Ο" "О" "Ⲟ" "Ρ"
                    "Р" "Ꮲ" "Ⲣ" "Ԛ" "ⵕ" "Ꭱ" "Ꮢ" "ᖇ" "Ѕ" "Ꮪ" "Τ" "Т"
                    "Ꭲ" "Ꮩ" "Ⅴ" "Ꮃ" "Ꮤ" "Χ" "Х" "Ⅹ" "Ⲭ" "Υ" "Ⲩ" "Ζ"
                    "Ꮓ" "［" "＼" "∖" "⧵" "⧹" "﹨" "］" "＾" "˄" "ˆ" "ᶺ"
                    "⌃" "＿" "ˍ" "⚊" "｀" "ˋ" "`" "‵" "ɑ" "а" "ϲ" "с"
                    "ⅽ" "ԁ" "ⅾ" "е" "ᥱ" "ɡ" "һ" "і" "ⅰ" "ϳ" "ј" "ⅼ"
                    "ⅿ" "ᥒ" "ο" "о" "ഠ" "ⲟ" "р" "ⲣ" "ѕ" "ᥙ" "∪" "ᴠ"
                    "ⅴ" "∨" "⋁" "ᴡ" "х" "ⅹ" "ⲭ" "у" "ỿ" "ᴢ" "｛" "﹛"
                    "｜" "ǀ" "ᛁ" "⎜" "⎟" "⎢" "⎥" "⎪" "⎮" "￨" "｝" "﹜"
                    "～" "˜" "⁓" "∼") 'words)
     1 font-lock-warning-face prepend)))

;;;###autoload
(define-minor-mode unicode-troll-stopper-mode
  "Highlight Unicode homoglyphs in the current buffer."
  :lighter " ТᖇОᒪᏞ"
  (if unicode-troll-stopper-mode
      (font-lock-add-keywords nil unicode-troll-stopper--keywords)
    (font-lock-remove-keywords nil unicode-troll-stopper--keywords))
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (font-lock-fontify-region (point-min) (point-max))))

(provide 'unicode-troll-stopper)
;;; unicode-troll-stopper.el ends here
