This package provides a minor mode `org-xlatex-mode'.  It provides
almost instant LaTeX previewing in Org buffers by embedding MathJax
in an xwidget inside a child frame.  The child frame automatically
appears and renders the formula at the point when appropriate.

org-xlatex is self-contained.  It requires Emacs to be compiled
with xwidget, but does not require any external programs.

=====
USAGE
=====

Simply turn on `org-xlatex-mode' in an Org buffer.

You can turn off and then turn on `org-xlatex-mode' again to reset
the internal states, in case you run into problems.

=============
CUSTOMIZATION
=============

Org-xlatex is designed to work out-of-the-box with reasonable
default values.  There is nothing you need to configure for it to
work.  Just turn on the minor mode and enjoy!

 * You may find an optional (off by default) feature
`org-xlatex-position-indicator' useful: it puts a red indicator for
the current cursor position in the preview.  It is a naive
implementation, by no means perfect, and may be confusing to new
users.  To enable it: (setq org-xlatex-position-indicator t)

 * If you find the default size of the preview frame too
small/large, consider customizing `org-xlatex-width' and/or
`org-xlatex-height'.

 * Those who use unconventional setups may want finer control over
the positioning and/or the size of the preview frame through
`org-xlatex-size-function' and `org-xlatex-position-function'.
Refer to their docstrings for details on how to use them.
