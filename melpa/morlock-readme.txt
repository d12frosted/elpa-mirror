This library defines more font-lock keywords for Emacs Lisp.

These keyword variables are available:

`morlock-el-font-lock-keywords' expressions that aren't
    covered by the default keywords.
`morlock-op-font-lock-keywords' expressions that would be
    operators in other languages: `xor', `not' and `null'.
`morlock-font-lock-keywords' combines the above two.

To use `morlock-font-lock-keywords' in `emacs-lisp-mode' and
`lisp-interaction-mode' enable `global-morlock-mode'.

If you want to only enable some of the keywords and/or only in
`emacs-lisp-mode', then require `morlock' and activate the keywords
in one of the variables using `font-lock-add-keywords'.  Doing so
is also slightly more efficient.

    (font-lock-add-keywords 'emacs-lisp-mode
                             morlock-el-font-lock-keywords)
