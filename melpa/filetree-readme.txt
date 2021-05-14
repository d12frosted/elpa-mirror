Filetree is a package that provides two basic functions:

File tree viewer
 The viewer displays a file list as a directory tree in a
 special buffer.  The file list can be populated from any list of files.
 There are functions to populate from a number of common sources: recentf,
 files in buffer-list, files in the current directory, and files found
 recursively in the current directory.  Within the viewer, the file list can
 be filtered and expanded in various ways and operations can be performed on
 the filtered file list (e.g., grep over files in list).  Multiple file lists
 can be saved and retrieved between sessions.

File notes
 The file notes enables the user to write and display (org-mode) notes
 associated with individual files and directories.  The note can be displayed
 in a side buffer either when cycling through files in the file tree viewer
 or when the file is open in a buffer.  The notes are kept in a single org-mode
 file with a heading for each file/directory.

To use add the following to your ~/.emacs:
(require 'filetree')

Use one of the following to run filetree for a common use case:
M-x filetree-show-recentf-files
M-x filetree-show-cur-dir
M-x filetree-show-cur-dir-recursively
M-x filetree-show-cur-buffers

-------------------------------------------
