epx is a command runner and manager for project.el in Emacs.
’epx’ stands for ’Emacs Project eXecutor’.

Warning! Only works in Unix-like systems for now due to
how environment variables are processed.  This is temporary.

It stores commands in dir-locals-file (e.g. .dir-locals.el) or a dedicated
file called .epx.eld in the project root.
This behaviour is controlled by the variable ‘epx-commands-file-type’.
The package can work with only one commands file per project.

The package allows you to add or remove commands, no editing capabilities
for now.  You can choose whether to use compilation buffer when you create
your command.

After the command is created, you can execute it using
’epx-run-command-in-shell’ (You’ll probably want to bind it).  Completion
for command names is provided.  Executing a command happens in a separate
window (either ’shell’ or compilation).
