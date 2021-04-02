
Kaolin is a set of eye pleasing themes for GNU Emacs
With support a large number of modes and external packages.
Kaolin themes are based on the pallete that was originally
inspired by Sierra.vim with adding some extra colors.

-------  This package includes the following themes  -------

 * kaolin-dark - a dark jade variant inspired by Sierra.vim.
 * kaolin-light - light variant of the original kaolin-dark.
 * kaolin-aurora - Kaolin meets polar lights.
 * kaolin-bubblegum - Kaolin colorful theme with dark blue background.
 * kaolin-eclipse - a dark purple variant.
 * kaolin-galaxy - bright theme based on one of the Sebastian Andaur arts.
 * kaolin-mono-dark - almost monochrome dark green Kaolin theme.
 * kaolin-mono-light - light variant of monochrome theme.
 * kaolin-ocean - dark blue variant.
 * kaolin-shiva - theme with autumn colors and melanzane background.
 * kaolin-temple - dark brown background with syntax highlighting based on orange and cyan shades.
 * kaolin-valley-dark - colorful Kaolin theme with brown background.
 * kaolin-valley-light - light version of kaolin-valley-dark theme.


-------  Configuration example  -------

 (require 'kaolin-themes)
 (load-theme 'kaolin-dark t)

 ;; Apply treemacs customization for Kaolin themes, requires the all-the-icons package.
 (kaolin-treemacs-theme)

 ;; Or if you have use-package installed
 (use-package kaolin-themes
   :config
   (load-theme 'kaolin-dark t)
   (kaolin-treemacs-theme))

 ;;  Custom theme settings

 ;; The following set to t by default
 (setq kaolin-themes-bold t       ; If nil, disable the bold style.
       kaolin-themes-italic t     ; If nil, disable the italic style.
       kaolin-themes-underline t) ; If nil, disable the underline style.

-------  Some extra theme features, disabled by default  -------

 ;; If t, use the wave underline style instead of regular underline.
 (setq kaolin-themes-underline-wave t)

 ;; When t, will display colored hl-line style
 (setq kaolin-themes-hl-line-colored t)

