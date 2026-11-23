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

  Additionally, vc-jj aims to provide Jujutsu-specific conveniences and
  commands.  For example, in Log View buffers, there are commands to
  help users manipulate revision logs in a Jujutsu-friendly way,
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
  storage backend Jujutsu supports is Git, although other storage
  backends may be supported in the future.

  Since version 0.34.0, Jujutsu repositories are "colocated" by default.
  Earlier versions of Jujutsu may colocate a Git repository with `jj git
  clone --colocate REPOSITORY-URL'.  Colocated repositories are ones
  that contain both a `.jj' and a `.git' directory in the repository
  root, allowing users to use both Jujutsu and Git commands in the same
  repository, without one getting in the way of the other.  (Although
  Git will complain about being in "detached HEAD" state.)  Because of
  this colocation, vc-jj can reuse some vc-git functionality where
  appropriate, such as handling `.gitignore' files.


2.1 Jujutsu terminology and concepts
────────────────────────────────────

  To those used to other version control systems, like Git, Jujutsu's
  version control model may be unfamiliar.

  Below is an attempt at a brief description of Jujutsu-specific
  terminology and concepts.

  In Jujutsu, there are both "commits" and "changes."  In Git, the
  primary unit of history is the commit, which is immutable and
  identified by a commit hash.  In Jujutsu, the primary unit is the
  change.  A Jujutsu "*commit*" is the same as in Git: a snapshot in
  time of the repository.  In Jujutsu, "*revision*" can be used
  interchangeably with "commit."  A *"change"*, on the other hand, is
  unique to Jujutsu: it can be thought of as a /logical unit of work/.
  A change is like the entire evolution of a commit as it changes over
  time.  Each change has an underlying commit.

  Every change has a corresponding change ID and every commit has a
  corresponding commit ID.  Most jj commands accept both change IDs and
  commit IDs.

  As the user modifies the repository, all changes are automatically
  recorded and all non-ignored files are automatically tracked.
  Consequently, unlike Git, there is no staging area or check-in
  operation.  Instead, all modifications occur in the current change —
  the "*working copy*."  As files are edited, added, and deleted,
  Jujutsu will take *snapshots* of the repository and automatically
  *rewrite* the underlying commit of the working copy, keeping the
  change intact but changing the corresponding underlying commit.

  Because of the conceptual differences between Git and Jujutsu,
  commands that assume a stage/commit workflow behave differently or are
  no-ops when used via vc-jj.

  In Git, `git log' shows a log of commits.  In Jujutsu, `jj log' shows
  a log of changes.  History rewriting is a normal part of jj’s
  workflow.  Changes may be edited, split, or reordered while preserving
  their identity via the change ID.  Users will find that it is much
  more natural to make changes in a repository by rewriting, playing
  with, and modifying the change log.

  Finally, in Jujutsu, there are *bookmarks*.  Although each Git
  *branch* has a corresponding Jujutsu bookmark and vice versa (in
  colocated repositories), a bookmark is merely an alias, or named
  pointer, to a commit.  Although bookmarks are pointers to commits,
  when a commit with a bookmark is rewritten, the bookmark automatically
  moves to the new commit, so bookmarks can effectively be treated as
  pointers to changes.

  In contrast to Git, the working copy (current change) may be on a
  bookmark's commit, but it is not "attached" to it in the way a Git
  commit is attached to a branch: in Jujutsu, there is no currently
  checked out or active bookmark.  As such, bookmarks do not
  automatically advance when new changes are created atop the commit
  they point to, unlike Git branches.  Users familiar with Mercurial
  will find that Jujutsu bookmarks are more similar to [Mercurial
  bookmarks] than Git branches.

  Users may read more about the concepts and terms used in Jujutsu here:
  <https://docs.jj-vcs.dev/latest/>.  In particular, a glossary of all
  Jujutsu-specific terms can be found here:
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

  Vc-jj uses Emacs's built-in Bug Reference mode (see [(emacs) Bug
  Reference]) to buttonize references to this project's Codeberg issues
  and PRs in Emacs-lisp mode buffers.  References have the form
  `KEYWORD#NUMBER', where `KEYWORD' is one of `bug', `Bug', `BUG',
  `issue', `Issue', `ISSUE', `pull', `Pull', `PULL', `pr', or `PR'.
  Issue keywords (`bug', `issue') link to Codeberg issues, and PR
  keywords (`pull', `pr') link to Codeberg PRs.  To follow a button,
  place point on it and press `C-c RET', or use `M-x
  bug-reference-push-button'.


[(emacs) Bug Reference]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Bug-Reference.html>


3.2 Testing
───────────

  All tests are written in `vc-jj-tests.el' with the built-in ERT
  package (Emacs Lisp Regression Testing).  To run all the tests, open
  the `vc-jj-tests.el' file in Emacs, evaluate the buffer by pressing
  `C-c C-e', then press `M-x ert RET t RET'.  For more information on
  ERT, see the [ERT manual].

  Alternatively, test coverage can be checked in the command line via
  the [Eldev] tool, which isolates your personal Emacs configuration
  from the Emacs instance used to run tests, helping distinguish between
  project bugs and personal configuration problems.  First, install the
  Eldev executable [as described in the Eldev manual].  Then in a shell
  whose current working directory is the project root, run `eldev test'
  to run all tests or `eldev test TEST1 TEST2' to run the tests named
  `TEST1' and `TEST2'.  Eldev also helps to easily run tests on other
  versions of Emacs; see the [corresponding manual section] for how to
  do so.

  Additionally, if installed, the [coverage.el] Emacs package can be
  used alongside Eldev to highlight lines in the project files by color
  according to whether they are covered by the existing tests.  In a
  shell, run `eldev test --undercover simplecov,dontsend' in the project
  root directory, then open `vc-jj.el' in Emacs and enable the
  `coverage-mode' minor mode.  You should now see lines highlighted
  green (covered) and red (not covered).  See the [associated Eldev
  manual section] for more information on integration with coverage.el.


[ERT manual] <https://www.gnu.org/software/emacs/manual/html_node/ert/>

[Eldev] <https://emacs-eldev.github.io/eldev/>

[as described in the Eldev manual]
<https://emacs-eldev.github.io/eldev/#installation>

[corresponding manual section]
<https://emacs-eldev.github.io/eldev/#different-emacs-versions>

[coverage.el] <https://github.com/trezona-lecomte/coverage>

[associated Eldev manual section]
<https://emacs-eldev.github.io/eldev/#undercover-plugin>


4 Other Emacs packages for Jujutsu
══════════════════════════════════

  The scope of the `vc-jj.el' project is to add jj support to the Emacs
  built-in `vc' and `project' libraries.  In case you look for a package
  with more specialized Jujutsu support, here are some that might fit
  the bill:

  [0WD0/majutsu]
        “Majutsu provides a Magit-style interface for Jujutsu (jj),
        offering an efficient way to interact with JJ repositories from
        within Emacs.”
  [bolivier/jj-mode.el]
        “Jujutsu version control mode for Emacs inspired by Magit”
  [bennyandresen/jujutsu.el]
        “An Emacs interface for jujutsu, inspired by magit and humbly
        not attempting to match it in scope.”
  [~puercopop/jujutsushi]
        “An Emacs UI to jujutsu”
  [Xylenox/majjic]
        “jjui + magit-section inspired jj ui for Emacs”


[0WD0/majutsu] <https://github.com/0WD0/majutsu>

[bolivier/jj-mode.el] <https://github.com/bolivier/jj-mode.el>

[bennyandresen/jujutsu.el] <https://github.com/bennyandresen/jujutsu.el>

[~puercopop/jujutsushi] <https://git.sr.ht/~puercopop/jujutsushi>

[Xylenox/majjic] <https://github.com/Xylenox/majjic>
