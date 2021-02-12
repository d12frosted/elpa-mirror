This is a major mode for Meson build system files.  Syntax
highlighting works reliably.  Indentation works too, but there are
probably cases, where it breaks.  Simple completion is supported
via `completion-at-point'.  To start completion, use either C-M-i
or install completion frameworks such as `company'.  To enable
`company' add the following to your .emacs:

    (add-hook 'meson-mode-hook 'company-mode)
