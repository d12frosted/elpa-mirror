Font-lock mode for Python bytecode assembly from Python standard library
dis, or from the pydisasm program of xdis.

It defines a private abbrev table that can be used to save abbrevs
for assembler mnemonics.  It binds just four keys:

TAB		tab to next tab stop
:		outdent preceding label, tab to tab stop
C-j, C-m	newline and tab to tab stop

Code is indented to the first tab stop level.

This mode runs two hooks:
  1) `pyasm-mode-set-comment-hook' before the part of the initialization
     depending on `asm-comment-char', and
  2) `pyasm-mode-hook' at the end of initialization.
