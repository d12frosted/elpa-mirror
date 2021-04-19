The `setup' macro simplifies repetitive configuration patterns.
For example, these macros:

   (setup shell
     (let ((key (kbd "C-c s")))
       (:global key shell)
       (:bind key bury-buffer)))

   (setup dired
     (:also-load dired-x)
     (:option (prepend dired-guess-shell-alist-user) '("" "xdg-open")
              dired-dwim-target t)
     (:hook auto-revert-mode))

   (setup (:package paredit)
     (:hide-mode)
     (:hook-into scheme-mode lisp-mode))

will be replaced with the functional equivalent of

   (global-set-key (kbd "C-c s") #'shell)
   (with-eval-after-load 'shell
     (define-key shell-mode-map (kbd "C-c s") #'bury-buffer))

   (with-eval-after-load 'dired
     (require 'dired-x))
   (customize-set-variable 'dired-guess-shell-alist-user
                           (cons '("" "xdg-open")
                                 dired-guess-shell-alist-user))
   (customize-set-variable 'dired-dwim-target t)
   (add-hook 'dired-mode-hook #'auto-revert-mode)

   (unless (package-install-p 'paredit)
     (package-install 'paredit))
   (setq minor-mode-alist
         (delq (assq 'paredit-mode minor-mode-alist)
               minor-mode-alist))
   (add-hook 'scheme-mode-hook #'paredit-mode)
   (add-hook 'lisp-mode-hook #'paredit-mode)

Additional "keywords" can be defined using `setup-define'.  All
known keywords are documented in the docstring for `setup'.