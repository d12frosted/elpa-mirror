
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

OR define your own colour:

(use-package selected-window-accent-mode
  :config (selected-window-accent-mode 1)
  :custom
  (selected-window-accent-fringe-thickness 10)
  (selected-window-accent-custom-color "#427900")
  (selected-window-accent-mode-style 'subtle))

OR subtle / theme accent colour with lightening and saturation and
tab accent

The takes the default highlight colour from the current theme but
applies lightening and saturation along with the same colour tab
accent.

(use-package selected-window-accent-mode
  :config (selected-window-accent-mode 1)
  :custom
  (selected-window-accent-fringe-thickness 20)
  (selected-window-accent-percentage-darken -10)
  (selected-window-accent-percentage-desaturate -100)
  (selected-window-accent-tab-accent t)
  (selected-window-accent-custom-color nil)
  (selected-window-accent-mode-style 'subtle))

; Usage

Interactively Toggle the mode on and off =M-x selected-window-accent-mode=

Interactively change the current style
=M-x selected-window-accent--switch-selected-window-accent-style=
which will present a =completing-read= selection in the minibuffer

The styles that are currently supported :

- default
- tiling
- subtle
;
