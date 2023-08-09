Flymake backend for Clippy, the Rust linter.

(use-package flymake-clippy
  :hook (rust-mode . flymake-clippy-setup-backend))
