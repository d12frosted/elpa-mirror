
Provides a major-mode for editing Qt build-system files.

; Version 1.0 (7 January 2007)

Based off simple.el

Add the following to your .emacs to install:

(require 'qt-pro-mode)
(add-to-list 'auto-mode-alist '("\\.pr[io]$" . qt-pro-mode))

or:

(use-package qt-pro-mode
  :ensure t
  :mode ("\\.pro\\'" "\\.pri\\'"))
