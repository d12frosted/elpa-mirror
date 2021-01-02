eval-in-repl: Consistent ESS-like eval interface for various REPLs

This package does what ESS does for R for various REPLs, including ielm.

Emacs Speaks Statistics (ESS) package has a nice function called
ess-eval-region-or-line-and-step, which is assigned to C-RET.
This function sends a line or a selected region to the corresponding
shell (R, Julia, Stata, etc) visibly. It also start up a shell if
there is none.

This package along with REPL/shell specific packages implement similar
work flow for various REPLs.

This file alone is not functional. Also require the following depending
on your needs.

eval-in-repl-ielm.el    for Emacs Lisp    (via ielm)
eval-in-repl-cider.el   for Clojure       (via cider.el)
eval-in-repl-slime.el   for Common Lisp   (via slime.el)
eval-in-repl-geiser.el  for Racket/Scheme (via geiser.el)
eval-in-repl-racket.el  for Racket        (via racket-mode.el)
eval-in-repl-scheme.el  for Scheme        (via scheme.el and cmuscheme.el)
eval-in-repl-hy.el      for Hy            (via hy-mode.el and inf-lisp.el)

eval-in-repl-python.el  for Python        (via python.el)
eval-in-repl-ruby.el    for Ruby          (via ruby-mode.el, and inf-ruby.el)
eval-in-repl-sml.el     for Standard ML   (via sml-mode.el)
eval-in-repl-ocaml.el   for OCaml         (via tuareg.el)
eval-in-repl-prolog.el  for Prolog        (via prolog.el)
eval-in-repl-javascript.el for Javascript (via js3-mode.el, js2-mode.el, and js-comint.el)

eval-in-repl-shell.el   for Shell         (via native shell support)


See the URL below for installation and configuration instructions,
known issues, and version history.
https://github.com/kaz-yos/eval-in-repl/
