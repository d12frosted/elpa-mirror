
This package implements an engine for auto-expanding snippets.
It is done by tracking your inputted chars along a tree until you
complete a registered key sequence.

Its like running a long prefix command, but the keys you type are not
'consumed' and appear in the buffer until you complete the whole command
--- and then the snippet is triggered!
