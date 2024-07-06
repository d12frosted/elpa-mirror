  For Emacs *users*:

    This package provides an interactive command to easily produce
    a keybinding cheat-sheet "on-the-fly", and then to launch any
    command on the cheat-sheet list. At its simplest, it gives the
    user a list of keybindings for commands specific to the current
    buffer's major-mode, but it's trivially simple to ask it to
    build an alternative (see below).

    Use this package to: learn keybindings; learn what commands are
    available specifically for the current buffer; run a command
    from a descriptive list; and afterwards return to work quickly.

  For Emacs *programmers*:

    This package provides a simple, flexible way to produce custom
    keybinding cheat-sheets and command launchers for sets of
    commands, with each command being described, along with its
    direct keybinding for direct use without the launcher (see
    below).

  If you've ever used packages such as 'ivy' or 'magit', you've
  probably benefited from each's custom combination keybinding
  cheatsheet and launcher: 'hydra' in the case of 'ivy', and
  'transient' for 'magit'. The current package 'key-assist' offers
  a generic and very simple alternative requiring only the
  'completing-read' function commonly used in core vanilla Emacs.
  'key-assist' is trivial to implement "on-the-fly" interactively
  for any buffer, and programmatically much simpler to customize
  that either 'hydra' or 'transient'. And it only requires the
  Emacs core function 'completing-read'.

