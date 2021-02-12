This Flycheck extension configures Flycheck automatically for the current
Cargo project.

# Setup

    (with-eval-after-load 'rust-mode
      (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

# Usage

Just use Flycheck as usual in your Rust/Cargo projects.
