Sourced other themes to get information about font faces for packages.

I. Installation
  A. Manual installation
    1. Download the `timu-caribbean-theme.el' file and add it to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-caribbean t)

  B. From Melpa
    1. M-x package-instal <RET> timu-caribbean-theme.el <RET>.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
      (load-theme 'timu-caribbean t)

  C. With use-package
    In your `~/.emacs.d/init.el' or `~/.emacs':
      (use-package timu-caribbean-theme
        :ensure t
        :config
        (load-theme 'timu-caribbean t))

II. Configuration
  You can now scale (up) some faces (in `org-mode' for now):

  - `org-document-info'
  - `org-document-title'
  - `org-level-1'
  - `org-level-2'
  - `org-level-3'

  More to follow in the future.

  By default the scaling is turned off.
  To setup the scaling add the following to your `~/.emacs.d/init.el' or `~/.emacs':
    (customize-set-variable 'timu-caribbean-scale-faces t)
