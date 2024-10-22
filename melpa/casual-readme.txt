Casual is a collection of opinionated Transient-based keyboard driven user
interfaces for various built-in modes.

INSTALLATION

Casual is organized into different user interface (UI) libraries tuned for
different modes. Different user interfaces for the following modes are
supported:

- Agenda (Elisp library: `casual-agenda')
  An interface for Org Agenda to help you plan your day.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/agenda.org'

- Bookmarks (Elisp library: `casual-bookmarks')
  An interface for editing your bookmark collection.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/bookmarks.org'

- Calc (Elisp library: `casual-calc')
  An interface for Emacs Calc, an embarrasingly feature-rich calculator.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/calc.org'

- Dired (Elisp library: `casual-dired')
  An interface for the venerable file manager Dired.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/dired.org'

- EditKit (Elisp library: `casual-editkit')
  A cornucopia of interfaces for the different editing features (e.g.
  marking, copying, killing, duplicating, transforming, deleting) of Emacs.
  Included are interfaces for rectangle, register, macro, and project
  commands.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/editkit.org'

- Info (Elisp library: `casual-info')
  An interface for the Info documentation system.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/info.org'

- I-Search (Elisp library: `casual-isearch')
  An interface for the many commands supported by I-Search.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/isearch.org'

- Re-Builder (Elisp library: `casual-re-builder')
  An interface for the Emacs regular expression tool.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/re-builder.org'

Users can choose any or all of the user interfaces made available by Casual
at their pleasure.

UPGRADING to Casual 2.x

If you have installed any Casual package that is version 1.x, you should
immediately run the following commands upon installation of casual.

M-x load-libary casual
M-x casual-upgrade-base-to-version-2

This command will uninstall any Casual v1.x packages that have been
superseded by this package.

If you are using Emacs ≤ 30.0, you will need to update the built-in package
`transient'. By default, `package.el' will not upgrade a built-in package.
Set the customizable variable `package-install-upgrade-built-in' to `t' to
override this. For more details, please refer to the "Install" section on
this project's repository web page.
