
Remember that you need to patch surf for history and incremental search to work!
See https://github.com/ecraven/exwm-surf/blob/master/exwm-surf.diff

Set your history and bookmark file:

(setq exwm-surf-history-file "/home/me/.surf/history")
(setq exwm-surf-bookmark-file "/home/me/.surf/bookmarks")

Get exwm to run `exwm-surf-init' to create the proper key bindings.

(add-hook 'exwm-manage-finish-hook 'exwm-surf-init))

You can customize `exwm-surf-key-bindings' to modify them to your liking.
The defaults are:
- C-s / C-r  Incremental search
- C-o        Open a new URL
- C-M-o      Edit the current URL
- M-b        Go to a bookmark
- C-M-b      Add a bookmark
- C-w        Copy the current URL to the kill ring
- C-y        Send Surf to the URL at the front of the kill ring
- M-f        Open the current URL in the default browser (See `browse-url')

The search recognizes prefixes (g for duckduckgo, go for google, df for dwarf fortress, ...).
See `exwm-search-prefixes-alist'.
