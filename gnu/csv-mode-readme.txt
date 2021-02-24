This package implements CSV mode, a major mode for editing records
in a generalized CSV (character-separated values) format.  It binds
files with prefix ".csv" to `csv-mode' (and ".tsv" to `tsv-mode') in
`auto-mode-alist'.

In CSV mode, the following commands are available:

- C-c C-s (`csv-sort-fields') and C-c C-n (`csv-sort-numeric-fields')
  respectively sort lexicographically and numerically on a
  specified field or column.

- C-c C-r (`csv-reverse-region') reverses the order.  (These
  commands are based closely on, and use, code in `sort.el'.)

- C-c C-k (`csv-kill-fields') and C-c C-y (`csv-yank-fields') kill
  and yank fields or columns, although they do not use the normal
  kill ring.  C-c C-k can kill more than one field at once, but
  multiple killed fields can be yanked only as a fixed group
  equivalent to a single field.

- `csv-align-mode' keeps fields visually aligned, on-the-fly.
  It truncates fields to a maximum width that can be changed per-column
  with `csv-align-set-column-width'.
  Alternatively, C-c C-a (`csv-align-fields') aligns fields into columns
  and C-c C-u (`csv-unalign-fields') undoes such alignment;
  separators can be hidden within aligned records (controlled by
  `csv-invisibility-default' and `csv-toggle-invisibility').

- C-c C-t (`csv-transpose') interchanges rows and columns.  For
  details, see the documentation for the individual commands.

CSV mode can recognize fields separated by any of several single
characters, specified by the value of the customizable user option
`csv-separators'.  CSV data fields can be delimited by quote
characters (and must if they contain separator characters).  This
implementation supports quoted fields, where the quote characters
allowed are specified by the value of the customizable user option
`csv-field-quotes'.  By default, the both commas and tabs are considered
as separators and the only field quote is a double quote.
These user options can be changed ONLY by customizing them, e.g. via M-x
customize-variable.

CSV mode commands ignore blank lines and comment lines beginning
with the value of the buffer local variable `csv-comment-start',
which by default is #.  The user interface is similar to that of
the standard commands `sort-fields' and `sort-numeric-fields', but
see the major mode documentation below.

The global minor mode `csv-field-index-mode' provides display of
the current field index in the mode line, cf. `line-number-mode'
and `column-number-mode'.  It is on by default.