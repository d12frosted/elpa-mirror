Add Swift support to Flycheck using Swift compiler frontend.

Flycheck-swift3 is designed to work with Apple swift-mode.el in the main
Swift repository <https://github.com/apple/swift/>.

Features:

- Apple swift-mode.el support
- Apple Swift 5.4 support
  If you use the toolchain option, you can use the old version of Swift.
- The `xcrun' command support (only on macOS)

Usage:

(with-eval-after-load 'flycheck
  (add-hook 'flycheck-mode-hook #'flycheck-swift3-setup))
