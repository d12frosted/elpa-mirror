Greader reads aloud the current buffer continuously, moving the point while
reading proceeds.

It can be used in conjunction with emacspeak or speechd-el packages.
it doesn't substitute those packages, but integrates them, providing a
functionality that those lacks.
In addition to reading the buffer, Greader provides a timer for reading,
and a "sleep mode" when you are tired and you want simply relax yourself.
for further details, please see the "README" file.

To start using greader, you have to install espeak and/or speech-dispatcher,
and make sure those packages work correctly.

In order to read a buffer:
'M-x greader-mode RET'
'C-r SPC'
