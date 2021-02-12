Show flycheck error messages using posframe.el

;; Setup

(with-eval-after-load 'flycheck
   (require 'flycheck-posframe)
   (add-hook 'flycheck-mode-hook #'flycheck-posframe-mode))
