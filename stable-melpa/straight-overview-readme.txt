
straight-overview is an add-on for the popular package manager
straight.el.  This package adds an overview buffer
(`M-x straight-overview') in the style of Dired, showing which
packages have new commits upstream.  It uses `tabulated-list-mode'
to present useful pieces of information like the installed commit
SHA1, the branch, how many commits and days each package is behind
its upstream branch, and the nearest tag when available.

It also synergizes with Magit and if the user presses `c', it uses
magit log to show an overview of the recently added commits, which
are not installed yet.  This is a quick way to see what a pull
would bring in.

straight-overview allows the user to pick and choose the packages
they want to update.  They can also pin a package at its installed
commit, so it cannot be marked for update.  straight-overview then
calls the original `straight-pull-package' for the packages that
were marked.

straight-overview fetches the upstream repositories asynchronously
and in parallel: these are external `git fetch' processes running
in the background at once; their number is capped by
`straight-overview-fetch-jobs', set by default to 16 jobs.  About
100 repositories take 3.5 s, and Emacs stays usable through the
whole time.  The original command in straight,
`straight-fetch-all', fetches one repository at a time, and Emacs
is not responsive until all packages have been fetched.

straight-overview also supports version floor control, meaning that
it skips a marked package, with a warning, when its dependencies
are missing or older than its `Package-Requires' asks for.  The
version floor checks follow the rules of `package.el' in core
Emacs.  The marked packages are then pulled respecting the order of
dependencies.  In contrast, straight reads `Package-Requires' but
keeps only the package names and drops the minimum versions
(`straight--process-dependencies').  Because it never checks a
dependency's version, it cannot ensure that the updated packages
remain consistent with each other, fulfilling their dependencies.

By default only packages that are behind are listed.  Opening the
list does not contact the remotes.  Instead, it reads the local git
refs, which are as recent as the last fetch through
`straight-overview-fetch'.  The local refs are also queried in
parallel to speed up the scan but with a synchronous (i.e.,
blocking) call.  On a laptop with 8 cores, about 100 packages are
scanned in 0.4s, which appears sufficiently fast for not requiring
an asynchronous architecture for scanning git's refs.

In the overview buffer (`straight-overview-mode'):

  G        fetch all remotes in parallel, in the background
  g        rescan the local refs (no fetch)
  m u U M  mark, unmark, unmark all, mark all outdated packages
  x        pull the marked packages, after checking their
           dependencies with package.el's rules
  X        force pulling the marked packages, also those whose
           dependencies are not met
  P F R    pin the package at its installed commit, free the pin,
           reset the package to its pinned commit
  c        show the new commits that a pull would bring in
  o RET    open the package's repository in a browser
  a        toggle between showing all packages or only the
           outdated ones

`M-x customize-group RET straight-overview' lists the options.

straight.el is not on MELPA but it is shipped with its own
bootstrap Elisp code, sourcing it directly from
https://github.com/radian-software/straight.el.  Because
straight.el is not on MELPA, it is not listed in
`Package-Requires', but it is naturally a key dependency of
straight-overview.  When straight-overview is started, it loads
`straight.el' if it is not loaded yet, or it signals an error if it
cannot be found.
