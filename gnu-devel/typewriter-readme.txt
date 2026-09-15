            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             TYPEWRITER-MODE: TURN EMACS INTO A TEXT ADDER
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package provides `typewriter-mode', a small minor mode that
deliberately handicaps Emacs to an extreme degree in order to provide
something as close as possible to the strict forward-only typewriter
experience.  Some find that the lack of editing facilities fosters a
state of concentration and focus that makes certain types of creative
writing more satisfying.

The package has seven configuration options:

• `typewriter-preserve-undo-history': if non-nil, you'll be able to undo
  edits if you turn `typewriter-mode'.  Default is `t'.

• `typewriter-recenter': if non-nil, the line where cursor is at is
  recentered (the command `recenter' is called) after every licit
  keystroke.  Default is `nil'.

• `typewriter-fill-column': if `nil', your lines will be as long as you
  want.  Set to any integer `N', emacs-turned-to-typewriter refuses to
  type anything once you reach column `N' until you press `RET' to open
  a new line.  Default is `nil'.

• `typewriter-warning-bell-offset': If your fill column is set, a
  physical /ding/ will sound this many characters before the margin to
  warn you that the carriage is about to jam.  Default is `8'.

• `typewriter-show-chars-remaining': If this and
  `typewriter-fill-column' are non-nil, the modeline will display how
  many characters are left in the current line until the fill column
  (the margin) is reached.  Default is `t'.

• `typewriter-modeline-format': Format string for the modeline indicator
  of remaining characters.  Default is `" [%d]"'.

• `typewriter-tab-width': self explanatory.  Default is `8'.

There are two hooks available for the user to customize the typing
experience, no function is added to them by default:

• `typewriter-keystroke-hook'

• `typewriter-carriage-return-hook'

Although no systematic test has been carried out, this package's
minimalism should ensure its compatibility with packages that change the
layout of text in the window, such as the fairly popular [olivetti], or
any configuration that (for instance) hides or alters element of the
emacs interface.


[olivetti] <https://github.com/rnkn/olivetti>
