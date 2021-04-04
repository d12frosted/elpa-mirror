;;; xah-math-input.el --- a minor mode for inputting math and Unicode symbols. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2010-2020 by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 2.8.20210403161148
;; Package-Version: 20210403.2312
;; Package-Commit: bc1ff04a11be7c3b728aa012324377305d48e087
;; Created: 08 Dec 2010
;; Package-Requires: ((emacs "24.1"))
;; Keywords: abbrev, convenience, unicode, math, LaTex
;; License: GPL v3
;; URL: http://ergoemacs.org/emacs/xmsi-math-symbols-input.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A minor mode for inputing math symbols and Unicode symbols.

;; M-x `global-xah-math-input-mode' to toggle on/off for all buffers.
;; M-x `xah-math-input-mode' to toggle on/off for current buffer.

;; In lisp code:
;; (global-xah-math-input-mode 1) ; turn on globally
;; (global-xah-math-input-mode 0) ; turn off globally
;; (xah-math-input-mode 1) or (xah-math-input-mode-on) ; turn on for current buffer
;; (xah-math-input-mode 0) or (xah-math-input-mode-off) ; turn off for current buffer

;; Type “inf”, then press 【Shift+Space】 `xah-math-input-change-to-symbol', then it becomes “∞”.
;; Other examples:

;; Other examples:
;;  a → α
;;  p → π
;;  /= → ≠ or ne
;;  >= → ≥ or ge
;;  -> → → or rarr
;;  and → ∧
;; etc.

;; M-x `xah-math-input-list-math-symbols' to see all abbrevs.

;; Home page: http://ergoemacs.org/emacs/xmsi-math-symbols-input.html

;;; Install:

;; Manual install.
;; To have emacs automatically load the file when it restarts, follow these steps:

;; Place the file in the dir 〔~/.emacs.d/lisp/〕. Create the folder if you don't have it.

