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

II. Configuration
  A. Scaling
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

        (customize-set-variable 'timu-rouge-scale-org-document-title t)
        (customize-set-variable 'timu-rouge-scale-org-document-info t)
        (customize-set-variable 'timu-rouge-scale-org-level-1 t)
        (customize-set-variable 'timu-rouge-scale-org-level-2 t)
        (customize-set-variable 'timu-rouge-scale-org-level-3 t)

    2. Custom scaling
      You can choose your own scaling values as well.
      The following is a somewhat exaggerated example.

        (customize-set-variable 'timu-rouge-scale-org-document-title 1.8)
        (customize-set-variable 'timu-rouge-scale-org-document-info 1.4)
        (customize-set-variable 'timu-rouge-scale-org-level-1 1.8)
        (customize-set-variable 'timu-rouge-scale-org-level-2 1.4)
        (customize-set-variable 'timu-rouge-scale-org-level-3 1.2)

  B. "Intense" colors for org-mode
    To emphasize some elements in org-mode.
    You can set a variable to make some faces more "intense".

    By default the intense colors are turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-rouge-org-intense-colors t)

  C. Muted colors for the theme
    You can set muted colors for the theme.

    By default muted colors are turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-rouge-muted-colors t)

  D. Border for the `mode-line'
    You can set a variable to add a border to the mode-line.

    By default the border is turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-rouge-mode-line-border t)

III. Utility functions
  A. Toggle between intense and non intense colors for `org-mode'
      M-x timu-rouge-toggle-org-colors-intensity RET.

  B. Toggle between borders and no borders for the `mode-line'
      M-x timu-rouge-toggle-mode-line-border RET.
