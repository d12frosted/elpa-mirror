
DOOM Themes is an opinionated UI plugin and pack of themes extracted from my
[emacs.d], inspired by some of my favorite color themes including:

Flagship themes
  `doom-one'
  `doom-one-light'
  `doom-vibrant'

Additional themes
  [X] `doom-acario-dark' (added by gagbo)
  [X] `doom-acario-light' (added by gagbo)
  [X] `doom-ayu-dark': (added by LoveSponge)
  [X] `doom-ayu-light': (added by LoveSponge)
  [X] `doom-city-lights' (added by fuxialexnder)
  [X] `doom-challenger-deep' (added by fuxialexnder)
  [X] `doom-dark+' (added by ema2159)
  [X] `doom-dracula' (added by fuxialexnder)
  [X] `doom-ephemeral' (added by karetsu)
  [X] `doom-fairy-floss' (added by ema2159)
  [X] `doom-flatwhite' (added by ShaneKilkelly)
  [X] `doom-gruvbox' (added by JongW)
  [X] `doom-gruxbox-light' (added by jsoa)
  [X] `doom-henna' (added by jsoa)
  [X] `doom-homage-white' (added by [mskorzhinskiy])
  [X] `doom-homage-black': (added by [mskorzhinskiy])
  [X] `doom-horizon' (added by karetsu)
  [X] `doom-Iosvkem' (added by neutaaaaan)
  [X] `doom-laserwave' (added by hyakt)
  [X] `doom-material' (added by tam5)
  [X] `doom-manegarm' (added by kenranunderscore)
  [X] `doom-miramare' (added by sagittaros)
  [X] `doom-molokai'
  [X] `doom-monokai-classic' (added by ema2159)
  [X] `doom-monokai-pro' (added by kadenbarlow)
  [X] `doom-moonlight' (added by Brettm12345)
  [X] `doom-nord' (added by fuxialexnder)
  [X] `doom-nord-light' (added by fuxialexnder)
  [X] `doom-nova' (added by bigardone)
  [X] `doom-oceanic-next' (added by juanwolf)
  [X] `doom-old-hope' (added by teesloane)
  [X] `doom-opera' (added by jwintz)
  [X] `doom-opera-light' (added by jwintz)
  [X] `doom-outrun' (added by ema2159)
  [X] `doom-palenight' (added by Brettm12345)
  [X] `doom-peacock' (added by teesloane)
  [x] `doom-plain': (added by [mateossh])
  [x] `doom-plain-dark': (added by [das-s])
  [X] `doom-rouge' (added by JordanFaust)
  [X] `doom-snazzy' (added by ar1a)
  [X] `doom-solarized-dark' (added by ema2159)
  [X] `doom-solarized-light' (added by fuxialexnder)
  [X] `doom-sourcerer' (added by defphil)
  [X] `doom-spacegrey' (added by teesloane)
  [X] `doom-tomorrow-night' (added by emacswatcher)
  [X] `doom-tomorrow-day' (added by emacswatcher)
  [X] `doom-wilmersdorf' (added by ianpan870102)
  [X] `doom-zenburn' (added by jsoa)
  [ ] `doom-mono-dark' / `doom-mono-light'
  [ ] `doom-tron'

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
