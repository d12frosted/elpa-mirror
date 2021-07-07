Mugur is a keyboard configurator that supports all QMK compatible keyboards.
mugur-mugur accepts a keymap (a list of all the keyboard layers and keys),
and it generates the equivalent QMK C code (keymap.c, config.h and rules.mk).
Currently supported features include all the basic QMK keycodes, the mod-tap
and modifiers functionalities, one-shot keys, layer toggle, macros, tap
dance, leader key and combos.  Additionally, an Emacs keybound function can
also be specified as a valid key.

Throught this package, mugur-key refers to any of the valid mugur specific
symbols, strings, characters or lists that can be used in building the
keymap.  It is roughly equivalent to an QMK keycode, as given in the keymaps
matrix in config.c.  To differentiate between the user-side of things and the
qmk-side, I'm using similar terms throught the package, like mugur-keymap and
qmk-keymap, for example, where by the first term is to be understood the
keymap as given by the user, containing mugur specific entries, and by the
second the transformed keymap, containing QMK keycodes, ready to be written
to the generated files.  The same applies to the other terms.
