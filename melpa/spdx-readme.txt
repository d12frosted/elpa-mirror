Insert SPDX license identifiers and copyright notices using the current
major mode's comment syntax.  Requires Emacs 29.1 or later.  License IDs
are bundled with the package; normal insertion needs no network access.

With MELPA configured, install using M-x package-install RET spdx RET.
An example init-file configuration:

  (use-package spdx
    :ensure t
    :bind (:map prog-mode-map
           ("C-c i l" . spdx-insert-spdx)))

Run M-x spdx-insert-spdx to choose a license with `completing-read' and
insert its header at point.  `spdx-insert-spdx-copyright' inserts both
copyright and license headers; `spdx-insert-copyright' inserts only the
copyright notice.  `spdx-insert-spdx-only' omits comment delimiters, and
`spdx-insert-spdx-identifier-only' inserts just the license ID.
These commands do not replace existing headers or update their years.

Lisp callers can supply optional arguments to skip individual prompts:

  (spdx-insert-spdx "MIT")
  (spdx-insert-spdx-copyright "MIT" "(C) 2026 Alice")

Omitted or nil values still prompt.  In particular, supplying only "MIT"
to `spdx-insert-spdx-copyright' still prompts for copyright text.
A non-nil final NO-PROMPT argument prohibits all prompts:

  (spdx-insert-spdx-copyright "MIT" "(C) 2026 Alice" t)

In this mode, missing inputs signal an error before insertion.  Commands
that insert comments also require configured comment syntax.  Licenses
must be single IDs from the bundled database; compound SPDX expressions
are not supported.  Copyright text must be a non-blank, single-line body,
including any desired year and sign.  `spdx-copyright-prefix' is added
automatically.

For snippets that need a string, `spdx-identifier-only',
`spdx-license-format', and `spdx-copyright-format' accept an optional
value and NO-PROMPT and return text without modifying the buffer.

Enable Tempo templates with:

  (add-hook 'prog-mode-hook #'spdx-tempo-setup)

Run M-x spdx-tempo-setup once for an existing buffer.  Type one of the
tags spdx, spdxo, spdxi, cpy, or spdxcpy, then run
M-x tempo-expand-if-complete to expand it.

Use M-x customize-group RET spdx RET to configure copyright defaults,
project detection, and whether deprecated license IDs are excluded.
See README.md in the repository for all options, examples, and details:
https://github.com/condy0919/spdx.el#readme
