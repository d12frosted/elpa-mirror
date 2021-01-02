Tabula Rasa was inspired by darkroom-mode.el, WriteRoom, and all of the other
distraction free tools. It was developed out of the need for a more customizable
distraction free mode for Emacs.

; Installation

Install through Melpa
or
put this file in your common lisp files dir (e.g. .emacs.d/site-lisp)

Regardless, put the following in your Emacs configuration file (e.g. .emacs) file:

(require 'tabula-rasa)

Type M-x tabula-rasa-mode to toggle the mode.

For customization of colors, etc, type M-x customize-group RET tabula-rasa RET
Customization options include:
- Text font and colors.
- Cursor and region colors.
- Column width
- Line spacing
- Minor modes to enable or disable for Tabula Rasa
- Whether or not to antialias text (experimental)
