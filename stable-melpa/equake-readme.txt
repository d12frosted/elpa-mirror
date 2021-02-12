This package is designed to recreate a Quake-style drop-down console fully
within Emacs, compatible with 'eshell, 'term, 'ansi-term, and 'shell modes.
It has multi-tab functionality, and the tabs can be moved and renamed
(different shells can be opened and used in different tabs).  It is intended
to be bound to shortcut key like F12 to toggle it off-and-on.

; Installation:
To install manually, clone the git repo somewhere and put it in your
load-path, e.g., add something like this to your init.el:
(add-to-list 'load-path
            "~/.emacs.d/equake/")
 (require 'equake)
