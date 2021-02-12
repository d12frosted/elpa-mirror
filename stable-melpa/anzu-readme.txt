`anzu.el' is an Emacs port of `anzu.vim'.

`anzu.el' provides a minor mode which displays 'current match/total
matches' in the mode-line in various search modes.  This makes it
easy to understand how many matches there are in the current buffer
for your search query.

To use this package, add following code to your init.el or .emacs

  (global-anzu-mode +1)
