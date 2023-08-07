Ported from https://github.com/purcell/flycheck-relint

Flymake is the built-in Emacs package to support on-the-fly syntax
checking.  This library adds support for flymake to `relint'.
It requires Emacs 26.

Enable it by calling `flymake-relint-setup' from a
file-visiting buffer.  To enable in all `emacs-lisp-mode' buffers:

(add-hook 'emacs-lisp-mode-hook #'flymake-relint-setup)
