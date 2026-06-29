Flymake backend for GNU Guile using `guild' compile.

Usage:
  (add-hook 'scheme-mode-hook 'flymake-guile)

   Emacs 29 and later:

  (use-package flymake-guile
    :ensure t
    :hook (scheme-mode-hook . flymake-guile))