View data from dired via ess(-r)

(require 'dired-view-data)
(dired-view-data-global-mode)
or call minor-mode in dired buffer mannualy
(dired-view-data-mode 1)
which make `dired-do-shell-command' (`S-!') recognize those files as well if
`dired-view-data-guess-shell-alist-p' is `t'.

In dired buffer, call `dired-view-data` (`V' or `C-c C-v') on a data file
(e.g., sas7bdat, xpt, rds, csv, rda or rdata), and buffer will pop up with
data displayed.

You can modify or add new format via `dired-view-data-data-name-format'.
