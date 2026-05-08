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
  Each node is identified by a unique UUID stored as an `#+id:'
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

  Themata support five question types: basic, double, MCQ, cloze, and
  mc-cloze.


1.4 The Link Between Nodes and Themata
──────────────────────────────────────

  When you write a node about a topic, you can create themata whose
  keimenon or parathema contains an `[[id:NODE-UUID]]' link to that
  node.  Gnosis records these relationships so that you can later review
  all themata associated with a particular node via
  `gnosis-review-topic'.
