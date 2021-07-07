Press `fd` quickly to:
----------------------

  - escape from all stock evil states to normal state
  - escape from evil-lisp-state to normal state
  - escape from evil-iedit-state to normal state
  - abort evil ex command
  - quit minibuffer
  - quit compilation buffers
  - abort isearch
  - quit ibuffer
  - quit image buffer
  - quit magit buffers
  - quit help buffers
  - quit apropos buffers
  - quit ert buffers
  - quit undo-tree buffer
  - quit paradox
  - quit gist-list menu
  - quit helm-ag-edit
  - hide neotree buffer
And more to come !

Configuration:
--------------

The key sequence can be customized with the variable
`evil-escape-key-sequence'.

The delay between the two key presses can be customized with
the variable `evil-escape-delay'. Default is `0.1'.

The key sequence can be entered in any order by setting
the variable `evil-escape-unordered-key-sequence' to non nil.

A major mode can be excluded by adding it to the list
`evil-escape-excluded-major-modes'.

An inclusive list of major modes can defined with the variable
`evil-escape-enable-only-for-major-modes'. When this list is
non-nil then evil-escape is enabled only for the major-modes
in the list.

A list of zero arity functions can be defined with the variable
`evil-escape-inhibit-functions', if any of these functions return
non nil then evil-escape is inhibited.
It is also possible to inhibit evil-escape in a let binding by
setting the `evil-escape-inhibit' variable to non nil.

It is possible to bind `evil-escape' function directly, for
instance to execute evil-escape with `C-c C-g':

(global-set-key (kbd "C-c C-g") 'evil-escape)

More information in the readme of the repository:
https://github.com/syl20bnr/evil-escape
