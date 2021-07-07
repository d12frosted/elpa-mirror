A major mode for editing NASM x86 assembly programs. It includes
syntax highlighting, automatic indentation, and imenu integration.
Unlike Emacs' generic `asm-mode`, it understands NASM-specific
syntax.

NASM Home: http://www.nasm.us/

Labels without colons are not recognized as labels by this mode,
since, without a parser equal to that of NASM itself, it's
otherwise ambiguous between macros and labels. This covers both
indentation and imenu support.

The keyword lists are up to date as of NASM 2.12.01.
http://www.nasm.us/doc/nasmdocb.html

TODO:
[ ] Line continuation awareness
[x] Don't run comment command if type ';' inside a string
[ ] Nice multi-; comments, like in asm-mode
[x] Be able to hit tab after typing mnemonic and insert a TAB
[ ] Autocompletion
[ ] Help menu with basic summaries of instructions
[ ] Highlight errors, e.g. size mismatches "mov al, dword [rbx]"
[ ] Work nicely with outline-minor-mode
[ ] Highlighting of multiline macro definition arguments
