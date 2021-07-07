Given a location and day/night color themes, this file provides a
`change-theme` function that selects the appropriate theme based on
whether it is day or night. It will continue to change themes at
sunrise and sunset. To install:

Set the location:
    (setq calendar-location-name "Dallas, TX")
    (setq calendar-latitude 32.85)
    (setq calendar-longitude -96.85)

Specify the day and night themes:
    (require 'theme-changer)
    (change-theme 'solarized-light 'solarized-dark)

One can also pass nil as either of parameters to change-theme, with the
effect of not using a theme (or using the default Emacs them) during that
period of the day. For example:

    (change-theme nil 'solarized-dark)

shall result in setting the default Emacs theme during the day, and
solarized-dark during the night.

You may need to add this file path to your loadpath. For example:
    (add-to-list 'load-path "~/.emacs.d/elisp/theme-changer")

If you want to use the color-theme package instead of the Emacs 24 color
theme facility:
    (setq theme-changer-mode "color-theme")
    (change-theme 'color-theme-solarized-light 'color-theme-solarized-dark)
