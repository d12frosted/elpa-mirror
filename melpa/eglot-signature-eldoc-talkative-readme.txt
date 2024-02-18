Eglot does not instruct ElDoc to echo the field "documentation" of
LSP-objects "signature information" and "parameter information"
(into the echo-area).  To read those fields, the user instead has
to open the *eldoc* buffer by calling the command
`eldoc-doc-buffer' (bound to C-h . by default).

This package offers a function, `eglot-signature-eldoc-talkative',
that makes Eglot instruct ElDoc to echo the field "documentation"
of LSP-objects "signature information" and "parameter information"
(into the echo-area).
