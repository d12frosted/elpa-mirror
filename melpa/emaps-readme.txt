Emaps provides utilities for working with keymaps and keybindings in Emacs.

Emaps provides the `emaps-define-key' function that provides the same
functionality as `define-key', but allows multiple keys to be defined
at once, for example:

   (emaps-define-key keymap
     "a" 'fun-a
     "b" 'fun-b
     "c" 'fun-c) ; etc.

Emaps also provides the following functions for viewing keymaps:

   * `emaps-describe-keymap-bindings' provides a *Help* buffer similar
      to `describe-bindings', but works for any keymap.
   * `emaps-describe-keymap' provides a *Help* buffer similar to
     `describe-variable', but attempts to normalize character display
     where possible.
