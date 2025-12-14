Major mode for editing LUMOS schema files (.lumos).

LUMOS is a type-safe schema language for Solana development that
bridges TypeScript ↔ Rust with guaranteed Borsh serialization
compatibility.

Features:
- Syntax highlighting for LUMOS keywords, types, and attributes
- Smart indentation
- LSP integration via lsp-mode
- Auto-completion and diagnostics
- Comment support (line and block)

Installation:

Using straight.el:
  (use-package lumos-mode
    :straight (lumos-mode :type git :host github :repo "getlumos/lumos-mode")
    :hook (lumos-mode . lsp-deferred))

Using package.el (MELPA):
  (use-package lumos-mode
    :ensure t
    :hook (lumos-mode . lsp-deferred))

Manual installation:
  (add-to-list 'load-path "~/.emacs.d/lisp/lumos-mode")
  (require 'lumos-mode)
  (add-hook 'lumos-mode-hook #'lsp-deferred)
