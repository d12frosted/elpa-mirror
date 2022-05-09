Sourced other themes to get information about font faces for packages.

I. Installation
  A. Manual installation
    1. Download the `timu-rouge-theme.el' file and add it to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-rouge t)

  B. From Melpa
    1. M-x package-instal <RET> timu-rouge-theme.el <RET>.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-rouge t)

  C. With use-package
    In your `~/.emacs.d/init.el' or `~/.emacs':
      (use-package timu-rouge-theme
        :ensure t
        :config
        (load-theme 'timu-rouge t))
