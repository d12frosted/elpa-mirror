Provides font-lock, indentation, navigation and basic refactoring for the
Clojure programming language (http://clojure.org).

Using clojure-mode with paredit or smartparens is highly recommended.

Here are some example configurations:

  ;; require or autoload paredit-mode
  (add-hook 'clojure-mode-hook #'paredit-mode)

  ;; require or autoload smartparens
  (add-hook 'clojure-mode-hook #'smartparens-strict-mode)

See inf-clojure (http://github.com/clojure-emacs/inf-clojure) for
basic interaction with Clojure subprocesses.

See CIDER (http://github.com/clojure-emacs/cider) for
better interaction with subprocesses via nREPL.
