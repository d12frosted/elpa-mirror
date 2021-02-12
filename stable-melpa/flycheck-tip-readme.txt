Usage:
Basic setting

  (require 'flycheck-tip)
  (define-key your-prog-mode (kbd "C-c C-n") 'flycheck-tip-cycle)
  (setq flycheck-display-errors-function 'ignore)

If you are still using flymake, you can use combined function that
show error by popup in flymake-mode or flycheck-mode.

  (define-key global-map (kbd "C-0") 'error-tip-cycle-dwim)
  (define-key global-map (kbd "C-9") 'error-tip-cycle-dwim-reverse)

If you build Emacs with D-Bus option, you may configure following setting.
This keeps the errors on notification area.  Please check
‘error-tip-notify-timeout’ to change limit of the timeout as well.

  (setq error-tip-notify-keep-messages t)
