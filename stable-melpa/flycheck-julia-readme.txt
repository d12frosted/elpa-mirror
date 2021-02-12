This Flycheck extension provides a `Lint.jl' integration for flycheck (see
URL `https://github.com/tonyhffong/Lint.jl') to check Julia buffers for
errors.

# Setup

Add the following to your init file:

     (add-to-list 'load-path "/path/to/directory/containing/flycheck-julia.el/file")
     (require 'flycheck-julia)
     (flycheck-julia-setup)
     (add-to-list 'flycheck-global-modes 'julia-mode)
     (add-to-list 'flycheck-global-modes 'ess-julia-mode)

# Usage

Just use Flycheck as usual in julia-mode buffers. Flycheck will
automatically use the `flycheck-julia` syntax checker.
