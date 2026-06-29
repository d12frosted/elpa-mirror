Eglot ("Emacs Polyglot") is an Emacs LSP client that stays out of
your way.

Typing M-x eglot in some source file is often enough to get you
started, if the language server you're looking to use is installed
in your system.  Please refer to the manual, available from
https://joaotavora.github.io/eglot/ or from M-x info for more usage
instructions.

If you wish to contribute changes to Eglot, please do read the user
manual first.  Additionally, take the following in consideration:

* Eglot's main job is to hook up the information that language
  servers offer via LSP to Emacs's UI facilities: Xref for
  definition-chasing, Flymake for diagnostics, Eldoc for at-point
  documentation, etc.  Eglot's job is generally *not* to provide
  such a UI itself, though a small number of simple
  counter-examples do exist, e.g. in the `eglot-rename' command or
  the `eglot-inlay-hints-mode' minor mode.  When a new UI is
  evidently needed, consider adding a new package to Emacs, or
  extending an existing one.

* Eglot was designed to function with just the UI facilities found
  in the latest Emacs core, as long as those facilities are also
  available as GNU ELPA :core packages.  Historically, a number of
  :core packages were added or reworked in Emacs to make this
  possible.  This principle should be upheld when adding new LSP
  features or tweaking existing ones.  Design any new facilities in
  a way that they could work in the absence of LSP or using some
  different protocol, then make sure Eglot can link up LSP
  information to it.

* There are few Eglot configuration variables.  This principle
  should also be upheld.  If Eglot had these variables, it could be
  duplicating configuration found elsewhere, bloating itself up,
  and making it generally hard to integrate with the ever growing
  set of LSP features and Emacs packages.  For instance, this is
  why one finds a single variable
  `eglot-ignored-server-capabilities' instead of a number of
  capability-specific flags, or why customizing the display of
  LSP-provided documentation is done via ElDoc's variables, not
  Eglot's.

* Linking up LSP information to other libraries is generally done
  in the `eglot--managed-mode' minor mode function, by
  buffer-locally setting the other library's variables to
  Eglot-specific versions.  When deciding what to set the variable
  to, the general idea is to choose a good default for beginners
  that doesn't clash with Emacs's defaults.  The settings are only
  in place during Eglot's LSP-enriched tenure over a project.  Even
  so, some of those decisions will invariably aggravate a minority
  of Emacs power users, but these users can use `eglot-stay-out-of'
  and `eglot-managed-mode-hook' to adjust things to their
  preferences.

* On occasion, to enable new features, Eglot can have soft
  dependencies on popular libraries that are not in Emacs core.
  "Soft" means that the dependency doesn't impair any other use of
  Eglot beyond that feature.  Such is the case of the snippet
  functionality, via the Yasnippet package, Markdown formatting of
  at-point documentation via the markdown-mode package, and nicer
  looking completions when the Company package is used.