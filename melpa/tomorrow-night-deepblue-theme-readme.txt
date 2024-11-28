The Emacs theme Tomorrow Night Deepblue is a beautiful deep blue variant of
the Tomorrow Night theme, which is renowned for its elegant color
palette that is pleasing to the eyes.

The Tomorrow Night Deepblue features a deep blue background color that
creates a calming atmosphere. The contrasting colors make it easy to
distinguish between different elements of your code. The
tomorrow-night-deepblue theme is also a great choice for programmer who miss
the blue themes that were trendy a few years ago.

The theme was inspired by classic text editors such as QuickBASIC, RHIDE, and
Turbo Pascal, as well as tools such as Midnight Commander which featured blue
backgrounds by default. There's something special about the early days of
programming and the tools we used that brings back fond memories.

Installation:
-------------
To install `tomorrow-night-deepblue-theme` from MELPA:

  (use-package tomorrow-night-deepblue-theme
    :ensure t
    :config
    ;; Disable all themes and load the Tomorrow Night Deep Blue theme
    (mapc #'disable-theme custom-enabled-themes)
    ;; Load the tomorrow-night-deepblue theme
    (load-theme 'tomorrow-night-deepblue t))

Links:
------
- GitHub: https://github.com/jamescherti/tomorrow-night-deepblue-theme.el
