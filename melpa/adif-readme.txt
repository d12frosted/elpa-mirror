This package provides a major mode for viewing and safely editing ADIF
(Amateur Data Interchange Format) log files without corrupting the
field-length metadata embedded in the format.

It is self-contained: the ADIF field names and the values each
enumerated field accepts are carried here, and no other package is
required.  The tables follow ADIF 3.1.7; `M-x adif-specification'
reports the version and the size of the tables.

Each ADIF record is stored as an alist in memory; the file is always
serialised with correct <FIELD:LENGTH> values, regardless of edits.

Usage:
  M-x find-file RET yourlog.adi RET       to open an existing log
  M-x adif-create-file RET newlog.adi RET to start one from scratch

The log is displayed as a summary table.  Press RET or 'e' on any
record to open it for editing in a line-oriented sub-buffer.

Key bindings in the summary view:
  RET / e   Edit record at point
  r         Edit the raw ADIF text of the record at point
  R         Edit the whole file as raw ADIF text
  i         Insert a new record, pre-filled from adif-new-record-fields
  n / p     Move to the next / previous record
  C-k       Kill record(s): region, or C-u for the filtered subset
  M-w       Copy record(s) without removing them
  C-y       Yank the most recently killed or copied records
  s / S     Sort on any field, ascending / descending
  f         Filter the view on any ADIF field
  =         List duplicate QSOs
  g         Revert from disk
  C-x C-s   Write the log (C-u first to write it as displayed)
  w         Show length problems found when the file was parsed
  ?         Describe the mode
  q         Quit

  These are also on the ADIF menu.


Sorting:
  A log opens most recent first, which is what adif-default-sort asks
  for; set that to nil to open in the order the file holds.

  The order and any filters in effect are kept when the file is
  re-read, including when another program appends a QSO and the
  summary refreshes by itself.  A new QSO takes its place in the
  order rather than dropping the view back to the order on disk, so
  there is nothing to set up again after every contact.

  Sorting arranges the display only.  The records are held in the
  order the file gives them and are written back in that order, so
  the file is not reordered by looking at it a different way.  C-u
  C-x C-s writes the log in the displayed order, making a sort
  permanent.

  's' and 'S' order the log on a field chosen the way a filter field
  is chosen; the default offered is the field last sorted on.
  QSO_DATE and TIME_ON sort on date and time together.  ADIF allows
  TIME_ON as HHMM or HHMMSS, and the two cannot be compared as
  numbers -- 1200 is the smaller number than 115959, yet 12:00:00 is
  the later time -- so short times are padded to HHMMSS first.
  Sorting reorders only what is held in memory; the file is rewritten
  the next time a record is saved or deleted, and 'g' restores the
  order on disk.

Filtering:
  'f' narrows the view to records whose chosen field matches a value.
  Any ADIF field can be used, including ones absent from the columns
  and ones no record in the file carries.  The filter is a view: the
  log is untouched, record numbering is unchanged, and editing or
  deleting a visible record acts on the record it names.  The
  duplicate report follows the filter; sorting still orders the whole
  log.  Answer either prompt with nothing, or press C-c C-f, to
  clear it.
  adif-filter-match chooses between substring, exact and regexp
  comparison.

Duplicates:
  '=' lists QSOs repeated on the same band in the same mode, which
  contest rules generally disallow.  The fields that define a
  duplicate are set by adif-duplicate-fields.  Duplicates are shown
  apart from the parse warnings on 'w': a length problem is a fault
  in the file, whereas a duplicate is ordinary data that the operator
  may have meant to keep.

Backups:
  The previous contents are kept aside before every write, since a QSO
  lost from a log cannot be worked again.  Where the copy goes and how
  many are kept follow the ordinary Emacs backup settings, so setting
  version-control to t gives numbered backups pruned to
  kept-new-versions.  adif-backup turns the whole thing off.

Following the file:
  The summary refreshes by itself when the log changes on disk, so a
  QSO appended by a logging program, a script or a second Emacs shows
  up without asking.  This is ordinary
  auto-revert-mode, enabled by adif-auto-revert and driven by file
  notification where the system provides it, so it costs nothing while
  the file is idle.  Writing the log checks the file's modification
  time first, so a QSO that arrived while you were editing cannot be
  overwritten unnoticed.

Getting at the raw file:
  'R' opens the text in a second buffer, in a text-mode derivative
  with the ADIF markup highlighted, and leaves the summary as it is.

  Do not switch major mode by hand with M-x text-mode: that leaves the
  rendered table in a buffer still visiting the log, and saving would
  write the table over the QSOs.  Saving in that state is refused; 'R'
  is the way to edit the text.

  adif-mode shows a rendered summary, not the file itself, so 'R'
  (adif-edit-raw-file) is the way out to the raw ADIF, in an
  adif-raw-mode buffer.  Field lengths are not maintained there, so a
  change to a value's length needs its <FIELD:LENGTH> tag fixed by
  hand; C-x C-s writes the file, refreshes the log view and reports
  any length that no longer matches its data.

Key bindings in the record edit buffer:
  C-c C-c / C-x C-s   Save record and return to log view
  C-c C-k             Discard changes and return to log view
  C-c C-a             Add a field (with completion over all ADIF fields)
  C-c C-v             Set the value of the field on the current line
  TAB                 Complete a field name or a value
  C-k                 Kill the field on the current line
  M-w                 Copy the field on the current line
  C-y / M-y           Yank a killed field back, and cycle the kill ring

  C-k, M-w and C-y do here what they do in any text buffer, with the
  field as the unit rather than the line, so a field killed in one
  record can be yanked into the next.  With the region active they
  fall back to acting on the region, which is how part of a value is
  still moved about as ordinary text.

Layout:
  Summary columns are made as wide as the longest value on display,
  never narrower than the heading and never wider than the width set
  in adif-summary-columns, and narrow again when a filter reduces
  what is shown.  adif-summary-auto-width turns this off in favour of
  the configured widths.

  In an edit buffer the field names are padded so that every value
  starts at the same column, and the descriptions beside coded values
  start at the same column as each other.  The padding is spaces,
  which are trimmed when the record is read back, so the record is
  not altered by being tidied.  adif-align-edit-buffer turns it off.

Edit-buffer format:
  Each line is  FIELDNAME: value
  Lines that do not match that pattern (blank lines, lines beginning
  with ';') are silently ignored on save and may be used as comments.
  Any ADIF field name is accepted, including custom APP_* fields.

Coded values:
  Fields limited to a fixed set of values are entered by selection
  rather than typing.  C-c C-v offers the valid codes as a completion
  list annotated with plain-English descriptions, so BAND, MODE,
  SUBMODE, CONTEST_ID, PROP_MODE, ANT_PATH and the QSL status fields
  cannot be mistyped.  The descriptions are also shown beside coded
  values in the edit buffer using overlays, which are display-only
  and never become part of the saved file.

  These prompts keep no minibuffer history, so only the field's own
  valid codes are ever offered -- never a value entered earlier for
  this or any other field.  How strictly the list is enforced is set
  by `adif-require-known-values'.

Use from other packages:
  Another package that writes ADIF, such as a logger, can take the
  specification from here rather than carrying its own copy.  These
  are the supported interface, and will keep their meaning:

    `adif-field-names'           every field name in the specification
    `adif-field-values-for'      the valid codes for a field, with
                                 their descriptions, or nil
    `adif-record-to-string'      one record, lengths computed
    `adif-file-header'           a new log's header, lengths computed
    `adif-specification-version' the ADIF release the tables follow
    `adif-field-type'            a field's data type, such as Date
    `adif-field-import-only-p'   whether a field is not to be written
    `adif-value-import-only-p'   whether a code is not to be written
    `adif-value-problem'         what is wrong with one value, or nil
    `adif-record-problems'       what is wrong with a whole record

  Names containing a double hyphen are internal and may change.
