This package assists the user in writing good Git commit messages.

While Git allows for the message to be provided on the command
line, it is preferable to tell Git to create the commit without
actually passing it a message.  Git then invokes the `$GIT_EDITOR'
(or if that is undefined `$EDITOR') asking the user to provide the
message by editing the file ".git/COMMIT_EDITMSG" (or another file
in that directory, e.g. ".git/MERGE_MSG" for merge commits).

When `global-git-commit-mode' is enabled, which it is by default,
then opening such a file causes the features described below, to
be enabled in that buffer.  Normally this would be done using a
major-mode but to allow the use of any major-mode, as the user sees
fit, it is done here by running a setup function, which among other
things turns on the preferred major-mode, by default `text-mode'.

Git waits for the `$EDITOR' to finish and then either creates the
commit using the contents of the file as commit message, or, if the
editor process exited with a non-zero exit status, aborts without
creating a commit.  Unfortunately Emacsclient (which is what Emacs
users should be using as `$EDITOR' or at least as `$GIT_EDITOR')
does not differentiate between "successfully" editing a file and
aborting; not out of the box that is.

By making use of the `with-editor' package this package provides
both ways of finish an editing session.  In either case the file
is saved, but Emacseditor's exit code differs.

  C-c C-c  Finish the editing session successfully by returning
           with exit code 0.  Git then creates the commit using
           the message it finds in the file.

  C-c C-k  Aborts the edit editing session by returning with exit
           code 1.  Git then aborts the commit.

Aborting the commit does not cause the message to be lost, but
relying solely on the file not being tampered with is risky.  This
package additionally stores all aborted messages for the duration
of the current session (i.e. until you close Emacs).  To get back
an aborted message use M-p and M-n while editing a message.

  M-p      Replace the buffer contents with the previous message
           from the message ring.  Of course only after storing
           the current content there too.

  M-n      Replace the buffer contents with the next message from
           the message ring, after storing the current content.

Some support for pseudo headers as used in some projects is
provided by these commands:

  C-c C-s  Insert a Signed-off-by header.
  C-c C-a  Insert a Acked-by header.
  C-c C-m  Insert a Modified-by header.
  C-c C-t  Insert a Tested-by header.
  C-c C-r  Insert a Reviewed-by header.
  C-c C-o  Insert a Cc header.
  C-c C-p  Insert a Reported-by header.
  C-c C-i  Insert a Suggested-by header.

When Git requests a commit message from the user, it does so by
having her edit a file which initially contains some comments,
instructing her what to do, and providing useful information, such
as which files were modified.  These comments, even when left
intact by the user, do not become part of the commit message.  This
package ensures these comments are propertizes as such and further
prettifies them by using different faces for various parts, such as
files.

Finally this package highlights style errors, like lines that are
too long, or when the second line is not empty.  It may even nag
you when you attempt to finish the commit without having fixed
these issues.  The style checks and many other settings can easily
be configured:

  M-x customize-group RET git-commit RET