;; Put the following lines in your emacs init file:
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; (require 'xah-math-input)
;; (global-xah-math-input-mode 1) ; activate the mode globally

;; References
;; http://xahlee.info/comp/unicode_index.html
;; http://xahlee.info/comp/unicode_math_operators.html
;; 〈How Mathematica does Unicode?〉 http://xahlee.info/math/mathematica_unicode.html



;;; Code:

(defvar xah-math-input-abrvs nil "A abbreviation hash table that maps a string to unicode char.")
(setq xah-math-input-abrvs (make-hash-table :test 'equal))

(defun xah-math-input--add-to-hash (@pairs)
  "Add @pairs to the hash table `xah-math-input-abrvs'.
@pairs is a sequence of pairs. Each element is a sequence of 2 items, [key, value]."
  (mapc
   (lambda (x) (puthash (elt x 0) (elt x 1) xah-math-input-abrvs))
   @pairs))

(xah-math-input--add-to-hash
 ;; xml entities http://xahlee.info/js/html_xml_entities.html
 [
  [ "nbsp" " " ]
  [ "bull" "•" ]
  ["nbsp" " "]
  ["bull" "•"]
  ["iexcl" "¡"]
  ["cent" "¢"]
  ["pound" "£"]
  ["curren" "¤"]
  ["yen" "¥"]
  ["brvbar" "¦"]
  ["sect" "§"]
  ["uml" "¨"]
  ["copy" "©"]
  ["ordf" "ª"]
  ["laquo" "«"]
  ["not" "¬"]
  ["reg" "®"]
  ["macr" "¯"]
  ["deg" "°"]
  ["plusmn" "±"]
  ["sup2" "²"]
  ["s2" "²"]
  ["sup3" "³"]
  ["s3" "³"]
  ["acute" "´"]
  ["micro" "µ"]
  ["para" "¶"]
  ["middot" "·"]
  ["cedil" "¸"]
  ["sup1" "¹"]
  ["ordm" "º"]
  ["raquo" "»"]
  ["frac14" "¼"]
  ["frac12" "½"]
  ["frac34" "¾"]
  ["iquest" "¿"]

  ["Agrave" "À"] ["Aacute" "Á"] ["Acirc" "Â"] ["Atilde" "Ã"] ["Auml" "Ä"] ["Aring" "Å"] ["AElig" "Æ"] ["Ccedil" "Ç"] ["Egrave" "È"] ["Eacute" "É"] ["Ecirc" "Ê"] ["Euml" "Ë"] ["Igrave" "Ì"] ["Iacute" "Í"] ["Icirc" "Î"] ["Iuml" "Ï"] ["ETH" "Ð"] ["Ntilde" "Ñ"] ["Ograve" "Ò"] ["Oacute" "Ó"] ["Ocirc" "Ô"] ["Otilde" "Õ"] ["Ouml" "Ö"]

  ["Oslash" "Ø"] ["Ugrave" "Ù"] ["Uacute" "Ú"] ["Ucirc" "Û"] ["Uuml" "Ü"] ["Yacute" "Ý"] ["THORN" "Þ"] ["szlig" "ß"] ["agrave" "à"] ["aacute" "á"] ["acirc" "â"] ["atilde" "ã"] ["auml" "ä"] ["aring" "å"] ["aelig" "æ"] ["ccedil" "ç"] ["egrave" "è"] ["eacute" "é"] ["ecirc" "ê"] ["euml" "ë"] ["igrave" "ì"] ["iacute" "í"] ["icirc" "î"] ["iuml" "ï"] ["eth" "ð"] ["ntilde" "ñ"] ["ograve" "ò"] ["oacute" "ó"] ["ocirc" "ô"] ["otilde" "õ"] ["ouml" "ö"]

  ["ugrave" "ù"] ["uacute" "ú"] ["ucirc" "û"] ["uuml" "ü"] ["yacute" "ý"] ["thorn" "þ"] ["yuml" "ÿ"] ["OElig" "Œ"] ["oelig" "œ"] ["Scaron" "Š"] ["scaron" "š"] ["Yuml" "Ÿ"]

  ["Alpha" "Α"] ["Beta" "Β"] ["Gamma" "Γ"] ["Delta" "Δ"] ["Epsilon" "Ε"] ["Zeta" "Ζ"] ["Eta" "Η"] ["Theta" "Θ"] ["Iota" "Ι"] ["Kappa" "Κ"] ["Lambda" "Λ"] ["Mu" "Μ"] ["Nu" "Ν"] ["Xi" "Ξ"] ["Omicron" "Ο"] ["Pi" "Π"] ["Rho" "Ρ"] ["Sigma" "Σ"] ["Tau" "Τ"] ["Upsilon" "Υ"] ["Phi" "Φ"] ["Chi" "Χ"] ["Psi" "Ψ"] ["Omega" "Ω"]

  ["alpha" "α"] ["beta" "β"] ["gamma" "γ"] ["delta" "δ"] ["epsilon" "ε"] ["zeta" "ζ"] ["eta" "η"] ["theta" "θ"] ["iota" "ι"] ["kappa" "κ"] ["lambda" "λ"] ["mu" "μ"] ["nu" "ν"] ["xi" "ξ"] ["omicron" "ο"] ["pi" "π"] ["rho" "ρ"] ["sigmaf" "ς"] ["sigma" "σ"] ["tau" "τ"] ["upsilon" "υ"] ["phi" "φ"] ["chi" "χ"] ["psi" "ψ"] ["omega" "ω"] ["theta2" "ϑ"] ["upsih" "ϒ"] ["piv" "ϖ"]

  ["ndash" "–"] ["mdash" "—"]

  ["lsquo" "‘"] ["rsquo" "’"] ["sbquo" "‚"] ["ldquo" "“"] ["rdquo" "”"] ["bdquo" "„"]

  ["lsaquo" "‹"] ["rsaquo" "›"]

  ["dagger" "†"]
  ["dagger2" "‡"]
  ["hellip" "…"]
  ["permil" "‰"]

  ["prime" "′"]
  ["prime" "′"]
  ["prime2" "″"]
  ["foot" "′"]
  ["inch" "″"]

  ["oline" "‾"]

  ["frasl" "⁄"]
  ["euro" "€"]
  ["trade" "™"]

  ["im" "ℑ"] ["weierp" "℘"] ["re" "ℜ"] ["alefsym" "ℵ"]

  ["larr" "←"] ["uarr" "↑"] ["rarr" "→"] ["darr" "↓"] ["harr" "↔"] ["crarr" "↵"] ["lArr" "⇐"] ["uArr" "⇑"] ["rArr" "⇒"] ["dArr" "⇓"] ["hArr" "⇔"]

  ["times" "×"] ["divide" "÷"] ["minus" "−"] ["lowast" "∗"] ["radic" "√"]
  ["oplus" "⊕"] ["otimes" "⊗"]
  ["oslash" "ø"]
  ["fnof" "ƒ"]
  ["circ" "ˆ"]
  ["tilde" "˜"]

  ["nabla" "∇"]
  ["part" "∂"]

  ["forall" "∀"] ["exist" "∃"] ["and" "∧"] ["or" "∨"] ["there4" "∴"]

  ["isin" "∈"] ["notin" "∉"] ["ni" "∋"]

  ["prod" "∏"] ["sum" "∑"] ["int" "∫"]

  ["cap" "∩"] ["cup" "∪"]

  ["infin" "∞"] ["prop" "∝"] ["ang" "∠"]

  ["sim" "∼"] ["cong" "≅"] ["asymp" "≈"] ["ne" "≠"] ["equiv" "≡"]

  ["le" "≤"] ["ge" "≥"]

  ["sub" "⊂"] ["sup" "⊃"] ["nsub" "⊄"] ["sube" "⊆"] ["supe" "⊇"]

  ["perp" "⊥"]
  ["sdot" "⋅"]

  ["lceil" "⌈"] ["rceil" "⌉"] ["lfloor" "⌊"] ["rfloor" "⌋"]

  ["lang" "〈"] ["rang" "〉"]

  ["loz" "◊"] ["spades" "♠"] ["clubs" "♣"] ["hearts" "♥"] ["diams" "♦"]

  ]
 )

(xah-math-input--add-to-hash
 ;; http://xahlee.info/math/math_unicode_greek.html
 '(

   ["a" "α"] ["b" "β"] ["g" "γ"] ["d" "δ"] ["e" "ε"] ["z" "ζ"] ["h" "η"] ["q" "θ"] ["i" "ι"] ["k" "κ"] ["l" "λ"] ["m" "μ"] ["n" "ν"] ["x" "ξ"] ["p" "π"] ["r" "ρ"] ["s" "σ"] ["t" "τ"] ["v" "υ"] ["f" "φ"] ["c" "χ"] ["y" "ψ"] ["o" "ω"]

   ["A" "Α"] ["B" "Β"] ["G" "Γ"] ["D" "Δ"] ["E" "Ε"] ["Z" "Ζ"] ["H" "Η"] ["Q" "Θ"] ["I" "Ι"] ["K" "Κ"] ["L" "Λ"] ["M" "Μ"] ["N" "Ν"] ["X" "Ξ"] ["P" "Π"] ["R" "Ρ"] ["S" "Σ"] ["T" "Τ"] ["V" "Υ"] ["F" "Φ"] ["C" "Χ"] ["Y" "Ψ"] ["O" "Ω"]

;; omicron in entities section, need full name

   ))

(xah-math-input--add-to-hash
 ;; Gothic, Double Struck http://xahlee.info/math/math_font_unicode.html
 [

  ["AA" "𝔸"] ["BB" "𝔹"] ["CC" "ℂ"] ["DD" "𝔻"] ["EE" "𝔼"] ["FF" "𝔽"] ["GG" "𝔾"] ["HH" "ℍ"] ["II" "𝕀"] ["JJ" "𝕁"] ["KK" "𝕂"] ["LL" "𝕃"] ["MM" "𝕄"] ["NN" "ℕ"] ["OO" "𝕆"] ["PP" "ℙ"] ["QQ" "ℚ"] ["RR" "ℝ"] ["SS" "𝕊"] ["TT" "𝕋"] ["UU" "𝕌"] ["VV" "𝕍"] ["WW" "𝕎"] ["XX" "𝕏"] ["YY" "𝕐"] ["ZZ" "ℤ"]

  ["dd" "ⅆ"] ["ee" "ⅇ"] ["ii" "ⅈ"] ["jj" "ⅉ"]

  ["N" "ℕ"]
  ["integer" "ℤ"]
  ["rational" "ℚ"]
  ["Q" "ℚ"]
  ["real" "ℝ"]
  ["R" "ℝ"]
  ["C" "ℂ"]
  ["quaternion" "ℍ"]
  ["H" "ℍ"]
  ["sedenion" "𝕊"]
  ["S" "𝕊"]

  ])

(xah-math-input--add-to-hash
;; http://xahlee.info/math/math_font_unicode.html

 [

  ["goA" "𝔄"] ["goB" "𝔅"] ["goC" "ℭ"] ["goD" "𝔇"] ["goE" "𝔈"] ["goF" "𝔉"] ["goG" "𝔊"] ["goH" "ℌ"] ["goI" "ℑ"] ["goJ" "𝔍"] ["goK" "𝔎"] ["goL" "𝔏"] ["goM" "𝔐"] ["goN" "𝔑"] ["goO" "𝔒"] ["goP" "𝔓"] ["goQ" "𝔔"] ["goR" "ℜ"] ["goS" "𝔖"] ["goT" "𝔗"] ["goU" "𝔘"] ["goV" "𝔙"] ["goW" "𝔚"] ["goX" "𝔛"] ["goY" "𝔜"] ["goZ" "ℨ"]

  ["goa" "𝔞"] ["gob" "𝔟"] ["goc" "𝔠"] ["god" "𝔡"] ["goe" "𝔢"] ["gof" "𝔣"] ["gog" "𝔤"] ["goh" "𝔥"] ["goi" "𝔦"] ["goj" "𝔧"] ["gok" "𝔨"] ["gol" "𝔩"] ["gom" "𝔪"] ["gon" "𝔫"] ["goo" "𝔬"] ["gop" "𝔭"] ["goq" "𝔮"] ["gor" "𝔯"] ["gos" "𝔰"] ["got" "𝔱"] ["gou" "𝔲"] ["gov" "𝔳"] ["gow" "𝔴"] ["gox" "𝔵"] ["goy" "𝔶"] ["goz" "𝔷"]

    ["continuum" "ℭ"]
  ])

(xah-math-input--add-to-hash
 ;; Scripted letter forms. Most are outside BMP.
 [

  ["sca" "𝒶"] ["scb" "𝒷"] ["scc" "𝒸"] ["scd" "𝒹"] ["sce" "ℯ"] ["scf" "𝒻"] ["scg" "ℊ"] ["sch" "𝒽"] ["sci" "𝒾"] ["scj" "𝒿"] ["sck" "𝓀"] ["scl" "𝓁"] ["scm" "𝓂"] ["scn" "𝓃"] ["sco" "ℴ"] ["scp" "𝓅"] ["scq" "𝓆"] ["scw" "𝓌"] ["scx" "𝓍"] ["scy" "𝓎"] ["scz" "𝓏"]

  ["scl" "ℓ"]

  ;; todo need all caps

  ["scB" "ℬ"]
  ["scE" "ℰ"]
  ["scF" "ℱ"]
  ["scH" "ℋ"]
  ["scI" "ℐ"]
  ["scL" "ℒ"]
  ["scM" "ℳ"]
  ["scP" "℘"]
  ["scR" "ℛ"]

])

(xah-math-input--add-to-hash
 ;; accented letters
 [

  ["a`" "à"] ["e`" "è"] ["i`" "ì"] ["o`" "ò"] ["u`" "ù"]
  ["A`" "À"] ["E`" "È"] ["I`" "Ì"] ["O`" "Ò"] ["U`" "Ù"]

  ["a^" "â"] ["e^" "ê"] ["i^" "î"] ["o^" "ô"] ["u^" "û"]
  ["A^" "Â"] ["E^" "Ê"] ["I^" "Î"] ["O^" "Ô"] ["U^" "Û"]

  ["a'" "á"] ["e'" "é"] ["i'" "í"] ["o'" "ó"] ["u'" "ú"] ["y'" "ý"]
  ["A'" "Á"] ["E'" "É"] ["I'" "Í"] ["O'" "Ó"] ["U'" "Ú"] ["Y'" "Ý"]

  ["A\"" "Ä"] ["E\"" "Ë"] ["I\"" "Ï"] ["O\"" "Ö"] ["U\"" "Ü"]
  ["a\"" "ä"] ["e\"" "ë"] ["i\"" "ï"] ["o\"" "ö"] ["u\"" "ü"] ["s\"" "ß"] ["y\"" "ÿ"]

  ["Ao" "Å"]
  ["ao" "å"]

  ["AE" "Æ"]
  ["ae" "æ"]

  ["a~" "ã"] ["n~" "ñ"] ["o~" "õ"]
  ["A~" "Ã"] ["N~" "Ñ"] ["O~" "Õ"]

  ])

(xah-math-input--add-to-hash
 ;; Chinese pinyin
 [

  ["a1" "ā"] ["e1" "ē"] ["i1" "ī"] ["o1" "ō"] ["u1" "ū"] ["ü1" "ǖ"] ["v1" "ǖ"]
  ["A1" "Ā"] ["E1" "Ē"] ["I1" "Ī"] ["O1" "Ō"] ["U1" "Ū"] ["Ü1" "Ǖ"] ["V1" "Ǖ"]

  ["a2" "á"] ["e2" "é"] ["i2" "í"] ["o2" "ó"] ["u2" "ú"] ["ü2" "ǘ"] ["v2" "ǘ"]
  ["A2" "Á"] ["E2" "É"] ["I2" "Í"] ["O2" "Ó"] ["U2" "Ú"] ["Ü2" "Ǘ"] ["V2" "Ǘ"]

  ["a3" "ǎ"] ["e3" "ě"] ["i3" "ǐ"] ["o3" "ǒ"] ["u3" "ǔ"] ["ü3" "ǚ"] ["v3" "ǚ"]
  ["A3" "ǎ"] ["E3" "ě"] ["I3" "ǐ"] ["O3" "ǒ"] ["U3" "ǔ"] ["Ü3" "Ǚ"] ["V3" "Ǚ"]

  ["a4" "à"] ["e4" "è"] ["i4" "ì"] ["o4" "ò"] ["u4" "ù"] ["ü4" "ǜ"] ["v4" "ǜ"]
  ["A4" "À"] ["E4" "È"] ["I4" "Ì"] ["O4" "Ò"] ["U4" "Ù"] ["Ü4" "Ǜ"] ["V4" "Ǜ"]

])

(xah-math-input--add-to-hash
 [
  ;; misc non-math symbols
  ["tm" "™"]
  ["3/4" "¾"]
  ["1/2" "½"]
  ["1/4" "¼"]
  ["..." "…"]
  ["fdash" "‒"]
  ["wdash" "〜"]
  ["--" "—"]
  ["??" "⁇"]
  ["?!" "⁈"]
  ["!?" "⁉"]
  ["!!" "‼"]
  ["no" "№"]
  ["No" "№"]

  ["obj" "￼"]
  ["tv" "📺"]

  [":o" "😮"]
  [":O" "😲"]

  ["smile" "☺"]
  [":)" "☺"]
  [":D" "☺"]
  [":/" "😕"]

  [":P" "😋"]
  [":(" "☹"]
  [";)" "😉"]

  ["wink" "😉"]
  ["cry" "😢"]
  ["sad" "☹"]

  ["thumbup" "👍"]
  ["thumbdown" "👎"]
  ["ok" "👌"]
  ["fist" "👊"]
  ["victory" "✌"]
  ["fuckyou" "🖕"]
  ["vulcan" "🖖"]
  ["handshake" "🤝"]
  ["clap" "👏"]
  ["callme" "🤙"]

  ["dc" "℃"]
  ["df" "℉"]

  ;;
  ]

 )

(xah-math-input--add-to-hash
 ;; http://xahlee.info/comp/unicode_units.html
 [
  ["m2" "㎡"]
  ["cm" "㎝"]
  ["cm2" "㎠"]
  ["cm3" "㎤"]
  ] )

(xah-math-input--add-to-hash
 ;; Keyboard http://xahlee.info/comp/unicode_computing_symbols.html
 [

  ["cmd" "⌘"] ["opt" "⌥"] ["alt" "⎇"] ["ctrl" "✲"] ["helm" "⎈"]
  ["caret" "‸"] ["menu" "▤"] ["shift" "⇧"]
  ["enter" "⌤"]
  ["return" "⏎"]
  ["pgup" "⇞"] ["pgdn" "⇟"] ["prevpage" "⎗"] ["nextpage" "⎘"] ["home" "↖"] ["end" "↘"]
  ["esc" "⎋"]
  ["eject" "⏏"]
  ["undo" "⎌"] ["redo" "↷"]
  ["backspace" "⌫"]
  ["delete" "⌦"]
  ["space" "␣"]
  ["tab" "↹"] ["tabl" "⇤"] ["tabr" "⇥"] ["|<-" "⇤"] ["->|" "⇥"] ["lrarr" "⇄"]
  ["sleep" "☾"]
  ["break" "⎊"]
  ["pause" "⎉"]
  ["print" "⎙"]
  ["keyboard" "⌨"]
  ["clear" "⌧"]
  ["cursor" "▮"]
  ["ibeam" "⌶"]
  ["watch" "⌚"]
  ["hourglass" "⌛"]
  ["scissor" "✂"]
  ["envelope" "✉"]
  ["write" "✍"]
  ])

(xah-math-input--add-to-hash
;; http://xahlee.info/comp/unicode_astronomy.html
 [ ["sun" "☉"] ["sunray" "☼"] ["moon" "☾"] ["moonr" "☽"] ["mercury" "☿"] ["earth" "♁"] ["saturn" "♄"] ["uranus" "♅"] ["neptune" "♆"] ["pluto" "♇"] ["jupiter" "♃"] ["male" "♂"] ["mars" "♂"] ["female" "♀"] ["venus" "♀"] ["comet" "☄"]] )

  (xah-math-input--add-to-hash
 [
  ;; superscripts
  ["^0" "⁰"]
  ["^1" "¹"]
  ["^2" "²"]
  ["^3" "³"]
  ["^4" "⁴"]
  ["^5" "⁵"]
  ["^6" "⁶"]
  ["^7" "⁷"]
  ["^8" "⁸"]
  ["^9" "⁹"]
  ["^+" "⁺"]
  ["^-" "⁻"]
  ["^=" "⁼"]
  ["^(" "⁽"]
  ["^)" "⁾"]
  ["^n" "ⁿ"]
  ["^i" "ⁱ"]

  ;; subscripts

  ["_(" "₍"]
  ["_)" "₎"]
  ["_+" "₊"]
  ["_-" "₋"]
  ["_0" "₀"]
  ["_1" "₁"]
  ["_2" "₂"]
  ["_3" "₃"]
  ["_4" "₄"]
  ["_5" "₅"]
  ["_6" "₆"]
  ["_7" "₇"]
  ["_8" "₈"]
  ["_9" "₉"]
  ["_=" "₌"]
  ["_a" "ₐ"]
  ["_e" "ₑ"]

  ["_h" "ₕ"]
  ["_i" "ᵢ"]
  ["_j" "ⱼ"]
  ["_k" "ₖ"]
  ["_l" "ₗ"]
  ["_m" "ₘ"]
  ["_n" "ₙ"]
  ["_o" "ₒ"]
  ["_p" "ₚ"]
  ["_r" "ᵣ"]
  ["_s" "ₛ"]
  ["_t" "ₜ"]
  ["_u" "ᵤ"]
  ["_v" "ᵥ"]
  ["_x" "ₓ"]
  ["_schwa" "ₔ"]

  ])

(xah-math-input--add-to-hash
'( ["inf" "∞"] ["infinity" "∞"] ["empty" "∅"] ["es" "∅"] ["+-" "±"] ["-+" "∓"]))

(xah-math-input--add-to-hash
 ;; http://xahlee.info/comp/unicode_matching_brackets.html
 '(

   ["flr" "⌊⌋"]
   ["ceil" "⌈⌉"]
   ["floor" "⌊⌋"]
   ["ceiling" "⌈⌉"]

   ["\"" "“”"] ;curly quote
   ["\"\"" "“”"]

   ["fq" "‹›"] ;french quote
   ["<>" "‹›"] ;
   ["dfq" "«»"] ; double french quote

   ["cb" "「」"] ; corner bracket
   ["[" "「」"]

   ["[(" "【】"] ; LEFT BLACK LENTICULAR BRACKET

    ["tb" "〔〕"] ; TORTOISE SHELL BRACKET
  ["(" "〔〕"]

   ))

(xah-math-input--add-to-hash
 ;; http://xahlee.info/comp/unicode_circled_numbers.html
 '(

   ["0" "⓪"] ["1" "①"] ["2" "②"] ["3" "③"] ["4" "④"] ["5" "⑤"] ["6" "⑥"] ["7" "⑦"] ["8" "⑧"] ["9" "⑨"] ["10" "⑩"] ["11" "⑪"] ["12" "⑫"] ["13" "⑬"] ["14" "⑭"] ["15" "⑮"] ["16" "⑯"] ["17" "⑰"] ["18" "⑱"] ["19" "⑲"] ["20" "⑳"]

 ["0)" "⓪"] ["1)" "①"] ["2)" "②"] ["3)" "③"] ["4)" "④"] ["5)" "⑤"] ["6)" "⑥"] ["7)" "⑦"] ["8)" "⑧"] ["9)" "⑨"]

 ["a)" "ⓐ"] ["b)" "ⓑ"] ["c)" "ⓒ"] ["d)" "ⓓ"] ["e)" "ⓔ"] ["f)" "ⓕ"] ["g)" "ⓖ"] ["h)" "ⓗ"] ["i)" "ⓘ"] ["j)" "ⓙ"] ["k)" "ⓚ"] ["l)" "ⓛ"] ["m)" "ⓜ"] ["n)" "ⓝ"] ["o)" "ⓞ"] ["p)" "ⓟ"] ["q)" "ⓠ"] ["r)" "ⓡ"] ["s)" "ⓢ"] ["t)" "ⓣ"] ["u)" "ⓤ"] ["v)" "ⓥ"] ["w)" "ⓦ"] ["x)" "ⓧ"] ["y)" "ⓨ"] ["z)" "ⓩ"]

 ["A)" "Ⓐ"] ["B)" "Ⓑ"] ["C)" "Ⓒ"] ["D)" "Ⓓ"] ["E)" "Ⓔ"] ["F)" "Ⓕ"] ["G)" "Ⓖ"] ["H)" "Ⓗ"] ["I)" "Ⓘ"] ["J)" "Ⓙ"] ["K)" "Ⓚ"] ["L)" "Ⓛ"] ["M)" "Ⓜ"] ["N)" "Ⓝ"] ["O)" "Ⓞ"] ["P)" "Ⓟ"] ["Q)" "Ⓠ"] ["R)" "Ⓡ"] ["S)" "Ⓢ"] ["T)" "Ⓣ"] ["U)" "Ⓤ"] ["V)" "Ⓥ"] ["W)" "Ⓦ"] ["X)" "Ⓧ"] ["Y)" "Ⓨ"] ["Z)" "Ⓩ"]

   ["0." "🄀"] ["1." "⒈"] ["2." "⒉"] ["3." "⒊"] ["4." "⒋"] ["5." "⒌"] ["6." "⒍"] ["7." "⒎"] ["8." "⒏"] ["9." "⒐"]

   ["0," "🄁"] ["1," "🄂"] ["2," "🄃"] ["3," "🄄"] ["4," "🄅"] ["5," "🄆"] ["6," "🄇"] ["7," "🄈"] ["8," "🄉"] ["9," "🄊"]

   ))

(xah-math-input--add-to-hash
;; http://xahlee.info/comp/unicode_clocks.html
 '( ["1:00" "🕐"] ["1:30" "🕜"] ["2:00" "🕑"] ["2:30" "🕝"] ["3:00" "🕒"] ["3:30" "🕞"] ["4:00" "🕓"] ["4:30" "🕟"] ["5:00" "🕔"] ["5:30" "🕠"] ["6:00" "🕕"] ["6:30" "🕡"] ["7:00" "🕖"] ["7:30" "🕢"] ["8:00" "🕗"] ["8:30" "🕣"] ["9:00" "🕘"] ["9:30" "🕤"] ["10:00" "🕙"] ["10:30" "🕥"] ["11:00" "🕚"] ["11:30" "🕦"] ["12:00" "🕛"] ["12:30" "🕧"]))

;; http://xahlee.info/comp/unicode_music_symbols.html
(xah-math-input--add-to-hash  '( ["music" "🎶"] ["n4" "♩"] ["n8" "♪"] ["n8d" "♫"] ["n16d" "♬"] ["flat" "♭"] ["natural" "♮"] ["sharp" "♯"]))

(xah-math-input--add-to-hash
 '(
   ;; letter-like forms
   ["al" "ℵ"]
   ["alef" "ℵ"]
   ["beth" "ב"]
   ["gimel" "ג"]
   ["dalet" "ד"]
   ["daleth" "ד"]
   ["Digamma" "Ϝ"]
   ["digamma" "ϝ"]
   ["wp" "℘"]
   ["angstrom" "Å"]
   ["R2" "ℝ²"]
   ["R3" "ℝ³"]
   ["r2" "ℝ²"]
   ["r3" "ℝ³"]
   ["fn" "ƒ"]))

(xah-math-input--add-to-hash
   ;; relations ;; http://xahlee.info/comp/unicode_math_operators.html
 '(
   ["<" "≺"]
   [">" "≻"]

   ["<=" "≤"]
   [">=" "≥"]
   ["!el" "∉"]
   ["el" "∈"]
   ["in" "∈"]
   ["&&" "∧"]
   ["||" "∨"]
   ["not" "¬"]
   ["===" "≡"]
   ["eq" "≡"]
   ["xor" "⊻"]
   ["nand" "⊼"]
   ["nor" "⊽"]

   ["~" "≈"]
   [":=" "≔"]
   ["=:" "≕"]
   ["!=" "≠"]
   ["/=" "≠"]

   ["fa" "∀"] ["forall" "∀"]
   ["ex" "∃"]
   ["tack" "⊢"]
   ["tee" "⊢"]
   ["|-" "⊢"]
   ["-|" "⊣"]

   ["because" "∵"]
   ["cuz" "∵"]
   ["therefore" "∴"]
   ["thus" "∴"]
   ["so" "∴"]
))

(xah-math-input--add-to-hash
 ;; http://xahlee.info/comp/unicode_arrows.html
 '(

   ["<-" "←"] ["->" "→"] ["<->" "↔"] ["!<-" "↚"] ["!->" "↛"] ["!<->" "↮"]
   ["≤" "⇐"] ["=>" "⇒"]
["to" "⇒"]
 ["<=>" "⇔"] ["!<=" "⇍"] ["!=>" "⇏"] ["!<=>" "⇎"]
   ["<==" "⟸"] ["==>" "⟹"] ["<==>" "⟺"]
   ["<-|" "↤"] ["|->" "↦"]
   ["<--" "⟵"] ["-->" "⟶"] ["<-->" "⟷"]

   ))

