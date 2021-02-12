This code is an extension of the `elscreen' mode that uses your
window title (Emacs frame name) to show the tabs/screens of
`elscreen`.

Usage, mostly the same as `elscreen':

   (require 'elscreen-fr)   ;; was (require 'elscreen)
   (elscreen-fr-start)      ;; was (elscreen-start)

Keep the same `elscreen' customization variables as usual, but take
into account that some of them will no take effect.  These
variables are: `elscreen-display-screen-number',
`elscreen-display-tab', `elscreen-tab-display-control' and
`elscreen-tab-display-kill-screen'.  All are set to nil when
`elscreen-fr' is started.

Useful keys to change from tab to tab, as in most user interfaces
using tabs:

   (global-set-key [(control prior)] 'elscreen-previous)
   (global-set-key [(control next)] 'elscreen-next)

The customization group lets you tweak few parameters.

Tested only under Linux / Gnome.  Feedback welcome!
