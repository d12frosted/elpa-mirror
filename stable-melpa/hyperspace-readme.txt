Hyperspace is a way to get nearly anywhere from wherever you are,
whether that's within Emacs or on the web.  It's somewhere in
between Quicksilver and keyword URLs, giving you a single,
consistent interface to get directly where you want to go.  It’s
for things that you use often, but not often enough to justify a
dedicated binding.

When you enter Hyperspace, it prompts you where to go:

HS:

This prompt expects a keyword and a query.  The keyword picks where
you want to go, and the remainder of the input is an optional
argument which can be used to further search or direct you within
that space.

Some concrete examples:

| *If you enter*   | *then Hyperspace*                                        |
|------------------+----------------------------------------------------------|
| "el"             | opens info node "(elisp)Top"                             |
| "el eval-region" | searches for "eval-region" in the elisp Info index       |
| "bb"             | shows all BBDB entries                                   |
| "bb kenneth"     | shows all BBDB entries with a name matching "kenneth"    |
| "ddg foo"        | searches DuckDuckGo for "foo" using browse-url           |
| "wp foo"         | searches Wikipedia for "foo" using browse-url            |
