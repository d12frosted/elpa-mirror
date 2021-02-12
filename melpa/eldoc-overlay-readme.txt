
Eldoc displays the function signature of the closest function call
around point either in the minibuffer or in the modeline.

This package modifies Eldoc to display this documentation inline
using a buffer text overlay.

 `eldoc-overlay-mode' is a per-buffer local minor mode.

By default, the overlay is not used in the minibuffer, eldoc is shown in the modeline
in this case.  Set the option `eldoc-overlay-enable-in-minibuffer' non-nil if you want
to enable overlay use in the minibuffer.

Finally, see the documentation for `eldoc-overlay-backend' if you want to try
a different overlay display package backend.
