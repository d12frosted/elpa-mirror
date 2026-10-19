org-semantic brings embedding search to org-mode.  A vector
embedding model reads each passage of your notes (what is
internally called a chunk) and turns it into a point in a
high-dimensional vector space.  Passages saying the same thing sit
close together, whatever words they used and even language
(English, French, etc.) if you used a multi-language embedding
model.  Your query becomes a vector in the same space, and the
score simply reflects the projection of the query vector onto the
indexed points.  So an org note in your collection can match a
question with which it has no word in common; in fact, an English
question can have a best match to an Italian note.

Traditional search is there too.  The words themselves go into a
second index, ranked by BM25 with per-language stemming.  When you
run a search, you can choose and switch which of the two rankings
(semantic vs. lexical) to use.

The search itself is a single Rust binary from the same repository.
This package is its client.  It starts the binary, keeps it
resident over a JSON-RPC pipe, and presents the results in a
buffer, where each candidate match opens the note at its line.  The
embedding models run entirely on your machine, and no information
from your notes or your searches is ever transmitted anywhere.
Each model is downloaded once and cached.

To start:

- Set `org-semantic-vault-root' to the directory of your notes.
- M-x org-semantic-find searches them.  When the binary, the model or
  the index is missing, it says so and offers to get it.
- M-x org-semantic-reindex updates the index.
  `org-semantic-auto-reindex-mode' updates it when you save a note.
- M-x org-semantic-doctor says what a vault has and what is wrong.

The manual is at https://alberti42.github.io/org-semantic/.
