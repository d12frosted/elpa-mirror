`easy-escape-minor-mode' uses syntax highlighting and composition to make ELisp regular
expressions more readable.  More precisely, it hides double backslashes
preceding regexp specials (`()|'), composes other double backslashes into
single ones, and applies a special face to each.  The underlying buffer text
is not modified.

For example, `easy-escape` prettifies this:
  "\\(?:\\_<\\\\newcommand\\_>\\s-*\\)?"
into this (`^' indicates a different color):
  "(?:\_<\\newcommand\_>\s-*)?".
   ^                        ^

The default is to use a single \ character instead of two, and to hide
backslashes preceding parentheses or `|'.  The escape character and its color
can be customized using `easy-escape-face' and `easy-escape-character' (which
see), and backslashes before ()| can be shown by disabling
`easy-escape-hide-escapes-before-delimiters'.

Suggested setup:
  (add-hook 'lisp-mode-hook 'easy-escape-minor-mode)

NOTE: If you find the distinction between the fontified double-slash and the
single slash too subtle, try the following:

* Adjust the foreground of `easy-escape-face'
* Set `easy-escape-character' to a different character.
