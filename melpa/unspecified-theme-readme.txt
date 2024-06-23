`unspecified-theme' is a package providing an equally named theme
which sets the attributes of all faces to `unspecified' -- except
for the `default' face.  In particular, it thus makes the default
attributes of (almost) all defined faces ineffective.  This is
useful at least in following scenarios:

- As an Emacs user, when you load this theme and customize only the
  `default' face, all faces will adhere to its specification.  Used
  as such, `unspecified-theme' provides a radically minimalist
  theme.

- As an Emacs theme developer, you use `unspecified-theme' to debug
  the composability of your theme: You can load `unspecified-theme'
  before loading your own theme in order to check if yours depends
  on default face attributes.  You might even require users of your
  theme to load `unspecified-theme' before loading yours in order
  to erase the default face attributes.
