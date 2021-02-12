Benchmark Emacs Startup time without ever leaving your Emacs.

Esup profiles your Emacs startup time by examining all top-level
S-expressions (sexps).  Esup starts a new Emacs process from
Emacs to profile each SEXP.  After the profiled Emacs is complete,
it will exit and your Emacs will display the results.

Esup will step into `require' and `load' forms at the top level
of a file, but not if they're enclosed in any other statement.

Installation:

Place esup.el and esup-child.el on your `load-path' by adding this
to your `user-init-file', usually ~/.emacs or ~/.emacs.d/init.el

  (add-to-list 'load-path "~/dir/to-esup")

Load the code:

  (autoload 'esup "esup" "Emacs Start Up Profiler." nil)

M-x `esup' to profile your Emacs startup and display the results.

The master of all the material is the GitHub repository
(see URL `https://github.com/jschaf/esup').

Bugs:

Bug tracking is currently handled using the GitHub issue tracker
(see URL `https://github.com/jschaf/esup/issues').
