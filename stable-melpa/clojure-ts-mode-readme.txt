Provides font-lock, indentation, and navigation for the
Clojure programming language (http://clojure.org).

For the tree-sitter grammar this mode is based on,
see https://github.com/sogaiu/tree-sitter-clojure.

Using clojure-ts-mode with paredit or smartparens is highly recommended.

Here are some example configurations:

  ;; require or autoload paredit-mode
  (add-hook 'clojure-ts-mode-hook #'paredit-mode)

  ;; require or autoload smartparens
  (add-hook 'clojure-ts-mode-hook #'smartparens-strict-mode)

See inf-clojure (http://github.com/clojure-emacs/inf-clojure) for
basic interaction with Clojure subprocesses.

See CIDER (http://github.com/clojure-emacs/cider) for
better interaction with subprocesses via nREPL.
