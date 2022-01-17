This is a small wrapper around the deps.new tool for creating deps.edn
Clojure projects from templates.

It provides access to the  built in deps.new templates via `clj-deps-new'.
The command will display a series of on-screen prompts to allow the user to
interactively select arguments, preview their output, and build projects.

You can also create transient prefixes and suffixes to access your own custom
templates. (see https://github.com/jpe90/emacs-deps-new#extending)

It requires external utilities 'tools.build' and 'deps.new' to be installed.
See https://github.com/seancorfield/deps-new for installation instructions.

Requires transient.el to be loaded.
