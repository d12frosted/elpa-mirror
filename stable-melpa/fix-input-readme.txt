Let's suppose you have switched to an alternative keyboard layout.
Chances are you're going to use that layout everywhere, not only in
Emacs, so you set it up on the OS level or maybe you even get a special
keyboard that uses that layout.  Now suppose that you need to use an
input method in Emacs.  The nightmare begins: the input methods in Emacs
translate Latin characters assuming the traditional QWERTY layout.  With
an alternative keyboard layout, the input methods do not work anymore.

One solution is to define a new custom input method and call it for
example `dvorak-russian'.  But that is not a general solution to the
problem—we want to be able to make any existing input method work with
any Latin layout on the OS level.  This package generates input methods
knowing the input method that corresponds to the layout on the OS level
and the input method you want to fix.
