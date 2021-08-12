This package provides functions similar to `thing-at-point' of `thingatpt.el'.

The functions are:

xah-get-bounds-of-thing
xah-get-bounds-of-thing-or-region
xah-get-thing-at-point
xah-get-thing-or-region

They are useful for writing commands that act on text selection if there's one, or current {symbol, block, …} under cursor.

This package is similar to emac's builtin thing-at-point package thingatpt.el.

The main differences are:

• Is not based on syntax table. So, the “thing” are predicable in any major mode.
• provides the 'block, which is similar to emacs's 'paragraph, but strictly defined by between blank lines.
• xah-get-bounds-of-thing-or-region Returns the boundary of region, if active. This saves you few lines of code.
• Thing 'url and 'filepath, are rather different from how thingatpt.el determines them, and, again, is not based on syntax table, but based on regex of likely characters. Also, result is never modified version of what's in the buffer. For example, if 'url, the http prefix is not automatically added if it doesn't exist in buffer.
• Thing 'line never includes newline character. This avoid inconsistency when line is last line.

The return values of these functions is the same format as emacs's thingatpt.el, so you can just drop-in replace by changing the function names in your code.

Home page: http://ergoemacs.org/emacs/elisp_get-selection-or-unit.html
