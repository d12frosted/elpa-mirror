Vcomplete - Visual completions

Vcomplete provides a minor mode enhancing the default completion
list buffer, providing visual aids for selecting completions.

Installation:

From ELPA: (not available yet)

M-x package-install RET vcomplete RET

From the repository:

Clone the repository:

$ git clone 'https://git.sr.ht/~dsemy/vcomplete'

Build the package:

$ cd vcomplete

$ make

Install the package:

M-x package-install-file RET /path/to/clone/vcomplete-VERSION.tar RET

Usage:

Enable ‘vcomplete-mode’:

(vcomplete-mode)

For use-package users:

(use-package vcomplete
  :config
  (vcomplete-mode))

When vcomplete-mode is active:
- The completion list buffer opens and updates automatically (see
  ‘vcomplete-auto-update’).
- The completion list buffer can be controlled through the
  minibuffer (during minibuffer completion) or the current buffer
  (during in-buffer completion), if it's visible.
- The currently selected completion is highlighted in the completion
  list buffer.

C-n moves point to the next completion.

C-p moves point to the previous completion.

M-RET (C-M-m) chooses the completion at point.

More commands can be added through ‘vcomplete-command-map’:

(define-key vcomplete-command-map [?\C-a] #'my-command)

You can customize ‘vcomplete-mode’ using the customize interface:

M-x customize-group RET vcomplete RET

For more information see the (Vcomplete) info node.

Copyright:

Copyright © 2021-2022 Daniel Semyonov <daniel@dsemy.com>
Licensed under GPLv3 or later.
