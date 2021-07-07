Send commands to Emacs from programs running in term.el.

In vanilla Emacs, programs running in term.el can send commands
back to Emacs by printing a 'magic escape sequence' which the
terminal emulator parses -- this is how directory tracking
works.  But the list of commands is hard-coded, and you can't add
new ones.

This package lets you add new commands.  It uses a different magic
escape sequence to avoid interfering with the built-in commands,
but the principle is the same.  When a program prints a command, it
won't show up on the screen, but will instead be interpreted by
Emacs.

This is a library, and doesn't make any user-visible changes.  For
an example of something that uses it, see the 'term-alert' package
(https://github.com/calliecameron/term-alert).


Usage

To register a command:

    (add-to-list
     'term-cmd-commands-alist
     '("command" . some-callback-function))

where "command" is the name of the command, and
some-callback-function is the function you want to be called when
the command is run.  The function should take two arguments -- the
first is the command name itself, and the second is the command's
argument.

To send a command, use the emacs-term-cmd script:

    emacs-term-cmd command arg

If called outside Emacs, this does nothing (i.e. it won't mess
things up).

Because the commands are based on terminal output, they work just
as well through nested shells, multiple SSH sessions, or tmux (not
100% reliable -- see comments in emacs-term-cmd).


Installation

Install the term-cmd package from MELPA.

The emacs-term-cmd command will always be on the PATH of any shell
launched from Emacs.  However, for full functionality you should add
~/.emacs.d/term-cmd (or wherever your user-emacs-directory is) to
the PATH in your environment or shell's startup files, too
(e.g. ~/.profile, ~/.bashrc, ~/.zshrc, etc.), on any machine you
often SSH into; this will allow shells inside tmux or on other
machines to send commands back to Emacs on your local machine.
