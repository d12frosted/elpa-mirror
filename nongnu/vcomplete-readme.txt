Vcomplete provides a minor mode which highlights the completion at
point the completion list buffer and (optionally) automatically
updates it.

Usage:

Enable `vcomplete-mode':

(vcomplete-mode)

For use-package users:

(use-package vcomplete
  :config
  (vcomplete-mode))

When `vcomplete-mode' is active:
- The completion list buffer opens and updates automatically (see
  `vcomplete-auto-update').
- The completion list buffer can be controlled through the
  minibuffer (during minibuffer completion) or the current buffer
  (during in-buffer completion), if it's visible.
- The currently selected completion is highlighted in the
  completion list buffer.

C-n moves point to the next completion.

C-p moves point to the previous completion.

M-RET (C-M-m) chooses the completion at point.

More commands can be added through `vcomplete-command-map':

(define-key vcomplete-command-map (kbd "C-a") #'my-command)

You can customize `vcomplete-mode' using the customize interface:

M-x customize-group RET vcomplete RET

For more information see info node `(Vcomplete)'.