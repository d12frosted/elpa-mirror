This package provides integration with shadowenv environment shadowing.
Lists the number of shadowed environment variables in the mode line.
See https://shopify.github.io/shadowenv/ for more details.

; Commands

`shadowenv-mode' Toggle shadowenv mode in a buffer.
`shadowenv-global-mode' Enable global shadowenv mode.
`shadowenv-reload' Reload shadowenv environment.
`shadowenv-shadows' Display changes to the current environment.

; use-package

Here's an example use-package configuration:

(use-package shadowenv
  :hook (after-init . shadowenv-global-mode))
