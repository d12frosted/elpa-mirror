kql-mode provides syntax highlighting for Kusto Query Language (KQL).
To use, add the following to your Emacs configuration:

I. Installation
  A. Manual installation
    1. Download the `kql-mode.el' file and add it to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (add-to-list 'auto-mode-alist '("\\.kql\\'" . kql-mode))

  B. From Melpa
    1. M-x package-install RET kql-mode RET.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (add-to-list 'auto-mode-alist '("\\.kql\\'" . kql-mode))

  C. With `use-package'
    (use-package kql-mode
      :ensure t
      :config
      (add-to-list 'auto-mode-alist '("\\.kql\\'" . kql-mode)))

II.  Activating the mode interactively
   M-x kql-mode RET
