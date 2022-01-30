Filetree is a package that provides a set of interactive file management
tools.  The core functionality is a file tree viewer which displays a
file list as a directory tree in a special buffer.  There are numerous
interactive tools available to the user within this special buffer.

In addition to this file tree viewer functionality, there is also a
file note taking feature in the package.  The file notes enable the user
to write and display (org-mode) notes associated with individual files
and directories.  The note can be displayed in a side buffer either when
cycling through files in the file tree viewer or when the file is open
in a buffer.


To use add the following to your ~/.emacs:
(require 'filetree')

To bring up a menu from which you can select a source for the filetree
M-x filetree-load-cmd-menu

Or use one of the following to run filetree for a common use case:
M-x filetree-show-recentf-files
M-x filetree-show-cur-dir
M-x filetree-show-cur-dir-recursively
M-x filetree-show-cur-buffers
M-x filetree-show-vc-dir-recursively

Use the following command to pull up the help transient for available commands
M-x filetree-command-help


-------------------------------------------
