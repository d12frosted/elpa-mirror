Seethru: Easily change Emacs' frame transparency

The use of seethru is very simple. To set the transparency to an
absolute value:

    (seethru 55)

To set the transparency relative to its current value:

    (seethru-relative -10)

This is usually used to bind to a key, like so:

    (global-set-key (kbd "<M-wheel-up>")
                    (lambda ()
                      (seethru-relative -10)))

To set up recommended keybindings, which are `C-c 8' to reduce
transparency and `C-c 9' to increase it, as well as shifted
keybinds which do the same, but slower:

    (seethru-recommended-keybinds)

To set up mouse bindings, which are wheel-up to increase
transparency and wheel-down to decrease it:

    (seethru-mouse-bindings)

You can optionally change the modifier used by either
`seethru-recommended-keybinds' or `seethru-mouse-bindings' simply
by passing an argument in, for example:

    (seethru-recommended-keybinds "C-x") ;; "C-x 8" and "C-x 9"
    (seethru-mouse-bindings "C") ;; hold control while wheeling
                                 ;; mouse to change transparency
