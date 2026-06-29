Introduction
============

This library implements the global minor mode `smart-yank-mode'
that changes the way Emacs handles the `kill-ring-yank-pointer' in
a way that some people prefer over the default behavior.

Normally, only a kill command resets the yank pointer.  With
`smart-yank-mode' enabled, any command except yank commands resets
it.

In addition, when yanking any "older" element from the kill-ring
with yank-pop (and not replacing it with a subsequent yank-pop), it
is automatically moved to the "first position" so `yank' invoked
later will yank this element again.

Finally, `yank-pop' (normally bound to M-y) is replaced with
`smart-yank-yank-pop' that is a bit more sophisticated:

- When _not_ called after a `yank', instead of raising an error
  like `yank-pop', yank the next-to-the-last kill.

- Hit M-y twice in fast succession (delay < 0.2 secs by default)
  when you got lost.  This will remove the yanked text.  If you
  bind a command to `smart-yank-browse-kill-ring-command', this
  command will be called too (typically something like
  `browse-kill-ring').


Example: you want to manually replace some words in some buffer
with a new word "foo".  With `smart-yank-mode' enabled, you can do
it like this:

  1. Put "foo" into the kill ring.
  2. Move to the next word to be replaced.
  3. M-d M-y
  4. Back to 2, iterate.


Setup
=====

Just enable `smart-yank-mode' and you are done.