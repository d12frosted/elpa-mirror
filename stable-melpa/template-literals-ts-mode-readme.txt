This package provides tree-sitter based syntax highlighting and
indentation for HTML and CSS inside JavaScript and TypeScript tagged
template literals (e.g., html`...` and css`...` as used by Lit and others).

Requires Emacs 30+ with tree-sitter support and the javascript,
typescript, css, and html grammars installed.

Usage:
  (add-hook 'js-ts-mode-hook #'template-literals-ts-mode)
  (add-hook 'typescript-ts-mode-hook #'template-literals-ts-mode)
