
This package provides functionality for correcting words via custom
interfaces. There are several functions for this:

- `flyspell-correct-at-point' - to correct word at point.
- `flyspell-correct-previous' to correct any visible word before the point.
- `flyspell-correct-next' to correct any visible word after the point.
- `flyspell-correct-wrapper' - a beefed wrapper for
  `flyspell-correct-previous' and `flyspell-correct-next' allowing one to
  correct many words at once (rapid flow) and change correction direction.

In most cases the last function is the most convenient, so don't forget to
bind it.

  (define-key flyspell-mode-map (kbd "C-;") 'flyspell-correct-wrapper)

When invoked, it will show the list of corrections suggested by Flyspell.

Most interfaces also allow you to save the new word to your dictionary,
accept this spelling in current buffer or for a whole session, or even skip
this word (useful in a rapid flow).

Default interface is implemented using `completing-read', but it's highly
advised to use `flyspell-correct-ido' (which comes bundled with this package)
or any interface provided by following packages: `flyspell-correct-ivy',
`flyspell-correct-helm' and `flyspell-correct-popup'.

In order to use `flyspell-correct-ido' interface instead of default
`flyspell-correct-dummy', place following snippet in your 'init.el' file.

  (require 'flyspell-correct-ido)

It's easy to implement your own interface for `flyspell-correct'. Checkout
documentation for `flyspell-correct-interface' variable.

For more information about this and related packages, please refer to
attached README.org file.
