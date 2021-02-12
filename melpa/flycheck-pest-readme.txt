Flycheck integration for Pest.

To use this package, add following code to your init file.

  (with-eval-after-load 'flycheck
    (require 'flycheck-pest)
    (flycheck-pest-setup))
