Issue M-x git-wip-timemachine to start browsing through WIP
versions of a file.

Control the time machine using the following keys:

. -- Visit current WIP version.
> -- Visit current WIP version.
< -- Visit oldest WIP version
     (equivalent to merge base of current branch and associated WIP branch
     *if* merge base introduces changes to current file).
p -- Visit previous WIP version.
n -- Visit next WIP version.
g -- Visit nth WIP version.
w -- Copy the abbreviated hash of the current WIP version.
W -- Copy the full hash of the current WIP version.
q -- Exit the time machine.

Finally, there's also `git-wip-timemachine-toggle` which does exactly
what its name suggests: If the timemachine is on, calling this command
will turn it off (and vice versa).

; Installation

1. If you haven't already, set up `git-wip`:

   - Clone the "git-wip" package to your $HOME directory:

     $ cd
     $ git clone https://github.com/itsjeyd/git-wip

     If you decide to clone to a different directory and that
     directory is *not* part of your `exec-path' in Emacs, you'll
     need to add the following code to your init-file (to make sure
     Emacs can find the git-wip script):

     (add-to-list 'exec-path "/path/to/git-wip")

   - Add the following code to your init-file:

     (load "/path/to/git-wip/emacs/git-wip.el")

     From now on, every time you save a file that is part of a git
     repository, Emacs will automatically create a WIP commit by
     calling out to git-wip for you.

2. Install `git-wip-timemachine' from MELPA via:

   M-x package-install RET git-wip-timemachine RET
