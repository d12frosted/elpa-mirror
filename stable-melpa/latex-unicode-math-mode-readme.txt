An Emacs minor mode for entering Unicode math symbols in
LaTeX-mode, with a sty file to make pdflatex Unicode-aware.  This
minor mode automatically replaces inputs like `\phi` with `ϕ` and
`\in` with `∈`.  These replacements happen inside of math
environments or everywhere, depending on the configuration.

If you use pdflatex, you can add `\usepackage{unicode-math-mode}`
to your tex file in order to make pdflatex aware of the Unicode
characters.  Use `M-x latex-unicode-save-sty-file` to put this file
somewhere where pdflatex will find it.

If you update this package, you may need to do this again to get
the latest sty file.
