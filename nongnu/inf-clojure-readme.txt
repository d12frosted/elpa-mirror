This package provides basic interaction with a Clojure subprocess (REPL).
It's based on ideas from the popular `inferior-lisp` package.

`inf-clojure` has two components - a nice Clojure REPL (`inf-clojure-mode`)
and a minor mode (`inf-clojure-minor-mode`), which extends `clojure-mode`
with commands to evaluate forms directly in the REPL.

`inf-clojure` provides a set of essential features for interactive
Clojure/ClojureScript/ClojureCLR development:

* REPL
* Interactive code evaluation
* Code completion
* Definition lookup
* Documentation lookup
* ElDoc
* Apropos
* Macroexpansion
* Namespace reloading
* Connecting to socket REPLs

It supports many Clojure runtimes including Clojure (JVM), ClojureScript,
ClojureCLR, babashka, Planck, and Joker.

For a more powerful/full-featured solution see https://github.com/clojure-emacs/cider.