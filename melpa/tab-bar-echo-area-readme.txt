Provides a global minor mode to temporarily display a list of
available tabs and tab groups (with the current tab and group
highlighted) in the echo area after tab-related commands.

This is intended to be used as an unobtrusive replacement for the
Emacs built-in display of the tab bar (that is, when you have
`tab-bar-show' set to nil).

The idea is to provide but a quick visual orientation aid to the
user after tab-related commands, and then get out of the way again.

I recommend using this together with the 'tab-bar-lost-commands'
package, which provides simple and convenient commands that help
with common tab bar use-cases regarding the creation, selection and
movement of tabs.

You might also want to check out the 'tab-bar-groups' package, which
backports a simplified version of Emacs 28 tab groups to Emacs 27 and
provides an integration with this package.
