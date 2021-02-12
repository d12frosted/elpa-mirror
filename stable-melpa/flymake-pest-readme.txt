A flymake handler for Pest files.

To use this pacakge, simply add below code your init.el

  (with-eval-after-load 'pest-mode
    (require 'flymake-pest)
    (add-hook 'pest-mode-hook #'flymake-pest-setup)
    (add-hook 'pest-input-mode-hook #'flymake-pest-input-setup))
