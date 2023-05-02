Tool for inspection of Emacs Lisp objects.

Usage:

    M-x `inspector-inspect-expression' to evaluate an elisp expression and inspect the result.
    M-x `inspector-inspect-last-sexp' to evaluate last sexp in current buffer and inspect the result.

    Or add the following to your config:
    (define-key global-map [remap eval-last-sexp] #'inspector-eval-last-sexp)
    (define-key global-map [remap eval-expression] #'inspector-eval-expression)
    and then use C-u C-x C-e and C-u M-: as alternatives to
    `eval-last-sexp' and `eval-expression'.

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