Display nerd icons in ibuffer.

Install:
From melpa, `M-x package-install RET nerd-icons-ibuffer RET`.
(add-hook 'ibuffer-mode-hook #'nerd-icons-ibuffer-mode)
or
(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))
