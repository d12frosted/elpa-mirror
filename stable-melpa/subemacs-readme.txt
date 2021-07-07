

# Subemacs — Evaluating expressions in a subprocess

Using the function `subemacs-eval', a form can be synchronously
evaluated in a freshly started Emacs process, which inherits only
the `load-path' from the current process.

Other values must be passed explicitly by making them part of the
form, e.g. by writing

    (let ((my-int 10))
      (subemacs-eval `(+ 5 ',my-int)))

        => 15

`subemacs-eval' also supports errors raised by Emacs' `signal' and
related functions, and displays messages emitted in the subprocess.



## Clean compilation

The original motivation for writing this package was Emacs Lisp
byte-compilation.  When byte-compiling a file from within a running
Emacs process, missing `require' calls for dependencies and typos
may be hidden from the byte compiler due to the environment already
containing them.

Such issues may not become apparent until the code is executed by a
user, who does not load the same files during startup.  While they
can be diagnosed by testing code with `emacs -Q`, this solution is
inconvenient.

Instead, compiling Emacs Lisp files in a clean process by default
turns the byte-compiler into a powerful ad-hoc tool to identify
issues from byte-compiler warnings.

Functions `subemacs-byte-compile-file' and
`subemacs-byte-recompile-directory' are therefore provided and also
serve as a demonstration of the use of `subemacs-eval'.



## Why not subemacs-funcall?

Originally I had planned to implement `subemacs-funcall', passing
functions to the subprocess would allow compile-time checking of
the passed expressions for issues.

Passing a `lambda' form to a hypothetical `subemacs-funcall' in an
environment where `lexical-binding' is enabled, will capture the
lexical environment into the resulting `closure' form and make it
available to the subprocess.  This behaviour however is not
documented and may break in the future.  As a consequence an
implementation of `subemacs-funcall' would either require enforcing
unexpected limitations (e.g. not allowing closures) or risk the
creation of code that depends on an undocumented feature of current
Emacs versions.

