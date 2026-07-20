flex-x adds a completion style based on the built-in `flex' style.

Features:

- Space-separated AND filtering.
- Sorting by minibuffer or Corfu history and flex score.
- Standard completion highlighting and whole-candidate highlighting for
  literal and word-prefix-sequence matches, including lazy highlighting.
- Optional regexp expanders for non-ASCII candidates, such as migemo or pyim.

Add `flex-x' to `completion-styles' to enable it:

  (add-to-list 'completion-styles 'flex-x)
