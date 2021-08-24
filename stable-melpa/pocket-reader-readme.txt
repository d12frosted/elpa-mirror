This is a client for Pocket (getpocket.com).  It allows you to
manage your reading list: add, remove, delete, tag, view, favorite,
etc.  Doing so in Emacs with the keyboard is fast and efficient.
Links can be opened in Emacs with any function, or in external
browsers, and specific sites/URLs can be opened with specific
browser functions.  Views can be sorted by date, title, domain,
tags, favorite, etc, and "limited" mutt-style.  Items can be
searched for using keywords, tags, favorite status, unread/archived
status, etc.

These keys can be used in the pocket-reader buffer:

"RET" pocket-reader-open-url
"TAB" pocket-reader-pop-to-url
"a" pocket-reader-toggle-archived
"b" pocket-reader-open-in-external-browser
"c" pocket-reader-copy-url
"d" pocket-reader (return to default view)
"D" pocket-reader-delete
"e" pocket-reader-excerpt
"E" pocket-reader-excerpt-all
"*" pocket-reader-toggle-favorite
"f" pocket-reader-toggle-favorite
"F" pocket-reader-show-unread-favorites
"g" pocket-reader-resort
"G" pocket-reader-refresh
"s" pocket-reader-search
"m" pocket-reader-toggle-mark
"M" pocket-reader-mark-all
"U" pocket-reader-unmark-all
"o" pocket-reader-more
"l" pocket-reader-limit
"R" pocket-reader-random-item
"ta" pocket-reader-add-tags
"tr" pocket-reader-remove-tags
"tt" pocket-reader-set-tags
"ts" pocket-reader-tag-search

In eww, Org, w3m, and some other major modes,
`pocket-reader-add-link' can be used to add a link at point to
Pocket.
