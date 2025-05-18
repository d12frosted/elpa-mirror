epx is a command runner and manager for project.el in Emacs.
’epx’ stands for ’Emacs Project eXecutor’.

Warning! Only works in Unix-like systems for now due to
how environment variables are processed.  This is temporary.

It stores commands in .dir-locals.el or any other dir-locals-file that
you set.  It allows you to add or remove commands, no editing
capabilities for now.  You can choose whether to use compilation
buffer when you create your command.

After the command is created, you can execute it using
’epx-run-command-in-shell’ (You’ll probably want to bind it).  Completion
for command names is provided.  Executing a command happens in a separate
window (either ’shell’ or compilation).
