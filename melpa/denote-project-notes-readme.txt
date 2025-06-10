This package provides some simple linkage between Denote notes and
projects.  It does so by providing two buffer/directory-local
variables that can be set through a provided command
(`denote-project-notes-set-identifier').  The notes can then be
displayed using `denote-project-notes-show'.  Additionally, a more
user-friendly DWIM command, `denote-project-notes-dwim' is
available: this will show project notes if the notes identifier is
set, or ask you to set the identifier; additionally, you can force
changing the notes with the prefix argument.  It is recomended to
bind one of these commands to a convenient key.

The primary variable to select notes is
`denote-project-notes-identifier', whish should be set to a Denote
identifier that can be found in
`denote-project-notes-denote-directory' (a Denote silo).  An
additional option includes using a username-to-identifier alist
(this must be set using `customize-dirlocals' or by editing the
.dir-locals.el file manually).

Display can be customized using either `display-buffer-alist' (the
default), or through `denote-project-notes-display-action' (a
`display-buffer' action).

;; Errors and Patches

If you find an error, or have a patch to improve this package,
please send an email to ~swflint/emacs-utilities@lists.sr.ht.
