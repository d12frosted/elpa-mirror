Provides `evil-keypad-start', a command to activate a transient
keypad mode inspired by Meow Keypad.  Allows entering complex Emacs
key sequences using a series of single key presses without holding
down modifier keys.

After triggering the keypad, type a sequence representing modifiers
and keys (e.g., 'x f' for C-x C-f, 'm x' for M-x, 'a s' for C-c a
s).  The keypad translates and executes the corresponding Emacs
command, then exits.  Numeric prefix arguments (e.g. C-u 4, M-5)
can be initiated using dedicated keypad keys before command keys.

Which-key integration is provided if `which-key-mode` is active,
showing the target Emacs keymap contents after a prefix is entered.
