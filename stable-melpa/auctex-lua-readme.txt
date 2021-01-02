
This package provides some basic utilities for working with Lua
code from within AUCTeX.  `LaTeX-edit-Lua-code-start' is the entry
point of this package; bind it to your favorite key and use it
inside of any environment in `LaTeX-Lua-environments'.  To commit
your changes to the parent buffer and return to it, simply use
`save-buffer' (or whichever key it is bound to).  The contents of
the parent buffer will be updated and the Lua buffer will be killed.

Beware!  Editing embedded Lua code is asynchronous.  If you kill
the buffer that was editing it, your changes will be lost!  In a
future update I will add a `yes-or-no-p' confirmation to killing
the buffer, but I've yet to figure that one out.
