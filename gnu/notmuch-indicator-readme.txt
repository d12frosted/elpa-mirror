# notmuch-indicator for Emacs

+ Package name (GNU ELPA): `notmuch-indicator`
+ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/notmuch-indicator>
  - Mirrors:
    + GitHub: <https://github.com/protesilaos/notmuch-indicator>
    + GitLab: <https://gitlab.com/protesilaos/notmuch-indicator>
+ Mailing list: <https://lists.sr.ht/~protesilaos/notmuch-indicator>
+ Backronym: notmuch-... Increasingly in Need of Displaying
  Inconsequential Counters Alongside Trivia that Obscure Reality.

* * *

This is a simple package that renders an indicator with an email count
of the `notmuch` index on the Emacs mode line.  The underlying mechanism
is that of `notmuch-count(1)`, which is used to find the number of items
that match the given search terms.

The indicator is enabled when `notmuch-indicator-mode` is on.

The user option `notmuch-indicator-args` provides the means to define
search terms and associate them with a given label.  The label is purely
cosmetic, though it helps characterise the resulting counter.

The value of `notmuch-indicator-args` is a list of plists (property
lists).  Each plist consists of one mandatory property and two optional
ones:

1. The `:terms`, which is required, is a string that holds the
   command-line arguments passed to `notmuch-count(1)` (read the Notmuch
   documentation for the technicalities).

2. The `:label`, which is optional, is an arbitrary string that is
   prepended to the return value of the above.  If nil or omitted, no
   label is displayed.

3. The `face`, which is optional, is the symbol of a face that is
   applied to the `:label`.  It should not be quoted, so like `:face
   bold`.  Good candidates are `bold`, `italic`, `success`, `warning`,
   `error`, though anything will do.  If nil or omitted, no face is
   used.

Multiple plist lists represent separate `notmuch-count(1)` queries.
These are run sequentially.  Their return values are joined into a
single string.

For instance, a value like the following defines three searches:

```elisp
(setq notmuch-indicator-args
      '((:terms "tag:unread and tag:inbox" :label "@")
        (:terms "from:bank and tag:bills" :label "😱")
        (:terms "--output threads tag:loveletter" :label "💕")))
```

These form a string which realistically is like: `@50 😱1000 💕0`.
Each component is clickable: it runs `notmuch-search` on the
applicable `:terms`.

The user option `notmuch-indicator-refresh-count` determines how often
the indicator will be refreshed.  It accepts a numeric argument which
represents seconds.

The user option `notmuch-indicator-force-refresh-commands` accepts as
its value a list of symbols.  Those are commands that will forcefully
update the indicator after they are invoked.

The user option `notmuch-indicator-hide-empty-counters` hides zero
counters from the indicator, when it is set to a non-nil value.

## Acknowledgements

The `notmuch-indicator` is meant to be a collective effort.  Every bit
of help matters.

+ Author/maintainer :: Protesilaos Stavrou.

+ Contributions to code or user feedback :: Henrik Kjerringvåg, Stefan
  Monnier, Yusef Aslam.
