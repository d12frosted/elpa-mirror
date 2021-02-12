`mu4e-query-fragments' allows to define query snippets ("fragments")
that can be used in regular `mu4e' searches or bookmarks. Fragments
can be used to define complex filters to apply in existing searches,
or supplant bookmarks entirely. Fragments compose properly with
regular mu4e/xapian operators, and can be arbitrarily nested.

`mu4e-query-fragments' can also append a default filter to new
queries, using `mu4e-query-fragments-append'. Default filters are
very often useful to exclude junk messages from regular queries.

To use `mu4e-query-fragments', use the following:

(require 'mu4e-query-fragments)
(setq mu4e-query-fragments-list
  '(("%junk" . "maildir:/Junk OR subject:SPAM")
    ("%hidden" . "flag:trashed OR %junk")))
(setq mu4e-query-fragments-append "NOT %hidden")

The terms %junk and %hidden can subsequently be used anywhere in
mu4e. See the documentation of `mu4e-query-fragments-list' for more
details.

Fragments are *not* shown expanded in order to keep the modeline
short. To test an expansion, use `mu4e-query-fragments-expand'.
