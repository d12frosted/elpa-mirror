
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

Each of the above features is automatically enabled/disabled via the
following hook functions for `cilk-mode'.  In fact, activating `cilk-mode'
does nothing except trigger the functions in `cilk-mode-hook'.  To disable
any feature hook function `cilk-mode-<feature>', set the value of the
corresponding variable `cilk-mode-enable-<feature>' to `nil' BEFORE loading
the package.

Each of the hook functions above can also be called interactively (in any
mode) to toggle the corresponding feature on/off.

The `cilk-mode' minor mode can only be enabled in buffers with major mode
`c-mode' or `c++-mode' (provided by `cc-mode').
