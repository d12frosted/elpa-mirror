This package provides a way to invoke Git shell command from minibuffer.
There is no major-mode nor minor-mode, so all you need is to remember
usual Git subcommands and options.

This package provides only one user command: type

    M-x RET git-command

to input Git shell command to minibuffer that you want to invoke.
Before running git command `$GIT_EDITOR` and `$GIT_PAGER` are set nicely so
that you can seamlessly edit files or view outputs with Emacs you are
currently working on.

Optionally, you can give prefix argument to create a new buffer for that git
invocation.


Completion
----------

It is highly recommended to Install `pcmpl-git` with this package to enable
completion when entering git command interactively.
