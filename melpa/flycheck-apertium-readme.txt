This package adds support for some Apertium source formats to
flycheck.

For best results, get the core Apertium development tools
(apertium-all-dev) from the nightly repos:
http://wiki.apertium.org/wiki/Installation

To use it, add this to your init.el:

(when (locate-library "flycheck-apertium")
  (require 'flycheck-apertium)
  (add-hook 'nxml-mode-hook 'flycheck-mode))

If not installing through ELPA, you'll also have to do

(add-to-list 'load-path "/path/to/flycheck-apertium-directory/")
