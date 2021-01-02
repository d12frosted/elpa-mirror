ctune: A package to tune out CC Mode Noise Macros.

When working with projects that extensively use C-style Macros,
the buffer you are editing can contain 'Noise Macros' (e.g., C Macros that
define GCC attributes).  These 'Noise Macros' (see the CC Mode Manual for
more info) can confuse CC Mode, causing bad indentation, fontification, etc.
This package is an attempt to make the addition and removal of these
entities somewhat more automated than what CC Mode offers.

At the time of writing this package, I know of three ways of handling the
issue.
1) Editing `dir-locals-file' by hand: Find the Noise Macro that is bothering
you, and add an entry for the correspondent major mode key in the alist of
`dir-locals-file'.  You might be working in a project that already contains
such entry, so changing the `dir-locals-file' is easy, although somewhat
tedious.

2) Adding the entries manually, while editing the buffer: You notice the
Noise Macro, it bothers you, and then you add the entry to the list, like
this: (add-to-list 'c-noise-macro-names '("NOISE_MACRO_THAT_BOTHERS_ME"))
This is OK, but perhaps you make a mistake and use `c-noise-macro-names'
when `c-noise-macro-with-parens-names' was needed, or it bothers you to
have to type all the Noise Macro name, or killing and yanking the name still
bothers you, etc.  Plus, after adding the Noise Macro to its right variable
you might forgot that you need to eval (c-make-noise-macro-regexps).
Then, you might want to save the values you added, so you can type
M-x add-dir-local-variable to do the saving.

3) Modify `c-noise-macro-names' and `c-noise-macro-with-parens-names' in
your init file: I don't like this option, but it does the job.  It's pretty
easy and straight-forward.

ctune tries to handle both 3 ways by providing an easy way to add the Noise
Macro to the right variable and save the values in the `dir-locals-file'
file.

; Suggestions/Ideas:

GNU C Coding Conventions, and other coding conventions as well, say that
macro names should be all upper case.  Maybe check that when asked to add
a macro name (but ctune should not enforce it, so there could be a user
option to turn off the query).
