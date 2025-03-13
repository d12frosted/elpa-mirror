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

- Calendar (Elisp library: `casual-calendar')
  An interface for the built-in calendar and diary of Emacs.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/calendar.org'

- Dired (Elisp library: `casual-dired')
  An interface for the venerable file manager Dired.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/dired.org'

- EditKit (Elisp library: `casual-editkit')
  A cornucopia of interfaces for the different editing features (e.g.
  marking, copying, killing, duplicating, transforming, deleting) of Emacs.
  Included are interfaces for rectangle, register, macro, and project
  commands.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/editkit.org'

- Image (Elisp library: `casual-image')
  An interface for viewing an image file with `image-mode'.
  Resizing an image is supported if ImageMagick 6 or 7 is installed. This
  interface deviates significantly with naming conventions used by
  `image-mode' to be more in alignment with conventional image editing tools.
  URL `https://github.com/kickingvegas/casual/blob/main/docs/image.org'

- Info (Elisp library: `casual-info')
  An interface for the Info documentation system.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/info.org'

- I-Search (Elisp library: `casual-isearch')
  An interface for the many commands supported by I-Search.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/isearch.org'

- Make (Elisp library: `casual-make')
  An interface to `make-mode'.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/make-mode.org'

- Re-Builder (Elisp library: `casual-re-builder')
  An interface for the Emacs regular expression tool.
  URL: `https://github.com/kickingvegas/casual/blob/main/docs/re-builder.org'

Users can choose any or all of the user interfaces made available by Casual
at their pleasure.

UPGRADING to Casual 2.x

If you have been using an earlier version 1.x of Casual, thank you. Please
use the following guidance:

* If you do not use `use-package' to configure Casual

Before installing Casual, you should update all of your existing Casual
packages. This is most easily done via the package menu buffer described in
info node `(emacs) Package Menu'. After updating your packages, install the
`casual' package.

Migrate your existing Casual packages from 1.x to 2.x by running the
following commands:

M-x load-library casual
M-x casual-upgrade-base-to-version-2

Any Casual v1.x packages that have been superseded by this package will be
uninstalled.

While not necessary, it is recommended to run `package-autoremove' to purge
any dangling dependent packages. Cautious readers can choose to audit any
packages that are targeted to be removed.

* If you have used `use-package' to configure Casual

For version 2.x going forward, I (Charles Choi) have decided to not offer any
documented guidance on using `use-package' to configure Casual due my lack of
expertise in using it. I leave it to more skilled readers to determine how to
best use it (described in info node `(use-package) Top') for their
configuration. Please also note that this is not a prohibition on using
`use-package' with Casual. I am simply admitting that I don't know how to use
it.

That said, if you have used :ensure t to install a superseded package, you
must remove that configuration. After doing so, please follow the above
instructions for installing `casual'.

If you are using Emacs ≤ 30.0, you will need to update the built-in package
`transient'. By default, `package.el' will not upgrade a built-in package.
Set the customizable variable `package-install-upgrade-built-in' to `t' to
override this. For more details, please refer to the "Install" section on
this project's repository web page.
