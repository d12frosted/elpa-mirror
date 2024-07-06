`evenok' is a package that provides themes using the OKLCH color
space in order to evenly distribute its eight base colors within
the color spectrum as it is perceived by humans.  This also allows
to choose colors with equally perceived lightness.

- https://bottosson.github.io/posts/oklab/
- https://oklch.com

;; Installation:

Clone the Git repository to your local persistent memory and put
its file-path to `load-path'.

;; Usage:

These themes are meant to be used on top of the
`unspecified-theme': https://codeberg.org/mekeor/unspecified-theme

You can load them together like this:

  (mapcar #'load-theme
      '(unspecified
        evenok-dark
        ;; evenok-dark-extra ;; optional, very opinionated
        ))

;; Demo:

A video demonstration of appearance and usage of the
`evenok-dark-theme' can be found here:
https://iv.catgirl.cloud/watch?v=_18ICdAmlTg

;; Roadmap:

- Update screenshots; add one for light variant.
- Use common colors for `eshell-ls-*' and `dired-*'.

;; Design Choices:

Links, buttons, or more generally clickables are underlined.

Faces which denote differences use following colors:
- added:   green
- changed: purple
- removed: red
