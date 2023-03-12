pd-remote is a remote-control and live-coding utility for Pd and Emacs.

You can add this to your .emacs for remote control of Pd patches in
conjunction with the accompanying pd-remote.pd abstraction.  In particular,
there's built-in live-coding support for faust-mode and lua-mode via the
pd-faustgen2 and pd-lua externals.  The package also includes a minor mode
(enabled automatically in faust-mode and lua-mode) which adds some
keybindings to invoke these commands.

Install this with the Emacs package manager or put it anywhere where Emacs
will find it, and load it in your .emacs as follows:

(require 'pd-remote)
(add-hook 'faust-mode-hook #'pd-remote-mode)
(add-hook 'lua-mode-hook #'pd-remote-mode)
