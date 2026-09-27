Aquí (`aqui.el') is an Elisp library for updating the location for GNU
Emacs with optimization for high accuracy on macOS. On macOS, Aquí will
use the Shortcuts app to obtain a location update from the native OS
location service. This approach avoids needing a specialized third party
executable to accomplish the location lookup. If Shortcuts is not
available, Aquí will use a third party internet service to obtain
location information.

USAGE:

Run M-x aqui RET to update location.

Refer to the Aquí User Guide (URL `https://kickingvegas.github.io/aqui/') for
more information.
