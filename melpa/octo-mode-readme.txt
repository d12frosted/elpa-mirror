Major mode for editing Octo source code. A high level assembly
language for the Chip8 virtual machine.
See: https://github.com/JohnEarnest/Octo

The mode could most likely have benefited from deriving asm-mode
as Octo is an assembly language. However part of the reasoning
behind creating this mode was learning more about Emacs'
internals. The language is simple enough to allow the mode to be
quite compact anyways.

Much inspiration was taken from yaml-mode so there might be
similarities in the source structure and naming choices.

; Installation:

The easiest way to install octo-mode is from melpa.
Assuming MELPA is added to your archive list you can list the
available packages by typing M-x list-packages, look for
octo-mode, mark it for installation by typing 'i' and then execute
(install) by typing 'x'. Or install it directly with M-x
package-install RET octo-mode.

If you want to install it manually, just drop this file anywhere
in your `load-path'. Be default octo-mode associates itself with
the *.8o file ending. You can enable the mode manually by M-x
octo-mode RET.
