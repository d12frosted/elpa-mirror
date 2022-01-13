A trivial global minor mode for VUnit which hooks to the
VHDL major mode and interfaces with a VUnit run script by
making use of the compile package inside Emacs.

The basic requirements are that the HDL simulator is in the
path and that VUnit is installed in the python environment.

Before compilation, the `vunit-path' must me specified.
This can either be done in the init file or the user will be
prompted for it.

Per default `vunit-run-script' assumes "run.py", but this
is also user configurable.  For a full list of available
configurations run "M-x customize" and search for vunit.

Keys highlighted in blue will execute the specified action and
quit the vunit-mode command window.
The ones marked in red, however, will add additional flags
to the actions available in blue.

The default keybinding to invoke vunit-mode is "C-x x".
