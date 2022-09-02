`shell-command+' is a `shell-command' substitute, that extends the
regular Emacs command with several features.  After installed,
configure the package as follows:

	(global-set-key (kbd "M-!") #'shell-command+)

A few examples of what `shell-command+' can do:

* Count all lines in a buffer, and display the result in the
  minibuffer:

  > wc -l

* Replace the current region (or buffer in no region is selected)
  with a directory listing of the parent directory.

  .. < ls -l

* Delete all instances of the charachters a, b, c, ..., z, in the
  selected region (or buffer, if no region was selected).

  | tr -d a-z

* Open a man-page using Emacs default man page viewer.
  `shell-command+' can be extended to use custom Elisp handlers via
  as specified in `shell-command+-substitute-alist'.

  man fprintf

See `shell-command+'s docstring for more details on how it's input
is interpreted.  See `shell-command+-features' if you want to
disable or add new features.

`shell-command+' was originally based on the command `bang' by Leah
Neukirchen (https://leahneukirchen.org/dotfiles/.emacs).