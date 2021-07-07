Generate all the keymaps, enums, arrays, make files and everything needed for
building a hex file and flashing a qmk powered keyboard.  See the github
README for details and usage.

; Definitions used in this package:
* mugur-key - The most basic entry in the mugur-keymap.  It represents the
list of all valid and mugur specific symbols, strings, characters and lists
that can be used by the user in building its mugur-keymap.  It is interpreted
by the mugur package and used in the end to generate the qmk-keymap.  There
need not be a one-to-one correspondence with a mugur-key and a qmk-keycode,
as it happens in the case of macros, for example (a single mugur-key is used
to fill multiple places in the keymap.c, for example)

* mugur-modifier - One of the symbols C, M, G or S which stand for Ctrl, Alt,
Win and Shift, respectively and which correspond to the qmk-modifier KC_LCTL,
KC_LALT, KC_LGUI and KC_LSHIFT respectively.  A mugur-modifier is a
restricted list of mugur-keys.

* qmk-modifier - One of the KC_LCTL, KC_LALT, KC_LGUI and KC_LSHIFT
qmk-keycodes, respectively, which stand for Ctrl, Alt, Win and Shift,
respectively.

* qmk-raw-modifier - Similar to qmk-modifier, but without the KC_ part, that
is LCTL, LALT, LGUI and LSHIFT

* qmk-keycode - The qmk equivalent code for the mugur-key given by the user.
Thus, a symbol like 'a, given in the mugur-keymap is transformed into the
equivalent qmk-keycode "KC_A".  These are the codes that are written to the
qmk-matrix

* qmk-layer - The totality of all qmk-keycode's, toghether with a layer
code/name that is part of a qmk-matrix.

* qmk-matrix - The matrix found in the qmk_firmware's file keymap.c.  It
contains all the qmk-keycode's and all the qmk-layer's, as specified by the
qmk documentation.  This is what is actually used to decide which keys does
what on your keyboard

* mugur-layer - The totality of all the mugur-key's, together with a string
representing the layer name, that is used to generate the qmk-layer.

* mugur-keymap - The totally of all the mugur-layer's.  This is the mugur
equivalent for the qmk-matrix.
