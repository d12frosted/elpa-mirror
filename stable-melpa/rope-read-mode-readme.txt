=rope-read-mode= can reverse every other line of a buffer or in a part
of a buffer.  With every other line reversed reading can be like
following a rope.

Precondition
------------

rope-read-mode depends on programm gm of the GraphicsMagick-suite (for
actual transformation of the lines.)

Turning it on and off
---------------------

=M-x rope-read-mode= in a buffer activates rope-read.  No visible
change in the buffer is to be expected.  The buffer is set read-only.

Type =M-x rope-read-mode= or press 'q' to quit rope-read.  The buffer
writability gets restored.

Action
------

When =rope-read-mode= is on you can press
- =C-g= to interrupt =rope-read-mode= anytime
- =q= to quit =rope-read-mode=
- =?= to open the help buffer
- =r= /redraw standard/ to go back to the representation of the buffer
  without reversed lines (keeping =rope-read-mode=)
- =p= /paragraph/ to reverse every other line starting with the line
  below the cursor up to the end of the paragraph (if visible) and
  move point there
- The next four commands are each followed by reversing every other
  line in the visible part.  The keys are taken the same as in
  =view-mode=:
  - =SPC= to scroll a screen down
  - =<backspace>= or =S-SPC= to scroll a screen up
  - =v= or =<return>= to scroll one line down
  - =V= or =y= to scroll one line up
- =g= /get the rope-read/ to trigger reversing every other line for
  the currently visible part of the buffer
- =d= /downwards/ to reverse every other line starting with the line
  below the cursor

Configuration
-------------

For convenience you can bind command =rope-read-mode= to a key.  e.g.

#+BEGIN_EXAMPLE
(keymap-global-set "C-c R" #'rope-read-mode)
#+END_EXAMPLE

You can control the flipping via customization.
See M-x customize-apropos rope-read.
