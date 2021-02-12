Light themes are easier on the eyes when sun is up.
But when it's dark around - you better to use dark theme.
This package makes process of switching between light and dark
theme as easy as hitting single keystroke.
Features:
* Define your favorite light and dark themes
* Choose which one to run by default
* Switch between them with a single keypress
* Easily roll back to default Emacs theme in case of messed faces

Example configuration:
Default is 'light
(setq heaven-and-hell-theme-type 'dark)

Set preferred light and dark themes (it can be a list of themes as well)
Default light is Emacs default theme, default dark is wombat
(setq heaven-and-hell-themes
      '((light . tsdh-light)
        (dark . (tsdh-dark wombat))))
If you want to load themes without manually confirming them, you can do
(setq heaven-and-hell-load-theme-no-confirm t)

Add init-hook so heaven-and-hell can load your theme
(add-hook 'after-init-hook 'heaven-and-hell-init-hook)

Set keys to toggle theme and return to default Emacs theme
(global-set-key (kbd "C-c <f6>") 'heaven-and-hell-load-default-theme)
(global-set-key (kbd "<f6>") 'heaven-and-hell-toggle-theme)
