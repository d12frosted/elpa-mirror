This package provides a sort of right-click contextual menu for
Emacs, accessed through the `embark-act' command (which you should
bind to a convenient key), offering you relevant actions to use on
a target determined by the context:

- In the minibuffer, the target is the current best completion
 candidate.
- In the `*Completions*' buffer the target is the completion at point.
- In a regular buffer, the target is the region if active, or else the
 file, symbol or url at point.

The type of actions offered depend on the type of the target:

- For files you get offered actions like deleting, copying,
 renaming, visiting in another window, running a shell command on the
 file, etc.
- For buffers the actions include switching to or killing the buffer.
- For package names the actions include installing, removing or
 visiting the homepage.

Everything is easily configurable: determining the current target,
classifying it, and deciding with actions are offered for each type
in the classification.  The above introduction just mentions part of
the default configuration.

Configuring which actions are offered for a type is particularly
easy and requires no programming: the `embark-keymap-alist'
variable associates target types with variable containing keymaps,
and those keymaps containing binds for the actions.  For example,
in the default configuration the type `file' is associated with the
symbol `embark-file-keymap'.  That symbol names a keymap with
single-letter key bindings for common Emacs file commands, for
instance `c' is bound to `copy-file'.  This means that if while you
are in the minibuffer after running a command that prompts for a
file, such as `find-file' or `rename-file', you can copy a file by
running `embark-act' and then pressing `c'.

These action keymaps are very convenient but not strictly necessary
when using `embark-act': you can use any command that reads from the
minibuffer as an action and the target of the action will be inserted
at the first minibuffer prompt.  After running `embark-act' all of your
key bindings and even `execute-extended-command' can be used to run a
command.  The action keymaps are normal Emacs keymaps and you should
feel free to bind in them whatever commands you find useful as actions.

The actions in `embark-general-map' are available no matter what
type of completion you are in the middle of.  By default this
includes bindings to save the current candidate in the kill ring
and to insert the current candidate in the previously selected
buffer (the buffer that was current when you executed a command
that opened up the minibuffer).

You can read about the Embark GitHub project wiki:
https://github.com/oantolin/embark/wiki/Default-Actions

Besides acting individually on targets, Embark lets you work
collectively on a set of target candidates.  For example, while
you are in the minibuffer the candidates are simply the possible
completions of your input.  Embark provides three commands to work
on candidate sets:

- The `embark-collect-snapshot' command produces a buffer listing
  all candidates, for you to peruse and run actions on at your
  leisure.  The candidates can be viewed in a grid or as a list
  showing additional annotations.  The `embark-collect-live'
  variant produces "live" Embark Collect buffers, meaning they
  autoupdate as the set of candidates changes.

- The `embark-export' command tries to open a buffer in an
  appropriate major mode for the set of candidates.  If the
  candidates are files export produces a Dired buffer; if they are
  buffers, you get an Ibuffer buffer; and if they are packages you
  get a buffer in package menu mode.

These are always available as "actions" (although they do not act
on just the current target but on all candidates) for embark-act and
are bound to S, L and E, respectively, in embark-general-map.  This
means that you do not have to bind your own key bindings for these
(although you can, of course), just a key binding for `embark-act'.
