Iota is a very simple package that provides an easy way to replace strings in
a region with an incrementing count.  This can be useful in a variety of
settings for doing things such as creating numbered lists, creating
enumerations, and more.  The substrings to match are defined by the variable
‘iota-regexp’ while the functions ‘iota’ and ‘iota-complex’ offer simple- and
advanced methods of enumeration.  You probably do not want to use these
functions in your emacs-lisp code; they are intended for interactive use.
