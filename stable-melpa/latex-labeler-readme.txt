Introduction

`latex-labeler.el' is an Emacs Lisp package designed to streamline
the process of labeling equations in LaTeX documents.  This package
enables numbering equations sequentially in a LaTeX file from top
to bottom.  The main purpose of `latex-labeler.el' is to
synchronize equation labels in a LaTeX file and a compiled
document.

Important note

While `latex-labeler.el' works seamlessly with AUCTeX and YaTeX, it
may encounter unexpected errors when used with the built-in
latex-mode, especially when labeling equations within subequations
environment.  We recommend using `latex-labeler.el' with AUCTeX or
YaTeX.

Getting started

If you use AUCTeX, add the following code to your
Emacs configuration file (e.g.  ~/.emacs.d/init.el):

(with-eval-after-load 'latex (require 'latex-labeler))


If you use YaTeX instead of AUCTeX, add the following code:

(with-eval-after-load 'yatex (require 'latex-labeler))


Usage

`latex-labeler.el' provides three commands for labeling equations
and updating references.

1. `latex-labeler-update': Update equation labels and references
that match the predefined format in your LaTeX document.

2. `latex-labeler-update-force': Forcefully update all labels and
references, regardless of the format.

3. `latex-labeler-change-prefix-and-update': Change the label
prefix interactively and updates labels.  When you change the
prefix, LaTeX Labeler appends the necessary local variables
configuration to your LaTeX file.

If you want to append section numbers to equation labels for a
specific file, add the following lines at the end of the LaTeX file:

% local variables:
% latex-labeler-with-section-counter: t
% end:

If you prefer to set this configuration globally, add the following
line to your Emacs configuration file:

(setq latex-labeler-with-section-counter t)