(xah-math-input--add-to-hash
 '(

   ;; operators
   ["rp" "∘"] ; ring operator
   ["cp" "⊕"] ; circle plus
   ["ct" "⊗"] ; circle times
   ["cm" "⊖"] ; circle minus
   ["cd" "⊘"] ; circle divide
   ["'" "′"]  ; prime
   ["''" "″"] ; double prime
   ["'''" "‴"]
   ["." "·"]
   ["sqrt" "√"]
   ["rt" "√"]
   ["del" "∇"]

   ["pd" "∂"] ; partial derivative
   ["cross" "⨯"]
   ["cint" "∮"] ; contour integral
   ["ccint" "∲"]
   ["cccint" "∳"]
   ["union" "∪"]
   ["intersection" "∩"]))

(xah-math-input--add-to-hash
 '(
   ["/_" "∠"] ;ANGLE
   ["rightangle" "⦜"]
   ["|_" "⦜"]
   ))

(xah-math-input--add-to-hash
 '(
   ["triangle" "▲"]
   ["tri" "▲"]
   ["tril" "◀"]
   ["trir" "▶"]
   ["trid" "▼"]

   ["square" "■"]
   ["circle" "●"]
   ["diamond" "◆"]
   ["star" "★"]
   ["spade" "♠"]
   ["club" "♣"]
   ["heart" "♥"]
   ["diam" "♦"]

   ["<3" "♥"]

   ))

