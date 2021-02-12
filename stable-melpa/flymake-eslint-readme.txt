A backend for Flymake which uses eslint.  Enable it with `M-x flymake-eslint-enable [RET]'.
Alternately, configure a mode-hook for your Javascript major mode of choice:

(add-hook 'some-js-major-mode-hook
  (lambda () (flymake-eslint-enable))

A handful of configurable options can be found in the `flymake-eslint' customization group: view and modify them with the command `M-x customize-group [RET] flymake-eslint [RET]'.

; License: MIT
