
Add a Bookmarks menu to the menu bar.

Installation:

Add either `(buffers-menu-mode t)', to enable the minor mode, or
`(buffers-menu-add-menu)' to your init file.

Customization:

*Menu Title*

You can change the title of the menu to reduce the amount of space
the menu occupies in the menu bar.  Not surprisingly the default is
"Bookmarks".

*Menu Placement*

The menu can be placed after any standard menu you choose.

*Jump Target*

This controls where bookmarks will appear when selected from the
menu.  The choices are `self', `window', and `frame'.  These
correspond with the bookmark commands `boookmark-jump',
`bookmark-jump-other-window', and `bookmark-jump-other-frame'.

*Item Length*

By default bookmarks are trimmed to 18 characters in the menu.

Commands:

There are only three commands: `bookmarks-menu-add-menu',
`bookmarks-menu-remove-menu', and `bookmarks-menu-mode'.  Enabling
and disabling the minor menu is equivalent to calling the add and
remove menu functions.
