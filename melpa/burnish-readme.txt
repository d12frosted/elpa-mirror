Burnish is an Elisp package that automates the export and viewing of an Org
file. With Burnish, users can rapidly iterate and review changes to an Org
file.

INSTALL

Burnish is intended to be run as a minor mode (`burnish-mode') to Org mode.
It can be added as a hook to `org-mode-hook'. This will always enable
`burnish-mode' whenever an Org file is loaded.

   (add-hook 'org-mode-hook #'burnish-mode)

Alternately ‘burnish-mode’ can be invoked in an Org buffer as desired:

   M-x burnish-mode RET

With `burnish-mode', automated export of an Org file and viewing the
result is done on every file save.  If this behavior is not desired,
then an alternate install is to bind the command `burnish'.

   (keymap-set org-mode-map burnish-export-key #'burnish)

`burnish-export-key' is a customizable variable whose default value is
‘C-<f5>’.
