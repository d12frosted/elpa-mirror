Sourced other themes to get information about font faces for packages.

I. Installation
  A. Manual installation
    1. Download the `timu-spacegrey-theme.el' file and add it to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-spacegrey t)

  B. From Melpa
    1. M-x package-install RET timu-spacegrey-theme RET.
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
  By default the theme is `dark', to setup the `light' flavour:

  A. Change the variable `timu-spacegrey-flavour' in the Customization Interface.
     M-x customize RET. Then Search for `timu'.

  B. add the following to your `~/.emacs.d/init.el' or `~/.emacs'
    (setq timu-spacegrey-flavour "light")
