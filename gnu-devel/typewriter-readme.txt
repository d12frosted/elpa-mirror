            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             TYPEWRITER-MODE: TURN EMACS INTO A TEXT ADDER
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[https://elpa.gnu.org/packages/typewriter.svg]

This package provides `typewriter-mode', a small minor mode that
deliberately handicaps Emacs to an extreme degree in order to provide
something as close as possible to the strict forward-only typewriter
experience.  Some find that the lack of editing facilities fosters a
state of concentration and focus that makes certain types of creative
writing more satisfying.

The package has several configuration options:

• `typewriter-preserve-undo-history': If non-nil, you'll be able to undo
  edits if you turn `typewriter-mode'.  Default is `t'.

• `typewriter-recenter': If non-nil, the line where cursor is at is
  recentered (the command `recenter' is called) after every licit
  keystroke.  Default is `t'.

• `typewriter-fill-column': If `nil', your lines will be as long as you
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

• `typewriter-mode-line-format': Format string for the modeline
  indicator of remaining characters.  Default is `" [%d]"'.

• `typewriter-tab-width': Self explanatory.  Default is `8'.

• `typewriter-strikethrough-char': The character used to cross out text
  (see below).  Default is `?X'; `nil' disables strikethrough.

There are four hooks available for the user to customize the typing
experience, no function is added to them by default.  They run *after*
successful completion of the corresponding action:

• `typewriter-insert-hook'

• `typewriter-carriage-return-hook'

• `typewriter-backward-char-hook'

• `typewriter-tab-hook'

Characters can also be struck with an input method (`C-\'), with `C-x 8'
key sequences, or with `insert-char' (`C-x 8 RET'): the same rules about
margins and overstriking apply.

You can't erase on a typewriter, but you can type something like `X' or
`-' over what you've written to cross it out.  `C-c -'
(`typewriter-strikethrough') strikes `typewriter-strikethrough-char'
(`X' by default) at the carriage, even over existing text.  Each strike
advances the carriage by one, so a numeric prefix crosses out several
characters: move back with `DEL' to the start of a word and press `C-u 5
C-c -' to cross out five characters.

This only works on the last line, the one the carriage is on: once
you've returned the carriage, the lines above can't be touched.  The
margin applies as usual.

Although no systematic test has been carried out, this package's
minimalism should ensure its compatibility with packages that change the
layout of text in the window, such as the fairly popular [olivetti], or
any configuration that (for instance) hides or alters elements of the
Emacs interface.

The package is on [GNU ELPA], and you can install it in the usual ways,
for instance:

┌────
│ (use-package typewriter
│   :ensure t)
└────


[https://elpa.gnu.org/packages/typewriter.svg]
<https://elpa.gnu.org/packages/typewriter.html>

[olivetti] <https://github.com/rnkn/olivetti>

[GNU ELPA] <https://elpa.gnu.org/packages/typewriter.html>
