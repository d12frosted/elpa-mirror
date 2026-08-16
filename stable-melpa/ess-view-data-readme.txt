This file is the entry point of the ess-view-data package.  The
implementation is split across four support files, all loaded by
requiring this one:
- ess-view-data-core.el: customization group, options and
  buffer-local state, pure utilities and the generic backend API.
- ess-view-data-backend.el: verb code generation, the shared
  backend skeleton and the dplyr / dplyr+DT / data.table+magrittr
  data backends plus the print/kable and save backends.
- ess-view-data-table.el: the tabulated-list table display,
  server-side sorting, cell widening and the render/refresh
  orchestration.
- ess-view-data-complete.el: completion cache and commands.

Customization:
ess-view-data-backend-list: dplyr (default), dplyr+DT, data.table+magrittr
ess-view-data-print-backend-list: print (default), kable
ess-view-data-save-backend-list: write.csv (default), readr::write_csv,
                                 data.table::fwrite kable
ess-view-data-complete-backend-list: jsonlite
ess-view-data-read-string: ess-completing-read (default), completing-read,
                           ido-completing-read, ivy-completing-read
ess-view-data-display-backend: how to display data in the view buffer.
  `table' (default): a structured tabulated-list with column types, aligned
  cells, truncated long cells and clickable sort headers.
  `print' / `kable': keep the historical text output of the print/kable
  backends (csv text with the '# Trace' / '# Last' / '# Page number' head
  lines and a csv-mode column header).
  To restore the historical csv + header view, set
  `ess-view-data-display-backend' to `print', e.g.:

    M-x customize-option RET ess-view-data-display-backend RET print
    (setq ess-view-data-display-backend 'print)

  NB: the setting is global; refresh the current view buffer
  (ess-view-data-reset or re-run ess-view-data-print) after switching.

Table display keys (`ess-view-data-table-mode'):
  S: sort by the column at point (server-side arrange over the whole data).
  W: widen the current column; cells re-truncate from the full-value cache
     at the new width, so repeated W reveals more of every long cell.
  w: ess-view-data-widen-current-column-full - fit the current column to
     its longest full value.
  a: ess-view-data-widen-all-columns-full - fit every column to its longest
     full value; the whole current page then sits in the buffer as full
     text and built-in isearch (C-s / C-r) can search the full values.
  v: ess-view-data-show-cell-value - show the full cell value at point in a
     read-only buffer (from the local cache, no R round trip).

The header line follows horizontal scrolling: it is rebuilt before every
redisplay from the window's current horizontal scroll, so column names stay
aligned with the data at any scroll position and the columns hidden right of
the window become reachable by scrolling right (also after `a').

Utils:
NOTE: it will make a copy of the data and then does the following action
ess-view-data-print: the main function to view data

Example: In a ess-r buffer or a Rscript buffer, `M-x ess-view-data-print`
and input `mtcars`.

ess-view-data-set-backend: change backend
ess-view-data-toggle-maxprint: toggle limitation of lines per page to print

ess-view-data-verbs

Example: In the ESS-V buffer, `M-x ess-view-data-verbs` and select the verb
to do with.

ess-view-data-filter

Example: In the ESS-V buffer, `M-x ess-view-data-filter`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.  An indirect buffer pops up and
'data-masking' Expressions can be edited.

ess-view-data-select / ess-view-data-unselect

Example: In the ESS-V buffer, `M-x ess-view-data-select`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.

ess-view-data-sort
ess-view-data-group / ess-view-data-ungroup
ess-view-data-mutate
ess-view-data-slice
ess-view-data-wide2long / ess-view-data-long2wide
ess-view-data-update
ess-view-data-reset

Example: In the ESS-V buffer, `M-x ess-view-data-reset`, an indirect buffer
pops up and the action history can be edited.

ess-view-data-unique
ess-view-data-count

Example: In the ESS-V buffer, `M-x ess-view-data-count`, `cyl <RET> mpg` to
select columns and <C-j> to finish input.  In the updated buffer with count
information, `M-x ess-view-data-print` to go back.

ess-view-data-summarise
ess-view-data-overview
ess-view-data-goto-page / -next-page / -previous-page / -first-page /
                          -last-page / -page-number
ess-view-data-save
