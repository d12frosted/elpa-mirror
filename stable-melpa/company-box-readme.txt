
A company front-end

Differences with the built-in front-end:

- Different colors for differents backends.
- Icons associated to functions/variables/.. and their backends
- Display candidate's documentation (support quickhelp-string)
- Not limited by the current window size, buffer's text properties, ..
  (it's better than you might think)

This package requires Emacs 26.
Also, not compatible with Emacs in a tty.


Installation:

With use-package:
(use-package company-box
  :hook (company-mode . company-box-mode))
Or:
(require 'company-box)
(add-hook 'company-mode-hook 'company-box-mode)

To customize:
M-x customize-group [RET] company-box [RET]


For more informations, see the homepage:
https://github.com/sebastiencs/company-box
