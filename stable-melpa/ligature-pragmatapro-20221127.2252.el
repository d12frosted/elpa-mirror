;;; ligature-pragmatapro.el --- PragmataPro support for ligature.el -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 0.1
;; URL: https://gitlab.com/wavexx/ligature-pragmatapro.el
;; Package-Requires: ((emacs "28") (ligature "1.0"))
;; Keywords: faces, fonts, ligatures, programming-ligatures

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; `ligature-pragmatapro' provides pre-baked `ligature'[0] configuration
;; for the PragmataPro[1] programming font.
;;
;; Support is configured for all programming modes by calling
;; `ligature-pragmatapro-setup', then enabling `ligature':
;;
;;   (ligature-pragmatapro-setup)
;;   (global-ligature-mode)
;;
;; To be more selective, just use mode hooks:
;;
;;   (ligature-pragmatapro-setup)
;;   (add-hook 'haskell-mode-hook 'ligature-mode)
;;
;; For even more advanced custom configuration, all PragmataPro
;; ligatures are available in `ligature-pragmatapro-ligatures' to be
;; used directly:
;;
;;   (require 'ligature-pragmatapro)
;;   (ligature-set-ligatures 'prog-mode ligature-pragmatapro-ligatures)
;;
;; [0] ligature: https://github.com/mickeynp/ligature.el
;; [1] PragmataPro: https://fsd.it/shop/fonts/pragmatapro/

;;; Code:

;; PragmataPro 0.829 test bench:
;;
;; != !== !=< !≡ !≡≡
;; ## #( #> #? #[ #_ #_( #{
;; $>
;; %=
;; &% && &&& &+ &- &/ &=
;; (|
;; *>
;; ++ +++ ++= += +>
;; -- -< -<< -= -> ->> --- --> -+- -\/ -|> -<| ->- -<- -| -|| -|:
;; .=
;; /= /== /-\ /-: /-> /=> /-< /=< /=: //=
;; := :≡ :=> :-\ :=/ :-/ :-| :=| :|- :|=
;; <$> <* <*> <+> <- <<= <= <=> <> <|> <<- <| <=< <~ <~~ <<~ <$ <+ <!> <@> <#> <%> <^> <&> <?> <.>
;; </> <\> <"> <:> <~> <**> <<^ <-> <!-- <-- <~< <==> <|- <<| <|| <-< <--> <== <<== <-\ <-/ <=\ <=/
;; =<< == === ==> => =~ =>> =~= =>> =>= =<= =< ==< =<| =| =|| =|: =/= =/<
;; >- >= >>- >>= >=> >>^ >>| >!= >-> >== >/= >-| >=| >-\ >=\ >-/ >=/ >λ=
;; ?.
;; [[ [|
;; \= \== \/- \-/ \-: \-> \=> \-< \=< \=:
;; ]]
;; ^= ^^ ^<< ^>>
;; _|_
;; |) |= |>= |> |+| |-> |--> |=> |==> |>- |<< ||> |>> |- ||- ||= |-: |=: |-< |=< |--< |==< |]
;; ~= ~> ~~> ~>>
;; ≡/ ≡/≡ ≡:≡ ≡≡ ≡≡≡

(require 'ligature)
(eval-when-compile (require 'rx))

(defconst ligature-pragmatapro-ligatures
  '(("!" (rx (or "=<" "=" "==" "≡" "≡≡")))
    ("#" (rx (or "#" "(" ">" "[" "?" "_" "_(" "{")))
    ("&" (rx (or "%" "&" "&&" "+" "-" "/" "=")))
    ("+" (rx (or "=" ">" "+" "+=" "++")))
    ("-" (rx (+ (or "-" "/" ":" "<" "=" ">" "+" "\\" "|"))))
    ("/" (rx (or "=" "==" "-\\" "-:" "->" "=>" "-<" "=<" "=:" "/=")))
    (":" (rx (or "=" "≡" "=>" "-\\" "=/" "-/" "-|" "=|" "|-" "|=")))
    ("<" (rx (+ (or "!" "#" "%" "&" "-" "/" ":" "<" "=" ">" "@" "\"" "$" "*" "+" "." "?" "\\" "^" "|" "~"))))
    ("=" (rx (+ (or "/" ":" "<" "=" ">" "|" "~"))))
    (">" (rx (+ (or "!" "-" "/" "=" ">" "\\" "^" "|" "λ"))))
    ("\\" (rx (or "=" "==" "/-" "-/" "-:" "->" "=>" "-<" "=<" "=:")))
    ("^" (rx (or "=" "^" "<<" ">>")))
    ("|" (rx (+ (or ")" "-" ":" "<" "=" ">" "+" "]" "|"))))
    ("~" (rx (or "=" ">" ">>" "~>")))
    ("≡" (rx (or "/"  "/≡" ":≡" "≡" "≡≡")))
    "$>" "%=" "(|" "*>" ".=" "?." "[[" "[|" "]]" "_|_")
  "RX ligatures for PragmataPro.")

;;;###autoload
(defun ligature-pragmatapro-setup ()
  "Setup PragmataPro ligatures for modes based on `prog-mode'."
  (ligature-set-ligatures 'prog-mode ligature-pragmatapro-ligatures))

(provide 'ligature-pragmatapro)

;;; ligature-pragmatapro.el ends here
