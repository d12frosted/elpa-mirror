This package uses xelb to build a dock bar for displaying status
information.

An example configuration with use-package:

(use-package slothbar
  :config
  (require 'slothbar-module-requires)
  (setq slothbar-modules '(:left
                           slothbar-tray-create slothbar-date-create
                           slothbar-workspaces-create
                           :right
                           slothbar-wifi-create slothbar-volume-create
                           slothbar-backlight-create
                           slothbar-battery-create))
  ;; to enable multi-screen support
  (slothbar-randr-mode))

then M-x: slothbar-mode
To exit:
M-x: slothbar-mode

On first run, expect a delay of around twenty to thirty seconds
(more or less depending on which fonts are chosen).  During this
time, available fonts configured in slothbar-font-candidates are
loaded and cached in a background process for future reference.

Check the default value of slothbar-font-candidates in
slothbar-font.el to determine a minimal set of fonts.

E.g. if slothbar-font-candidates is:
  '(("Aporetic Sans" "IBM Plex Serif" "Deja Vu Serif" "Cantarell")
    ("Font Awesome")
    ("Aporetic Sans Mono" "IBM Plex Mono" "DejaVu Sans Mono:style=Book")
    ("all-the-icons")
    ("Symbols Nerd Font Mono"))
then for module format strings using:
+ ^f0 ensure one of Aporetic Sans, IBM Plex Serif, Deja Vu Serif, or
  Cantarell is installed
+ ^f1 install the free version of font awesome
+ ^f2 ensure one of Aporetic Sans Mono, IBM Plex Mono, or Deja Vu Sans
  Mono is installed
+ ^f3 run M-x all-the-icons-install-fonts (or install another way)
+ ^f4 run M-x nerd-icons-install-fonts (or install another way)
