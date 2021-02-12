Insert Elisp result as comment in scratch buffer.

To use this package, just bind `scratch-comment-eval-sexp'

  (define-key lisp-interaction-mode-map "\C-j" 'scratch-comment-eval-sexp)

To restore,

  (define-key lisp-interaction-mode-map "\C-j" 'eval-print-last-sexp)
