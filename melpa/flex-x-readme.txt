flex-x adds a completion style based on the built-in `flex' style.

Features:

- Fuzzy matching before whitespace and literal AND filtering after it.
- Sorting by minibuffer history and flex score.
- Standard completion highlighting, including lazy highlighting.
- An optional regexp expander for non-ASCII candidates, such as migemo or
  pyim.

Add `flex-x' to `completion-styles' to enable it:

  (add-to-list 'completion-styles 'flex-x)
