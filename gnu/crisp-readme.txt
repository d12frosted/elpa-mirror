Keybindings and minor functions to duplicate the functionality and
finger-feel of the CRiSP/Brief editor.  This package is designed to
facilitate transitioning from Brief to (XE|E)macs with a minimum
amount of hassles.

Enable this package by putting (require 'crisp) in your .emacs and
use M-x crisp-mode to toggle it on or off.

This package will automatically load the scroll-all.el package if
you put (setq crisp-load-scroll-all t) in your .emacs before
loading this package.  If this feature is enabled, it will bind
meta-f1 to the scroll-all mode toggle.  The scroll-all package
duplicates the scroll-all feature in CRiSP.

Also, the default keybindings for brief/CRiSP override the M-x
key to exit the editor.  If you don't like this functionality, you
can prevent this behavior (or redefine it dynamically) by setting
the value of `crisp-override-meta-x' either in your .emacs or
interactively.  The default setting is t, which means that M-x will
by default run `save-buffers-kill-emacs' instead of the command
`execute-extended-command'.

Finally, if you want to change the string displayed in the mode
line when this mode is in effect, override the definition of
`crisp-mode-mode-line-string' in your .emacs.  The default value is
" *Crisp*" which may be a bit lengthy if you have a lot of things
being displayed there.

All these overrides should go *before* the (require 'crisp) statement.