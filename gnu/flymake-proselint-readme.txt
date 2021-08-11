This package adds support for proselint (http://proselint.com/) in Flymake.

Once installed, the backend can be enabled with:
(add-hook 'markdown-mode-hook #'flymake-proselint-setup)