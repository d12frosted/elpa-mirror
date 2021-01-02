
Keep handy notes of your read Gnus articles with helm and org.

This file provides the core setup and data needs of gnus-notes.

Keep notes on the gnus articles that are important to me. The
rest can simply be removed from gnus-notes, without affecting Gnus.
If an article is removed from gnus-notes, by accident or I want it
back for whatever reason, no problem. All I have to do is view the
article in gnus, and it is back on gnus-notes.

Gnus notes works in the background silently, keeping track of the
articles read with gnus. When an article is read, it adds a quick
note of it to notes. Simply, that's all. It removes notes of
deleted articles or the ones expunged by gnus.

Gnus-notes is similar to the Gnus registry, but whereas the
registry tries to catch everything, gnus-notes is light-weight.
It doesn't try to keep everything. Only the articles "I have"
read. Its job is much simpler. "My read" articles are the only
really important "to me" articles, isn't is so ?

This simplicity allows the user to add and remove articles to
gnus-notes, stress free.

Viewing gnus-notes with the powerful helm interface brings great
search capabilities and all the other helm goodness.
Gnus-notes has been built around helm.

Additional integration provided, or planned, with:
- org-mode, built-in
- BBDB built-in with gnus (gnus-insinuate 'bbdb 'message)
- EBDB (todo)

Gnus is not limited to email, that is why gnus uses the term "articles".
Gnus-notes follows the Gnus general philosophy, it also uses the term
"articles". Most testing has been done on email (and IMAP in particular) and RSS.

This package is a fork of gnus-recent with additional inspiration by gnorb.
