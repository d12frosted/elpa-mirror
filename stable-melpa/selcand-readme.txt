Like vimium, selcand-select enumerates a potentially large list
of candidates using very short hints that the user may type to
make a selection.
It is intended to be used from emacs lisp code to prompt the user
to select from a list of choices.
Sample usage: (load-theme (selcand-select (custom-available-themes)))
