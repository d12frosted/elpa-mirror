Used Doom themes for boilerplate for modes & packages.

I. Installation
  A. Manual installation
    1. Download the `timu-spacegrey-theme.el' file and add it to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-spacegrey t)

  B. From Melpa
    1. M-x package-instal <RET> timu-spacegrey-theme.el <RET>.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-spacegrey t)

  C. With use-package
    In your `~/.emacs.d/init.el' or `~/.emacs':
      (use-package timu-spacegrey-theme
        :ensure t
        :config
        (load-theme 'timu-spacegrey t))

II. Configuration
  There is a light version now included as well.
  By default the theme is `dark', to setup the `light' flavour
  add the following to your `~/.emacs.d/init.el' or `~/.emacs':
    (setq timu-spacegrey-flavour "light")
