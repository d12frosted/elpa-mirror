1 Gnosis
════════

  Gnosis is a personal knowledge management and spaced repetition system
  for Emacs.  It integrates two complementary subsystems in a single
  package: a Zettelkasten-style note system called *nodes*, and a
  flashcard-based self-testing system built around *themata*.  Both
  subsystems share a single SQLite database, and their contents are
  linked together so that flashcard questions can refer directly to the
  notes they are drawn from.


1.1 Why Gnosis
──────────────

  Most spaced repetition tools treat flashcards as isolated units.  You
  create a card, review it, and the system schedules the next review.
  The cards have no relationship to each other or to anything outside
  the review loop.

  Most note-taking tools do the opposite: they help you build a web of
  interconnected ideas, but they offer no mechanism for systematically
  testing and reinforcing what you have written.

  Gnosis bridges these two approaches.  Your notes and your review
  material live in the same system, linked together.  When you write a
  node about a topic, you can create themata whose questions reference
  that node.  When you review, you can review all the questions linked
  to a given note, or follow the link graph to review related topics.
  The goal is a single system where understanding and recall reinforce
  each other.


1.2 Nodes
─────────

  Nodes are Zettelkasten-style notes stored as plain org-mode files.
  Each node is identified by a unique UUID stored in an Org `:ID:'
  property.  Nodes are indexed in the database so that they can be
  searched, browsed by tag, and linked together using standard org-mode
  `[[id:UUID]]' syntax.


1.3 Themata
───────────

  A /thema/ (plural /themata/) is a review card.  Each thema consists of
  a /keimenon/ (the question or prompt), an /answer/, and an optional
  /parathema/ (supplementary context shown after the answer).  Themata
  are reviewed using a spaced repetition algorithm that adapts the
  interval between reviews based on performance.

  Themata support basic, double, MCQ, cloze and mc-cloze text questions,
  image-region and image-occlusion questions, and optional 3D model
  questions.


1.4 Installation
────────────────

  Install from GNU ELPA with `M-x package-refresh-contents', then `M-x
  package-install RET gnosis RET'.  Emacs installs the declared `compat'
  and `keymap-popup' dependencies.  Core Gnosis requires Emacs 29.1 or
  later with working SQLite support: `M-: (sqlite-available-p)' should
  return `t'.  Python and native canvas support are not required.

  Open `M-x gnosis-dashboard' to start, or `C-h i g (gnosis) RET' for
  the installed manual.  See [Installation and Setup] for directories
  and configuration.  Existing users: back up the old database, Org
  files and media *before the first database open* with upgraded code;
  see the manual's [Database Upgrades and Rollback] section for 0.13.0
  (schema 11).


[Installation and Setup] <file:docs/gnosis.org::#installation>

[Database Upgrades and Rollback]
<file:docs/gnosis.org::#database-upgrades>


1.5 Optional 3D support
───────────────────────

  Gnosis works without Python or a 3D renderer.  Model themata use the
  optional `canvas-3d' backend, which is not included in the ELPA
  package.  Install it separately from a matching Gnosis source
  checkout; keep the whole `optional/canvas-3d/' directory, not just its
  Lisp file.

  The backend requires a graphical Emacs with `canvas-refresh' and the
  `canvas' image type (Emacs 32 development builds), Python 3.12–3.14,
  and a working EGL/OpenGL 3.3 driver.  Only Linux EGL is currently
  verified.  Installing Python dependencies does not add canvas support
  to an older Emacs.

  Install [uv], then prepare and check the backend:

  ┌────
  │ cd /path/to/gnosis/optional/canvas-3d
  │ uv sync --locked
  │ ./preflight.py
  └────

  Point Gnosis at that directory in your Emacs configuration:

  ┌────
  │ (with-eval-after-load 'gnosis
  │   (setq gnosis-model-renderer-directory
  │         "/path/to/gnosis/optional/canvas-3d/"))
  └────

  The renderer loads only when needed.  Opening a model never installs
  software or downloads dependencies.  See the [canvas-3d setup guide]
  for preflight options, a standalone test scene, and renderer
  configuration.  Anatomical models are not bundled.


[uv] <https://docs.astral.sh/uv/getting-started/installation/>

[canvas-3d setup guide]
<https://git.thanosapollo.org/emacs-gnosis/tree/optional/canvas-3d/README.md>


1.6 The Link Between Nodes and Themata
──────────────────────────────────────

  When you write a node about a topic, you can create themata whose
  keimenon or parathema contains an `[[id:NODE-UUID]]' link to that
  node.  Gnosis records these relationships so that you can later review
  all themata associated with a particular node via
  `gnosis-review-topic'.
