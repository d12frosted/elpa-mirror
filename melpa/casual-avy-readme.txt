Casual Avy is an opinionated Transient-based menu for Avy.

INSTALLATION
(require 'casual-avy) ; optional if using autoloaded menu
(keymap-global-set "M-g" #'casual-avy-tmenu)

If you are using Emacs ≤ 30.0, you will need to update the built-in package
`transient'. By default, `package.el' will not upgrade a built-in package.
Set the customizable variable `package-install-upgrade-built-in' to `t' to
override this. For more details, please refer to the "Install" section on
this project's repository web page.
