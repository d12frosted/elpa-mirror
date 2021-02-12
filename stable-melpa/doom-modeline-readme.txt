
This package offers a fancy and fast mode-line inspired by minimalism design.

It's integrated into Doom Emacs (https://github.com/hlissner/doom-emacs) and
Centaur Emacs (https://github.com/seagle0128/.emacs.d).

The doom-modeline offers:
- A match count panel (for anzu, iedit, multiple-cursors, symbol-overlay,
  evil-search and evil-substitute)
- An indicator for recording a macro
- Current environment version (e.g. python, ruby, go, etc.) in the major-mode
- A customizable mode-line height (see doom-modeline-height)
- A minor modes segment which is compatible with minions
- An error/warning count segment for flymake/flycheck
- A workspace number segment for eyebrowse
- A perspective name segment for persp-mode
- A window number segment for winum and window-numbering
- An indicator for modal editing state, including evil, overwrite, god, ryo
  and xah-fly-keys, etc.
- An indicator for battery status
- An indicator for current input method
- An indicator for debug state
- An indicator for remote host
- An indicator for LSP state with lsp-mode or eglot
- An indicator for github notifications
- An indicator for unread emails with mu4e-alert
- An indicator for unread emails with gnus (basically builtin)
- An indicator for irc notifications with circe, rcirc or erc.
- An indicator for buffer position which is compatible with nyan-mode or poke-line
- An indicator for party parrot
- An indicator for PDF page number with pdf-tools
- An indicator for markdown/org preivews with grip
- Truncated file name, file icon, buffer state and project name in buffer
  information segment, which is compatible with project, find-file-in-project
  and projectile
- New mode-line for Info-mode buffers
- New package mode-line for paradox
- New mode-line for helm buffers
- New mode-line for git-timemachine buffers

Installation:
From melpa, `M-x package-install RET doom-modeline RET`.
In `init.el`,
(require 'doom-modeline)
(doom-modeline-mode 1)
or
(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))
