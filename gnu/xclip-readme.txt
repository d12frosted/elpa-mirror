This package allows Emacs to copy to and paste from the GUI clipboard
when running in text terminal.

It can use external command-line tools for that, which you may need
to install in order for the package to work.
More specifically, it can use the following tools:
- Under X11: `xclip' or `xsel' (https://xclip.sourceforge.net and
  https://www.vergenet.net/~conrad/software/xsel/ respectively).
- MacOS: `pbpaste/pbcopy'
- Cygwin: `getclip/putclip'
- Under Wayland: `wl-clipboard' (https://github.com/bugaevc/wl-clipboard)
- Termux: `termux-clipboard-get/set'
- Emacs: It can also use Emacs's built-in GUI support to talk to the GUI.
  This requires an Emacs built with GUI support.
  It uses `make-frame-on-display' which has been tested to work under X11,
  but it's not known whether it works under MacOS or Windows.

To use, just add (xclip-mode 1) to your ~/.emacs or do `M-x clip-mode'
after which the usual kill/yank commands will use the GUI selections
according to `select-enable-clipboard/primary'.

An alternative package for use under X11 is
[Gpastel](https://gitlab.petton.fr/DamienCassou/gpastel), which uses
[GPaste](https://github.com/Keruspe/GPaste/) rather than Xclip and hooks
into Emacs in a different way.  AFAICT it currently only supports
copy/pasting from an external application to Emacs and not from Emacs to
another application (for which it relies on the default code).