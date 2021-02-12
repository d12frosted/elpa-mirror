Usage:
  (require 'flymake-rust)
  (add-hook 'rust-mode-hook 'flymake-rust-load)

If you want to use rustc compiler, you must add following string:
  (setq flymake-rust-use-cargo 1)

Uses flymake-easy, from https://github.com/purcell/flymake-easy
