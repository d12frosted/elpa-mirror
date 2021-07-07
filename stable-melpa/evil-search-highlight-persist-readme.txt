
This extension will make isearch and evil-ex-search-incremental to
highlight the search term (taken as a regexp) in all the buffer and
persistently until you make another search or clear the highlights
with the evil-search-highlight-persist-remove-all command (default
binding to C-x SPC). This is how Vim search works by default when
you enable hlsearch.

To enable:

(require 'evil-search-highlight-persist)
(global-evil-search-highlight-persist t)

To only display string whose length is greater than or equal to 3
(setq evil-search-highlight-string-min-len 3)
