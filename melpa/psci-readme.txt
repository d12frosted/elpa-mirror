Provides a simple interface to evaluate Purescript expression.
Input is handled by the comint package.

To start psci repl:
M-x psci.  Type C-h m in the *psci* buffer for more info.

To activate some basic bindings, you can add the following hook
to purescript-mode:
(add-hook 'purescript-mode-hook 'inferior-psci-mode)

To come back and forth between a purescript-mode buffer and
repl, you could use repl-toggle (available on melpa):
(require 'repl-toggle)
(add-to-list 'rtog/mode-repl-alist '(purescript-mode . psci))

More informations: https://ardumont/emacs-psci
Issue tracker: https://github.com/purescript-emacs/emacs-psci/issues
