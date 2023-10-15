## notmuch-indicator for GNU Emacs

This is a simple package that renders an indicator with an email count
of the `notmuch` index on the Emacs mode line.  The underlying mechanism
is that of `notmuch-count(1)`, which is used to find the number of items
that match the given search terms.  In practice, the user can define one
or more searches and display their counters.  These form a string which
realistically is like: `@50 😱1000 💕0` for unread messages, bills, and
love letters, respectively.

+ Package name (GNU ELPA): `notmuch-indicator`
+ Official manual: <https://protesilaos.com/emacs/notmuch-indicator>
+ Change log: <https://protesilaos.com/emacs/notmuch-indicator-changelog>
+ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/notmuch-indicator>
  - Mirrors:
    + GitHub: <https://github.com/protesilaos/notmuch-indicator>
    + GitLab: <https://gitlab.com/protesilaos/notmuch-indicator>
+ Mailing list: <https://lists.sr.ht/~protesilaos/general-issues>
+ Backronym: notmuch-... Interested in Notmuch Data Indicators that
  Count Any Terms Ordinarily Requested.
