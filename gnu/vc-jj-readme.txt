1 jj (Jujutsu) integration with Emacs vc.el and project.el
══════════════════════════════════════════════════════════

  Support for Emacs built-in [`vc.el'] and [`project.el'] for the
  [Jujutsu] version control system.


[`vc.el']
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Version-Control.html>

[`project.el']
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Projects.html>

[Jujutsu] <https://github.com/jj-vcs/jj>

1.1 Installation
────────────────

  This package is distributed via GNU Elpa
  (<https://elpa.gnu.org/packages/vc-jj.html>) and can be installed via
  `M-x package-install'.


1.2 Jujutsu configuration
─────────────────────────

  Emacs has built-in support for git-style diff and conflict markers, so
  you might want to set the following options in your Jujutsu
  configuration, for example via `jj config edit --user' or `jj config
  edit --repo':

  ┌────
  │ [ui]
  │ ui.diff-formatter = ":git"
  │ conflict-marker-style = "git"
  └────


1.3 Contributing
────────────────

  We welcome bug reports and pull requests!  Since `vc-jj.el' is
  distributed via GNU elpa, non-trivial code contributions need to have
  the standard FSF copyright assignment in place; feel free to contact
  us for details.  Note that "trivial" (below 15 lines or obvious) code
  suggestions in bug reports are fine.
