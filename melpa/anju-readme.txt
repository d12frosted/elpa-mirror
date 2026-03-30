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

Basic installation of Anju composes of two parts:

1. Turn on `context-menu-mode' to major modes of preference. This is done
   using the `add-hook' function as shown below.

    (add-hook 'prog-mode-hook #'context-menu-mode)
    (add-hook 'text-mode-hook #'context-menu-mode)
    (add-hook 'dired-mode-hook #'context-menu-mode)
    (add-hook 'shell-mode-hook #'context-menu-mode)

2. Call `anju-init' in your Emacs initialization file.

    (anju-init)

The `anju-init' command can be customized to preference. Read more on this in
the Anju User Guide in Info.
