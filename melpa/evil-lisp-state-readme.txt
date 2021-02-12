Adds a new Evil state called --LISP-- (<L>) with mnemonics key bindings
to navigate Lisp code and edit the sexp tree.

Principle:
----------

To execute a command while in normal state, a leader is used.
The leader has to be defined with the function `evil-lisp-state-leader'.
By default, any command when executed sets the current state to
`lisp state`.

For example, to slurp three times while in normal state:
    <leader> 3 s
Or to wrap a symbol in parenthesis then slurping two times:
    <leader> w 2 s

Key Binding  | Function
-------------|------------------------------------------------------------
`leader .'   | switch to `lisp state'
`leader %'   | evil jump item
`leader :'   | ex command
`leader ('   | insert expression before (same level as current one)
`leader )'   | insert expression after (same level as current one)
`leader $'   | go to the end of current sexp
`leader ` k' | hybrid version of kill sexp (can be used in non lisp dialects)
`leader ` p' | hybrid version of push sexp (can be used in non lisp dialects)
`leader ` s' | hybrid version of slurp sexp (can be used in non lisp dialects)
`leader ` t' | hybrid version of transpose sexp (can be used in non lisp dialects)
`leader 0'   | go to the beginning of current sexp
`leader a'   | absorb expression
`leader b'   | forward barf expression
`leader B'   | backward barf expression
`leader c'   | convolute expression
`leader ds'  | delete symbol
`leader dw'  | delete word
`leader dx'  | delete expression
`leader e'   | (splice) unwrap current expression and kill all symbols after point
`leader E'   | (splice) unwrap current expression and kill all symbols before point
`leader h'   | previous symbol
`leader H'   | go to previous sexp
`leader i'   | switch to `insert state`
`leader I'   | go to beginning of current expression and switch to `insert state`
`leader j'   | next closing parenthesis/bracket/brace
`leader J'   | join expression
`leader k'   | previous opening parenthesis/bracket/brace
`leader l'   | next symbol
`leader L'   | go to next sexp
`leader p'   | paste after
`leader P'   | paste before
`leader r'   | raise expression (replace parent expression by current one)
`leader s'   | forwared slurp expression
`leader S'   | backward slurp expression
`leader t'   | transpose expression
`leader u'   | undo
`leader U'   | got to parent sexp backward
`leader C-r' | redo
`leader v'   | switch to `visual state`
`leader V'   | switch to `visual line state`
`leader C-v' | switch to `visual block state`
`leader w'   | wrap expression with parenthesis
`leader W'   | unwrap expression
`leader y'   | copy expression

Configuration:
--------------

No default binding comes with the package, you have to explicitly
bind the lisp state to a key with the function `evil-lisp-state-leader'
For instance: `(evil-lisp-state-leader ", l")'

Key bindings are set only for `emacs-lisp-mode' by default.
It is possible to add major modes with the variable
`evil-lisp-state-major-modes'.

It is also possible to define the key bindings globally by
setting `evil-lisp-state-global' to t. In this case
`evil-lisp-state-major-modes' has no effect.

If you don't want commands to enter in `lisp state' by default
set the variable `evil-lisp-state-enter-lisp-state-on-command'
to nil. Then use the `.' to enter manually in `lisp state'
