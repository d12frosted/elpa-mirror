This package provides some simple linkage between Denote notes and
projects.  It does so by providing two buffer/directory-local
variables that can be set through a provided command
(`denote-project-notes-set-identifier').  The notes can then be
displayed using `denote-project-notes-show'.  It is recomended to
bind one or both of these commands to a convenient key.

The primary variable to select notes is
`denote-project-notes-identifier', whish should be set to a Denote
identifier that can be found in
`denote-project-notes-denote-directory' (a Denote silo).

Display can be customized using either `display-buffer-alist' (the
default), or through `denote-project-notes-display-action' (a
`display-buffer' action).

;; Errors and Patches

If you find an error, or have a patch to improve this package,
please send an email to ~swflint/emacs-utilities@lists.sr.ht.
