View data files from Dired via ESS and R.

(require 'dired-view-data)
(dired-view-data-global-mode)

or enable the minor mode in Dired buffers manually:
(dired-view-data-mode 1)

In a Dired buffer, call `dired-view-data' (`V' or `C-c C-v') on a
data file (sas7bdat, xpt, xlsx/xls, parquet, sav, dta, rds, csv,
tsv, rda or rdata) and a buffer pops up with the data rendered by
`ess-view-data'.

Add or change formats via `dired-view-data-data-name-format'.
Quit the R session with `dired-view-data-quit-session'.

Optionally set `dired-view-data-guess-shell-alist-p' to t to also
hook `dired-do-shell-command' (`!') for those files; it is off by
default.  See NEWS.md for what changed in version 2.
