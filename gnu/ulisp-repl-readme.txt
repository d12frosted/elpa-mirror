Interact with uLisp running on a target board, through a serial
port.

Usage:

M-x ulisp-repl

Uses Emacs's built-in serial-port support.  If you are running on a
non-Linux kernel, you will need to adapt
`ulisp--select-serial-device'.

This mode uses `paredit' if you have it installed.

To browse uLisp reference documentation:

M-x eww RET http://www.ulisp.com/show?3L RET