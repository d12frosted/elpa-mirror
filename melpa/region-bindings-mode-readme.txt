Minor mode providing an extra keymap which is active when the
region is active. You can then add custom keybindings to the region
keymap, e.g. you could set "k" to call the command 'kill-region'
when the region is active.

This is a pretty good way to keep the global bindings clean.

; Installation:

Add this to your .emacs:

(add-to-list 'load-path "/folder/containing/file")
(require 'region-bindings-mode)
(region-bindings-mode-enable)

Alternatively, you can install this easily via MELPA through the
Emacs package manager. To add MELPA to the package archives:

(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
