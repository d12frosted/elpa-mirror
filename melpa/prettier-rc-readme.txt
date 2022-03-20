Formats your JavaScript & Typescript code using Prettier and defined rc rules.

Usage
-----

    Running `prettier-rc` will look on the current project's folder for any
    defined `.prettierrc.*`, `prettier.config.*`, `.prettierignore` and
    `.editorconfig` rules and automatically pass them to Prettier on the
    current buffer.

      M-x prettier-rc

    To automatically format after saving:

      (add-hook 'typescript-mode-hook 'prettier-rc-mode)
      (add-hook 'js2-mode-hook 'prettier-rc-mode)
      (add-hook 'web-mode-hook 'prettier-rc-mode)
