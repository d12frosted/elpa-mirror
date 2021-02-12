`dkl' provides an ASCII-art representation of a keyboard layout, within an Emacs buffer.

<img src="screencap.png">

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Layout file format](#layout)
- [TODO](#todo)
- [Issues](#issues)
- [License](#license)

## Installation

Install [dkl from MELPA](https://melpa.org/#/dkl), or put the `dkl' directory in your load-path and do a `(require 'dkl)'.

## Usage

Create an `dkl-layout' buffer with `M-x dkl-display'.

Within the `dkl-layout' buffer, the default keybindings are:

* l - Set the layout to use (`dkl-set-current-layout`).

* q - Close the `dkl-layout' buffer and window (`dkl-close`).

* s - Toggle display of shifted and unshifted layouts (`dkl-shift-toggle`).

Customisation options, including how `dkl' highlights typed keys, are available via the `dkl' customize-group.

<a name="layout"></a>

## Layout file format

A layout file contains Emacs Lisp which:

* ensures the layout is used with the correct keyboard;

* specifies the directionality of the script used in the layout; and

* sets the `dkl--current-layout` variable.

For example:

```elisp
(if (not (string= dkl-keyboard-name "standard"))
    (user-error "Layout `qwerty-us' must be used with `dkl-keyboard-name' set to \"standard\"")
  (progn
    (setq dkl--current-layout-script-direction 'left-to-right)
    (setq dkl--current-layout
          '(;; Top row
            (60 . ((0 . ("`" "~"))
                   (4 . ("1" "!"))
            ...
```

The layout data structure is an alist. Each entry in the alist represents a keyboard row:

* The `car` of the entry indicates the character position for the first glyph in that row.

* The `cdr` of the entry is itself an alist, where:

  * the `car` of each entry is an offset, in characters, from the first glyph in that row;

  * the `cdr` of each entry is a list of the unshifted and shifted glyphs to display.

## TODO

* `devanagari-inscript` layout:

  * Fix failure to highlight certain keys during composition.

## Issues / bugs

If you discover an issue or bug in `dkl' not already noted:

* as a TODO item, or

* in [the project's "Issues" section on GitHub](https://github.com/flexibeast/dkl/issues),

please create a new issue with as much detail as possible, including:

* which version of Emacs you're running on which operating system, and

* how you installed `dkl'.

## License

[GNU General Public License version 3](http://www.gnu.org/licenses/gpl.html), or (at your option) any later version.
