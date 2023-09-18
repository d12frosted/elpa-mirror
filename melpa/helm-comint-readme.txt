
You can bind this as follows in .emacs:

(add-hook 'comint-mode-hook
          (lambda ()
              (define-key comint-mode-map (kbd "M-s f") 'helm-comint-prompts-all)))
