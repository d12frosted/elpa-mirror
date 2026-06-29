Just like occur, except that changes in the *All* buffer are
propagated to the original buffer.

You can no longer use mouse-2 to find a match in the original file,
since the default definition of mouse is too useful.
However, `C-c C-c' still works.

Line numbers are not listed in the *All* buffer.

Ok, it is _not_ just like occur.

Some limitations:

- Undo in the *All* buffer is an ordinary change in the original.
- Changes to the original buffer are not reflected in the *All* buffer.
- A single change in the *All* buffer must be limited to a single match.