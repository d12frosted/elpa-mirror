
This is an interface for managing Subversion working copies.  It
can show you an up-to-date view of the current status, and commit
changes. If also helps you do other tasks such as updating,
switching, diffing and more.

To get you started, add this line to your startup file:

 (autoload 'svn-status "dsvn" "Run `svn status'." t)
 (autoload 'svn-update "dsvn" "Run `svn update'." t)

This file integrates well with vc-svn, so you might want to do this
as well:

  (require 'vc-svn)

To get the status view, type

  M-x svn-status

and select a directory where you have a checked-out Subversion
working copy.  A buffer will be created that shows what files you
have modified, and any unknown files.  The file list corresponds
closely to that produced by "svn status", only slightly
reformatted.

Navigate through the file list using "n" and "p", for next and
previous file, respectively.

You can get a summary of available commands by typing "?".

Some commands operate on files, and can either operate on the file
under point, or on a group of files that have been marked.  The
commands used for marking a file are the following:

  m      mark and go down
  DEL    unmark and go up
  u      unmark and go down
  SPC    toggle mark
  M-DEL  unmark all

The commands that operate on files are:

  f      Visit the file under point (does not use marks)
  o      Visit the file under point in another window (does not use marks)
  =      Show diff of uncommitted changes.  This does not use marks
           unless you give a prefix argument (C-u)
  c      Commit files
  a      Add files
  r      Remove files
  R      Resolve conflicts
  M      Rename/move files
  U      Revert files
  P      View or edit properties of the file or directory under point
           (does not use marks)
  l      Show log of file or directory under point (does not use marks)

These commands update what is shown in the status buffer:

  g      Rerun "svn status" to update the list.  Use a prefix
           argument (C-u) to clear the list first to make sure that
           it is correct.
  s      Update status of selected files
  S      Show status of specific file or directory
  x      Expunge unchanged files from the list

To update the working copy:

  M-u    Run "svn update".  If a prefix argument is given (C-u),
           you will be prompted for a revision to update to.
  M-s    Switch working copy to another branch.
  M-m    Merge in changes using "svn merge".

To view the Subversion log, type "M-x svn-log".

Bugs and missing features:

- Annotate (blame).
- Log, with a useful log mode where the user can easily view any revision
  as a diff or visit a revision of a file in a buffer.
- Integration with ediff or similar to resolve conflicts.
