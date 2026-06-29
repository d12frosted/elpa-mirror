A simulator for the Little Man Computer.
https://en.wikipedia.org/wiki/Little_man_computer

The simulator uses a plain editable buffer, so you can edit the machine
words just like any other text, and every word can be given a name (label)
which can also be edited in the normal way.  Additionally to the labels it
shows the disassembled meaning of instruction words.  Of course, it can't
always know which words are meant to be code rather than data, so it relies
on information from the assembler to do that, and otherwise just marks every
word it executes as being "code".

The assembly uses a slightly different (Lispish) syntax where comments start
with ";", and each instruction needs to be wrapped in parentheses.
Other than that it's the same assembly as documented elsewhere
(accepts a few mnemonic variants, such as IN/INP, STA/STO, BR/BRA).
Another difference is that the DAT mnemonic accepts any number of words
rather than just one.

So the assembly (stored in files with extension ".elmc") looks like:

  label1
         (BR label2) ;Useless extra jump.
  label2
         (LDA data1) ;Cleverest part of the algorithm.
         (ADD data2)
         (STO data1)
         (BR label1)
         
  data1  (DAT 0)
  data2  (DAT 050 060 070)

And actually, since the assembler re-uses the Emacs Lisp reader to parse the
code, you can use binary, octal, and hexadecimal constants as well, using
the notations #b101010, #o277, and #x5F respectively.

The lmc-asm-mode supports the usual editing features such as label
completion, mnemonic completion, jumping to a label, automatic indentation,
and code folding.