Add avy support for Flycheck syntax errors quick navigation.

1. Load the package
===================

,----
| (add-to-list 'load-path "/path/to/avy-flycheck.el")
| (require 'avy-flycheck)
`----

2. Give the command a keybinding
================================

`avy-flycheck-setup' bind `avy-flycheck-goto-error' to `C-c ! g'.
(avy-flycheck-setup)

or you can bind `avy-flycheck-goto-error' in global key map
(global-flycheck-mode)
(global-set-key (kbd "C-c '") #'avy-flycheck-goto-error)

3 Acknowledgment
================

This package is based on awesome [flycheck] package and [abo-abo(Oleh
Krehel)]'s awesome [avy] package.

[flycheck] http://www.flycheck.org  https://github.com/flycheck/flycheck

[abo-abo(Oleh Krehel)] https://github.com/abo-abo/

[avy] https://github.com/abo-abo/avy
