This file provides a set of list-oriented functions for operating over the
contents of buffers, mostly revolving around regexp searching, and regions.
They avoid the use of looping, manipulating global state with `match-data'.
Many high-level functions exist for matching sentences, lines and so on.

Functions are generally purish: i.e. that is those functions which do
change state, by for example replacing text or adding overlays, should only
change state in one way; they will not affect point, current buffer, match
data or so forth.

Likewise to protect against changes in state, markers are used rather than
integer positions. This means that it is possible, for example, to search
for regexp matches and then replace them all without the earlier
replacements invalidating the location of the later ones. Otherwise
replacements need to be made in reverse order. This can have implications
for performance, so m-buffer also provides functions for making markers nil;
there are also macros which help manage markers in `m-buffer-macro'.

Where possible, functions share interfaces. So most of the match functions
take a list of "match" arguments, either position or as a plist, which avoids
using lots of `nil' arguments. Functions operating on matches take a list of
`match-data' as returned by the match functions, making it easy to chain
matches.

This file is documented using lentic.el. Use
[[http://github.com/phillord/lentic-server][lentic-server]] to view.
