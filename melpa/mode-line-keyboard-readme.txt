This package turns the header and mode lines into a keyboard.  This
is mainly intended to be used in environments without a normal
keyboard, such as touch devices.  Concretely, the Android
application "Termux" provides a Linux terminal environment that
includes a terminal version of Emacs.

Activate:

Enable the mode in a single buffer using:

    M-x mode-line-keyboard-mode RET

For all buffers use:

    M-x mode-line-keyboard-global-mode RET

Alternatively, add the following line to your init file:

    (mode-line-keyboard-global-mode 1)

Usage:

When enabled, the mode line contains the string `KB>'.  If you
click on it, the header will look like:

    1/4 SHFT CTRL META SPC TAB RET <X X> 1 2 3 4 5 6 7 8 9 0

And the mode line will look like:

    1/2 a b c d e f g h ...

To type on the keyboard, simply click on the characters, modifiers,
and special keys.

The `1/4' indicates that this is one of four lines -- clicking on
it display the next line.  To hide the keyboard click on `<KB'
which (by default) is on the last mode line.

Clicking in the echo area inserts a space (unless the minibuffer is
active).

To avoid accidental point movement when the Mode Line Keyboard is
visible, you have to double click to move the point, triple click
to mark a word etc.

Dependencies:

This package require Emacs 26.  In earlier Emacs versions, plain
typing works OK.  However, when typing something more complex like
`C-x C-f', the function `read-key-sequence-vector' raises the error
`args-out-of-range'.

Tips:

When Emacs is used in a terminal, the `header-line' face by default
has the `:underline' property set.  As many terminal environments
today provide many colors, this doesn't look good, and it makes it
hard to distinguish between characters like `.' and `,'.

You can override this by using something like:

    (deftheme my-theme "Theme to make the header line more readable.")
    (custom-theme-set-faces
      'my-theme
      '(header-line ((((class color)) :inherit mode-line))))

Customization:

The variables `mode-line-keyboard-header-line-content' and
`mode-line-keyboard-mode-line-content' control what should be
displayed in the header and mode lines, respectively.

They are lists, and each entry in the list corresponds to one
concrete line.

Each entry can be one of the following:

  * `integer' -- A character
  * `(:range integer integer)' -- A range of characters
  * `(integer label)' -- A character, but display "label".
  * `(:shift integer integer)' -- A character and its shifted counterpart.
  * `(:toggle var func label)' -- A modifier (like `control').
  * `(func label)' -- Call `func' when "label" is clicked.
  * `:keyword' -- Looked up in `mode-line-keyboard-template-list'.

The variable `mode-line-keyboard-template-list' is a list.  Each
element is a list starting with a keyword followed by one or more
items that this keyword is substituted for.

Notes:

When this package in used, `mouse-movement' events are suppressed.
Normally, this is not a problem.  Without this, clicking on `ESC'
on the Mode Line Keyboard and subsequently moving the mouse would
trigger an error that `ESC <mouse-movement>' is undefined.  (Note,
this happens when moving the mouse after pressing `ESC' on the
keyboard as well, however, in practice this is seldom an issue in
that context.)

Known problems:

* In Termux, sometimes (especially at startup), clicking in the
  echo area to insert a space doesn't work (instead the message
  "Minibuffer window is not active").  It appears as though Termux
  sends the `ESC ... M' sequence (down mouse) but not `ESC ... m'
  (up mouse) -- or that Emacs doesn't pick it up.  (To test this,
  click in the echo area and then `C-h l'.)

* When clicking on a label such as `CTRL' or `KB>', this package
  calls `read-key' recursively.  This mean that if you repeatedly,
  say, show and hide the keyboard, many times you could run out of
  call stack.  (All calls return once you have typed a key.)  In
  practice, This should not be a problem, unless you are the
  nervous type.

* Inserting a space by clicking in the echo are result in a undo
  event by itself.  This is probably due to that there are two
  events seen by Emacs, one `down' event and one `up'.  (It would
  probably be possible to fix this by "swallowing" the down event,
  as done by other keys.)

* When typing fast it's easy to accidentally move the point.  (When
  the Mode Line Keyboard is visible, the user must double-click to
  move the point.  However, when typing fast the clicks are
  double-clicks, and if the click is outside the mode or header
  line, the double click will move the point.)

Future ideas:

* Caps lock support, at least for shift, but maybe for all
  modifiers.

* Today, it's possible to step through a number of keyboard lines.
  Howevever, there are no reasons to limit the layout to lines.
  One could imagine a tree structure, where some labels on the mode
  or header line would open new sublayouts.  This could be used,
  for example, to open a dedicated meny for parentheses or to
  support accented characters.

* Allow layouts to be major-mode specific.  For example, when
  writing C, curly braces maybe should be accessible than when
  writing Lisp.

* Provide a convenient mechanism for theme packages.  (I can't wait
  to see the kind of layouts users might come up with.)

* Better support for automatic detection and adaptation to native
  languages (e.g. swedish -- which is my native langugage -- we has
  three extra letter å, ä, and ö).

Implementation:

This package adds key binding for things `mode-line mouse-1' to
`input-decode-map'.  These bindings convert the events to plain
keys, or perform some other kind of action.  The header- and
mode-line strings used by Mode Line Keyboard has the property
`mode-line-keyboard-action'.  When the property is a vector
(typically containing a key) it is returned.  When it's a function,
it is called, this is for example used by the entries that add
modifiers.

Some of the Mode Line Keyboard functions call `read-key'.  This
will in turn tunnel whatever they read through `input-decode-map',
which could cause Mode Line Keyboard functions to be called.  This
could, of course, mean that the same function is called in a
bizarre kind of recursive way.

In some cases, this package tries to silence events.  This is done
by calling `read-key' and returning the next event.

Personal note:

When I first started writing this package I though it would be
"easy pick", and I planned to spend an evening or two one it.  Boy,
was I wrong.  The Emacs event system turned out to be very complex,
and it took a lot of time and energy to try to understand how it
works.  In addition, I ran into numerous bugs in Emacs along the
way.

In order to understand what happens when a key is pressed or when
something is clicked, I wrote the package `keymap-logger' that
instruments a number of system keymaps and log the result.

Tips:

When Emacs is used in a terminal, the `header-line' face by default
has the `:underline' property set.  As many terminal environments
today provide many colors, this doesn't look good, and it makes it
hard to distinguish between characters like `.' and `,'.

You can override this by using something like:

    (deftheme my-theme "Theme to make the header line more readable.")
    (custom-theme-set-faces
      'my-theme
      '(header-line ((((class color)) :inherit mode-line))))
