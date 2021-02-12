This mode focuses on providing operations similar to GUI context menus.
It not only activates commands, it also supports operations on Region.

Put the following into your .emacs file (~/.emacs.d/init.el) to enable context menu.

    (right-click-context-mode 1)

This function does not depend on GUI, it is fully available on terminal.
The menu is launched by "right click" (<mouse-3>) by default, but you can assign any key.

    (define-key right-click-context-mode-map (kbd "C-c :") 'right-click-context-menu)

This menu can be constructed with a simple DSL based on S-expression.
Additional information can be found in README and implementation code.

## Context-menu construction DSL

For example, the following code adds undo and redo to the beginning of the context menu.

    (setq right-click-context-global-menu-tree
          (append
           '((\"Undo\" :call (if (fboundp 'undo-tree-undo) (undo-tree-undo) (undo-only)))
             (\"Redo\"
             :call (if (fboundp 'undo-tree-redo) (undo-tree-redo))
             :if (and (fboundp 'undo-tree-redo) (undo-tree-node-previous (undo-tree-current buffer-undo-tree)))))
           right-click-context-global-menu-tree))
