
The Selected Window Accent Mode is an Emacs package designed to
visually distinguish the currently selected window by applying a
unique accent color to its fringes, mode line, header line, and
margins.

; Quick Start

To use left and bottom accent based on the themes highlight colour:

(use-package selected-window-accent-mode
  :config (selected-window-accent-mode 1)
  :custom
  (selected-window-accent-fringe-thickness 10)
  (selected-window-accent-custom-color nil)
  (selected-window-accent-mode-style 'subtle))

; Define your own colour

(use-package selected-window-accent-mode
  :config (selected-window-accent-mode 1)
  :custom
  (selected-window-accent-fringe-thickness 10)
  (selected-window-accent-custom-color "orange")
  (selected-window-accent-mode-style 'tiling)
  (selected-window-accent-percentage-darken 0)
  (selected-window-accent-percentage-desaturate 0)
  (selected-window-accent-tab-accent t)
  (selected-window-accent-smart-borders t))

; Tweak a themes highlight colour

(use-package selected-window-accent-mode
  :config (selected-window-accent-mode 1)
  :custom
  (selected-window-accent-fringe-thickness 10)
  (selected-window-accent-custom-color nil)
  (selected-window-accent-mode-style 'tiling)
  (selected-window-accent-percentage-darken 20)
  (selected-window-accent-percentage-desaturate 20)
  (selected-window-accent-tab-accent t)
  (selected-window-accent-smart-borders t))

  (global-set-key (kbd "C-c w") selected-window-accent-map)
