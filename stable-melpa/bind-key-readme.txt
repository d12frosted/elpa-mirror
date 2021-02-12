If you have lots of keybindings set in your .emacs file, it can be hard to
know which ones you haven't set yet, and which may now be overriding some
new default in a new emacs version.  This module aims to solve that
problem.

Bind keys as follows in your .emacs:

  (require 'bind-key)

  (bind-key "C-c x" 'my-ctrl-c-x-command)

If the keybinding argument is a vector, it is passed straight to
`define-key', so remapping a key with `[remap COMMAND]' works as
expected:

  (bind-key [remap original-ctrl-c-x-command] 'my-ctrl-c-x-command)

If you want the keybinding to override all minor modes that may also bind
the same key, use the `bind-key*' form:

  (bind-key* "<C-return>" 'other-window)

If you want to rebind a key only in a particular keymap, use:

  (bind-key "C-c x" 'my-ctrl-c-x-command some-other-mode-map)

To unbind a key within a keymap (for example, to stop your favorite major
mode from changing a binding that you don't want to override everywhere),
use `unbind-key':

  (unbind-key "C-c x" some-other-mode-map)

To bind multiple keys at once, or set up a prefix map, a `bind-keys' macro
is provided.  It accepts keyword arguments, please see its documentation
for a detailed description.

To add keys into a specific map, use :map argument

   (bind-keys :map dired-mode-map
              ("o" . dired-omit-mode)
              ("a" . some-custom-dired-function))

To set up a prefix map, use `:prefix-map' and `:prefix' arguments (both are
required)

   (bind-keys :prefix-map my-customize-prefix-map
              :prefix "C-c c"
              ("f" . customize-face)
              ("v" . customize-variable))

You can combine all the keywords together.  Additionally,
`:prefix-docstring' can be specified to set documentation of created
`:prefix-map' variable.

To bind multiple keys in a `bind-key*' way (to be sure that your bindings
will not be overridden by other modes), you may use `bind-keys*' macro:

   (bind-keys*
    ("C-o" . other-window)
    ("C-M-n" . forward-page)
    ("C-M-p" . backward-page))

After Emacs loads, you can see a summary of all your personal keybindings
currently in effect with this command:

  M-x describe-personal-keybindings

This display will tell you if you've overridden a default keybinding, and
what the default was.  Also, it will tell you if the key was rebound after
your binding it with `bind-key', and what it was rebound it to.
