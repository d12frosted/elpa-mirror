`let-completion-mode' makes Emacs Lisp in-buffer completion
aware of lexically enclosing binding forms.  Local variables
are promoted to the top of the candidate list and annotated
with a two-column display: a detail column showing the binding
value (or kind hint or enclosing function context) and a tag
column showing the provenance of the binding (e.g. "let",
"arg", "iter").  Full pretty-printed fontified expressions
appear in corfu-popupinfo or any completion UI that reads
`:company-doc-buffer'.

Binding form recognition is data-driven via a registry of
descriptors stored as symbol properties.  46 built-in forms
(`let', `let*', `defun', `lambda', `cl-defun', `dolist',
`condition-case', `cl-flet', `cl-letf', `cl-defmethod', etc.)
are registered at load time.  Third-party macros opt in by
calling `let-completion-register-binding-form' with a plist
describing where bindings sit and what shape they take, or by
providing a custom extractor function for exotic syntax.

The package installs a single around-advice on
`elisp-completion-at-point' when enabled and removes it when
disabled.  Loading produces no side effects beyond symbol
property registrations.

Usage:

    (add-hook 'emacs-lisp-mode-hook #'let-completion-mode)

To show only local candidates for a single invocation:

    M-x let-completion-locals-only-complete

Or persistently with `let-completion-locals-only-mode'.

Recommended configuration for the detail column:

    (setq let-completion-tag-kind-alist
          '((lambda          . "λ")
            (function        . "𝘧")
            (cl-function     . "𝘧")
            (make-hash-table . "#s")
            (quote           . "'")
            (cons            . "cons")
            (list            . "list")))

Customize `let-completion-inline-max-width' to control the
threshold for inline value display.  Customize
`let-completion-tag-kind-alist' to map value heads to kind
strings.  Customize `let-completion-detail-functions' for full
control over the detail column content.

See the README for the complete recommended configuration
including tag shortening, kind alist, and face overrides.
