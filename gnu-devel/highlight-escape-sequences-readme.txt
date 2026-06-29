This global minor mode highlights escape sequences in strings and
other kinds of literals with `hes-escape-sequence-face' and with
`hes-escape-backslash-face'. They inherit from faces
`font-lock-regexp-grouping-construct' and
`font-lock-regexp-grouping-backslash' by default, respectively.

It currently supports `ruby-mode', `emacs-lisp-mode', JS escape
sequences in both popular modes, C escapes is `c-mode', `c++-mode',
`objc-mode' and `go-mode',
and Java escapes in `java-mode' and `clojure-mode'.

To enable it elsewhere, customize `hes-mode-alist'.

Put this in the init file:

(hes-mode)