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
  1. Scalling
    You can now scale some faces (in `org-mode' for now):

    - `org-document-info'
    - `org-document-title'
    - `org-level-1'
    - `org-level-2'
    - `org-level-3'

    More to follow in the future.

    By default the scaling is turned off.
    To setup the scaling add the following to your `~/.emacs.d/init.el' or `~/.emacs':

    a. Default scaling
      This will turn on default values of scaling in the theme.

        (customize-set-variable 'timu-rouge-scale-org-document-title t)
        (customize-set-variable 'timu-rouge-scale-org-document-info t)
        (customize-set-variable 'timu-rouge-scale-org-level-1 t)
        (customize-set-variable 'timu-rouge-scale-org-level-2 t)
        (customize-set-variable 'timu-rouge-scale-org-level-3 t)

    b. Custom scaling
      You can choose your own scaling values as well.
      The following is a somewhat exaggerated example.

        (customize-set-variable 'timu-rouge-scale-org-document-title 1.8)
        (customize-set-variable 'timu-rouge-scale-org-document-info 1.4)
        (customize-set-variable 'timu-rouge-scale-org-level-1 1.8)
        (customize-set-variable 'timu-rouge-scale-org-level-2 1.4)
        (customize-set-variable 'timu-rouge-scale-org-level-3 1.2)

  1. "Intense" colors for org-mode
    To emphasize some elements in org-mode.
    You can set a variable to me some faces more "intense".

    By default the intense colors are turned off.
    To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
      (customize-set-variable 'timu-rouge-org-insense-colors t)
