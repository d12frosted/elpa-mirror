DSL IDE builds presentations on top of org mode documents.  It integrates
with arbitrary buffers and org babel, making anything Emacs can do easy to
incorporate into a presentation.  Headers are configured with extensible
actions.  Custom steps can be scripted with babel blocks or made into
reusable custom actions.  DSL IDE achieves a good result with no preparation
but can achieve anything Emacs can display if you need it to.

See the README for more detailed instructions.

There are examples of using the features within the test directory.

Requirement:
   org-mode 9.6.29 or higher version
   The latest version of the org-mode is recommended.
                     (see https://orgmode.org/)

Usage:
   1. Open an org-mode file
   2. Run `dslide-deck-start'
   3. Use arrow keys.  See `dslide-mode-map'

Note:
   - Customize variables, M-x customize-group RET dslide RET

The code outline is as follows:

1. Class interface definitions for stateful sequence, deck (root sequence),
slide, and actions (sequences that run within slides).

2. Org element mapping implementations that are private but exposed publicly
on slide actions and elsewhere because they are super useful.

3. Miscellaneous implementation details of parsing arguments, debug printing,
header, animation etc.

4. Lifecycle of the mode, switching between base buffer, contents, and
slides, user interface commands.

For users, you might want to create your own actions, so check `dslide-action'
and its sub-classes.  Read the manual on `(info \"(eieio) \Top")'

The `dslide-deck' class contains some functions related to adding callbacks or
entering custom sequences.

For hackers wishing to extend the code, in addition, you will want to check
`dslide--make-slide' if you want your slides to hydrate actions differently.
Also pay very close attention to `dslide-stateful-sequence' and how sequences
and steps can be pushed.

This package is a fork and mostly complete re-write of org-tree-slide by
Takaaki ISHIKAWA.  Thanks to everyone who worked on org-tree-slide over the
years.  The implementation ideas and features of org-tree-slide were a great
inspiration for this package.