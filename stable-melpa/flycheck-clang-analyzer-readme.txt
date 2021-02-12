This packages integrates the Clang Analyzer `clang --analyze` tool with
flycheck to automatically detect any new defects in your code on the fly.

It depends on and leverages either the existing c/c++-clang flycheck
backend, or `emacs-cquery', `emacs-ccls' `irony-mode' or `rtags' to provide
compilation arguments etc and so provides automatic static analysis with
zero setup.

Automatically chains itself as the next checker after c/c++-clang, lsp-ui,
irony and rtags flycheck checkers.

;; Setup

(with-eval-after-load 'flycheck
   (require 'flycheck-clang-analyzer)
   (flycheck-clang-analyzer-setup))
