This package provides tree-sitter based syntax highlighting and
indentation for embedded languages inside JavaScript and TypeScript
tagged template literals (e.g., html`...` and css`...` as used by
Lit and others).

Requires Emacs 30+ with tree-sitter support and the javascript,
typescript grammars installed, plus grammars for each embedded
language you configure.

Usage:
  (add-hook 'js-ts-mode-hook #'template-literals-ts-mode)
  (add-hook 'typescript-ts-mode-hook #'template-literals-ts-mode)

By default, html`...` and css`...` tagged literals are supported.
Customize `template-literals-ts-tag-grammar-alist' to add more:
  (add-to-list 'template-literals-ts-tag-grammar-alist '("sql" . sql))
