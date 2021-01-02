
This package is designed to run functions depending on the column
that the cursor is in.  My initial idea with it, is just to have it
change the cursor colour, lightening it as you go over the fill
column length.

The point of this is that monitor sizes have in recent years got
plain silly, and its now relatively easy to buy one the size of a
small wardrobe.  Combined with the other wise wonderful
`dabbrev-expand' which makes it feasible to use very explantory,
and very long variable, and function names, source code has a habit
of becoming stupidly wide.  Now of course this wouldn't matter very
much, if we all had wide screens.  However in recent years, flat
screen monitors have become widely prevelant, and these generally
have lower resolutions, and smaller screen sizes, unless you are
very rich.  This raises the nasty possibility of a split therefore
in behaviour between those using LCD, and CRT based monitors.
Coming, as I do, from the left of the political spectrum, naturally
I find such divisiveness worrying.  This, therefore, is my
contribution to preventing it.

This package functions as a normal minor mode, so
`wide-column-mode' toggles it on and off. There is also a global
minor mode which you can access with `global-wide-column-mode'
(Emacs 21 only). There is a problem with the getting the default
cursor colour; this happens when wide-column is loaded, and I can't
get around it without a hook in `set-cursor-color'. Set the
variable `wide-column-default-cursor-colour' which will solve this
problem.


; Similar Packages:

Sandip Chitale (sandip.chitale@blazesoft.com) highlight-beyond-fill

; Installation

Place this file in your Emacs load path. Put (require 'wide-column)
into your .emacs or equivalent file. This operates as a normal
minor mode, so `wide-column-mode' will toggle it on and off.

The code was developed on Gnu Emacs 21. Emacs 20 support has now
been removed because it required code duplication horribleness.

It may work on XEmacs, but I don't have one around to try. You will
certainly need the fsf compatibility packages if you do.

; Issues;

1) I'm not sure about the error handling. I think things are
working quite well. However if the affector function crashes out,
it will appear to the user that wide-column mode is on, but
actually, it will be disabled. I can solve this easily, by
switching the mode off on errors, but easy-mmode produces
mini-buffer messages, which hide my own attempts to provide error
reporting. I think this way is better. If a crash happens the
system will be inconsistent, but the alternative will be to have
the minor-mode switch itself off.

2) The colour list is poor. I would like to improve things here,
but I am not sure how. See the comments near the definition of
`wide-column-colour-list'

3) Custom support would be good, and no doubt will be added at some
time.

4) It's not going to work if people use lots of different default
cursor colours. Seems like a daft thing to do to me! Something to
work on anyway. Maybe I could solve this by advicing
`set-cursor-colour', but this would fail if someone uses
`modify-frame-parameters' directly, and I really don't want to
advice this function anyway.
