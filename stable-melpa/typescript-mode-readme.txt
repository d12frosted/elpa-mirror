This is based on Karl Landstrom's barebones typescript-mode. This
is much more robust and works with cc-mode's comment filling
(mostly).
The modifications to the original javascript.el mode mainly consisted in
replacing "javascript" with "typescript"

The main features of this typescript mode are syntactic
highlighting (enabled with `font-lock-mode' or
`global-font-lock-mode'), automatic indentation and filling of
comments.


General Remarks:

XXX: This mode assumes that block comments are not nested inside block
XXX: comments

Exported names start with "typescript-"; private names start with
"typescript--".
