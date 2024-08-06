Casual Calc is an opinionated Transient-based user interface for Emacs Calc.

INSTALLATION
(require 'casual-calc)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set calc-alg-map "C-o" #'casual-calc-tmenu)

Alternately using `use-package':
(use-package calc
  :defer t)
(use-package casual-calc
  :ensure nil
  :bind (:map
         calc-mode-map
         ("C-o" . casual-calc-tmenu)
         :map
         calc-alg-map
         ("C-o" . casual-calc-tmenu)))
  :after (calc))
