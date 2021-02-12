Colorize the mode line according to the Flycheck status.

This package provides the `flycheck-color-mode-line-mode' minor mode which
changes the color of the mode line according to the status of Flycheck syntax
checking.

To enable this mode in Flycheck, add it to `flycheck-mode-hook':

(add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode)

Thanks go to:
- Thomas Järvstrand (tjarvstrand) for the initial code from the excellent
  EDTS package
- Sebastian Wiesner (lunaryorn) for flycheck and his awesome support.
