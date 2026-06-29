This package provides the command M-x ioccur, which is similar to
M-x occur, except that it is incremental.

You can jump and quit to an occurrence, or jump and save the search
buffer (ioccur-buffer) for further use.  You can toggle literal and
regexp searching while running.  It is auto documented both in
mode-line and tooltip.  It has its own history, `ioccur-history',
which is a real ring.

To save `ioccur-history' via the Desktop package, add this to your
init file (see (info "(emacs) Saving Emacs Sessions") for details):

(add-to-list 'desktop-globals-to-save 'ioccur-history)