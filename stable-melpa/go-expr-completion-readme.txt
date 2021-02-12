
`go-expr-completion.el' to complete a left-hand side from given expression for Go.


To use this package, add these lines to your init.el or .emacs file:

(with-eval-after-load 'go-mode
  (define-key go-mode-map (kbd "C-c C-c") 'go-expr-completion))

----------------------------------------------------------------

Usage
Navigate your cursor to the arbitrary expression, type `C-c C-c` or `M-x go-expr-completion`,
and then this plugin completes the left-hand side for given expression (and `if err...` if necessary).
