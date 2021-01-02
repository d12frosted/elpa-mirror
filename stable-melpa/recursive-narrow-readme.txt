This package defines two functions, recursive-narrow-to-region and
recursive-widen that replace the builtin functions narrow-to-region and
widen.  These functions operate the same way, except in the case of multiple
calls to recursive-narrow-to-region.  In this case, recursive-widen will go
to the previous buffer visibility, not make the entire buffer visible.

; Installation:

To install, put this file somewhere in your load-path and add the following
to your .emacs file:

(require 'recursive-narrow)
