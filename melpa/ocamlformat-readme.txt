
This package provides utilities to format OCaml code using the ocamlformat
command.  The recommended usage is to format before saving a file:

  (add-hook 'before-save-hook 'ocamlformat-before-save)
