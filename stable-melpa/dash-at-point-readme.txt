
Dash ( http://kapeli.com/ ) is an API Documentation Browser and
Code Snippet Manager.  dash-at-point make it easy to search the word
at point with Dash.

Add the following to your .emacs:

  (add-to-list 'load-path "/path/to/dash-at-point")
  (autoload 'dash-at-point "dash-at-point"
            "Search the word at point with Dash." t nil)
  (global-set-key "\C-cd" 'dash-at-point)

Run `dash-at-point' to search the word at point, then Dash is
launched and search the word. To edit the search term first,
use C-u to set the prefix argument for `dash-at-point'.

Dash queries can be narrowed down with a docset prefix.  You can
customize the relations between docsets and major modes.

  (add-to-list 'dash-at-point-mode-alist '(perl-mode . "perl"))

Additionally, the buffer-local variable `dash-at-point-docset' can
be set in a specific mode hook (or file/directory local variables)
to programmatically override the guessed docset.  For example:

  (add-hook 'rinari-minor-mode-hook
            (lambda () (setq dash-at-point-docset "rails")))
