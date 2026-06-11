* TL;DR

=rope-read-mode= can reverse every other line of a buffer or in a part
of a buffer.  With rope-read-mode reading is like following a rope.

1. Activate with {M-x rope-read-mode RET}
2. Press p or g.
2.1. Wait for it.
3. Enjoy.
4. Press p, SPC, DEL, r or g.
5. Goto step 3 or:
6. Press q to quit.

note: rope-read-mode depends on programm =gm= of the
GraphicsMagick-suite for full functionality .

* Documentation

** About rope-read

=rope-read-mode= reverses every other line for a text.  With every
other line reversed reading can be like following a rope.

read a line in one direction e.g. from left to right and the next line
from right to left.

Not so cool with rope read: a reversed line is somewhat harder to read
compared with a non-reversed line.

Typically you need to practice for some time to be able to read
reversed lines effortlessly.

*** Why rope-read?

- Chill.  =rope-read-mode= allows fluent reading.

  - Find the start of the next line easily.

  - Avoid flurry eye movement.

- Have an alternative view on text.

*** Illustration

[[file:rope-read-illustration.png][file:./rope-read-illustration.png]]

** Usage

*** Turning it on and off

=M-x rope-read-mode= in a buffer activates rope-read.  No visible
change in the buffer is to be expected.  The buffer is set read-only.

Type =M-x rope-read-mode= or press 'q' to quit rope-read.  The buffer
writability gets restored.

*** Action

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

*** Customization

**** Keybinding to activate rope-read

For convenience you can bind command =rope-read-mode= to a key.  For
example to activate or deactivate =rope-read-mode= by pressing the key
seqence C-c R use the line

#+BEGIN_EXAMPLE
(keymap-global-set "C-c R" #'rope-read-mode)
#+END_EXAMPLE

in your emacs init file.

**** Customize the flipping

You can control the flipping somewhat via customization.
See =M-x customize-apropos rope-read=.

*** Image files

The reverse representation of lines is realized with images (if
=rope-read-pure-text= is off.)  They get collected in directory
rope-read-mode/ in the user-emacs-directory.

You can delete this directory any time.

*** User Feedback

[2016-10-03 Mon 15:04] M: "I use rope read mode occasionally to read
info manuals, mail (via gnus) and text of web pages (via eww).  Most
of the time I start the mode and then use key 'p' to walk through the
text.  Finally I use key 'q' to quit."

** Preconditions for full rope-read-mode functionality

- Emacs is running under X.
- The programm =gm= of the GraphicsMagick-suite is available.

The =gm= program has the job to create images of lines and rotate them.

** rope-read-mode without image creation

turn option =rope-read-pure-text= on to enable rope-read-mode without
creating images.

note that with this setting the characters in every other line get
just reversed.  the result might not be as readable as with the
flipping of the lines.
