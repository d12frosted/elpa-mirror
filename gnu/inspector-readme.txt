Tool for inspection of Emacs Lisp objects.

Usage:

    M-x `inspector-inspect-expression' to evaluate an elisp expression and inspect the result.
    M-x `inspector-inspect-last-sexp' to evaluate last sexp in current buffer and inspect the result.
    M-x `inspector-inspect-defun' to evaluate the top-level defun at point at inspect the result.

Inside the inspector:

    M-x `inspector-pop' bound to letter l, to navigate to previous object.
    M-x `inspector-quit' bound to letter q, to exit the inspector.

Also, M-x `forward-button' and M-x `backward-button' are conveniently bound to n and p.
They can be used for fast navigation across the buttons that the inspector displays.

Finally, you can use M-x `eval-expression' bound to letter e,
to evaluate an elisp expression using the object currently being inspected (it is bound to *).

From the Emacs debugger:

When on an Emacs debugging backtrace, press letter i to inspect the pointed frame and its local variables.

When on edebug-mode, use C-c C-i for inspecting expressions in the debugger.

From *Help* buffers:

When in a *Help* buffer, such as the ones created from `describe-function', `describe-variable',
`describe-keymap', and `describe-symbol', you can use M-x `inspector-inspect-help-buffer-expression'
to inspect the symbol associated with that Help buffer.