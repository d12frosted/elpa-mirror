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
  A. Dark and light fravour
    By default the theme is `dark', to setup the `light' flavour:

    - Change the variable `timu-spacegrey-flavour' in the Customization Interface.
      M-x customize RET. Then Search for `timu'.

    or

    - add the following to your `~/.emacs.d/init.el' or `~/.emacs'
      (setq timu-spacegrey-flavour "light")

  B. Scale selected faces
    You can now scale (up) some faces (in `org-mode' for now):

    - `org-document-info'
    - `org-document-title'
    - `org-level-1'
    - `org-level-2'
    - `org-level-3'

    More to follow in the future.

    By default the scaling is turned off.
    To setup the scaling add the following to your `~/.emacs.d/init.el' or `~/.emacs':
      (customize-set-variable 'timu-spacegrey-scale-faces t)
