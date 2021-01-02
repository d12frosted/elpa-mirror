;; Commentary:

Sometimes it is useful to run Emacs in a plain terminal window, even
when a graphical display is available, but it's a nuisance if you need
to copy and paste from the text-mode Emacs to another program.  This is
a tiny minor mode which lets Emacs on Mac OS X use the system clipboard
even when running in a text terminal, via the external `pbpaste' and
`pbcopy' programs.

To enable it, either customize the variable `osx-clipboard-mode' to `t',
or add the following line to your init file:

,----
| (osx-clipboard-mode +1)
`----

Attempting to enable this mode an a non-OS-X system or in a graphical
Emacs will do nothing, so it should be safe to enable it unconditionally
even if you share your configuration between multiple machines.
