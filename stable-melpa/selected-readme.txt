When `selected-minor-mode' is active, the keybindings in `selected-keymap'
will be enabled when the region is active.  This is useful for commands that
operates on the region, which you only want keybound when the region is
active.

`selected-keymap' has no default bindings.  Bind it yourself:

    (define-key selected-keymap (kbd "u") #'upcase-region)

You can also bind keys specific to a major mode, by creating a keymap named
selected-<major-mode-name>-map (if the map isn't found, tries derived ones):

    (setq selected-org-mode-map (make-sparse-keymap))
    (define-key selected-org-mode-map (kbd "t") #'org-table-convert-region)

There's also a global minor mode available: `selected-global-mode' if you
want selected-minor-mode in all buffers.
