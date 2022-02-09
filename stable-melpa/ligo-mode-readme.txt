This provides font lock and other support for the three dialects of
the Ligo smart contract language for the Tezos blockchain.

For users of `lsp-mode', setup can be performed automatically by
calling the command `ligo-setup-lsp', or with the following snippet
in an init file:

  (with-eval-after-load 'lsp-mode
    (with-eval-after-load 'ligo-mode
      (ligo-setup-lsp)))
