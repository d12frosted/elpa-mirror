ROPgadget is a well-known python utility for solving "pwn" challenges in
IT-Security competitions (CTFs).  The tool searches for so-called gadgets,
which are short function fragments that end with a return/syscall/jump
instruction.  They are generally used to obtain arbitrary code execution by
overwriting return addresses on the stack with suitable gadgets.  This Elisp
package uses the ROPgadget utility to find these gadgets and merely displays
these in a Emacs friendly way.  You need to have the ROPgadget tool installed
and in your PATH If you do not have the utility in your PATH, you can set the
location via the variable `ropgadget-executable'.

To find gadgets in a binary, run M-x ropgadget.

Inside a ROPgadget buffer, you can filter the displayed gadgets by pressing
``f'' or M-x ropgadget-filter
