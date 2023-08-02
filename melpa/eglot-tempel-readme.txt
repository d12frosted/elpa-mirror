LSP can provide inline/template hinting for function completion,
Currently eglot only checks for yasnippet to enable this
feature.  This package patches the function or mocks yasnippet
(depending on what is installed) to use tempel.el for that feature
by translating the LSP template into a sexp used by tempel.el
