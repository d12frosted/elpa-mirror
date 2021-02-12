
### HTML to Markdown converter written in Emacs-lisp. ###

This package defines two main functions: `html-to-markdown' and
`html-to-markdown-string'.

The functions are written entirely in Emacs-lisp (which means they'll
work on any platform with no external dependencies), and they convert
HTML source code into Markdown format. Of course, HTML has many more
features than Markdown, so any tags that can't be converted are left
as-is (or deleted, if the user so requests).

Instructions
------

To use this package, simply install it from Melpa (M-x
`package-install' RET html-to-markdown) and the relevant functions will
be autoloaded.

- `html-to-markdown'
  Is meant for interactive use. It takes the current buffer (or
  region), converts to Markdown, and displays the result in a separate
  window.

- `html-to-markdown-string'
  Is meant for lisp code. It takes a string argument, which is
  converted to Markdown, and the result is returned.

Both of these functions take an extra boolean argument
`erase-unknown'. If it's non-nil, tags which can't be converted will
be erased.
