Eldev (Elisp Development Tool) is an Emacs-based build system,
targeted solely at Elisp projects.  It is an alternative to Cask.
Unlike Cask, Eldev itself is fully written in Elisp and its
configuration files are also Elisp programs.  If you are familiar
with Java world, Cask can be seen as a parallel to Maven — it uses
project description, while Eldev is sort of a parallel to Gradle —
its configuration is a program on its own.

Eldev is a command-line utility that runs Emacs in batch mode.
Therefore, you should not (or at least need not) install it in your
Emacs.  Instead, use one of the following ways.

If you have a catch-all directory for executables.

1. From this directory (e.g. `~/bin') execute:

     $ curl -fsSL https://raw.github.com/doublep/eldev/master/bin/eldev > eldev && chmod a+x eldev

No further steps necessary — Eldev will bootstrap itself as needed
on first invocation.

If you don't have such a directory and don't care where `eldev'
executable is placed.

1. Run:

     $ curl -fsSL https://raw.github.com/doublep/eldev/master/webinstall/eldev | sh

   This will install eldev script to ~/.eldev/bin.

2. Add the directory to your $PATH; e.g. in ~/.profile add this:

     export PATH="$HOME/.eldev/bin:$PATH"

Afterwards Eldev will bootstrap itself as needed on first
invocation.

For further help and more ways to install, please see the homepage:

  https://github.com/doublep/eldev
