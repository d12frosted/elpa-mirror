Entering hardcore-mode will disable arrow keys, backspace and return.

* Use C-f/b/p/n instead of right/left/up/down
* Use C-h instead of backspace
* Use C-m or C-j instead of return

To use C-h instead of backspace, you might need to redefine C-h:

    ;; Use shell-like backspace C-h, rebind help to F1
    (define-key key-translation-map [?\C-h] [?\C-?])
    (global-set-key (kbd "<f1>") 'help-command)

If hardcore-mode is too hardcore for you, you can add these before
you require the mode:

    (setq too-hardcore-backspace t)
    (setq too-hardcore-return t)
    (require 'hardcore-mode)
    (global-hardcore-mode)

These are the settings I am using at the time. Still not hardcore enough. ^^

Code:
