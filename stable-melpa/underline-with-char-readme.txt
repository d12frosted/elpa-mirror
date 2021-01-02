
This program supports underlining with a certain character.

When point is in an empty line then fill the line with a character
making it as long as the line above.

This program provides just command `underline-with-char' and
variable `underline-with-char-fill-char'.

You can change the default underline character via

M-x customize-variable underline-with-char-fill-char



Examples
========

Notation:
- | means the cursor.
- RET means the return key.


Full underlining
................

Input
_____

lala
|

Action
______

M-x underline-with-char RET

Output
______

lala
----|


Partial underlining
...................

Input
_____

lolololo
//|

Action
______

M-x underline-with-char RET

Output
______

lolololo
//------|


Use a certain char for current and subsequent underlinings (1)
..............................................................

Input
_____

lala
|

Action
______

C-u M-x underline-with-char X RET

Output
______

lala
XXXX|


Use a certain char for current and subsequent underlinings (2)
..............................................................

Input
_____

lala
|

Action
______

C-u M-x underline-with-char X RET RET M-x underline-with-char RET

Output
______

lala
XXXX
XXXX|