(xah-math-input--add-to-hash
;; http://xahlee.info/comp/unicode_full-width_chars.html
 '(

   ["fw," "，"] ["fw." "．"] ["fw:" "："] ["fw;" "；"] ["fw!" "！"] ["fw?" "？"] ["fw`" "｀"] ["fw'" "＇"] ["fw\"" "＂"] ["fw&" "＆"]

   ["fw(" "（）"] ["fw)" "）"] ["fw[" "［］"] ["fw]" "］"] ["fw{" "｛｝"] ["fw}" "｝"]

   ["fw@" "＠"]

   ["fw^" "＾"] ["fw`" "｀"] ["fw~" "～"] ["fw_" "＿"] ["fw¯" "￣"]

   ["fw#" "＃"] ["fw+" "＋"] ["fw-" "－"] ["fw*" "＊"] ["fw=" "＝"] ["fw<" "＜"] ["fw>" "＞"] ["fw%" "％"]

   ["fw|" "｜"] ["fw¦" "￤"] ["fw/" "／"] ["fw\\" "＼"] ["fw¬" "￢"]

   ["fw((" "｟"] ["fw))" "｠"]

   ["fw$" "＄"] ["fw£" "￡"] ["fw¢" "￠"] ["fw₩" "￦"] ["fw¥" "￥"]

   ))

  ;; 2010-12-10. char to add
  ;; soft hyphen ­
  ;; ↥ ↧ ⇤ ⇥ ⤒ ⤓ ↨

