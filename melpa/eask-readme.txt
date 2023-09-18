
This package provides everything you need for Eask CLI development.

  - auto-completion
  - eldoc
  - code navigation
  - peek definition

Generally, you would not want to call any of these functions or use any of
these variables from your Emacs editor environment.  Unless you are extending
Eask's core functionalities.

(@* "Usage" )

Call the following whenever you need the to know Eask's API,

  (require 'eask-core)

Or enable it when the project is a valid Eask project,

  (add-hook 'emacs-lisp-hook #'eask-api-setup)

For more information, please visit our repo page
https://github.com/emacs-eask/eask-api
