
This package provides basic interaction with a Clojure subprocess (REPL).
It's based on ideas from the popular `inferior-lisp` package.

`inf-clojure` has two components - a nice Clojure REPL with
auto-completion and a minor mode (`inf-clojure-minor-mode`), which
extends `clojure-mode` with commands to evaluate forms directly in the
REPL.

`inf-clojure` provides a set of essential features for interactive
Clojure(Script) development:

* REPL
* Interactive code evaluation
* Code completion
* Definition lookup
* Documentation lookup
* ElDoc
* Apropos
* Macroexpansion
* Support connecting to socket REPLs
* Support for Lumo
* Support for Planck
* Support for Joker

For a more powerful/full-featured solution see https://github.com/clojure-emacs/cider.

If you're installing manually, you'll need to:

* drop the file somewhere on your load path (perhaps ~/.emacs.d)
* Add the following lines to your .emacs file:

   (autoload 'inf-clojure "inf-clojure" "Run an inferior Clojure process" t)
   (add-hook 'clojure-mode-hook #'inf-clojure-minor-mode)
