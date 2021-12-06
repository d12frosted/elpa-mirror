This package overlays doc-strings (typically from C/C++ headers).


; Usage


Write the following code to your .emacs file:

  (require 'doc-show-inline)

Or with `use-package':

  (use-package doc-show-inline)

If you prefer to enable this per-mode, you may do so using
mode hooks instead of calling `doc-show-inline-mode'.
The following example enables this for C-mode:

  (add-hook 'c-mode-hook
    (lambda ()
      (doc-show-inline-mode)))
