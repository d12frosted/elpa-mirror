To find shell-history, you can use `M-x helm-shell-history' command

; Preference setting:
(use-package 'helm-shell-history
		:ensure t
		:config
		(setq helm-shell-history-file "~/.zsh_history")
		(add-hook 'shell-mode-hook
          (lambda ()
            (define-key shell-mode-map (kbd "M-r") 'helm-shell-history))))
