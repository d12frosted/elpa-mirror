The Kitty Keyboard Protocol (KKP) is documented here: https://sw.kovidgoyal.net/kitty/keyboard-protocol

kitty modifier encoding
shift     0b1         (1)
alt       0b10        (2)
ctrl      0b100       (4)
super     0b1000      (8)
hyper     0b10000     (16)
meta      0b100000    (32)
caps_lock 0b1000000   (64)
num_lock  0b10000000  (128)

Possible format of escape sequences sent to Emacs.
- CSI keycode u
- CSI keycode; modifier u
- CSI number ; modifier ~
- CSI {ABCDEFHPQRS}
- CSI 1; modifier {ABCDEFHPQRS}
