Add memo to directory and show it in dired.

To use this package, simply add this to your init.el:
  (add-hook 'dired-mode-hook 'dired-lsi-mode)

If you use `dired-git', I suggest below customize.
  (setq dired-lsi--create-spacer-fn
        (lambda () (when all-the-icons-dired-mode "  \t")))
