
`solaire-mode' is inspired by editors who visually distinguish code-editing
windows from sidebars, popups, terminals, ecetera. It changes the background
of file-visiting buffers (and certain aspects of the UI) to make them easier
to distinguish from other, not-so-important buffers.

Praise the sun.

; Installation

M-x package-install RET solaire-mode

  (require 'solaire-mode)

Brighten buffers that represent real files:

  (add-hook 'change-major-mode-hook #'turn-on-solaire-mode)

If you use auto-revert-mode:

  (add-hook 'after-revert-hook #'turn-on-solaire-mode)

And to unconditionally brighten certain buffers:

  (add-hook 'ediff-prepare-buffer-hook #'solaire-mode)

You can do similar with the minibuffer when it is active:

  (add-hook 'minibuffer-setup-hook #'solaire-mode-in-minibuffer)
