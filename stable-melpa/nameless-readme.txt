Usage
─────

  To use this package add the following configuration to your Emacs init
  file.

  ┌────
  │ (add-hook 'emacs-lisp-mode-hook #'nameless-mode)
  └────

  You can configure a string to use instead of `:' by setting the
  `nameless-prefix', and the name of the face used is `nameless-face'.

  While the mode is active, the `_' key inserts the package
  namespace if appropriate.
