Gnosis is a learning tool that integrates a note-taking system with
spaced repetition and self-testing.  It works together with
org-gnosis, which provides a Zettelkasten-style note-taking system
where notes (nodes) are org files indexed in an SQLite database.

The intended workflow is:

1. Write notes on a topic using `org-gnosis-find'.
2. Create themata (flashcard-like questions) related to the topic
   using `gnosis-add-thema'.
3. Link themata to note topics by inserting org-gnosis links in
   the keimenon (question text) or parathema (extra context) using
   `org-gnosis-insert'.
4. Review themata with spaced repetition via `gnosis-review', or
   review all themata linked to a specific topic via
   `gnosis-review-topic'.

Gnosis and org-gnosis maintain separate SQLite databases.  The
gnosis database stores themata, decks, review history, and links
from themata to org-gnosis nodes.  The org-gnosis database stores
nodes, tags, and links between nodes.

The spaced repetition algorithm is highly adjustable, allowing
users to set specific values not just for thema decks but for tags
as well, creating a personalized learning environment for each
topic.
