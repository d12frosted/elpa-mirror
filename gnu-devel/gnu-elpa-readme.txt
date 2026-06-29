This package adds placeholders for the features defined by GNU ELPA packages
such that the users are informed about the existence of those features and
so they can easily install the relevant package on the spot.

FIXME/TODO:

- Allow packages more control over what is auto-predefined.
- Don't just silently drop those packages with more than 10 autoloads.
- Allow more than `auto-mode-alist' and `autoload's, e.g. allow
  new menu entries.
- Merge with `gnu-elpa-keyring-update'?