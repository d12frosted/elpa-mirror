Display icons for all buffers in ibuffer.

Install:
From melpa, `M-x package-install RET all-the-icons-ibuffer RET`.
(add-hook 'ibuffer-mode-hook #'all-the-icons-ibuffer-mode)
or
(use-package all-the-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . all-the-icons-ibuffer-mode))
