This package allows to open files as another user, by default "root":

    `sudo-edit'

Suggested keybinding:

    (global-set-key (kbd "C-c C-r") 'sudo-edit)

Installation:

To use this mode, put the following in your init.el:

    (require 'sudo-edit)
