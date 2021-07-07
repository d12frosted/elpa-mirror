This package provides integration between Embark and Consult. To
use it, arrange for it to be loaded once both of those are loaded:

(with-eval-after-load 'consult
  (with-eval-after-load 'embark
    (require 'embark-consult)))

Some of the functionality here was previously contained in Embark
itself:

- Support for consult-buffer, so that you get the correct actions
for each type of entry in consult-buffer's list.

- Support for consult-line, consult-outline, consult-mark and
consult-global-mark, so that the insert and save actions don't
include a weird unicode character at the start of the line, and so
you can export from them to an occur buffer (where occur-edit-mode
works!).

Just load this package to get the above functionality, no further
configuration is necessary.

Additionally this package contains some functionality that has
never been in Embark: access to Consult preview from auto-updating
Embark Collect buffer that is associated to an active minibuffer
for a Consult command. For information on Consult preview, see
Consult's info manual or its readme on GitHub.

If you always want the minor mode enabled whenever it possible use:

(add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)

If you don't want the minor mode automatically on and prefer to
trigger the consult previews manually use this instead:

(define-key embark-collect-mode-map (kbd "C-j")
  #'consult-preview-at-point)