(defun xah-math-input--add-cycle (cycleList)
  "DOCSTRING"
  (let (
        (ll (- (length cycleList) 1) )
        (ii 0)
        )
    (while (< ii ll)
      (let (
            (charThis (elt cycleList ii ))
            (charNext (elt cycleList (+ ii 1) ))
            )
        (puthash charThis charNext xah-math-input-abrvs)
        (setq ii (1+ ii) ) ) )
    (puthash (elt cycleList ll) (elt cycleList 0) xah-math-input-abrvs)
    ))

;; cycle brackets
(xah-math-input--add-cycle ["〘〙" "〔〕"])
(xah-math-input--add-cycle ["〈〉" "《》"])
(xah-math-input--add-cycle ["‹›" "«»"])
(xah-math-input--add-cycle ["【】" "〖〗"])
(xah-math-input--add-cycle ["「」" "『』"])

;; cycle arrows
(xah-math-input--add-cycle ["←" "⇐"])
(xah-math-input--add-cycle ["↑" "⇑"])
(xah-math-input--add-cycle ["→" "⇒"])
(xah-math-input--add-cycle ["↓" "⇓"])
(xah-math-input--add-cycle ["↔" "⇔"])
(xah-math-input--add-cycle ["⇐" "←"])
(xah-math-input--add-cycle ["⇑" "↑"])
(xah-math-input--add-cycle ["⇒" "→"])
(xah-math-input--add-cycle ["⇓" "↓"])
(xah-math-input--add-cycle ["⇔" "↔"])

