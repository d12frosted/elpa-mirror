
This is an interactive tool to interact with git branches using
StGit.

StGit is a command-line tool providing similar functionality to
Quilt (i.e. pushing/popping patches to/from a stack) on top of Git.
These operations are performed using Git commands and the patches
are stored as Git commit objects, allowing easy merging of the
StGit patches into other repositories using standard Git
functionality.

To start using the Emacs interface, run M-x stgit and select the
git repository you are working in.

To get quick help about the available keybindings in the buffer,
press '?'

; Installation:

To install: put this file on the load-path and place the following
in your .emacs file:

   (require 'stgit)

To start: `M-x stgit'
