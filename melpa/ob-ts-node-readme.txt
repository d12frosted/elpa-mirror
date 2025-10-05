
Org-Babel support for evaluating TypeScript code blocks using ts-node.
See: https://github.com/TypeStrong/ts-node

Requirements:
- Node.js
- ts-node

Integration:
- Emacs >=29: uses built-in `typescript-ts-mode`
- Emacs <29: falls back to built-in `typescript-mode` (lisp/progmodes/typescript.el)
- If neither mode is available (non-standard builds): fallback to `js-mode`.

Provides:
- Execution of `#+begin_src typescript` and `#+begin_src ts` blocks
- Automatic tangling to `.ts` files
