Casual Symbol Overlay is a Transient user interface for Symbol Overlay.

INSTALLATION
(require 'casual-symbol-overlay) ; optional if using autoloaded menu
(keymap-set symbol-overlay-map "C-o" #'casual-symbol-overlay-tmenu)

If you are using Emacs ≤ 30.0, you will need to update the built-in package
`transient'. By default, `package.el' will not upgrade a built-in package.
Set the customizable variable `package-install-upgrade-built-in' to `t' to
override this. For more details, please refer to the "Install" section on
this project's repository web page.
