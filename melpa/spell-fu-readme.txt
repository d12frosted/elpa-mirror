This package checks the spelling of on-screen text.


; Usage


Write the following code to your .emacs file:

  (require 'spell-fu)
  (global-spell-fu-mode-mode)

Or with `use-package':

  (use-package spell-fu)
  (global-spell-fu-mode-mode)

If you prefer to enable this per-mode, you may do so using
mode hooks instead of calling `global-spell-fu-mode-mode'.
The following example enables this for org-mode:

  (add-hook 'org-mode-hook
    (lambda ()
      (setq spell-fu-faces-exclude '(org-meta-line))
      (spell-fu-mode)))
