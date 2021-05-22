
`solaire-mode' is inspired by editors who visually distinguish code-editing
windows from sidebars, popups, terminals, ecetera. It changes the background
of file-visiting buffers (and certain aspects of the UI) to make them easier
to distinguish from other, not-so-important buffers.

Praise the sun.

; Installation

M-x package-install RET solaire-mode

  (require 'solaire-mode)
  (solaire-global-mode +1)

And to unconditionally darken certain buffers:

  (add-hook 'ediff-prepare-buffer-hook #'solaire-mode)
