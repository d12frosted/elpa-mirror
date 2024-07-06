
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
