Hide dotfiles in dired.

To activate this mode add something like this to your init.el:

    (defun my-dired-mode-hook ()
      "My `dired' mode hook."
      ;; To hide dot-files by default
      (dired-hide-dotfiles-mode))

    ;; To toggle hiding
    (define-key dired-mode-map "." #'dired-hide-dotfiles-mode)
    (add-hook 'dired-mode-hook #'my-dired-mode-hook)
