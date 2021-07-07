## Install

Please install this package from MELPA. (https://melpa.org/)

Otherwise, put this file into load-path'ed directory.
And put the following expression into your ~/.emacs.
You may need some extra packages.

    (require 'shelldoc)

Now you can see man page when `read-shell-command` is invoked.
e.g. M-x shell-command
`C-v` / `M-v` to scroll the man page window.
`C-c C-s` / `C-c C-r` to search the page.

You can complete `-` (hyphen) option at point.
Try to type C-i after insert `-`.

## Configuration

* To show original man page initially. (probably english)

    (setq shelldoc-keep-man-locale nil)

* You may install new man page after shelldoc:

    M-x shelldoc-clear-cache

* shelldoc is working as a minor mode if you desire.

 * eshell

    (add-hook 'eshell-mode-hook 'shelldoc-minor-mode-on)

 * sh-mode (editing shell script)

    (add-hook 'sh-mode-hook 'shelldoc-minor-mode-on)

 * M-x shell

    (add-hook 'shell-mode-hook 'shelldoc-minor-mode-on)

* To toggle shelldoc feature.

    M-x shelldoc
