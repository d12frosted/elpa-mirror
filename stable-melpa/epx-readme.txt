epx is a command runner and manager for project.el in Emacs.
’epx’ stands for ’Emacs Project eXecutor’.

Source code is available in:
main repo: https://git.sr.ht/~alex-iam/epx
mirror: https://github.com/alex-iam/epx

This package allows you to store and run per-project commands, in the
style of Makefile, but more Emacs-specific and tailored for this need.
The separate window for the command execution is inspired by modern IDEs.

User can create a command by calling ‘epx-add-command’.  They will
be prompted for the command itself, its name, whether to use
compilation buffer for this command, and environment variables -
one name and one value at a time.

Then created command can be executed by calling ‘epx-run-command-in-shell’.
This command provides completion for command name.  It runs the command,
setting environment variables temporarily.  Command is ran in a separate
window, which will contail either shell or compilation buffer, depending
on command’s :compile option.

Commands are stored in dir-locals-file (e.g. .dir-locals.el) or a dedicated
file called .epx.eld in the project root.
This behaviour is controlled by the variable ‘epx-commands-file-type’.
The package can work with only one commands file per project.

Warning! Only works in Unix-like systems for now due to
how environment variables are processed.  This is temporary.
