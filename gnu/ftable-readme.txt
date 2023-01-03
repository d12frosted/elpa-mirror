			      ━━━━━━━━━━━
			       FTABLE.EL
			      ━━━━━━━━━━━


[https://elpa.gnu.org/packages/ftable.svg]

This package provides some convenient commands for filling a table,
i.e., adjusting the layout of the table so it can fit in n columns.

<file:./ftable.gif>

Commands provided:

ftable-fill
      Fill the table at point
ftable-reformat
      Change the style of the table. For example, from
┌────
│ ASCII +--+--+ to Unicode ┌──┬──┐
│       |  |  |            │  │  │
│       +--+--+            └──┴──┘
└────

ftable-edit-cell
      Edit the cell at point

There are some limitations. Currently ftable doesn’t support tables with
compound cells (cells that span multiple rows/columns) because they are
more complicated to handle. If the need arises in the future (unlikely),
I might improve ftable to handle more complex tables. Also, after
filling, any manual line-break in a cell is discarded.


[https://elpa.gnu.org/packages/ftable.svg]
<https://elpa.gnu.org/packages/ftable.html>


1 Customization
═══════════════

  ftable-fill-column
        `fill-column' for ftable.
