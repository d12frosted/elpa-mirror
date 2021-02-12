This package is a replacement of `describe-bindings' for Helm.

Usage:

You can use this package independently from Helm - in particular,
you don't need to turn on `helm-mode' to be able to use this.  Helm
just needs to be installed.

Add followings on your .emacs.

  (require 'helm-descbinds)
  (helm-descbinds-mode)

or use customize to set `helm-descbinds-mode' to t.

Now, `describe-bindings' is replaced with `helm-descbinds'. As
usual, type `C-h b', or any incomplete key sequence plus C-h , to
run `helm-descbinds'.  The bindings are presented in a similar way
as `describe-bindings ' does, but you can use completion to find
the command you searched for and execute it, or view it's
documentation.

In the Helm completions buffer, you match key bindings with the
Helm interface:

 - When you type RET, the selected candidate command is executed.

 - When you hit RET on a prefix key, the candidates are narrowed to
   this prefix

 - When you type TAB, you can select "Execute", "Describe" or "Find
   Function" by the menu (i.e. these are the available "actions"
   and are of course also available via their usual shortcuts).

 - When you type C-z (aka "persistent action"), the selected
   command is described without quitting Helm.
