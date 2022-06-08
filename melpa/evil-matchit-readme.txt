
This program emulates matchit.vim by Benji Fisher.

If EVIL is installed,
  - Add `(global-evil-matchit-mode 1)' into Emacs setup.
  Then press % or `evilmi-jump-items' to jump between then matched pair.
  Text object "%" is also provided.

  - The shortcut "%" is defined in `evilmi-shortcut'.  It's both the name of
  text object and shortcut of `evilmi-jump-items'.  Some people prefer set it
  to "m".  Here is sample setup:

  (setq evilmi-shortcut "m")
  (global-evil-matchit-mode 1)


If EVIL is NOT installed,
 - Use `evilmi-jump-items-native' to replace `evilmi-jump-items'

 - `evilmi-shortcut' and `global-evil-matchit-mode' are not used

Tips:
  It's reported some mode is not compatible with this package.
  You can use `evilmi-jump-hook' to turn off the mode before
  jumping to the matched tag.
  Then turn on it after the jump using the same hook.

  An example to toggle `global-tree-sitter-mode',

  (add-hook 'evilmi-jump-hook
            (lambda (before-jump-p)
              (global-tree-sitter-mode (not before-jump-p))))

See https://github.com/redguardtoo/evil-matchit/ for more information

This program requires EVIL (https://github.com/emacs-evil/evil)

The other commands like `evilmi-select-items' and `evil-delete-items'
always work with or without EVIL.