;; equal, equivalence, congruence, similarity, identity
(xah-math-input--add-cycle ["~" "∼" "〜" "≈" "≅"])
(xah-math-input--add-cycle ["=" "≈" "≡" "≅"])

(xah-math-input--add-cycle ["⊢" "⊣"])

;; dash, hyphen, minus sign
(xah-math-input--add-cycle ["-" "–" "−" ])
(xah-math-input--add-cycle [ "-" "‐" "‑"  "–"  "‒"])
(xah-math-input--add-cycle ["—"  "―" ])

(xah-math-input--add-cycle ["#" "♯" "№"])

(xah-math-input--add-cycle ["θ" "ϑ"])

;; cycle black white chars
(xah-math-input--add-cycle ["■" "□"])
(xah-math-input--add-cycle ["●" "○"])
(xah-math-input--add-cycle ["◆" "◇"])
(xah-math-input--add-cycle ["▲" "△"])
(xah-math-input--add-cycle ["◀" "◁"])
(xah-math-input--add-cycle ["▶" "▷"])
(xah-math-input--add-cycle ["▼" "▽"])
(xah-math-input--add-cycle ["★" "☆"])
(xah-math-input--add-cycle ["♠" "♤"])
(xah-math-input--add-cycle ["♣" "♧"])
(xah-math-input--add-cycle ["♥" "♡"])
(xah-math-input--add-cycle ["♦" "♢"])

