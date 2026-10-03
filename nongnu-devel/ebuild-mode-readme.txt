                             ━━━━━━━━━━━━━
                              EBUILD-MODE
                             ━━━━━━━━━━━━━


Major modes for editing ebuilds and other Gentoo specific files.

This collection of modes will help the user to efficiently write and
edit ebuilds, eclasses and other files that are specific to Gentoo, a
meta-distribution with various targets (GNU/Linux distribution, prefixed
environments in other operating systems, and integration of other
kernels and userlands like the BSDs or the GNU Hurd).

Ebuilds describe the build process and dependencies of a software
package to compile and install it automatically under the control of a
package manager.  They are simple text files based on Bash scripts.
Eclasses are comparable to libraries providing generic functions that
ebuilds can use by sourcing the eclass on request.

This package provides:

• `ebuild-mode' and `ebuild-eclass-mode': major modes to edit the above
  two file types, with font-lock syntax highlighting, completion of
  package manager and eclass function names, KEYWORDS manipulation,
  creation of new ebuilds from a skeleton, and interfaces to Portage,
  pkgdev and pkgcheck.
• `ebuild-repo-mode': minor mode for files in an ebuild repository; sets
  up some editing conventions like `tab-width', fixes whitespace and
  updates copyright years on save.
• `devbook-mode': editing the Gentoo Devmanual (DevBook XML).
• `gentoo-newsitem-mode': editing GLEP 42 news items.
• `glep-mode': editing Gentoo Linux Enhancement Proposals (GLEPs).


1 Requirements
══════════════

  GNU Emacs 26.3 or later, or XEmacs 21.5.35 or later.  `devbook-mode'
  and `glep-mode' work with GNU Emacs only.


1.1 Optional dependencies
─────────────────────────

  • [nxml-gentoo-schemas]: schema-based syntax validation in
    `nxml-mode'.
  • [tty-format]: color display of log files containing ANSI SGR control
    sequences.


[nxml-gentoo-schemas]
<https://packages.gentoo.org/packages/app-emacs/nxml-gentoo-schemas>

[tty-format] <https://user42.tuxfamily.org/tty-format/>


2 Installation
══════════════

2.1 Gentoo
──────────

  The package is available as `app-emacs/ebuild-mode' (GNU Emacs) and
  `app-xemacs/ebuild-mode' (XEmacs).


2.2 NonGNU ELPA
───────────────

  The package can be installed with `package.el':

  ┌────
  │ M-x package-install RET ebuild-mode RET
  └────


  On Emacs 26 and 27, `nongnu' must be added to `package-archives'
  first.


3 Documentation
═══════════════

  See the Info manual (`C-h i m ebuild-mode RET') for the full
  documentation.


4 Resources
═══════════

  • Source code (web): <https://gitweb.gentoo.org/proj/ebuild-mode.git/>
  • Git clone: <https://anongit.gentoo.org/git/proj/ebuild-mode.git>
  • Bug tracker: <https://bugs.gentoo.org/>


5 License
═════════

  GNU General Public License, version 2 or any later version.
