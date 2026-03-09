`let-completion-mode' makes Emacs Lisp in-buffer completion aware of
lexically enclosing binding forms.  Local variables from `let',
`let*', `when-let*', `if-let*', `and-let*', `dolist', and `dotimes'
are promoted to the top of the candidate list, annotated with their
binding values when short enough or a [local] tag otherwise, and
shown in full via pretty-printed fontified expressions in
corfu-popupinfo or any completion UI that reads `:company-doc-buffer'.

Names that the built-in `elisp--local-variables' misses (untrusted
buffers, macroexpansion failure) are injected into the completion
table directly so they always appear as candidates.  For `if-let'
and `if-let*', bindings are suppressed in the else branch where
they are not in scope.

The package installs a single around-advice on
`elisp-completion-at-point' when enabled and removes it when
disabled.  Loading the file produces no side effects.

Usage:

    (add-hook 'emacs-lisp-mode-hook #'let-completion-mode)

Customize `let-completion-inline-max-width' to control the maximum
printed width for inline value annotations, or set it to nil to
always show [local] instead.
