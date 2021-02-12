Installation and activation:
- From MELPA: do

(install-package 'amsreftex)

and activate with

(amsreftex-turn-on)

or

(use-package amsreftex
  :ensure t
  :config
  (amsreftex-turn-on))

- Manually: download `amsreftex.el`, put it somewhere in your load-path
and then do

(require 'amsreftex)
(amsreftex-turn-on)

Usage:

Once `amsreftex` is activated, `reftex` should detect if you are
using `amsrefs` databases and Just Work.

It does this by checking for the existence of `\bibselect` or
`\bib` macros.  You may need to re-parse your document with `M-x
reftex-parse-all` after inserting these macros for the first time.

If, for any reason, you want to revert to vanilla `reftex`,
just do `M-x amsreftex-turn-off`.

- Sorting:
Do `M-x amsreftex-sort-bibliography` to sort in-document
bibliographies or stand-alone `amsrefs` databases.

If point is in a `biblist` environment, that alone will be
sorted.  Otherwise, all `\bib` records in the buffer will be
sorted (after checking that you really want to do that).  In
this case, all text outside `\bib` records is left
untouched.

Configuration:
- Database search path
By default, `amsreftex` inspects $TEXINPUTS to find the search-path
for `amsrefs` databases (.ltb files).  Customize
`reftex-ltbpath-environment-variables' to change this.

- Sort order
By default, `amsreftex-sort-bibliography` sorts by author
then year.  The list of fields to sort by is contained in
`amsreftex-sort-fields' so do
    (setq amsreftex-sort-fields '("author" "title"))
to sort by author then title.

You can choose how to sort names by setting
`amsreftex-sort-name-parts'.  By default, we sort by last
name then initial.  Do
    (setq amsreftex-sort-name-parts '(first last))
in the unlikely event that you want to sort by first name
then last name!

NEWS:
v0.2: -`amsreftex-sort-bibliography' added
      - Rename turn-on/off-amsreftex to amsreftex-turn-on/off to
        placate package-lint.
v0.1: initial release.

Implementation:
Vanilla reftex is mostly agnostic about the format of the
bibliography databases it uses.  It parses them into an internal
format with which it works from then on.  To adapt reftex to work
with amsrefs databases, we need only adjust the workings of 10
functions which make bibtex-specific assumptions (often in the shape
of regexps) to accomplish their ends.  These are:
`reftex-locate-bibliography-files'
`reftex-parse-bibtex-entry'
`reftex-get-crossref-alist'
`reftex-extract-bib-entries'
`reftex-extract-bib-entries-from-thebibliography'
`reftex-pop-to-bibtex-entry'
`reftex-echo-cite'
`reftex-end-of-bibentry'
`reftex-parse-from-file'
`reftex-bibtex-selection-callback'
We adjust these functions by advising them to call alternatives if
we are in an document using amsrefs.

We notify the presence of amsrefs databases by adding a cell to the
document's `reftex-docstruct-symbol' alist (with car 'database and
currently ignored cdr).  This is done by unconditionally replacing
`reftex-parse-from-file' by `amsreftex-parse-from-file' when
amsreftex is turned on.  Thereafter, most of the functions above
are advised to check for this cell and call an amsrefs-friendly
replacement if it is present.

The only exceptions to this rule are `reftex-parse-from-file',
discussed above, `reftex-bibtex-selection-callback' and
`reftex-end-of-bib-entry'.  The latter are called from a selection
buffer where the docstruct alist is not available and so we
unconditionally replace them with versions that make its own test
for amsrefs.
