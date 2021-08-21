
Add the following to your .emacs file:

    (require 'highlight-parentheses)

Enable the mode using `M-x highlight-parentheses-mode' or by adding it to a
hook such as `prog-mode-hook'.  You can also enable
`global-highlight-parentheses-mode' which enables it in all buffers
automatically.  Additionally, you can

    (add-hook 'minibuffer-setup-hook #'highlight-parentheses-minibuffer-setup)

in order to enable it also in the minibuffer, e.g., when input is read from
the minibuffer.

The look of the highlighted parens can be customized using these options:

- `highlight-parentheses-colors'
- `highlight-parentheses-background-colors'
- `highlight-parentheses-attributes'

If you set them from Lisp rather than through the customize interface, you
may have to call `highlight-parentheses--color-update' in order to have the
changes affect already opened buffers.

You can also customize the `highlight-parentheses-highlight' face which acts
as a blanket face on top of which the colors and attributes defined by the
three customize options listed above are applied.
