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
 * Line continuation awareness
