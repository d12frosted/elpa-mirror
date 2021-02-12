Dim or hide autoload cookie lines.

Unlike the built-in font-lock keyword which only changes the
appearance of the "autoload" substring of the autoload cookie
line and repurposes the warning face also used elsewhere, the
keyword added here changes the appearance of the complete line
using a dedicated face.

That face is intended for dimming.  While you are making sure
your library contains all the required autoload cookies you can
just turn the mode off.

To install the dimming keywords add this to your init file:

   (global-dim-autoload-cookies-mode 1)

You might even want to dim the cookie lines some more by using
a foreground color in `dim-autoload-cookies-line' that is very
close to the `default' background color.

Additionally this package provides a mode which completely hides
autoload cookies.  To hide autoload cookies in the current buffer
use `hide-autoload-cookies-mode'.  A globalized mode also exists,
but its use is discouraged.  Also note that it doesn't make sense
to enable both global modes at the same time, or to enable both
local modes in the same buffer.

Use the command `cycle-autoload-cookies-visibility' to cycle
between the three possible styles in the current buffer, like
so:

   ,-> Show -> Dim -> Hide -.
   '------------------------'
