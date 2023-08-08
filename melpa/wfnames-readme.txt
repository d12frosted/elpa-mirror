A mode to edit filenames, similar to wdired.

This package have no user interface, but you can easily use it with
Helm package by customizing `helm-ff-edit-marked-files-fn'
variable.  If you are not using Helm you will have to define
yourself a function that call `wfnames-setup-buffer' with a list of
files as argument.

Usage:
Once in the Wfnames buffer, edit your filenames and hit C-c C-c to
save your changes.  You have completion on filenames and directories
with TAB but if you are using Iedit package and it is in action use =M-TAB=.
