A major mode for Deno.

`deno-ts-mode' is derived from `typescript-ts-mode' so it depends
on the same TypeScript tree-sitter parsers.  Install both the TSX
and TypeScript parsers for full deno syntax support (see README for
full details).

This package helps solve some of the problems that arise from deno
and TypeScript sharing the same file extension.  With
`deno-ts-setup-auto-mode-alist', `deno-ts-mode' will check for the
presence of a Deno config file when a major mode is selected for a
".ts" or ".tsx" file.  When the config file is located,
`deno-ts-mode' is selected.  Otherwise, `typescript-ts-mode' and
`tsx-ts-mode' are selected as fallbacks.  This function is
optional, so you can determine your auto-mode bindings however you
wish.

Example configuration:

(use-package deno-ts-mode
  :config
  (deno-ts-setup-auto-mode-alist))

(use-package eglot
  :ensure t
  :hook ((deno-ts-mode . eglot-ensure))
  :config
  (deno-ts-setup-eglot))
