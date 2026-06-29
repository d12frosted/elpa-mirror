1 Disproject
════════════

  Disproject is a [GNU Emacs] package that implements [Transient] menus
  for managing and interacting with project files.  It aims to provide a
  featureful, yet extensible interface from which users can intuitively
  dispatch commands on projects.

  Some of its notable features include:
  • a main menu with access to many of the built-in project library's
    commands and other project-aware commands;
  • auto-detection of current project as the default project to act on
    from the menu;
  • options for switching to other projects from the menu in order to
    execute commands elsewhere;
  • a menu for finding common "special" project files, like the
    dir-locals file;
  • a menu for custom project-local suffix commands;
  • and display-buffer override options, to control where commands
    should display buffers to.


  An Info manual is included with this program under the name
  `disproject', which can also be viewed in the Org format at
  <file:doc/disproject.org>.

  This package was inspired by the `project-switch-project' command,
  from the built-in project library.  Users may also draw similarities
  to the Projectile library's `projectile-commander'.

  <file:images/disproject-dispatch.png>

  See [images] for more screenshots of Disproject menus.


[GNU Emacs] <https://www.gnu.org/software/emacs/>

[Transient] <https://github.com/magit/transient>

[images] <file:images/>

1.1 Installation
────────────────

  [file:https://melpa.org/packages/disproject-badge.svg]
  [file:https://stable.melpa.org/packages/disproject-badge.svg]
  [file:https://packages.guix.gnu.org/packages/emacs-disproject/badges/latest-version.svg]


[file:https://melpa.org/packages/disproject-badge.svg]
<https://melpa.org/#/disproject>

[file:https://stable.melpa.org/packages/disproject-badge.svg]
<https://stable.melpa.org/#/disproject>

[file:https://packages.guix.gnu.org/packages/emacs-disproject/badges/latest-version.svg]
<https://packages.guix.gnu.org/packages/emacs-disproject>

1.1.1 MELPA
╌╌╌╌╌╌╌╌╌╌╌

  Disproject is available in [MELPA] and [MELPA Stable].  See [Getting
  Started] instructions for using MELPA.


[MELPA] <https://melpa.org/#/disproject>

[MELPA Stable] <https://stable.melpa.org/#/disproject>

[Getting Started] <https://melpa.org/#/getting-started>


1.1.2 Guix
╌╌╌╌╌╌╌╌╌╌

  Disproject is also available as a [GNU Guix] package.

  The stable version can be found in the `(gnu packages emacs-xyz)'
  module under the name `emacs-disproject'.  It may be installed in the
  user profile like so:

  ┌────
  │ guix install emacs-disproject
  └────

  Alternatively, one may use the package definition in `./guix.scm' to
  install a development version of Disproject from the repository.  For
  example, to install in the user profile, run the following in this
  repository's root directory:

  ┌────
  │ guix package --install-from-file=guix.scm
  └────


[GNU Guix] <https://guix.gnu.org/>


1.2 Usage
─────────

  Disproject is usable out of the box.  After it is loaded, the only
  command that needs to be known is `disproject-dispatch', which opens a
  transient interface - referred to as the "main menu" - with access to
  a collection of commands that the user can choose from to execute on
  projects.

  The following configuration is a suggested minimal setup that can be
  added to the user's init file:

  ┌────
  │ (use-package disproject
  │   ;; Replace `project-prefix-map' with `disproject-dispatch'.
  │   :bind ( :map ctl-x-map
  │           ("p" . disproject-dispatch)))
  └────

  See [the manual] for more information on using and configuring
  Disproject.


[the manual] <file:doc/disproject.org>
