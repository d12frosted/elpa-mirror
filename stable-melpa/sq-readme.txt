Provides convenient functions and key bindings to inspect OpenPGP
data using sq, Sequoia PGP's command line frontend.  Currently,
this is mostly useful for OpenPGP developers.

To enable, add this to your .emacs:

  (require 'sq)
  (sq-global-set-keys) ;; Uses the 'C-c s' chord.

You can give an alternative chord prefix to sq-global-set-keys.
