DSL IDE creates presentations out of org mode documents.  Every single step
in a presentation can be individually configured, customized, or
programmed.  Org headings and elements are configured with extensible
actions.  Custom steps can be scripted with babel blocks.  Keyboard macros
can play back real command sequences.  Frequent customizations can be made
into custom actions.  DSL IDE achieves a good result with no preparation
but can achieve anything Emacs can display if you need it to.

To try it out, install this package and load the demo.org found in the test
directory of the repository.  `dslide-deck-start' will begin the
presentation and the first slides tell you how to progress, like a
tutorial.  The README for the repository is generated from the manual and
explains conceptually the meaning of the examples in the demo.

Requirement:
   org-mode 9.6.29 or higher version
   The latest version of the org-mode is recommended.
                     (see https://orgmode.org/)

Configuring:
M-x customize-group RET dslide RET

Customizing & Extending:

For high level overview of the key concepts present in this Elisp file, see
the Hacking section of the dslide manual, available in completions for
`info-display-manual'.  The package code has key areas documented to expand
on ideas in the manual, using docstrings and more technical commentary
closer to the source.

This package began as a fork and became a complete re-write of
org-tree-slide by Takaaki ISHIKAWA.  Thanks to everyone who worked on
org-tree-slide over the years.  The implementation ideas and features of
org-tree-slide were a great inspiration for this package.  Long live
🖊️🍍🍎🖊️.
