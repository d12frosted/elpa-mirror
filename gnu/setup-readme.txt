The `setup' macro simplifies repetitive configuration patterns.
For example, these macros:

    (setup shell
      (let ((key "C-c s"))
        (:global key shell)
        (:bind key bury-buffer)))


    (setup (:package paredit)
      (:hide-mode)
      (:hook-into scheme-mode lisp-mode))

   (setup (:package yasnippet)
     (:with-mode yas-minor-mode
     (:rebind "<backtab>" yas-expand)
     (:option yas-prompt-functions '(yas-completing-prompt)
              yas-wrap-around-region t)
     (:hook-into prog-mode)))

will be replaced with the functional equivalent of

    (global-set-key (kbd "C-c s") #'shell)
    (with-eval-after-load 'shell
       (define-key shell-mode-map (kbd "C-c s") #'bury-buffer))


    (unless (package-install-p 'paredit)
      (package-install 'paredit ))
    (delq (assq 'paredit-mode minor-mode-alist)
          minor-mode-alist)
    (add-hook 'scheme-mode-hook #'paredit-mode)
    (add-hook 'lisp-mode-hook #'paredit-mode)

   (unless (package-install-p 'yasnippet)
     (package-install 'yasnippet))
   (with-eval-after-load 'yasnippet
     (dolist (key (where-is-internal 'yas-expand yas-minor-mode-map))
     (define-key yas-minor-mode-map key nil))
     (define-key yas-minor-mode-map "<backtab>" #'yas-expand)
     (customize-set-variable 'yas-prompt-functions '(yas-completing-prompt))
     (customize-set-variable 'yas-wrap-around-region t))
   (add-hook 'prog-mode-hook #'yas-minor-mode)


Additional "keywords" can be defined using `setup-define'.  All
known keywords are documented in the docstring for `setup'.