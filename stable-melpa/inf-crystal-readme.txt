
inf-crystal provides a REPL buffer connected
to a [icr](https://github.com/crystal-community/icr) subprocess.
It's based on ideas from the popular `inferior-lisp` package.

`inf-crystal` has two components - a basic crystal REPL
and a minor mode (`inf-crystal-minor-mode`), which
extends `crystal-mode` with commands to evaluate forms directly in the
REPL.

`inf-crystal` provides a set of essential features for interactive
Crystal development:

* REPL
* Interactive code evaluation

### ICR

To be able to connect to [inf-crystal](https://github.com/brantou/inf-crystal.el),
you need to make sure that [icr](https://github.com/crystal-community/icr) is installed.
Installation instructions can be found on
the main page of [icr](https://github.com/crystal-community/icr#installation).

### Installation

#### Via package.el

TODO

#### Manual

If you're installing manually, you'll need to:
* drop the file somewhere on your load path (perhaps ~/.emacs.d)
* Add the following lines to your .emacs file:

```elisp
   (autoload 'inf-crystal "inf-crystal" "Run an inferior Crystal process" t)
   (add-hook 'crystal-mode-hook 'inf-crystal-minor-mode)
```

### Usage

Run one of the predefined interactive functions.

See [Function Documentation](#function-documentation) for details.
