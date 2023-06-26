A major mode for editing QuakeC and QuakeC src files.

The dialect is QuakeC as described in the QuakeC Reference Manual.
In addition to the Vanilla dialect some popular FTEQCC and GMQCC
extentions are supported, e.g. C-style function definitions. The
mode provides imenu, which-func and Eldoc support, as well an xref
backend for finding definition and a completion-at-point function
for local symbol completion function. By default FTEQCC is used as
a compile command.

Apart from *.qc files a support for original *.src format is
provided through the bundled `quakec-progs-mode'.
