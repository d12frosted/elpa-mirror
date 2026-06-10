Anju is a project to align mouse interactions in Emacs with contemporary
(circa 2026) expectations. Effort towards this alignment is made in the
following areas:

- Context-sensitive menus
- De-emphasis of middle mouse button usage (binding <mouse-2>)
- Support direct manipulation when possible
- Re-organization of the main menu bar

The features offered by Anju are opinionated, but avoids unconventional
behavior. Anju aspires to bring a calmer mouse experience to Emacs.

INSTALLATION

To install Anju, add the command `anju-init' to your Emacs initialization
file.

    (anju-init)

This command will initialize `context-menu-mode' and reconfigure the
following mouse menus and bindings:

- Legacy mouse bindings
- Mode line bindings
- Main menu
- Context menus for different modes

The `anju-init' command can be customized to preference. See Info node
`(anju) Anju Initialization (anju-init)' for more detail.

While not required, the following additions to your Emacs initialization
file can further enhance your mouse experience:

- Enable `org-mouse'

    (require 'org-mouse)

- Add Markdown export support to Org mode
  - `M-x' `customize-variable' `org-export-backends', check `md' option.

- Globally bind `C-x 1' to `anju-toggle-one-window'.

    (keymap-global-set "C-x 1" #'anju-toggle-one-window)

- Set `use-file-dialog' to `t' to support mouse-driven-only dialog
  interactions, or `nil' to always get a mini-buffer prompt.
