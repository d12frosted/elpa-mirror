A major mode for Deno.

`deno-ts-mode' is derived from `typescript-ts-mode' so it depends
on the same TypeScript tree-sitter parsers.  Install both the TSX
and TypeScript parsers for full deno syntax support (see README for
full details).

This package helps solve some of the problems that arise from Deno
and TypeScript sharing the same file extension.  If a Deno
configuration file is found at project root, `deno-ts-mode' takes
precedence over `typescript-ts-mode'.  Both ".ts" and ".tsx" file
extensions are supported.

Example configuration:

(use-package deno-ts-mode
  :ensure t)

(use-package eglot
  :ensure t
  :hook ((deno-ts-mode . eglot-ensure)
         (deno-tsx-ts-mode . eglot-ensure)))
