Minor mode for drawing multi-character tokens as Unicode glyphs
(lambda -> λ).

Only works when `font-lock-mode' is enabled.

This mode is heavily inspired by Trent Buck's pretty-symbols-mode[1]
and Arthur Danskin's pretty-mode[2]; but aims to replace those modes, and
the many others scattered on emacswiki.org, with:

* A simple framework that others can use to define their own symbol
  replacements,
* that doesn't turn on all sorts of crazy mathematical symbols by default,
* is a self-contained project under source control, open to contributions,
* available from the MELPA package repository[4].

You probably won't want to use this with haskell-mode which has its own much
fancier fontification[3]. Eventually it would be nice if this package grew
in power and became part of Emacs, so other packages could use it instead of
rolling their own.

Add your own custom symbol replacements to the list
`pretty-symbol-patterns'.

Only tested with GNU Emacs 24.

[1] http://paste.lisp.org/display/42335/raw
[2] http://www.emacswiki.org/emacs/pretty-mode.el
[3] https://github.com/haskell/haskell-mode/blob/master/haskell-font-lock.el
[4] http://melpa.milkbox.net/
