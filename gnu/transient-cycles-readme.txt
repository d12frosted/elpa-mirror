Many commands can be conceptualised as selecting an item from an ordered
list or ring.  Sometimes after running such a command, you find that the
item selected is not the one you would have preferred, but the preferred
item is nearby in the list.  If the command has been augmented with
transient cycling, then it finishes by setting a transient map with keys to
move backwards and forwards in the list of items, so you can select a
nearby item instead of the one the command selected.  From the point of
view of commands subsequent to the deactivation of the transient map, it is
as though the first command actually selected the nearby item, not the one
it really selected.

For example, suppose that you often use `eshell' with a prefix argument to
create multiple Eshell buffers, *eshell*, *eshell*<2>, *eshell*<3> and so
on.  When you use `switch-to-buffer' to switch to one of these buffers, you
will typically end up in the most recently used Eshell.  But sometimes what
you wanted was an older Eshell -- but which one?  It would be convenient to
quickly cycle through the other Eshell buffers when you discover that
`switch-to-buffer' took you to the wrong one.  That way, you don't need to
remember which numbered Eshell you were using to do what.

In this example, we can think of `switch-to-buffer' as selecting from the
list of buffers in `eshell-mode'.  If we augment the command with transient
cycling, then you can use the next and previous keys in the transient map
to cycle through the `eshell-mode' buffers to get to the right one.
Afterwards, it is as though `switch-to-buffer' had taken you directly
there: the buffer list is undisturbed except for the target Eshell buffer
having been moved to the top, and only the target Eshell buffer is pushed
to the window's previous buffers (see `window-prev-buffers').

This library provides macros to define variants of commands which have
transient cycling, and also some minor modes which replace some standard
Emacs commands with transient cycling variants the author has found useful.
`transient-cycles-buffer-siblings-mode' implements a slightly more complex
version of the transient cycling described in the above example.

Definitions of command variants in this file only hide the fact that
transient cycling went on -- in the above example, how the buffer list is
undisturbed and how only the final buffer is pushed to the window's
previous buffers -- to the extent that doing so does not require saving a
lot of information when commencing transient cycling.