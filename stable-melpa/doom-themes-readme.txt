
DOOM Themes is an opinionated UI plugin and pack of themes extracted from my
[emacs.d], inspired by some of my favorite color themes including:

Flagship themes
  `doom-one'
  `doom-one-light'
  `doom-vibrant'

Additional themes
  [X] `doom-city-lights' (added by fuxialexnder)
  [X] `doom-darcula' (added by fuxialexnder)
  [X] `doom-molokai'
  [X] `doom-nord' (added by fuxialexnder)
  [X] `doom-nord-light' (added by fuxialexnder)
  [X] `doom-opera' (added by jwintz)
  [X] `doom-opera-light' (added by jwintz)
  [X] `doom-nova' (added by bigardone)
  [X] `doom-peacock' (added by teesloane)
  [X] `doom-solarized-light' (added by fuxialexnder)
  [X] `doom-spacegrey' (added by teesloane)
  [X] `doom-tomorrow-night'
  [X] `doom-tomorrow-day'
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
