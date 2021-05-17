Increment / Decrement binary, octal, decimal and hex literals.

Works like C-a/C-x in VIM, i.e. searches for number up to EOL and
then increments or decrements and keep zero padding up.

Known Bugs:
See http://github.com/juliapath/evil-numbers/issues

Install:

(require 'evil-numbers)

and bind, for example:

(global-set-key (kbd "C-c +") 'evil-numbers/inc-at-pt)
(global-set-key (kbd "C-c -") 'evil-numbers/dec-at-pt)
(global-set-key (kbd "C-c C-+") 'evil-numbers/inc-at-pt-incremental)
(global-set-key (kbd "C-c C--") 'evil-numbers/dec-at-pt-incremental)

or only in evil's normal and visual state:

(evil-define-key '(normal visual) 'global (kbd "C-c +") 'evil-numbers/inc-at-pt)
(evil-define-key '(normal visual) 'global (kbd "C-c -") 'evil-numbers/dec-at-pt)
(evil-define-key '(normal visual) 'global (kbd "C-c C-+") 'evil-numbers/inc-at-pt-incremental)
(evil-define-key '(normal visual) 'global (kbd "C-c C--") 'evil-numbers/dec-at-pt-incremental)

Usage:
Go and play with your numbers!
