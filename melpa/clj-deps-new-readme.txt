This is a small wrapper around the deps-new and clj-new tools for creating
Clojure projects from templates.

It provides access to built-in and some additional commmunity deps-new and
clj-new templates via `clj-deps-new'.  The command displays a series of
on-screen prompts allowing the user to interactively select arguments,
preview their output, and create projects.

You can also create transient prefixes and suffixes to access your own custom
templates.  (see https://github.com/jpe90/emacs-deps-new#extending)

It requires external utilities 'tools.build', 'deps-new', and 'clj-new' to be
installed.  See https://github.com/seancorfield/deps-new for installation
instructions.

This code assumes you installed 'clj-new' and 'deps-new' as tools using
the names 'clj-new' and 'new', respectively, as recommended in the
documentation for those tools.  If you used different names or are
specifying aliases in your deps.edn, be sure to customize the variables
`clj-deps-new-clj-new-alias' and `clj-deps-new-deps-new-alias' to
match your setup.

Requires transient.el to be loaded.
