Provides a development environment for writing OCaml code.  Built on
top of `ocaml-lsp-server`
(https://ocaml.org/p/ocaml-lsp-server/latest) via Eglot
(https://www.gnu.org/software/emacs/manual/html_mono/eglot.html)
for LSP interactions.  `ocaml-eglot` provides standard
implementations of the various custom-requests exposed by
`ocaml-lsp-server`.

Under the bonnet, `ocaml-eglot` and `ocaml-lsp-server` take
advantage of `merlin` (https://ocaml.org/p/merlin-lib/latest) as a
library to provide advanced IDE services.
