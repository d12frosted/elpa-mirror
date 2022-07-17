
Support for lsp code actions,

1) Add sideline-lsp to sideline backends list,

  (setq sideline-backends-right '(sideline-lsp))

2) Then enable sideline-mode in the target buffer,

  M-x sideline-mode

Make sure your have lsp-mode enabled, and connected to the language server.
