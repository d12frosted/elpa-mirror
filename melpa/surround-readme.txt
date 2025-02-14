
Provides functions for working with pairs like parentheses and quotes,
including wrapping text, deleting pairs, marking pairs or within them, and
changing them.  This is similar to vim's surround plugin.

For a detailed introduction and example usage, see the readme file at
https://github.com/mkleehammer/surround

This package provides a keymap with functions for working with pairs of
delimiters like (), {}, quotes, etc.  If you are using use-package, the
easiest way to configure is like so:

   (use-package surround
    :ensure t
    :bind-keymap ("M-'" . surround-keymap))

This will bind M-', but obviously choose the key you prefer.  C-c s may be a
good option.  The keymap will have the following keys bound:

- s :: Surrounds the region or current symbol with a pair
- i :: Selects the text within a pair (inner select / mark)
- o :: Selects the pair and text within (outer select / mark)
- k :: Kills text within a pair (inner kill)
- K :: Kills the pair and text within (outer kill)
- d :: Deletes the pair, but leaves text within
- c :: Change the pair for another (e.g. change [1] to {1})

For convenience, the 'i' and 'k' commands perform an outer select or kill if
given a closing pair character, such as ')'.  That is, "M-' i (" will perform
an inner mark but "M-' i )" will perform an outer mark.  When the left and
right pair characters are the same, such as when using quotes, the commands
always perform the inner command.

The keymap also has shortcut commands for marking some pairs, bound to just
the pair characters themselves.  For example, "M-' (" will mark within
parentheses.  These all work like the 'i' command, so they default to inner
but will work as an outer select if a right / closing pair character is
entered:

Inner: ( { [ < ' ` "
Outer: ) } ] >
