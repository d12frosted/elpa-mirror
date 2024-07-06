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

;; Usage:

`unspecified-theme' can be used just like any other theme.  After
installation, i.e. ensuring it is in a directory that is member of
your `load-path', evaluate the following:

  (load-theme 'unspecified 'no-confirm)

In addition, as mentioned before, you may want to customize the
`default' face in your `user' theme.  For example, if you want
everything to be white on black, then also evaluate the following:

  (custom-set-faces
    '(default ((t :background "#000000" :foreground "#ffffff")) t))

;; Screenshot:

A screenshot is available in the `screenshot' branch and thus
accessible on the web:
https://codeberg.org/mekeor/unspecified-theme/raw/branch/screenshot/screenshot.png

;; Details:

Beside setting face attributes to `unspecified',
`unspecified-theme' also sets some face-related variables.  Take a
look at the code for the details.

`unspecified-theme' does not theme the `default' face because that
can lead to unexpected behavior in its author's experience.

;; Dependencies:

`unspecified-theme' depends on the `most-faces' package:
https://codeberg.org/mekeor/most-faces

;; Roadmap:

Split this theme into two or three: (1.) A theme that unspecifies
all faces-as-faces; (2.) A theme that unspecifies all
faces-as-variables; (3.) A theme that unspecifies more complex
variables referring to faces, like `highlight-parentheses-colors'
and `ibuffer-fontification-alist'.
