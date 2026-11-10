This package uses xelb to build a dock bar on X11 and elwl/wlr-layer-shell
to build a bar on Wayland.

An example configuration with use-package:

Each entry in `slothbar-bars' is one bar definition.  Its :modules
value is the layout/module list.  The remaining keys configure the bar.

(use-package slothbar
  :config
  (require 'slothbar-module-requires)
  (setq slothbar-bars '((:modules
                         (:left
                          ;; XEmbed tray; skipped automatically on Wayland
                          slothbar-tray-create
                          slothbar-date-create
                          slothbar-workspaces-create

                          :center slothbar-focus-create
                          :right slothbar-wifi-create

                          ;; default output channel volume
                          slothbar-volume-create
                          ;; specify the Capture channel
                          ;; for microphone volume
                          (lambda ()
                           (slothbar-volume-create
                             :icon '((1 . ?󰍭) (110 . ?󰍬))
                             :channel "Capture"
                             :format "^8^f2^[^f4%i^]%p"))
                          slothbar-backlight-create
                          slothbar-battery-create)
                         :bottom t ; nil for top
                         ;; :each = one bar on every output
                         ;; "<output name>" = one specific output
                         :output :each)))
  ;; X RandR output hotplug.  Wayland output hotplug is automatic.
  (slothbar-randr-mode))

then M-x: slothbar-mode
To exit:
M-x: slothbar-mode

On first run, font discovery and loading can add a noticeable delay
before the bar appears.  With byte-compiled fontsloth and one of
the preferred nerd-bundle fonts available, an isolated cold-cache
load measured about 0.4 seconds in one test environment.
Interpreted fontsloth, or multiple very large fonts, can take
several seconds.  Fonts configured in slothbar-font-candidates are
cached for later runs, so warm starts are much faster.  Run `maak
test-font-cache' to re-measure; it reports which fontsloth file was
loaded.

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
