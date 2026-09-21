1 Gnosis
════════

  Gnosis is a note-taking and self-testing system for Emacs.  Write
  linked Org notes, turn what you want to remember into questions, and
  review with spaced repetition or practice a topic directly.

  Notes remain plain Org files.  SQLite stores their index, questions,
  schedules and review history.  No server or AI service is required.


1.1 Notes and questions
───────────────────────

  A /node/ is an Org note or heading with an `:ID:'.  A /thema/ (plural
  /themata/) is a question.  Link a thema to its source notes to review
  a topic together or return to the source when an answer needs context.

  • Write and link notes, keep a journal, and find material by topic or
    tag.
  • Use basic questions, multiple choice, cloze deletions, images and
    image occlusion.  Interactive 3D questions are optional.
  • Review with FSRS-6 scheduling, or practice selected questions
    without changing their spaced-repetition schedules.
  • Add explanations and source links shown after answering.  Edit weak
    questions as you study.


1.2 Agent integration
─────────────────────

  Optional Emacs Lisp interfaces let an external agent find questions,
  read their sources, propose tag and source-link changes, and start
  native practice sessions.  Organization changes use preview/apply
  operations; stale edits and writes during an active review are
  refused.

  An agent can help you find questions for a topic or organize existing
  material.  You still answer in Gnosis.  Free-response questions can
  also use an optional rubric-based evaluator; its verdict remains
  subject to review and override.

  The interfaces are provider-independent: `gnosis-agent' handles
  practice, `gnosis-agent-content' handles discovery and organization,
  and `gnosis-agent-eval' handles response evaluation.  See their
  docstrings for the API.  Models and credentials are configured
  separately.


1.3 Installation
────────────────

  Install from GNU ELPA:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install RET gnosis RET
  │ M-x gnosis-dashboard
  └────

  Requires Emacs 29.1 or later with SQLite support.  Check with `M-:
  (sqlite-available-p)'.  Emacs installs the Lisp dependencies; Python
  is not needed for ordinary use.

  Read the [manual] for configuration and usage, or open the installed
  version with `C-h i g (gnosis) RET'.  The source checkout may contain
  features not yet available in the ELPA release.

  Before opening an existing database with upgraded code, back up the
  database, Org files and media.  See [Database Upgrades and Rollback].


[manual] <file:docs/gnosis.org>

[Database Upgrades and Rollback]
<file:docs/gnosis.org::#database-upgrades>


1.4 Optional 3D questions
─────────────────────────

  The separate `canvas-3d' backend requires a graphical Emacs with
  canvas support (Emacs 32 development builds), Python 3.12–3.14 and
  EGL/OpenGL 3.3.  Only Linux EGL is currently verified.  It is not
  included in the ELPA package, and anatomical models are not bundled.

  See the [canvas-3d setup guide] for installation and checks.


[canvas-3d setup guide]
<https://git.thanosapollo.org/emacs-gnosis/tree/optional/canvas-3d/README.md>
