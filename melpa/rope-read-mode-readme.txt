** About rope-read

*** What

=rope-read-mode= can reverse every other line of a buffer or in a part
of a buffer.

With every other line reversed reading can be like following a rope.

*** Illustration

[[file:rope-read-illustration.png][file:./rope-read-illustration.png]]

*** Ad

- Are you tired moving the look from one end of a line to the other
  end just because of a line break?

- Are you too lazy moving the look from one end of a line to the
  other end just because of a line break?

- Do you think about the line break coercing the brutal change of the
  look from one side to the other as humiliating?

- Do you want to read three or four lines more of a text before you
  fall asleep?

More than zero yes answers?

Then rope read might help!

*** Why

- Chill.  =rope-read-mode= allows fluent reading.

  - Find the start of the next line easily.

  - Avoid stressful eye movement.

- Have an alternative view on text.

*** Learn

Typically you need to practice for some time to be able to read
upside-down lines effortlessly.

** Usage

*** Turning it on and off

=M-x rope-read-mode= in a buffer activates rope-read.  No visible
change in the buffer is to be expected.  The buffer is set read-only.

Type =M-x rope-read-mode= or press 'q' to quit rope-read.  The buffer
writability gets restored.

*** Action

When =rope-read-mode= is on you can press
- =C-g= to interrupt =rope-read-mode= anytime,
- =g= to trigger reversing every other line for the currently visible
  part of the buffer,
- =r= to go back to the representation of the buffer without reversed
  lines (keeping =rope-read-mode=),
- =d= to reverse every other line starting with the line below the
  cursor,
- =p= to reverse every other line starting with the line below the
  cursor up to the end of the paragraph (if visible) and move point
  there.
- The next four commands are followed by reversing every other line:
  - =SPC= to scroll a screen down,
  - =<backspace>= or =S-SPC= to scroll a screen up,
  - =v= or =<return>= to scroll one line down,
  - =V= or =y= to scroll one line up,
- =?= to open the help buffer,
- =q= to quit =rope-read-mode=.

For convenience you can bind command =rope-read-mode= to a key.  For
example to activate or deactivate =rope-read-mode= by pressing scroll
lock two times use the line

#+BEGIN_EXAMPLE
(global-set-key (kbd "<Scroll_Lock> <Scroll_Lock>") 'rope-read-mode)
#+END_EXAMPLE

*** Image files

The reverse representation of lines is realized with images.  They get
collected in directory =rope-read-image-overlay-path= which defaults
to =~/.emacs.d/rope-reading=.  You can delete this directory any time.

*** Security

=rope-read-mode= does not change the content of a buffer.  Data loss
has not been reported yet.

Since the overlay-image files get stored on disk this could be a
security issue.  E.g. when you use =rope-read-mode= to look at your
super secret password file.

*** Beep

The system beep can be annoying.  The line

#+BEGIN_SRC shell
amixer set Beep off
#+END_SRC

silences the beep on some systems.  Precondition is that you have the
~amixer~ program ready.

** Install

*** Emacs Package

=rope-read-mode= is available as MELPA package
[[http://melpa.org/#/rope-read-mode][file:http://melpa.org/packages/rope-read-mode-badge.svg]] and ready
immediately after the install.

*** Install from el file

If you just have the emacs-lisp file then:
- load the file into Emacs
- do =M-x eval-buffer=

That's it.  You installed rope-read-mode and =M-x rope-read-mode= is
available.

** Dependencies

- Emacs is running under X.
- The programm =convert= of the ImageMagick-suite is available.

The =convert= program has the job to create images of lines and rotate
them.

** Development

*** Known Bugs

- rope-read-mode sometimes spontaneously fails.
  - In this case a refresh with =g= might help.
  - You can always try =C-g q= and start again.
- rope-read-mode often does not work for org-mode files.
  - Possibly this is due to the interference of overlays of org and
    rope-read.

*** Wishes

- Quicker transformation.

*** Vision

=rope-read-mode= gets =rope-mode= which allows also editing.
=rope-mode= would provide a further editing feeling maybe.

*** Lentic Literate Style

This program is written in emacs lisp in lentic style based on the
'lentic' package [[http://melpa.org/#/lentic][file:http://melpa.org/packages/lentic-badge.svg]].

This means the that this file can be regarded just as an emacs lisp
file.  But actually this file contains extra comments which allow the
interpretation of the file as Org file.  Lentic-mode makes it easy to
write this style.

A possible initialization of lentic is this:

#+BEGIN_EXAMPLE
(global-lentic-start-mode)
#+END_EXAMPLE

Find more about lentic at
[[http://melpa.org/#/lentic][file:http://melpa.org/packages/lentic-badge.svg]].

*** Communication

Use the GitHub infrastructure i.e. pull requests or
https://github.com/marcowahl/rope-read-mode/issues.  Or contact the
author directly.

*** Contribution

Contributions in any respect are welcome, e.g. ideas and improvements.

*** Contributors

| Syohei YOSHIDA |
| Marco WAHL     |

** Related

- rope-read for firefox at
  https://greasyfork.org/en/scripts/10634-rope-read
- 'spray' which is available as Elpa package
  [[http://melpa.org/#/spray][file:http://melpa.org/packages/spray-badge.svg]] realizes another
  alternative view mode.
- 'fliptext' which also is available as Elpa package
  [[http://melpa.org/#/fliptext][file:http://melpa.org/packages/fliptext-badge.svg]] realizes an

  ˙ʇxǝʇ pǝddılɟ ɹoɟ poɥʇǝɯ-ʇnduı

** History

| 201501151211 | v0.1 New option rope-read-calculate-exact-y-coordinates |
| 201501311657 | v0.2 Replace whenever a line is ready                   |
| 201503160841 | Dropped option heuristic y-coordinates calculation      |
| 201503161010 | v0.3 Operations based on visual movement-commands       |
| 201508081255 | v0.3.1 rope-read-mode starts line reversing at point    |
| 201510202326 | v0.3.2 rope-read-mode does nothing at start             |
| 201511182342 | Paragraph wise rope-read is useful.                     |
| 201602082358 | One scan through the documentation                      |
