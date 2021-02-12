Provides a number of interactive functions for easily navigating
between blocks of code at the same level of indentation.

This package does not bind any keys for you.
Here are some example bindings for evil-mode:

  (define-key evil-motion-state-map "H" 'block-nav-previous-indentation-level)
  (define-key evil-motion-state-map "J" 'block-nav-next-block)
  (define-key evil-motion-state-map "K" 'block-nav-previous-block)
  (define-key evil-motion-state-map "L" 'block-nav-next-indentation-level)

  ;; Although this may not be desirable since it overrides vim keys you may use.
