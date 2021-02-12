Ever wish to go back to an older saved version of a file?  Then
this package is for you.  This package copies every file you save
in Emacs to a backup directory tree (which mirrors the tree
structure of the filesystem), with a timestamp suffix to make
multiple saves of the same file unique.  Never lose old saved
versions again.

To activate globally, place this file in your `load-path', and add
the following lines to your ~/.emacs file:

(require 'backup-each-save)
(add-hook 'after-save-hook 'backup-each-save)

To activate only for individual files, add the require line as
above to your ~/.emacs, and place a local variables entry at the
end of your file containing the statement:

eval: (add-hook (make-local-variable 'after-save-hook) 'backup-each-save)

NOTE:  I would give a full example of how to do this here, but it
would then try to activate it for this file since it is a short
file and the docs would then be within the "end of the file" local
variables region.  :)

To filter out which files it backs up, use a custom function for
`backup-each-save-filter-function'.  For example, to filter out
the saving of gnus .newsrc.eld files, do:

(defun backup-each-save-no-newsrc-eld (filename)
  (cond
   ((string= (file-name-nondirectory filename) ".newsrc.eld") nil)
   (t t)))
(setq backup-each-save-filter-function 'backup-each-save-no-newsrc-eld)
