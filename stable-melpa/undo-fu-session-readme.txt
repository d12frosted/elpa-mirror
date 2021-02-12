This extension provides a way to use undo steps of
individual file buffers persistently.


; Usage


Write the following code to your .emacs file:

  (require 'undo-fu-session)
  (global-undo-fu-session-mode)

Or with `use-package':

  (use-package undo-fu-session)
  (global-undo-fu-session-mode)

If you prefer to enable this per-mode, you may do so using
mode hooks instead of calling `global-undo-fu-session-mode'.
The following example enables this for org-mode:

  (add-hook 'org-mode-hook (lambda () (undo-fu-session-mode))
