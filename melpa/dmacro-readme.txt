Tired of performing the same editing operations again and again?
Using the Dynamic Macro system on GNU Emacs, you can make the system
perform repetitive operations automatically, only by typing the special
key after doing the same operations twice.

To use this package, simply add belo code to your init.el:
  (setq dmacro-key (kbd "C-S-e"))
  (dmacro-mode)

If you want to use `dmacro-mode' in global, you can turn on global one:
  (global-dmacro-mode)

NOTE: If you change `dmacro-key', you need to restart `dmacro-mode'
to reflect the change.
