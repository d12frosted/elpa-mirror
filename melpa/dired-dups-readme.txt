
Bitcoin donations gratefully accepted: 12k9zUo9Dgqk8Rary2cuzyvAQWD5EAuZ4q

This library provides the command `dired-find-duplicates' which searches a directory for
duplicates of the marked files in the current dired buffer.
It requires that the unix find and md5sum commands are on your system.

; Installation:

Put dired-dups.el in a directory in your load-path, e.g. ~/.emacs.d/
You can add a directory to your load-path with the following line in ~/.emacs
(add-to-list 'load-path (expand-file-name "~/elisp"))
where ~/elisp is the directory you want to add
(you don't need to do this for ~/.emacs.d - it's added by default).

Add the following to your ~/.emacs startup file.

(require 'dired-dups)
