Peep dired items using posframe.

To use this package, simply add this to your init.el:
  (add-hook 'dired-mode-hook 'dired-posframe-mode)

Or, you can use manual dired-posframe.  Hide posframe to type C-g.
  (define-key global-map (kbd "C-*") 'dired-posframe-show)
