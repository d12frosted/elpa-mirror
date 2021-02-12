This library provides hyperlinks of symbols (functions, variables,
faces) within Emacs' Info viewer to their builtin help
documentation.  This linking is enabled by installing the package.
(It might be necessary kill an old *info* buffer, though).  Inform
adds - as an autoload instruction - a function to the hook
`Info-selection-hook'.  If you don't want this linking feature any
longer you can set the variable `inform-make-xref-flag' to nil or
just uninstall the package and restart Emacs.

You can follow the additional links with the usual Info
keybindings.  The customisation variable
`mouse-1-click-follows-link' is influencing the clicking behavior
(and the tooltips) of the links, the variable's default is 450
(milli seconds) setting it to nil means only clicking with mouse-2
is following the link (hint: Drew Adams).

The link color of symbols - referencing their builtin documentation
- is distinct from links which are referencing further Info
documentation.  The hyperlink color is NOT changing when you are
visiting the link as it happens for the *Help* links.

The linking is done, when the symbol names in texinfo
documentations (like the Emacs- and Elisp manual) are

1. Quoted symbol names like `quoted-symbol' or:

2. Function names are prefixed by M-x, for example M-x
function-name or are quoted and prefixed like `M-x function-name'.

3. Function names appearing behind the following forms, which
occur, for example, in the Elisp manual:

  -- Special Form: function-name
  -- Command:
  -- Function:
  -- Macro:

4. And variables names behind the following text:

  -- User Option: variable-name
  -- Variable:

Inform is checking if the Info documents are relevant Elisp and
Emacs related files to avoid false positives.  Please see the
customization variable `inform-none-emacs-or-elisp-documents'.

 In any case all symbol names must be known to Emacs, i.e. their
names are found in the variable `obarray'.

The code reuses, mostly, mechanisms from Emacs' lisp/help-mode.el
file.
