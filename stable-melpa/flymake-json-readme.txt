
Usage:
  (require 'flymake-json)

Then, if you're using `json-mode':

  (add-hook 'json-mode 'flymake-json-load)

or, if you use `js-mode' for json:

  (add-hook 'js-mode-hook 'flymake-json-maybe-load)

otherwise:

  (add-hook 'find-file-hook 'flymake-json-maybe-load)

Uses flymake-easy, from https://github.com/purcell/flymake-easy
