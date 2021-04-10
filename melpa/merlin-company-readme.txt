(require 'merlin-company) should be enough to get merlin to work within
company.

If you always want company-mode to be available, consider adding:
  (add-hook 'after-init-hook #'global-company-mode)
in your .emacs.
