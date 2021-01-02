
Bitcoin donations gratefully accepted: 16iXhMdmTBcmrJAcDyv1H371mjXZNfDg7z

This provides a single command `helm-helm-commands' which will present a helm buffer
containing a list of helm commands and short descriptions. You can press C-z on an item
to see a longer description of the command, and RET to execute the command.

Note: you can achieve the same thing with the `helm-M-x' command which comes with helm,
but that requires a few more keystrokes and doesn't show descriptions by default.

;;


; Installation:

Put helm-helm-commands.el in a directory in your load-path, e.g. ~/.emacs.d/
You can add a directory to your load-path with the following line in ~/.emacs
(add-to-list 'load-path (expand-file-name "~/elisp"))
where ~/elisp is the directory you want to add
(you don't need to do this for ~/.emacs.d - it's added by default).

Add the following to your ~/.emacs startup file.

(require 'helm-helm-commands)
