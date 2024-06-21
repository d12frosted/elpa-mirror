Variant Lisp Interaction mode for easier interleaving of paragraphs of
plain text with Lisp code.  This means you can have

    ;; This buffer is for text that is not saved ...
    ;; To create a file, visit it with C-x C-f and ...

    (here is some Lisp)

    Here is a plain text paragraph )( including some unmatched parentheses.
    Uh oh!  Paredit won't like that.

    (here is some more Lisp)

but (e.g.) Paredit won't complain about the unmatched parentheses.
Indeed, the whole plain text paragraph is font-locked as a comment.

If you use Paredit but want to be able to use *scratch* for both Lisp
interaction and blocks of plain text, then this mode is for you.
Also compatible with the `orgalist-mode' and `orgtbl-mode' minor modes.

To enable this mode after installing this file, simply customise
`initial-major-mode' to `literate-scratch-mode'.