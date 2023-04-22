This package provides a minor mode which hides files and directories,
ignored by git due to an entry in the project's `.gitignore'.

When the minor mode is active, the ignored items are hidden.  When it is
deactivated, they are shown again.  The recommended use case is to bind the
command to toggle the minor mode `(dired-gitignore-mode)' to some
convenient key.

In order to hide ignored files by default hook it into `dired-mode-hook'

(add-hook 'dired-mode-hook 'dired-gitignore-mode)

It needs the executables for `git' and `ls' in the `PATH' and a standard UNIX shell
behind the `shell-file-name' variable.  The fish shell <3.4.0 does not work.
