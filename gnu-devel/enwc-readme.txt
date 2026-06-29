ENWC is the Emacs Network Client.  It is designed to provide a front-end to
various network managers, such as NetworkManager and Wicd.

Currently, only NetworkManager and Wicd are supported, although experimental
support exists for Connman.

In order to use this package, add

(setq enwc-default-backend BACKEND-SYMBOL)

where BACKEND-SYMBOL is either 'wicd or 'nm, to your .emacs file (or other init
file).

Then you can just run `enwc' to start everything.

Example:

(setq enwc-default-backend 'nm)