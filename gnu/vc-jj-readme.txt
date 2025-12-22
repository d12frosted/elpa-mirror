1 jj (Jujutsu) integration with Emacs vc.el and project.el
══════════════════════════════════════════════════════════

  Support for Emacs built-in [`vc.el'] and [`project.el'] for the
  [Jujutsu] version control system.

  <file:screenshots/screenshot-1.png>


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


1.2 Usage
─────────

  Vc-jj supports Emacs 28 and later. Most but not all of the VC and
  VC-related commands (vc.el, log-edit, log-view, and project.el) are
  currently supported.  Supported commands include:
  ⁃ `project-vc-dir'
  ⁃ `vc-print-root-log'
  ⁃ `vc-print-log'
  ⁃ `vc-next-action'
  ⁃ `vc-diff'
  ⁃ `vc-root-diff'
  ⁃ `vc-rename-file'
  ⁃ `vc-delete-file'
  ⁃ `vc-revision-other-window'
  ⁃ `vc-clone'
  ⁃ `vc-annotate'
  ⁃ `log-view-modify-change-comment'

  Additionally, vc-jj aims to provide jujutsu-specific conveniences and
  commands.  For example, in Log View buffers, there are commands to
  help users manipulate revision logs in a jujutsu-friendly way,
  directly within Log View buffers: `vc-jj-log-view-bookmark-set',
  `vc-jj-log-view-abandon-change', `vc-jj-log-view-edit-change' and
  more.

  To see all available commands call `C-h a vc-jj RET'.  To see all
  available customization options, call `M-x customize-group vc-jj RET'.


1.3 Jujutsu configuration
─────────────────────────

  Emacs has built-in support for git-style diff and conflict markers, so
  you might want to set the following options in your Jujutsu
  configuration, for example via `jj config edit --user' or `jj config
  edit --repo':

  ┌────
  │ [ui]
  │ diff-formatter = ":git"
  │ conflict-marker-style = "git"
  └────

  Jujutsu offers many configuration options.  Vc-jj has not thoroughly
  tested its compatibility with these options, but it is expected that
  vc-jj work well even if the user configures many of them.


2 Jujutsu and Git
═════════════════

  Jujutsu is a distributed version control system that is separated from
  the format in which files are stored on-disk.  Currently, the only
  storage backend jujutsu supports is Git, although other storage
  backends may be supported in the future.

  Since version 0.34.0, jujutsu repositories are "colocated" by default.
  Earlier versions of jujutsu may colocate a Git repository with `jj git
  clone --colocate REPOSITORY-URL'.  Colocated repositories are ones
  that contain both a `.jj' and a `.git' directory in the repository
  root, allowing users to use both Jujutsu and Git commands in the same
  repository, without one getting in the way of the other.  (Although
  Git will complain about being in "detached HEAD" state.)  Because of
  this colocation, vc-jj can reuse some vc-git functionality where
  appropriate, such as handling `.gitignore' files.


2.1 Jujutsu terminology and concepts
────────────────────────────────────

  To those used to other version control systems, like Git, jujutsu's
  version control model may be unfamiliar.

  Below is an attempt at a brief description of jujutsu-specific
  terminology and concepts.

  In Jujutsu, there are both "commits" and "changes."  In Git, the
  primary unit of history is the commit, which is immutable and
  identified by a commit hash.  In jujutsu, the primary unit is the
  change.  A jujutsu "*commit*" is the same as in Git: a snapshot in
  time of the repository.  In Jujutsu, "*revision*" can be used
  interchangeably with "commit."  A *"change"*, on the other hand, is
  unique to jujutsu: it can be thought of as a /logical unit of work/.
  A change is like the entire evolution of a commit as it changes over
  time.  Each change has an underlying commit.

  As the user modifies the repository, all changes are automatically
  recorded and all non-ignored files are automatically tracked.
  Consequently, unlike Git, there is no straging area or check-in
  operation.  Instead, all modifications occur in the current change —
  the "*working copy*."  As files are edited, added, and deleted,
  jujutsu will take *snapshots* of the repository and automatically
  *rewrite* the underlying commit of the working copy, keeping the
  change intact but changing the corresponding underlying commit.

  Every change has a corresponding change ID and every commit has a
  corresponding commit ID.  Most jj commands accept both change IDs and
  commit IDs.

  Because of the conceptual differences between Git and Jujutsu,
  commands that assume a stage/commit workflow behave differently or are
  no-ops when used via vc-jj.

  In Git, `git log' shows a log of commits.  In Jujutsu, `jj log' shows
  a log of changes.  History rewriting is a normal part of jj’s
  workflow.  Changes may be edited, split, or reordered while preserving
  their identity via the change ID.  Users will find that it is much
  more natural to make changes in a repository by rewriting, playing
  with, and modifying the change log.

  Finally, in Jujutsu, there are *bookmarks*.  Although each git
  *branch* corresponds to a Jujutsu bookmark and vice versa, a bookmark
  is merely an alias or named pointer to a commit.  (Bookmarks
  automatically follow a commit if it gets rewritten.)  The working copy
  (current change) may be on a bookmark's commit, but it is not
  "attached" to it in the way a commit in Git corresponds to a certain
  branch: bookmarks do not move when new changes are made atop them.
  Users familiar with Mercurial will find that Jujutsu bookmarks are
  more similar to [Mercurial bookmarks] than Git branches.

  Users may read more about the concepts and terms used in jujutsu here:
  <https://docs.jj-vcs.dev/latest/>.  In particular, a glossary of all
  jujutsu-specific terms can be found here:
  <https://docs.jj-vcs.dev/latest/glossary/>.


[Mercurial bookmarks] <https://wiki.mercurial-scm.org/Bookmarks>


3 Contributing
══════════════

  We welcome bug reports and pull requests!  `vc-jj.el' tries its best
  to support Emacs 28.1 and above, but users may notice bugs related to
  Emacs version incompatibilities.  In such cases, please consider
  submitting a bug report—we will try our best to address it.

  Since `vc-jj.el' is distributed via GNU elpa, non-trivial code
  contributions need to have the standard FSF copyright assignment in
  place; feel free to contact us for details.  Note that "trivial"
  (below 15 lines or obvious) code suggestions in bug reports are fine.


3.1 Development
───────────────

  The code in file `vc-jj.el' is organized according to the structure
  set out in the preamble of the file `vc.el' in the Emacs source tree.

  Test code coverage can be checked via the [Eldev] tool and [coverage]:
  in a shell, run `eldev test --undercover simplecov,dontsend' in the
  project root directory, then in Emacs open `vc-jj.el' and activate
  `coverage-mode'.


[Eldev] <https://emacs-eldev.github.io/eldev/>

[coverage] <https://github.com/trezona-lecomte/coverage>


4 Other Emacs packages for Jujutsu
══════════════════════════════════

  The scope of the `vc-jj.el' project is to add jj support to the Emacs
  built-in `vc' and `project' libraries.  In case you look for a package
  with more specialized jujutsu support, here are some that might fit
  the bill:

  [bolivier/jj-mode.el]
        “Jujutsu version control mode for Emacs inspired by Magit”
  [bennyandresen/jujutsu.el]
        “An Emacs interface for jujutsu, inspired by magit and humbly
        not attempting to match it in scope.”
  [~puercopop/jujutsushi]
        “A emacs interface to jujutsu”


[bolivier/jj-mode.el] <https://github.com/bolivier/jj-mode.el>

[bennyandresen/jujutsu.el] <https://github.com/bennyandresen/jujutsu.el>

[~puercopop/jujutsushi] <https://git.sr.ht/~puercopop/jujutsushi>
