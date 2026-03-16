Gnosis is a personal knowledge management and review system that
integrates a note-taking system with spaced repetition and
self-testing.  It provides Zettelkasten-style linked notes (nodes)
alongside spaced repetition themata, all in a single SQLite database.

The intended workflow is:

1. Write notes on a topic using `gnosis-nodes-find'.
2. Create themata (flashcard-like questions) related to the topic
   using `gnosis-add-thema'.
3. Link themata to note topics by inserting node links in
   the keimenon (question text) or parathema (extra context) using
   `gnosis-nodes-insert'.
4. Review themata with spaced repetition via `gnosis-review', or
   review all themata linked to a specific topic via
   `gnosis-review-topic'.

Everything lives in one database: themata, review history,
nodes, node links, and thema-to-node links.

The spaced repetition algorithm is highly adjustable, allowing
users to set specific values for tags, creating a personalized
learning environment for each topic.
