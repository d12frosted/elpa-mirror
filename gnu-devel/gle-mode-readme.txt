This is a major mode for files using the GLE (Graphics Layout Engine)
language.  See https://glx.sourceforge.net/
[ Apparently the site uses "glx" while everything else seems to use
  "gle" instead, because "gle" was already occupied in sourceforge.  ]

It provides:
- Code highlighting
- Automatic indentation
- Flymake support (requires Emacs-26's fymake)
- Imenu support
- Electric bloc names (after begin/end)
- Completion of bloc names
- Skeletons/templates to insert or close blocs

If you have misspelled a keyword or a command (etc.),
it should jump into your eyes because it is not highlighted.

Known defects:

- `print' is not highlighted in:

    if a==0 then print 0
    else if a==1 then print 1
    else print 2

- The `gle--line-syntax' description of the GLE language was extracted
  by hand from the doc and it is probably incomplete, and it is hard
  to update.

Contributors:
Andrey Grozin <A.G.Grozin@inp.nsk.su> (2022-11-07)
provided the data to build the syntax description from which
the highlighting works.

TODO
- provide more completion