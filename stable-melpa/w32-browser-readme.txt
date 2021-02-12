
   Run Windows application associated with a file.

Functions `w32-browser' & `dired-w32-browser' were originally from
code posted on EmacsWiki (author unknown).

Modified `w32-browser' to invoke `find-file' if it cannot use
`w32-shell-execute'.  Modified `dired-multiple-w32-browser' to use
`w32-browser-wait-time'.  Wrote `dired-mouse-w32-browser',
`w32explore', `dired-w32explore', and `dired-mouse-w32explore'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
