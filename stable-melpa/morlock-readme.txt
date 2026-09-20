This package provides `morlock-mode' which highlights additional
expressions in Emacs Lisp mode.

Symbols are highlighted if their `font-lock-keyword' symbol
property is non-nil.  This package does that for symbols listed
in `morlock-font-lock-symbols'.  To highlight additional symbols
either add them to that list or set that symbol property directly.

The `morlock-font-lock-keywords' variable is used for more complex
expressions.

When using Emacs 32, this package can be replaced with just:

  (dolist (symbol '(not null xor))
    (put symbol 'font-lock-keyword t))
