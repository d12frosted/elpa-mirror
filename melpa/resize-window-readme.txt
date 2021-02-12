Easily allows you to resize windows.  Rather than guessing that you
want `C-u 17 C-x {`, you could just press FFff, which enlarges 5
lines, then 5 lines, then one and then one.  The idea is that the
normal motions n,p,f,b along with r for reset and w for cycling
windows allows for super simple resizing of windows.  All of this is
inside of a while loop so that you don't have to invoke more chords
to resize again, but just keep using standard motions until you are
happy.

But, just run `M-x resize-window`. There are only a few commands to learn,
and they mimic the normal motions in emacs.

  n : Makes the window vertically bigger, think scrolling down. Use
       N  to enlarge 5 lines at once.
  p : Makes the window vertically smaller, again, like scrolling. Use
       P  to shrink 5 lines at once.
  f : Makes the window horizontally bigger, like scrolling forward;
       F  for five lines at once.
  b : window horizontally smaller,  B  for five lines at once.
  r : reset window layout to standard
  w : cycle through windows so that you can adjust other window
      panes.  W  cycles in the opposite direction.
  2 : create a new horizontal split
  3 : create a new vertical split
  0 : delete the current window
  k : kill all buffers and put window config on the stack
  y : make the window configuration according to the last config
  pushed onto the stack
  ? : Display menu listing commands
