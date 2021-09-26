The `setup` macro simplifies repetitive configuration patterns, by
providing context-sensitive local macros in `setup` bodies.  These
macros can be mixed with regular elisp code without any issues,
allowing for flexible and terse configurations.

For example, these macros:

   (setup shell
     (let ((key (kbd "C-c s")))
       (:global key shell)
       (:bind key bury-buffer)))

   (setup dired
     (:also-load dired-x)
     (:option (prepend dired-guess-shell-alist-user) '("" "xdg-open")
              dired-dwim-target t)
     (unless global-auto-revert-mode
       (:hook auto-revert-mode)))

   (setup (:package company)
     (:bind "M-TAB" company-complete)
     (:hook-into prog-mode conf-mode))


expanded to the to the functional equivalent of

   (let ((key "C-c s"))
     (global-set-key (kbd key) #'shell)
     (with-eval-after-load 'shell
       (define-key shell-mode-map (kbd key) #'bury-buffer)))

   (with-eval-after-load 'dired
     (require 'dired-x))
   (customize-set-variable 'dired-guess-shell-alist-user
                           (cons '("" "xdg-open")
                                 dired-guess-shell-alist-user))
   (customize-set-variable 'dired-dwim-target t)
   (unless global-auto-revert-mode
     (add-hook 'dired-mode-hook #'auto-revert-mode))

   (unless (package-install-p 'company)
     (package-install 'company))
   (with-eval-after-load 'company
     (define-key company-mode-map (kbd "M-TAB") #'company-complete))
   (add-hook 'prog-mode-hook #'company-mode)
   (add-hook 'conf-mode-hook #'company-mode)

Additional "keywords" can be defined using `setup-define'.  All
known keywords are documented in the docstring for `setup'.

More information can be found on Emacs Wiki:
https://www.emacswiki.org/emacs/SetupEl