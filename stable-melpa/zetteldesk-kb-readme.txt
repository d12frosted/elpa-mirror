This file defines a few hydras for the keybindings in
zetteldesk.el.  The hydra displays small descriptions of each
function to help a beginner with getting familiarised with the
package.  The keybindings used are based on what my personal config
uses, but to fit it all in a single hydra, there are some
differentiations.

I made this optional and not part of the main package as I don't
consider it essential, just helpful for those who want a ready set
of keybindings, with descriptions instead of the function names to
try the package out.  Due to the modularity of Emacs, I recommend
you set up your own keybindings either from scratch or by
customising these hydras so they make the most sense to you and fit
your mental model.  I however thought that something like this will
be very useful until you get the hang of the package.

The hydras are defined with the `pretty-hydra-define' macro from
the `major-mode-hydra' package as imo its end result is a very good
looking hydra menu, perfect for something like this.  For this
reason, this part of the package, relies on that package.
