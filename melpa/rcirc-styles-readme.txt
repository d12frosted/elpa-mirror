The de facto standard for IRC color codes, as originally
implemented in mIRC, can be found at
http://en.wikichip.org/wiki/irc/colors .

As may be expected from the context, it's a bit ad hoc and not the
easiest thing in the world to parse correctly, which may explain why a
prior attempt to satisfy this use case, under the name of
"rcirc-controls.el", attempted to do so with a recondite yet woefully
inadequate regexp.

Rather than attempt to fix the regexp, and even if successful make
it even more incomprehensible than it started out being, I decided
it'd be easier and more maintainable to write a string-walking
parser.

So I did that.  In addition to those cases supported in the previous
library, this code correctly handles:
* Background colors, including implicit backgrounds when a new code
  provides only a foreground color.
* Colors at codes between 8 and 15 (and correct colors for codes < 8).
* Color specifications implicitly terminated by EOL.
* Color specifications implicitly terminated by new color
  specifications.
* The ^O character terminating color specifications.

While I was at it, I noticed some areas in which the both the stock
attribute markup function in rcirc, and the one provided in
the previous library, could use improving.

So I did that too, and the following cases are now correctly handled:
* Implicit termination of attribute markup by EOL.
* ^V as the specifier for reverse video, rather than italics.
* ^] as the specifier for italics.

There are a couple of attribute codes which I've only seen
mentioned in a few places, and haven't been able to confirm
whether or how widely they're used:
* ^F for flashing text;
* ^K for fixed-width text.
Since these appear to be so ill-used, I'm not terribly anxious to
support them in rcirc, but they are on my radar. If you want one or
both of these, open an issue!

As far as I'm aware, this code implements correct and, subject to
the preceding caveats, complete support for mIRC colors and
attributes. If I've missed something, let me know!

Finally, a note: Since this package entirely obsoletes
rcirc-controls, it will attempt rather vigorously to disable its
predecessor, by removing rcirc-controls' hooks from
`rcirc-markup-text-functions' if they are installed.  Not to do so,
when both packages are loaded, would result in severely broken
style markup behavior.
