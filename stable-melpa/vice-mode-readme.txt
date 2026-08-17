Vice brings Vim's composable "operator + text object" editing to
Emacs without modal state.  The `vice-key-prefix' key (default
"C-c v") runs `vice-dispatch', which reads a whole operation of the
form

    [count] operator [a|i] object

For example "C-c v d a (" deletes the surrounding parentheses,
"C-c v y i \"" copies the contents of a string, and
"C-c v 2 d a (" deletes two levels of enclosing parentheses.

Operators come from `vice-operator-alist' (d y ; v r =) and
objects from `vice-object-alist' (brackets, strings, word, symbol,
paragraph, function, ...).  Objects resolve through syntax-table,
thing-at-point, and tree-sitter providers, so the grammar works
beyond Lisp.
