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

Originally I had planned to implement `subemacs-funcall', as
passing functions to the subprocess would allow compile-time
checking of the passed expressions for issues.

Passing a `lambda' form to a hypothetical `subemacs-funcall' in an
environment where `lexical-binding' is enabled, will capture the
lexical environment into the resulting `closure' form and make it
available to the subprocess.  This behaviour however is not
documented and may break in the future.  As a consequence an
implementation of `subemacs-funcall' would either require enforcing
unexpected limitations (e.g. not allowing closures) or risk the
creation of code that depends on an undocumented feature of current
Emacs versions.

Passing a quoted `lambda' form would avoid these problems, but
would also sacrifice compile-time checks, and thus the only
advantage.



## Comparison to async.el

[async.el](https://github.com/jwiegley/emacs-async) implements a
superset of the functionality of `subemacs.el', with
`async-sandbox' having essentially the functionality of
`subemacs-eval'. However, a few complementary properties allow
`subemacs.el' to remain useful.

  - `subemacs-eval' forwards the STDOUT and STDERR of the
    subprocess and allows access to the contents as a string.
    `async-sandbox' does not.

  - With `subemacs-byte-compile-file', the module contains a
    useful development tool, that is optimized for quickly
    checking against compiler warnings.

  - On Windows at least, `async-sandbox' has more overhead.

        (async-sandbox '(lambda ())) ; ≈ 0.75 seconds
        (subemacs-eval '(progn))     ; ≈ 0.35 seconds

  - On Windows, I sometimes experience `async-sandbox' hanging,
    while I never had such a problem with `subemacs-eval'.


<!--
TODO Another possible usecase: Chaining external commands and elisp.
TODO     Currently emacs has no good method to execute multiple
TODO     external commands in an asynchronous shell buffer,
TODO     executing emacs lisp in between.
-->

## Changelog

### v1.1

- Rewrote `subemacs-byte-compile-file'.
- Adjusted README text to describe usecases compared to `async.el'.

### v1.0

Original release. Supports exclusively synchronous execution.
