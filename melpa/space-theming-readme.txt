
Easily override theme faces by configuration.
This is a port of the 'theming' layer from Spacemacs to regular Emacs.

Customize `space-theming-modifications' with your face overrides, e.g. for theme white-sand and tango:

  (setq space-theming-modifications
        '((white-sand
           (cursor :background "#585858")
           (region :background "#a4a4a4" :foreground "white"))
          (tango
           (hl-line :inherit nil :background "#dbdbd7")
           (form-feed-line :strike-through "#b7b8b5"))))

And activate with:

  (space-theming-init-theming)

For detailed instructions, please look at the README.md at https://github.com/p3r7/space-theming/blob/master/README.md
