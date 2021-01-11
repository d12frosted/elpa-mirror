Flymake is the built-in Emacs package to support on-the-fly syntax
checking.  This library adds support for flymake to `package-lint'.
It requires Emacs 26.

Enable it by calling `package-lint-flymake-setup' from a
file-visiting buffer.  To enable in all `emacs-lisp-mode' buffers:

(add-hook 'emacs-lisp-mode-hook #'package-lint-flymake-setup)
