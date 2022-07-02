TopSpace provides the ability to scroll down the first line of a buffer
to be below the top of the window with blank lines drawn above it,
allowing the first line to be displayed in the center of the window
as if it weren't the first line.
This is done by automatically drawing an upper margin/padding above line 1
as you recenter and scroll down top text, without modifying the
underlying file.

See https://github.com/trevorpogue/topspace for a gif demo & documentation.

Features:

- Easier on the eyes: Recenter or scroll down top text to a more
  comfortable eye level for reading, especially when in full-screen
  or on a large monitor.

- Easy to use: No new keybindings are required, keep using all
  your previous scrolling & recentering commands, except now you
  can also scroll above the top lines.  It also integrates
  seamlessly with `centered-cursor-mode' to keep the cursor
  centered all the way to the top line.

How it works:

The "upper margin" is created by drawing an overlay before
window-start containing newline characters.  As you scroll above the
top line, more newline characters are added or removed accordingly.

No new keybindings are required as topspace automatically works for
any commands or subsequent function calls which use `scroll-up',
`scroll-down', or `recenter' as the underlying primitives for
scrolling.  This includes all scrolling commands/functions available
in Emacs as far as the author is aware.  This is achieved by using
`advice-add' with the `scroll-up', `scroll-down', and `recenter'
commands so that custom topspace functions are called before or after
each time any of these other commands are called (interactively or
otherwise).
