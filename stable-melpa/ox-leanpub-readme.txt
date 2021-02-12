Org-mode export backends to produce books and courses in the correct
structure and format for publication with Leanpub (https://leanpub.com).
`ox-leanpub' allows you to write your material entirely in Org mode, and
completely manages the production of the files and directories needed for
Leanpub to render your book.

This package contains three libraries:

- `ox-leanpub-markua.el' exports Org files in Leanpub’s Markua format (see
  `https://leanpub.com/markua/read'), the default and recommended format for
  Leanpub books and courses.

- `ox-leanpub-markdown.el' exports Org files in Leanpub Flavored Markdown
  (LFM) (see `https://leanpub.com/lfm/read'), the original markup format for
  Leanpub books.

- `ox-leanpub-book.el' exports an Org file in multiple files and directories
  in the structure required by Leanpub, including the necessary `manuscript/'
  directory and the `Book.txt', `Sample.txt' and `Subset.txt' files. It can
  use either Markua or LFM as the export backend.

*Note:* it is highly recommended to use the Markua exporter, as it’s more
 mature and complete. Some Org constructs might not be exported correctly to
 Markdown.

If you have any feedback or bug reports, please open an issue at
`https://gitlab.com/zzamboni/ox-leanpub/-/issues'.

See full documentation in the README.org file or at
`https://github.com/zzamboni/ox-leanpub'.
