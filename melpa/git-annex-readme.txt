Typing C-x C-q in an annexed file buffer causes Emacs to run "git annex
edit".  When the buffer is killed Emacs will run "git annex add && git
commit -m Updated".

Dired has been extended to not show Annex symlinks, but instead to color
annexed files green (and preserve the "l" in the file modes).  You have the
following commands available in dired-mode on all marked files (or the
current file):

    @ a    Add file to Git annex
    @ e    Edit an annexed file
