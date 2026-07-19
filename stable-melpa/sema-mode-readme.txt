A major mode for editing Sema (.sema) files — a Lisp dialect with
first-class LLM primitives.  Provides syntax highlighting, indentation,
and REPL integration, plus LSP hookup via eglot or lsp-mode (`sema lsp').

Install from MELPA:
  M-x package-install RET sema-mode

Or from source:
  (add-to-list 'load-path "/path/to/emacs-sema")
  (require 'sema-mode)

If you use eglot, register Sema's language server (`sema lsp') so that
`M-x eglot' starts it in Sema buffers:

  (with-eval-after-load 'eglot #'sema-register-with-eglot)

For automatic startup, also add `eglot-ensure' to the mode hook:

  (add-hook 'sema-mode-hook #'eglot-ensure)

Homepage: https://sema-lang.com
Source:   https://github.com/sema-lisp/emacs-sema
