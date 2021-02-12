
This is an Emacs interface to the Ditz distributed issue tracking
system, which can be found at http://rubygems.org/gems/ditz.

Put this file in your Lisp load path and something like the following in
your .emacs file:

    (require 'ditz-mode)
    (define-key global-map "\C-c\C-d" ditz-prefix)

See the documentation for `ditz-mode' for more info.
