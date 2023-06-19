A fast, local search engine for your text files. Query your notes and get a
ranked list of the best matches.

`docsim.el' uses a few different information retrieval algorithms to provide
a ranked list of text documents. It takes term frequency into account, weighs
rare words more heavily, uses stoplists to ignore common terms, and
(optionally) stems English words (so "spinning" can match "spinner").

Why not just use `grep', `ripgrep', or `ag'? Those tools are all great, but
they search for literal text matches, usually line-by-line. You might use
docsim when you want to know, "what documents are *most similar* to this
query, or to this other note?"

If I search for "chunky bacon," I still want to see documents that talk about
"chunks of bacon." And, below those, I probably want to see notes that
discuss regular "bacon," even if it's not chunky.

To use this mode, you'll first need to install the `docsim' command-line
tool. See `https://github.com/hrs/docsim'.