(xah-math-input--add-cycle ["✂" "✄"])              ;scissor
(xah-math-input--add-cycle ["↹" "⇥" "⇤"])          ; tab
(xah-math-input--add-cycle ["⏎" "↩" "↵" "⌤" "⎆"])     ; return/enter

(xah-math-input--add-cycle ["∇" "⌫" "⌦"])     ; del delete
(xah-math-input--add-cycle ["↶" "⎌"])     ; undo
(xah-math-input--add-cycle ["✲" "⎈" "‸"])     ; control

(xah-math-input--add-cycle ["*" "•" "×"]) ; bullet, multiply, times

(xah-math-input--add-cycle ["," "，"])
(xah-math-input--add-cycle ["·" "。"])      ; MIDDLE DOT, IDEOGRAPHIC FULL STOP
(xah-math-input--add-cycle [":" "："])    ; FULLWIDTH COLON
(xah-math-input--add-cycle [";" "；"])
(xah-math-input--add-cycle ["!" "❗" "❕" "！"])
(xah-math-input--add-cycle ["♩" "♪" "♫" "♬"])
(xah-math-input--add-cycle ["🎶" "🎵" "🎼"])

(xah-math-input--add-cycle ["&" "＆" "﹠"])
(xah-math-input--add-cycle ["?" "？" "�" "¿" "❓" "❔"])

(xah-math-input--add-cycle [" " " " "　"])         ; space, NO-BREAK SPACE, IDEOGRAPHIC SPACE

(defun xah-math-input--hash-to-list (hashtable)
  "Return a list that represent the HASHTABLE."
  (let (mylist)
    (maphash (lambda (kk vv) (setq mylist (cons (list vv kk) mylist))) hashtable)
    mylist
    ))

(defun xah-math-input-list-math-symbols ()
  "Print a list of math symbols and their input abbreviations.
See `xah-math-input-mode'."
  (interactive)
  (with-output-to-temp-buffer "*xah-math-input output*"
    (mapc (lambda (tt)
            (princ (concat (car tt) " " (car (cdr tt)) "\n")))
          (sort
           (xah-math-input--hash-to-list xah-math-input-abrvs)
           (lambda
             (a b)
             (string< (car a) (car b)))))))

(defvar xah-math-input-keymap nil "Keymap for xah-math-input mode.")

(progn
  (setq xah-math-input-keymap (make-sparse-keymap))
  (define-key xah-math-input-keymap (kbd "S-SPC") 'xah-math-input-change-to-symbol))

(defun xah-math-input--abbr-to-symbol (@inputStr)
  "Returns a char corresponding to @inputStr.
If none found, return nil.
Version 2018-02-16"
  (let ($resultChar $charByNameResult)
    (setq $resultChar (gethash @inputStr xah-math-input-abrvs))
    (cond
     ($resultChar $resultChar)
     ;; begin with u+
     ((string-match "\\`u\\+\\([0-9a-fA-F]+\\)\\'" @inputStr) (char-to-string (string-to-number (match-string 1 @inputStr) 16)))
     ;; decimal. 「945」 or 「#945」
     ((string-match "\\`#?\\([0-9]+\\)\\'" @inputStr) (char-to-string (string-to-number (match-string 1 @inputStr))))
     ;; e.g. decimal with html entity markup. 「&#945;」
     ((string-match "\\`&#\\([0-9]+\\);\\'" @inputStr) (char-to-string (string-to-number (match-string 1 @inputStr))))
     ;; hex number. e.g. 「x3b1」 or 「#x3b1」
     ((string-match "\\`#?x\\([0-9a-fA-F]+\\)\\'" @inputStr) (char-to-string (string-to-number (match-string 1 @inputStr) 16)))
     ;; html entity hex number. e.g. 「&#x3b1;」
     ((string-match "\\`&#x\\([0-9a-fA-F]+\\);\\'" @inputStr) (char-to-string (string-to-number (match-string 1 @inputStr) 16)))
     ;; unicode full name. e.g. 「GREEK SMALL LETTER ALPHA」
     ((and (string-match "\\`\\([- a-zA-Z0-9]+\\)\\'" @inputStr)
           (setq $charByNameResult (xah-math-input--name-to-codepoint @inputStr)))
      (char-to-string $charByNameResult))
     (t nil))))

