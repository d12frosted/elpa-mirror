Scroll down and recenter top lines.

- Easier on the eyes: Recenter or scroll down top text to a more
  comfortable eye level for reading, especially when in full-screen
  or on a large monitor.

- Easy to use: No new keybindings are required, keep using all
  your previous scrolling & recentering commands, except now you
  can also scroll above the top lines.  It also integrates
  seamlessly with `centered-cursor-mode' to keep the cursor
  centered all the way to the top line.

How it works:
A top margin is created above the top text line as you scroll down
top text.  The "margin" is created by drawing an overlay before
window-start containing newline characters.  As you scroll above the
top line, more newline characters are added or removed accordingly.

No new keybindings are required as topspace automatically works for
any commands or subsequent function calls which use `scroll-up',
`scroll-down', or `recenter' as the underlying primitives for
scrolling.  This includes all scrolling commands/functions available
in Emacs as far as the author is aware.
