Adds support for pdf-view (from `pdf-tools') and DocView buffers in
`save-place-mode'.

If using pdf-view-mode or doc-view-mode, this package will
automatically persist between Emacs sessions the current PDF page,
size and other information from `pdf-view-bookmark-make-record' or
`doc-view-bookmark-make-record', depending on the mode used.  These
information are persisted using `save-place-mode'.  Visiting the
same PDF file will restore the previously displayed page and scale
amount (if available).

; Acknowledgements:

- João Pedro <jpedrodeamorim@gmail.com>, for making the package
  work with doc-view-mode
