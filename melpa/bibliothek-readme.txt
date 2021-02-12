Bibliothek.el is a management tool for a library of PDFs.  Or it
aspires to be so.  It's quite fresh ATM, it'll grow as it gets
used more.

Presently, bibliothek.el displays PDF files from directories in
‘bibliothek-path’ in a tabulated list,
(see (info "(elisp) Tabulated List Mode")).

The functionality provided by this program is as such:

- List PDF files from directories specified in ‘bibliothek-path’,
  recursively if ‘bibliothek-recursive’ is non-nil.

  This list includes three columns: title, author, path.  Sorting
  based on these via clicking the table headers is possible.

- Filter this list with ‘bibliothek-filter’

  Using this function, the list can be filtered.  Currently this is
  rather unsophisticated, and only allows matching a single regexp
  against all the metadata PDF-tools can fetch from a file, with a
  match being counted positive if any of the fields match.  More
  complex mechanisms for better filtering are planned.

- View metadata of file under cursor.

- Visit the file associated to the item under cursor.

See also the docstring for the ‘bibliothek’ command, which lists
the keybindings, besides additional info.



;; Installation:

Bibliothek.el depends on ‘pdf-tools’.

After putting a copy of bibliothek.el in a directory in the
‘load-path’, bibliothek.el can be configured as such:

(require 'bibliothek)
(setq bibliothek-path (list "~/Documents"))

Then, the Bibliothek interface can be brought up via
M-x bibliothek RET.
