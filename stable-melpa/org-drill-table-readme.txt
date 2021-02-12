Generate drill cards from org tables.

org-drill requires individual headlines with the "drill" tag; creating these
can be laborious and it is difficult to get an overview of your cards when
the buffer is folded.

This package provides a command, `org-drill-table-generate', that will
generate drill cards based on an org-mode table in the current subtree. The
cards will inserted under a new "Cards" heading in the current tree.

For example, given the following org headline,

   * Vocab
   |-----------+---------+----------------|
   | English   | Spanish | Example        |
   |-----------+---------+----------------|
   | Today     | Hoy     | Hoy es domingo |
   | Yesterday | Ayer    |                |
   | Tomorrow  | Mañana  |                |
   |-----------+---------+----------------|

invoking `org-drill-table-generate' will generate cards for each table row:

   * Vocab
   :PROPERTIES:
   :DRILL_HEADING:
   :DRILL_CARD_TYPE: twosided
   :DRILL_INSTRUCTIONS: Translate the following word.
   :END:
   |-----------+---------+----------------|
   | English   | Spanish | Example        |
   |-----------+---------+----------------|
   | Today     | Hoy     | Hoy es domingo |
   | Yesterday | Ayer    |                |
   | Tomorrow  | Mañana  |                |
   |-----------+---------+----------------|
   ** Cards
   *** Today                                                          :drill:
   :PROPERTIES:
   :DRILL_CARD_TYPE: twosided
   :END:
   Translate the following word.
   **** English
   Today
   **** Spanish
   Hoy
   **** Example
   Hoy es domingo
   *** Yesterday                                                      :drill:
   :PROPERTIES:
   :DRILL_CARD_TYPE: twosided
   :END:
   Translate the following word.
   **** English
   Yesterday
   **** Spanish
   Ayer
   *** Tomorrow                                                       :drill:
   :PROPERTIES:
   :DRILL_CARD_TYPE: twosided
   :END:
   Translate the following word.
   **** English
   Tomorrow
   **** Spanish
   Mañana

Note that there are several things happening here:
  - Each column in the table is put on its own row if it's non-empty
  - Instead of using the DRILL_HEADING property as a generic heading, the first element of each row is used as the heading


If instead of using the words from the first column as the headings, you want to use the same string for each heading,
(i.e. the old behavior) this can be done by specifying the DRILL_HEADING property

`org-drill-table-generate' checks the existing list of cards so it does not
add duplicates.

This package provides an additional command, `org-drill-table-update', which
can be added to `org-ctrl-c-ctrl-c-hook'.
