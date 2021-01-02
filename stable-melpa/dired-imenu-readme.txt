
After you add the following line to your Emacs init file you can
call imenu from a dired buffer and get a list of all files in the
current buffer with completion. That's easier to use the isearch if
you use something like idomenu.

(require 'dired-imenu)
