This library adds the following help functions and support for Eshell:
- run-help function inspired by Zsh
- eldoc support

To use this package, add these lines to your .emacs file:
    (require 'esh-help)
    (setup-esh-help-eldoc)  ;; To use eldoc in Eshell
And by using M-x eldoc-mode in Eshell, you can see help strings
for the pointed command in minibuffer.
And by using M-x esh-help-run-help, you can see full help string
for the command.
