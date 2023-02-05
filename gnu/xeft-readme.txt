Usage:

Type M-x xeft RET, and you should see the Xeft buffer. Type in your
search phrase in the first line and the results will show up as you
type. Press C-n and C-p to go through each file. You can preview a
file by pressing SPC when the point is on a file, or click the file
with the mouse. Press RET to open the file in the same window.

Type C-c C-g to force a refresh. When point is on the search
phrase, press RET to create a file with the search phrase as
the filename and title.

Note that:

1. Xeft only looks for first-level files in ‘xeft-directory’. Files
   in sub-directories are not searched unless ‘xeft-recursive’ is
   non-nil.

2. Xeft creates a new file by using the search phrase as the
   filename and title. If you want otherwise, redefine
   ‘xeft-create-note’ or ‘xeft-filename-fn’.

3. Xeft saves the current window configuration before switching to
   Xeft buffer. When Xeft buffer is killed, Xeft restores the saved
   window configuration.

On search queries:

Since Xeft uses Xapian, it supports the query syntax Xapian
supports:

AND, NOT, OR, XOR and parenthesizes

+word1 -word2      which matches documents that contains word1 but not
                   word2.

word1 NEAR word2   which matches documents in where word1 is near
                   word2.

word1 ADJ word2    which matches documents in where word1 is near word2
                   and word1 comes before word2

"word1 word2"      which matches exactly “word1 word2”

Xeft deviates from Xapian in one aspect: consecutive phrases have
implied “AND” between them. So "word1 word2 word3" is actually seen
as "word1 AND word2 AND word3". See ‘xeft--tighten-search-phrase’
for how exactly is it done.

See https://xapian.org/docs/queryparser.html for Xapian’s official
documentation on query syntax.

Further customization:

You can customize the following faces

- `xeft-selection'
- `xeft-inline-highlight'
- `xeft-preview-highlight'
- `xeft-excerpt-title'
- `xeft-excerpt-body'

Functions you can customize to alter Xeft’s behavior:

- `xeft-filename-fn': How does Xeft create new files from search
  phrases.

- `xeft-file-filter': Which files does Xeft include/exclude from
  indexing.

- `xeft-directory-filter': When `xeft-recursive' is t, which
  sub-directories does Xeft include/exclude from indexing.

- `xeft-title-function': How does Xeft find the title of a file.

- `xeft-file-list-function': If `xeft-file-filter' and
  `xeft-directory-filter' are not flexible enough, this function
  gives you ultimate control over which files to index.