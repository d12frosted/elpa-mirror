
Provides `cilk-mode', a minor mode that augments `c-mode' and `c++-mode'
for editing Cilk source code.

This package simply groups together a few small customizations of other
modes to make Cilk C/C++ code editing more convenient.  Specifically, the
package provides the following functions:

1. `cilk-mode-cc-keywords' :: Correct indentation of code blocks with Cilk
keywords in CC Mode.  This is done by modifying buffer-local bindings of
the relevant C/C++ keyword regexp variables of `cc-mode'.

2. `cilk-mode-font-lock' :: Fontification of Cilk keywords.  This is done
via `font-lock-mode' and the provided face `cilk-mode-parallel-keyword'.
By default, the `cilk-mode-parallel-keyword' face is the same as
`font-lock-keyword-face'.  To change how Cilk keywords are fontified, use
the `set-face-attribute' function to customize the
`cilk-mode-parallel-keyword' face.

3. `cilk-mode-flycheck-opencilk' :: Syntax checking with `flycheck' and the
OpenCilk compiler (https://opencilk.org).  This is done via buffer-local
bindings of `flycheck' options for the `c/c++-clang' checker.  If
`flycheck' is not installed, this feature is elided.  The OpenCilk compiler
path is found in `cilk-mode-flycheck-opencilk-executable'.

Each of the above features is enabled whenever the `cilk-mode' minor mode
is activated.  To stop a feature with function `cilk-mode-<feature>' from
automatically activating with `cilk-mode', set the corresponding variable
`cilk-mode-enable-<feature>' to nil.  To toggle a feature on or off, one
may also call the corresponding function interactively.

The `cilk-mode' minor mode can only be enabled in buffers with major mode
`c-mode' or `c++-mode' (provided by CC Mode).
