Provides a global minor mode to temporarily display a list of
available tab names (with the current tab's name highlighted) in the
echo area after tab-related commands.

The list of tab names shows after creating, closing, switching to,
and renaming a tab, and remains visible until the next command is
issued.

This is intended to be used as an unobtrusive replacement for the
Emacs built-in display of the tab-bar (that is, when you have
`tab-bar-show' set to nil).

The idea is to provide but a quick visual orientation aid to the user
after tab-related commands, and then get out of the way again.

I recommend using this in combination with the tab-bar-lost-commands
package, which provides simple and convenient commands that help with
common tab bar use-cases regarding the creation, selection and
movement of tabs.
