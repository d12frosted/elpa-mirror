`anzu.el' is an Emacs port of `anzu.vim'.

`anzu.el' provides a minor mode which displays the match count for
various search commands in the mode-line, using the format
`current/total'.  This makes it easy to know how many matches your
search query has in the current buffer.

To use this package, add following code to your init.el or .emacs

  (global-anzu-mode +1)
