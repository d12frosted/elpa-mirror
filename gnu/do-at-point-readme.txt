The command `do-at-point' is a generalised `find-file-at-point',
both in the sense that it can understand more than just files, and
do more than just open a file.  Depending on the "thing" at point,
different "actions" can be dispatched, e.g. opening a url using
`browse-url' or occurring a symbol at point.

The entry point of this package is `do-at-point'.  Bind it to a
convenient key:

  (global-set-key (kbd "C-'") #'do-at-point)

Most of the behaviour is controlled via the user option
`do-at-point-actions' and `do-at-point-user-actions'.  A mode may
use `do-at-point-local-actions' to add additional things and/or
actions.

Inspired by Embark and `isearch-forward-thing-at-point'.