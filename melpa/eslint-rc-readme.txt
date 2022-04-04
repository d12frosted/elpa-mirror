
Formats your JavaScript & Typescript code using ESLint and defined rc rules.

Usage
-----

    Running `eslint-rc` will look on the current project's folder for any
    defined `.eslintrc.*` and `.eslintignore` rules and automatically pass
    them to ESLint on the current buffer.

      M-x eslint-rc

    To automatically format after saving:

      (add-hook 'typescript-mode-hook 'eslint-rc-mode)
      (add-hook 'js2-mode-hook 'eslint-rc-mode)
      (add-hook 'web-mode-hook 'eslint-rc-mode)
