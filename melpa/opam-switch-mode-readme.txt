
Provide command `opam-switch-set-switch' to change the opam switch
of the running Emacs session and minor mode `opam-switch-mode' to
select the opam switch via a menu-bar menu.

`opam-switch-set-switch' reads the name of the switch in the
minibuffer, providing completion with all available switches.  With
no input (i.e., leaving the minibuffer empty) the environment is
reset to the state before the first call of
`opam-switch-set-switch'.

The menu is generated each time the minor mode is enabled and
contains the switches that are known at that time.  If you create a
new switch, re-enable the minor mode to get it added to the menu.
The menu contains an additional entry "reset" to reset the
environment to the state when Emacs was started.

For obvious reasons, `opam-switch-set-switch' does not change the
switch of any other shell.

See https://opam.ocaml.org for comprehensive documentation on opam.
