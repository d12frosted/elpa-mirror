
Change cursor shape and color when running Emacs in a terminal.
Works with any package that sets `cursor-type' (evil, meow, etc.)
or standalone.

Usage:

  (unless (display-graphic-p)
    (require 'evil-terminal-cursor-changer)
    (etcc-on))

With evil-mode, it works out of the box since evil sets `cursor-type'
per state.  Without evil, just set `cursor-type' directly:

  (setq cursor-type 'bar)   ; ⎸
  (setq cursor-type 'box)   ; █
  (setq cursor-type 'hbar)  ; _

Supported terminals: xterm, iTerm2, Kitty, Konsole, Apple Terminal,
Alacritty, WezTerm, Windows Terminal, foot, Ghostty, Hyper, Rio,
Tabby, dumb (mintty, etc.), and anything supporting DECSCUSR sequences.
