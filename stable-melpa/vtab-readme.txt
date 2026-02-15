Extends Emacs `tab-bar-mode' to display a vertical tab bar in a side window.

Usage:
  (require 'vtab)
  (vtab-mode 1)

Keybindings (M-s prefix by default):
  M-s M-c  New tab
  M-s M-k  Close tab
  M-s M-n  Next tab
  M-s M-p  Previous tab
  M-s M-s  Go to tab by number
  M-s [key]  Direct tab selection (right-hand layout):
    7890 -> tab 1-4,  uiop -> tab 5-8
    jkl; -> tab 9-12, m,./ -> tab 13-16
  Customize via (define-key vtab-mode-map ...)
