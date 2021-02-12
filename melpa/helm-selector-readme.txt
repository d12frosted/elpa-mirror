
Helm Selector is a collection of Helm (https://emacs-helm.github.io/helm/)
helper functions for convenient buffer selection.

It is especially helpful to create Helm sessions to navigate buffers of a
given mode in a "do what I mean" fashion:

- If current buffer is not of mode X, switch to last buffer of mode X, or
  create one if none exists.
- If current buffer is of mode X, show a Helm session of all buffers in mode X.

In the Helm session, it's also possible to input an arbitrary name which will be
used for the creation of a new buffer of mode X.

Helm Selector comes with a bunch of predefined selectors which should be
autoloaded.  Here follows an example setup to bind the Info and the shell
selector:

(require 'helm-selector)
(global-set-key (kbd "C-h i") 'helm-selector-info)
(global-set-key (kbd "s-RET") 'helm-selector-shell)
(global-set-key (kbd "s-S-RET") 'helm-selector-shell-other-window)

Calling `helm-selector-shell' with a prefix argument is equivalent to
`helm-selector-shell-other-window'.