(defun xah-math-input--name-to-codepoint (@name)
  "Returns integer that's the codepoint of Unicode char named @name (string).
Version 2018-07-09"
  (interactive)
  (if (version<= "26" emacs-version)
      (gethash @name (ucs-names))
    (assoc-string @name (ucs-names) t)))

(defun xah-math-input-change-to-symbol (&optional print-message-when-no-match)
  "Change text selection or word to the left of cursor into a Unicode character.

A valid input can be any abbreviation listed by the command `xah-math-input-list-math-symbols', or, any of the following form:

 945     ← decimal
 #945    ← decimal with prefix #
 &#945;  ← XML entity syntax

 x3b1    ← hexadimal with prefix x
 U+3B1   ← hexadimal with prefix U+ (lower case ok.)
 #x3b1   ← hexadimal with prefix #x
 &#x3b1; ← XML entity syntax

Full Unicode name can also be used, e.g. 「greek small letter alpha」.

If preceded by `universal-argument', print error message when no valid abbrev found.

See also: `xah-math-input-mode'.
Version 2018-07-09"
  (interactive "P")
  (let ($p1 $p2 $inputStr $resultChar)
    (if (region-active-p)
        (progn
          (setq $p1 (region-beginning))
          (setq $p2 (region-end))
          (setq $inputStr (buffer-substring-no-properties $p1 $p2))
          (setq $resultChar (xah-math-input--abbr-to-symbol $inputStr))
          (when $resultChar (progn (delete-region $p1 $p2) (insert $resultChar))))
      ;; if there's no text selection, grab all chars to the left of cursor point up to whitespace, try each string until there a valid abbrev found or none char left.
      (progn
        (setq $p2 (point))
        (skip-chars-backward "^ \t\n" -20)
        (setq $p1 (point))
        (while (and (not $resultChar) (>= (- $p2 $p1) 1))
          (setq $inputStr (buffer-substring-no-properties $p1 $p2))
          (setq $resultChar (xah-math-input--abbr-to-symbol $inputStr))
          (when $resultChar (progn (goto-char $p2) (delete-region $p1 $p2) (insert $resultChar)))
          (setq $p1 (1+ $p1)))))
    (when (not $resultChar)
      (when print-message-when-no-match
        (xah-math-input-list-math-symbols)
        (user-error "「%s」 no match found for that abbrev/input. M-x `xah-math-input-list-math-symbols' for a list. Or use a decimal e.g. 「945」 or hexadecimal e.g. 「x3b1」, or full Unicode name e.g. 「greek small letter alpha」."  $inputStr)))))

;;;###autoload
(define-globalized-minor-mode global-xah-math-input-mode xah-math-input-mode xah-math-input-mode-on)

;;;###autoload
(defun xah-math-input-mode-on ()
  "Turn on `xah-math-input-mode' in current buffer."
  (interactive)
  (xah-math-input-mode 1))

;;;###autoload
(defun xah-math-input-mode-off ()
  "Turn off `xah-math-input-mode' in current buffer."
  (interactive)
  (xah-math-input-mode 0))

;;;###autoload
(define-minor-mode xah-math-input-mode
  "Toggle xah-math-input minor mode.

A mode for inputting a math and Unicode symbols.

Type “inf”, then press \\[xah-math-input-change-to-symbol] (or M-x `xah-math-input-change-to-symbol'), then it becomes “∞”.

Other examples:
 a → α
 p → π
 /= → ≠ or ne
 >= → ≥ or ge
 -> → → or rarr
 and → ∧
etc.

If you have a text selection, then selected word will be taken as input. For example, type 「extraterrestrial alien」, select the phrase, then press \\[xah-math-input-change-to-symbol], then it becomse 👽.

For the complete list of abbrevs, call `xah-math-input-list-math-symbols'.

Decimal and hexadecimal can also be used. Example:

 945     ← decimal
 #945    ← decimal with prefix #
 &#945;  ← XML entity syntax

 x3b1    ← hexadimal with prefix x
 #x3b1   ← hexadimal with prefix #x
 &#x3b1; ← XML entity syntax

Full Unicode name can also be used, e.g. 「greek small letter alpha」.

If you wish to enter a symbor by full unicode name but do not know the full name, M-x `insert'. Asterisk “*” can be used as a wildcard to find the char. For example, M-x `insert' , then type 「*arrow」 then Tab, then emacs will list all unicode char names that has “arrow” in it. (this feature is part of Emacs 23)

Home page at: URL `http://ergoemacs.org/emacs/xah-math-input-math-symbols-input.html'"
  nil
  :global nil
  :lighter " ∑α"
  :keymap xah-math-input-keymap
  )

(provide 'xah-math-input)

;;; xah-math-input.el ends here
