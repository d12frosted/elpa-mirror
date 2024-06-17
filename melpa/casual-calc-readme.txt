Casual Calc is an opinionated Transient-based porcelain for Emacs Calc.

INSTALLATION
(require 'casual-calc)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set calc-alg-map "C-o" #'casual-calc-tmenu)
