
This program emulates matchit.vim by Benji Fisher.
Add `(global-evil-matchit-mode 1)' into Emacs setup.
Then press % or `evilmi-jump-items' to jump between then matched pair.
Text object "%" is also provided.

The shortcut "%" is defined in `evilmi-shortcut'.  It's both the name of
text object and shortcut of `evilmi-jump-items'.  Some people prefer set it
to "m".  Here is sample setup:

  (setq evilmi-shortcut "m")
  (global-evil-matchit-mode 1)

See https://github.com/redguardtoo/evil-matchit/ for help.

This program requires EVIL (https://github.com/emacs-evil/evil)
