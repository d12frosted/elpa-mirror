![][image]

## About

Gotham is a **very dark** Emacs color theme.  It's a port of the
[Gotham theme for Vim] and tries adhering closely to the original.
There is support for both GUI and terminal Emacs.  The terminal
version assumes that your terminal emulator comes with a customized
16-color palette from the [Gotham contrib repository], however you can
enable 256 color support by customizing `gotham-tty-extended-palette`
in exchange for a negligible amount of color degradation.

## Screenshots

![][screenshot]

Thanks to [Norbert Klar] for the following three!

![][go-screenshot]

![][go-screenshot2]

![][go-screenshot3]

## Installation

To install the theme via `package.el`, set up the [MELPA (Stable)]
repository if you haven't already and do `M-x package-install RET
gotham-theme RET`.

Alternatively, you can install the theme manually by downloading
`gotham-theme.el` and putting it in a suitable location such as
`~/.emacs.d/themes/`.  Add the following to your init file:

    (add-to-list 'custom-theme-load-path (expand-file-name "~/.emacs.d/themes/"))

Once the theme is installed, you can enable it with `M-x load-theme
RET gotham RET`.  Make sure no other themes are enabled with `M-x
disable-theme`.  To enable the theme automatically at startup, add the
following to your init file:

    (load-theme 'gotham t)

[image]: img/gotham.png
[Gotham theme for Vim]: https://github.com/whatyouhide/vim-gotham
[Gotham contrib repository]: https://github.com/whatyouhide/gotham-contrib
[screenshot]: img/scrot.png
[Norbert Klar]: https://github.com/norbertklar
[go-screenshot]: img/go.png
[go-screenshot2]: img/go2.png
[go-screenshot3]: img/go3.png
[MELPA (Stable)]: http://melpa.org/
