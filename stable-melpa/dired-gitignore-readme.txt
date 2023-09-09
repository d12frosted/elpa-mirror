This package provides a minor mode which hides files and directories,
ignored by git due to an entry in the project's `.gitignore'.

When the minor mode is active, the ignored items are hidden.  When it is
deactivated, they are shown again.

The recommended use case is to bind the command to toggle the global minor mode
`(dired-gitignore-global-mode)' to some convenient key.  If you want to ignore
.gitignored files by default put

(dired-gitignore-global-mode t)

into your startup file.

Alternatively you can to use `(dired-gitignore-mode)' to toggle the ignoring.
That affects only the current `dired' buffer.

It needs the executables for `git' and `ls' in the `PATH' and a standard UNIX shell
behind the `shell-file-name' variable.

Changelog in: CHANGES.org in https://github.com/johannes-mueller/dired-gitignore.el/
