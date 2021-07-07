Let's suppose that you have switched to Dvorak or Colemak.  Chances are
you're going to use that layout everywhere, not only in Emacs (we still
need to leave Emacs sometimes and use other programs), so you setup it on
OS level or maybe you even have hardware Dvorak keyboard.  You adapt to
this new layout and everything is OK.

Now suppose that you need to input non-Latin text and for that you
naturally need to activate an input method in Emacs.  The nightmare
begins: input methods in Emacs translate Latin characters as if they are
on a traditional QWERTY layout.  So now the input method you used before
does not work anymore.

One solution is to define a new custom input method and call it for
example `dvorak-russian'.  But that is not a general solution to the
problem—we want to be able to make any existing input method work just
the same with any Latin layout on OS level.  This package generates
“fixed” input methods knowing input method that corresponds to layout on
OS level and input method you want to fix.  And I want to tell you—it's a
win.
