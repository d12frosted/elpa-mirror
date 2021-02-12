`unifdef' is a package that can delete code guarded by C-style
preprocessor directives.

Examples:

Take this relatively simple code:

    #ifdef USELONGLONG
    long long x;
    #else
    long x;
    #endif

`M-x unifdef-current-buffer RET USELONGLONG RET' will transform
this into:

    long long x;

A (somewhat) more complex piece of code:

    #if ALPHA
      Alpha();
    #elif BETA
      Beta();
    #elif GAMMA
      Gamma();
    #else
      Delta();
    #endif

`M-x unifdef-current-buffer RET BETA RET' will transform
this into:

    #if ALPHA
      Alpha();
    #else
      Beta();
    #endif


What is converted:

This package can convert code that test if a symbol is defined or
if a symbol is true.  For example:

    #ifdef SYMBOL

    #if defined SYMBOL

    #if defined(SYMBOL)

    #if SYMBOL

Or if the symbol is undefined or false:

    #ifndef SYMBOL

    #if !defined SYMBOL

    #if !defined(SYMBOL)

    #if !SYMBOL

And likewise for `elif'.

What is not converted:

This package does *not* handle complex expressions involving
symbols.  For example:

    #if ALPHA && BETA

    #if ALPHA == 1234

    #if (ALPHA ^ BETA) == 0x1234

    #if defined(ALPHA) && defined(BETA)

Commands:

* `unifdef-current-buffer' -- Convert all occurrences in the
  current buffer.

* `unifdef-convert-block' -- Convert the next preprocessor block.
  (Note, in some cases, this command might need to be applied
  repeatedly.)

When prefixed with C-u the command is inverted, i.e. it assumes
that the supplied symbol is undefined or false.  In the example
above, the line `long x;' would be retained.

Warning:

The command provided by this package can perform massive changes to
your source files.  Make sure that they are backed up, e.g. by
using a version control system.  As for all tools that
automatically transform source code, it is advisable to manually
inspect the end result.
