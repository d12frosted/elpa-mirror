A simple Emacs interface for the Mercurial (Hg) Distributed SCM.

Quick Guide
-----------

After the installation, an ``aHg`` menu appears as a child of the standard
``Tools`` menu of Emacs. The available commands are:

Status:
   Shows the status of the current working directory, much like the
   ``cvs-examine`` command of PCL-CVS.

Log Summary:
   Shows a table with a short change history of the current working
   directory.

Detailed Log:
   Shows a more detailed change history of the current working directory.

Commit Current File:
   Commits the file you are currently visiting.

View Changes of Current File:
   Displays changes of current file wrt. the tip of the repository.

Mercurial Queues:
   Support for basic commands of the mq extension.

Execute Hg Command:
   Lets you execute an arbitrary hg command. The focus goes to the
   minibuffer, where you can enter the command to execute. You don't have
   to type ``hg``, as this is implicit. For example, to execute ``hg
   outgoing``, simply enter ``outgoing``. Pressing ``TAB`` completes the
   current command or file name.

Help on Hg Command:
   Shows help on a given hg command (again, use ``TAB`` to complete partial
   command names).


aHg buffers
~~~~~~~~~~~

The ``Status``, ``Log Summary``, ``Detailed Log`` and the ``List of MQ
Patches`` commands display their results on special buffers. Each of these
has its own menu, with further available commands.


Customization
~~~~~~~~~~~~~

There are some options that you can customize (e.g. global keybindings or
fonts). To do so, use ``M-x customize-group RET ahg``.
