Minor modes each put a word on the mode line to signify that they're
active.  This can cause other displays, such as % of file that point is
at, to run off the right side of the screen.  For some minor modes, such
as mouse-avoidance-mode, the display is a waste of space, since users
typically set the mode in their .emacs & never change it.  For other
modes, such as my jiggle-mode, it's a waste because there's already a
visual indication of whether the mode is in effect.

A diminished mode is a minor mode that has had its mode line
display diminished, usually to nothing, although diminishing to a
shorter word or a single letter is also supported.  This package
implements diminished modes.

You can use this package either interactively or from your .emacs file.
In either case, first you'll need to copy this file to a directory that
appears in your load-path.  `load-path' is the name of a variable that
contains a list of directories Emacs searches for files to load.
To prepend another directory to load-path, put a line like
(add-to-list 'load-path "c:/My_Directory") in your .emacs file.

To create diminished modes interactively, type
  M-x load-library
to get a prompt like
  Load library:
and respond `diminish' (unquoted).  Then type
  M-x diminish
to get a prompt like
  Diminish what minor mode:
and respond with the name of some minor mode, like mouse-avoidance-mode.
You'll then get this prompt:
  To what mode-line display:
Respond by just hitting <Enter> if you want the name of the mode
completely removed from the mode line.  If you prefer, you can abbreviate
the name.  If your abbreviation is 2 characters or more, such as "Av",
it'll be displayed as a separate word on the mode line, just like minor
modes' names.  If it's a single character, such as "V", it'll be scrunched
up against the previous word, so for example if the undiminished mode line
display had been "Abbrev Fill Avoid", it would become "Abbrev FillV".
Multiple single-letter diminished modes will all be scrunched together.
The display of undiminished modes will not be affected.

To find out what the mode line would look like if all diminished modes
were still minor, type M-x diminished-modes.  This displays in the echo
area the complete list of minor or diminished modes now active, but
displays them all as minor.  They remain diminished on the mode line.

To convert a diminished mode back to a minor mode, type M-x diminish-undo
to get a prompt like
  Restore what diminished mode:
Respond with the name of some diminished mode.  To convert all
diminished modes back to minor modes, respond to that prompt
with `diminished-modes' (unquoted, & note the hyphen).

When you're responding to the prompts for mode names, you can use
completion to avoid extra typing; for example, m o u SPC SPC SPC
is usually enough to specify mouse-avoidance-mode.  Mode names
typically end in "-mode", but for historical reasons
auto-fill-mode is named by "auto-fill-function".

To create diminished modes noninteractively in your .emacs file, put
code like
  (require 'diminish)
  (diminish 'abbrev-mode "Abv")
  (diminish 'jiggle-mode)
  (diminish 'mouse-avoidance-mode "M")
near the end of your .emacs file.  It should be near the end so that any
minor modes your .emacs loads will already have been loaded by the time
they're to be converted to diminished modes.

To diminish a major mode, (setq mode-name "whatever") in the mode hook.
