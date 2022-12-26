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
  A. Dark and light flavour
    By default the theme is `dark', to setup the `light' flavour:

    - Change the variable `timu-spacegrey-flavour' in the Customization Interface.
      M-x customize RET. Then Search for `timu'.

    or

    - add the following to your `~/.emacs.d/init.el' or `~/.emacs'
      (setq timu-spacegrey-flavour "light")

  B. Scaling
    You can now scale some faces (in `org-mode' for now):

    - `org-document-info'
    - `org-document-title'
    - `org-level-1'
    - `org-level-2'
    - `org-level-3'

    More to follow in the future.

    By default the scaling is turned off.
    To setup the scaling add the following to your `~/.emacs.d/init.el' or `~/.emacs':

    1. Default scaling
      This will turn on default values of scaling in the theme.

        (customize-set-variable 'timu-spacegrey-scale-org-document-title t)
        (customize-set-variable 'timu-spacegrey-scale-org-document-info t)
        (customize-set-variable 'timu-spacegrey-scale-org-level-1 t)
        (customize-set-variable 'timu-spacegrey-scale-org-level-2 t)
        (customize-set-variable 'timu-spacegrey-scale-org-level-3 t)

    2. Custom scaling
      You can choose your own scaling values as well.
      The following is a somewhat exaggerated example.

        (customize-set-variable 'timu-spacegrey-scale-org-document-title 1.8)
        (customize-set-variable 'timu-spacegrey-scale-org-document-info 1.4)
        (customize-set-variable 'timu-spacegrey-scale-org-level-1 1.8)
        (customize-set-variable 'timu-spacegrey-scale-org-level-2 1.4)
        (customize-set-variable 'timu-spacegrey-scale-org-level-3 1.2)

  C. "Intense" colors for `org-mode'
    To emphasize some elements in org-mode.
    You can set a variable to make some faces more "intense".

    By default the intense colors are turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-spacegrey-org-intense-colors t)

  D. Border for the `mode-line'
    You can set a variable to add a border to the mode-line.

    By default the border is turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-spacegrey-mode-line-border t)

III. Utility functions
  A. Toggle dark and light flavour of the theme
      M-x timu-spacegrey-toggle-dark-light RET.

  B. Toggle between intense and non intense colors for `org-mode'
      M-x timu-spacegrey-toggle-org-colors-intensity RET.

  C. Toggle between borders and no borders for the `mode-line'
      M-x timu-spacegrey-toggle-mode-line-border RET.
