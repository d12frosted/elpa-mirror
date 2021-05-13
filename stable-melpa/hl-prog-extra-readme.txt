This package provides an easy way to highlight words in programming modes,
where terms can be highlighted on code, comments or strings.


; Usage


Write the following code to your .emacs file:

  (require 'hl-prog-extra)
  (global-hl-prog-extra-mode)

Or with `use-package':

  (use-package hl-prog-extra)
  (global-hl-prog-extra-mode)

If you prefer to enable this per-mode, you may do so using
mode hooks instead of calling `global-hl-prog-extra-mode'.
The following example enables this for org-mode:

  (add-hook 'python-mode-hook
    (lambda ()
      (hl-prog-extra-mode)))
