`ac-ispell.el' provides ispell/aspell completion source for auto-complete.
You can use English word completion with it.

To use this package, add following code to your init.el or .emacs

   ;; Completion words longer than 4 characters
   (custom-set-variables
     '(ac-ispell-requires 4)
     '(ac-ispell-fuzzy-limit 4))

   (eval-after-load "auto-complete"
     '(progn
         (ac-ispell-setup)))

   (add-hook 'git-commit-mode-hook 'ac-ispell-ac-setup)
   (add-hook 'mail-mode-hook 'ac-ispell-ac-setup)
