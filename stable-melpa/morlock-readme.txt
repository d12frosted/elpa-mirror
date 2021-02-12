This library defines more font-lock keywords for Emacs lisp.

These keyword variables are available:

`morlock-el-font-lock-keywords' expressions that aren't
    covered by the default keywords.
`morlock-op-font-lock-keywords' expressions that would be
    operators in other languages: `or' `and' `not'.
`morlock-cl-font-lock-keywords' expressions that used to be
    covered by the default keywords but aren't anymore since
    the `cl-' prefix was added.
`morlock-font-lock-keywords' combines the above tree.

To use `morlock-font-lock-keywords' in `emacs-lisp-mode' and
`lisp-interaction-mode' enable `global-morlock-mode'.

If you want to only enable some of the keywords and/or only in
`emacs-lisp-mode', then require `morlock' and activate the keywords
in one of the variables using `font-lock-add-keywords'.  Doing so
is also slightly more efficient.

    (font-lock-add-keywords 'emacs-lisp-mode
                             morlock-el-font-lock-keywords)

Please let me know if you think anything should be added here.
