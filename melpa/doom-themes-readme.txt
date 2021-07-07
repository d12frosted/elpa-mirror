
DOOM Themes is an opinionated UI plugin and pack of themes extracted from my
[emacs.d], inspired by some of my favorite color themes including:

Flagship themes
  `doom-one'
  `doom-one-light'
  `doom-vibrant'

Additional themes
  + `doom-acario-dark' (added by gagbo)
  + `doom-acario-light' (added by gagbo)
  + `doom-ayu-dark': (added by LoveSponge)
  + `doom-ayu-light': (added by LoveSponge)
  + `doom-city-lights' (added by fuxialexnder)
  + `doom-challenger-deep' (added by fuxialexnder)
  + `doom-dark+' (added by ema2159)
  + `doom-dracula' (added by fuxialexnder)
  + `doom-ephemeral' (added by karetsu)
  + `doom-fairy-floss' (added by ema2159)
  + `doom-flatwhite' (added by ShaneKilkelly)
  + `doom-gruvbox' (added by JongW)
  + `doom-gruxbox-light' (added by jsoa)
  + `doom-henna' (added by jsoa)
  + `doom-homage-white' (added by [mskorzhinskiy])
  + `doom-homage-black': (added by [mskorzhinskiy])
  + `doom-horizon' (added by karetsu)
  + `doom-Iosvkem' (added by neutaaaaan)
  + `doom-ir-black' (added by legendre6891)
  + `doom-laserwave' (added by hyakt)
  + `doom-material' (added by tam5)
  + `doom-manegarm' (added by kenranunderscore)
  + `doom-miramare' (added by sagittaros)
  + `doom-molokai' (added by hlissner)
  + `doom-monokai-classic' (added by ema2159)
  + `doom-monokai-pro' (added by kadenbarlow)
  + `doom-monokai-machine' (added by minikN)
  + `doom-monokai-octagon' (added by minikN)
  + `doom-monokai-ristretto' (added by minikN)
  + `doom-monokai-spectrum' (added by minikN)
  + `doom-moonlight' (added by Brettm12345)
  + `doom-nord' (added by fuxialexnder)
  + `doom-nord-light' (added by fuxialexnder)
  + `doom-nova' (added by bigardone)
  + `doom-oceanic-next' (added by juanwolf)
  + `doom-old-hope' (added by teesloane)
  + `doom-opera' (added by jwintz)
  + `doom-opera-light' (added by jwintz)
  + `doom-outrun' (added by ema2159)
  + `doom-palenight' (added by Brettm12345)
  + `doom-peacock' (added by teesloane)
  + `doom-plain': (added by [mateossh])
  + `doom-plain-dark': (added by [das-s])
  + `doom-rouge' (added by JordanFaust)
  + `doom-snazzy' (added by ar1a)
  + `doom-solarized-dark' (added by ema2159)
  + `doom-solarized-light' (added by fuxialexnder)
  + `doom-sourcerer' (added by defphil)
  + `doom-spacegrey' (added by teesloane)
  + `doom-tomorrow-night' (added by emacswatcher)
  + `doom-tomorrow-day' (added by emacswatcher)
  + `doom-wilmersdorf' (added by ianpan870102)
  + `doom-zenburn' (added by jsoa)

## Install

  `M-x package-install RET doom-themes`

A comprehensive configuration example:

  (require 'doom-themes)

  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled

  ;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each
  ;; theme may have their own settings.
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Enable custom neotree theme
  (doom-themes-neotree-config)  ; all-the-icons fonts must be installed!
