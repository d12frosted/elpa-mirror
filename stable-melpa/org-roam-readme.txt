
Org-roam is a Roam Research inspired Emacs package and is an addition to
Org-mode to have a way to quickly process complex SQL-like queries over a
large set of plain text Org-mode files. To achieve this Org-roam provides a
database abstraction layer, the capabilities of which include, but are not
limited to:

- Link graph traversal and visualization.
- Instantaneous SQL-like queries on headlines
  - What are my TODOs, scheduled for X, or due by Y?
- Accessing the properties of a node, such as its tags, refs, TODO state or
  priority.

All of these functionality is powered by this layer. Hence, at its core
Org-roam's primary goal is to provide a resilient dual representation of
what's already available in plain text, while cached in a binary database,
that is cheap to maintain, easy to understand, and is as up-to-date as it
possibly can. For users who would like to perform arbitrary programmatic
queries on their Org files Org-roam also exposes an API to this database
abstraction layer.

-----------------------------------------------------------------------------

In order for the package to correctly work it's mandatory to add somewhere to
your configuration the next form:

    (org-roam-setup)

The form can be called both, before or after loading the package, which is up
to your preferences. If you call this before the package is loaded, then it
will automatically load the package.

-----------------------------------------------------------------------------

This package also comes with a set of officially supported extensions that
provide extra features. You can find them in the "extensions/" subdirectory.
These extensions are not automatically loaded with `org-roam`, but they still
will be lazy-loaded through their own `autoload's.

Org-roam also has other extensions that don't come together with this package.
Such extensions are distributed as their own packages, while also
authored and maintained by different people on distinct repositories. The
majority of them can be found at https://github.com/org-roam and MELPA.
