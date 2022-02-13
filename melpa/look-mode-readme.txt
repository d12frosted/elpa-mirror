
This package provides a function to load a list of files into a
temporary buffer for viewing.  The buffer (*look*) is writable, but
not directly associated with the source material.  The original
rationale was that when used with `eimp' (Emacs Image Manipulation
Package), one could resize images without any danger of overwriting
the original file; however, as of 2022-02, `eimp' is no required by
`look-mode'.  This may also be of interest to someone wishing to
scan the files of a directory.

After loading, M-l is bound to `look-at-files' from dired.  If
there is more than one marked file in the current dired view, those
files are passed to `look-at-files' as the file list, otherwise,
the user is prompted for a file glob.  One moves through the file
list using the keybindings: C-. or M-n (`look-at-next-file') C-, or
M-p (`look-at-previous-file')

In the *look* buffer, C-c l accesses the Customize interface for
the "look" group.

In 2015, "Joe Bloggs <vapniks@yahoo.com>" added a lot of additional
functionality to look-mode.  This version branches from his commit
[546b261], with bugfixes applied before git cherry-picking.
Additional functionality:
Navigation
`look-at-nth-file'
`look-at-specific-file'
Search
`look-re-search-forward'
`look-re-search-backward'
List Manipulation
`look-remove-this-file'
`look-insert-file'
`look-move-current-file'
`look-sort-files'
